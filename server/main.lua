local RSGCore = exports['rsg-core']:GetCoreObject()

-- ============================================
-- КЭШИ И ПЕРЕМЕННЫЕ
-- ============================================
local storageAccessSettings = {}
local salarySettings = {}
local playerWorkTime = {} -- Отслеживание времени работы игроков онлайн

-- ============================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================

-- Форматирование денег
local function FormatMoney(amount)
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Отправка уведомления
local function SendNotify(playerId, message, type)
    TriggerClientEvent('ox_lib:notify', playerId, {
        title = 'Бизнес',
        description = message,
        type = type or 'info'
    })
end
-- ============================================
-- ОПРЕДЕЛЕНИЕ БЛИЖАЙШЕГО БАНКА
-- ============================================

-- Функция расчёта расстояния между двумя точками
local function GetDistance(coords1, coords2)
    local dx = coords1.x - coords2.x
    local dy = coords1.y - coords2.y
    local dz = coords1.z - coords2.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Получение ближайшего банка к бизнесу
local function GetNearestBank(businessId)
    local business = Config.Businesses[businessId]
    if not business then 
        return {name = 'bank', label = 'Банк Сан-Дени', moneytype = 'bank'}
    end
    
    local businessCoords = business.menuPosition
    local nearestBank = Config.Banks[1]
    local nearestDistance = 999999
    
    for _, bank in ipairs(Config.Banks) do
        local distance = GetDistance(businessCoords, bank.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestBank = bank
        end
    end
    
    if Config.Debug then
        print(('[rsg-businessmenu] Nearest bank for %s: %s (distance: %.2f)'):format(businessId, nearestBank.label, nearestDistance))
    end
    
    return nearestBank
end

-- Добавление денег в банк через rsg-banking moneytype
local function AddMoneyToPlayerBank(Player, amount, bank, reason)
    local src = Player.PlayerData.source
    local moneyType = bank.moneytype
    
    -- Используем стандартную функцию RSGCore для добавления денег
    -- rsg-banking использует moneytype как тип денег
    local success = Player.Functions.AddMoney(moneyType, amount, reason)
    
    if success then
        if Config.Debug then
            print(('[rsg-businessmenu] Added $%d to %s (moneytype: %s)'):format(amount, Player.PlayerData.citizenid, moneyType))
        end
        
        -- Обновляем UI банка
        TriggerClientEvent('rsg-banking:client:updateBalance', src)
        
        return true
    else
        -- Если не удалось через RSGCore, пробуем напрямую в БД
        if Config.Debug then
            print(('[rsg-businessmenu] RSGCore.AddMoney failed, trying direct DB update'):format())
        end
        
        -- Обновляем напрямую в таблице players (money JSON)
        local playerData = MySQL.query.await('SELECT money FROM players WHERE citizenid = ?', {Player.PlayerData.citizenid})
        if playerData and playerData[1] then
            local money = json.decode(playerData[1].money) or {}
            money[moneyType] = (money[moneyType] or 0) + amount
            
            MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', 
                {json.encode(money), Player.PlayerData.citizenid})
            
            -- Обновляем данные игрока
            Player.PlayerData.money[moneyType] = money[moneyType]
            Player.Functions.SetPlayerData('money', Player.PlayerData.money)
            
            TriggerClientEvent('rsg-banking:client:updateBalance', src)
            
            return true
        end
    end
    
    return false
end

-- Проверка и выплата зарплаты
local function CheckAndPaySalary(citizenid)
    local data = playerWorkTime[citizenid]
    if not data then return false end
    
    local minutesThisSession = math.floor((os.time() - data.startTime) / 60)
    local totalMinutes = data.minutesWorked + minutesThisSession
    
    if totalMinutes < 60 then
        return false
    end
    
    local Player = RSGCore.Functions.GetPlayerByCitizenId(citizenid)
    if not Player then return false end
    
    local business = Config.Businesses[data.businessId]
    if not business then return false end
    
    local grade = Player.PlayerData.job.grade.level or 0
    local salary = 0
    
    if salarySettings[data.businessId] and salarySettings[data.businessId][grade] then
        salary = salarySettings[data.businessId][grade]
    end
    
    if salary <= 0 then
        if Config.Debug then
            print(('[rsg-businessmenu] No salary for %s grade %d'):format(data.businessId, grade))
        end
        return false
    end
    
    -- Проверяем кассу
    local cashResult = MySQL.query.await('SELECT cash_balance FROM business_cash WHERE business_id = ?', {data.businessId})
    local cashBalance = (cashResult and cashResult[1]) and cashResult[1].cash_balance or 0
    
    if cashBalance < salary then
        TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
            title = business.label,
            description = 'Недостаточно средств в кассе для зарплаты',
            type = 'error',
            duration = 10000
        })
        return false
    end
    
    -- Определяем ближайший банк к бизнесу
    local nearestBank = GetNearestBank(data.businessId)
    
    -- Выплачиваем в банк
    local paySuccess = AddMoneyToPlayerBank(Player, salary, nearestBank, 'business-salary-' .. data.businessId)
    
    if not paySuccess then
        if Config.Debug then
            print(('[rsg-businessmenu] Failed to pay salary to %s'):format(citizenid))
        end
        return false
    end
    
    -- Списываем из кассы
    MySQL.update.await('UPDATE business_cash SET cash_balance = cash_balance - ? WHERE business_id = ?', 
        {salary, data.businessId})
    
    -- Сбрасываем счётчик (оставляем остаток)
    local remainingMinutes = totalMinutes - 60
    playerWorkTime[citizenid].minutesWorked = remainingMinutes
    playerWorkTime[citizenid].startTime = os.time()
    
    MySQL.update.await('UPDATE business_work_time SET minutes_worked = ? WHERE citizenid = ? AND business_id = ?',
        {remainingMinutes, citizenid, data.businessId})
    
    -- Уведомление
    TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
        title = Config.Locale.salary_received,
        description = string.format('$%s от %s (%s)', FormatMoney(salary), business.label, nearestBank.label),
        type = 'success',
        duration = 8000
    })
    
    if Config.Debug then
        print(('[rsg-businessmenu] Paid $%d to %s at %s for 1 hour at %s'):format(salary, citizenid, nearestBank.label, data.businessId))
    end
    
    return true
end
-- Уведомление всем сотрудникам бизнеса
local function NotifyBusinessEmployees(businessId, message, type, excludeSource)
    local business = Config.Businesses[businessId]
    if not business then return end
    
    local players = RSGCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        if playerId ~= excludeSource then
            local Player = RSGCore.Functions.GetPlayer(playerId)
            if Player and Player.PlayerData.job and Player.PlayerData.job.name == business.job then
                SendNotify(playerId, message, type)
            end
        end
    end
end

-- Форматирование времени аренды
local function FormatRentTime(mysqlTimestamp)
    if not mysqlTimestamp then 
        return "Не указано" 
    end
    
    local rentTime = nil
    local now = os.time()
    
    if type(mysqlTimestamp) == "number" then
        if mysqlTimestamp > 9999999999 then
            rentTime = math.floor(mysqlTimestamp / 1000)
        else
            rentTime = mysqlTimestamp
        end
    elseif type(mysqlTimestamp) == "string" then
        local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
        local year, month, day, hour, min, sec = mysqlTimestamp:match(pattern)
        
        if year then
            rentTime = os.time({
                year = tonumber(year), 
                month = tonumber(month), 
                day = tonumber(day), 
                hour = tonumber(hour), 
                min = tonumber(min), 
                sec = tonumber(sec)
            })
        else
            local pattern2 = "(%d+)-(%d+)-(%d+)"
            year, month, day = mysqlTimestamp:match(pattern2)
            if year then
                rentTime = os.time({
                    year = tonumber(year), 
                    month = tonumber(month), 
                    day = tonumber(day), 
                    hour = 0, 
                    min = 0, 
                    sec = 0
                })
            end
        end
    elseif type(mysqlTimestamp) == "table" then
        if mysqlTimestamp.year then
            rentTime = os.time(mysqlTimestamp)
        end
    end
    
    if not rentTime then
        return "Ошибка данных"
    end
    
    local diff = rentTime - now
    
    if diff <= 0 then
        return "Просрочено!"
    end
    
    local days = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    local minutes = math.floor((diff % 3600) / 60)
    
    local parts = {}
    
    if days > 0 then
        table.insert(parts, days .. ' дн.')
    end
    
    if hours > 0 then
        table.insert(parts, hours .. ' ч.')
    end
    
    if days == 0 and minutes > 0 then
        table.insert(parts, minutes .. ' мин.')
    end
    
    if #parts == 0 then
        return "Менее минуты"
    end
    
    return table.concat(parts, ' ')
end

-- ============================================
-- ЗАГРУЗКА НАСТРОЕК
-- ============================================

local function LoadStorageSettings()
    local result = MySQL.query.await('SELECT * FROM business_storage_access')
    if result then
        for _, row in ipairs(result) do
            if not storageAccessSettings[row.business_id] then
                storageAccessSettings[row.business_id] = {}
            end
            storageAccessSettings[row.business_id][row.storage_index] = row.min_grade
        end
    end
    if Config.Debug then
        print('[rsg-businessmenu] Loaded storage settings')
    end
end

local function LoadSalarySettings()
    local result = MySQL.query.await('SELECT * FROM business_salaries')
    if result then
        for _, row in ipairs(result) do
            if not salarySettings[row.business_id] then
                salarySettings[row.business_id] = {}
            end
            salarySettings[row.business_id][row.grade] = row.salary
        end
    end
    if Config.Debug then
        print('[rsg-businessmenu] Loaded salary settings')
    end
end

-- Инициализация
CreateThread(function()
    Wait(1000)
    LoadStorageSettings()
    LoadSalarySettings()
end)

-- ============================================
-- СИСТЕМА ОТСЛЕЖИВАНИЯ ВРЕМЕНИ РАБОТЫ
-- ============================================

-- Начало отслеживания времени работы
local function StartTrackingWorkTime(citizenid, job)
    local businessId = nil
    for bizId, biz in pairs(Config.Businesses) do
        if biz.job == job then
            businessId = bizId
            break
        end
    end
    
    if not businessId then return end
    
    -- Загружаем сохранённое время из БД
    local result = MySQL.query.await('SELECT minutes_worked FROM business_work_time WHERE citizenid = ? AND business_id = ?', 
        {citizenid, businessId})
    
    local minutesWorked = 0
    if result and result[1] then
        minutesWorked = result[1].minutes_worked or 0
    else
        MySQL.insert.await('INSERT INTO business_work_time (citizenid, business_id, minutes_worked) VALUES (?, ?, 0)', 
            {citizenid, businessId})
    end
    
    playerWorkTime[citizenid] = {
        businessId = businessId,
        job = job,
        minutesWorked = minutesWorked,
        startTime = os.time()
    }
    
    if Config.Debug then
        print(('[rsg-businessmenu] Started tracking for %s at %s (%d min already)'):format(citizenid, businessId, minutesWorked))
    end
end

-- Остановка отслеживания и сохранение
local function StopTrackingWorkTime(citizenid)
    if not playerWorkTime[citizenid] then return end
    
    local data = playerWorkTime[citizenid]
    local minutesThisSession = math.floor((os.time() - data.startTime) / 60)
    local totalMinutes = data.minutesWorked + minutesThisSession
    
    MySQL.update.await('UPDATE business_work_time SET minutes_worked = ? WHERE citizenid = ? AND business_id = ?',
        {totalMinutes, citizenid, data.businessId})
    
    if Config.Debug then
        print(('[rsg-businessmenu] Stopped tracking for %s: %d min session, %d total'):format(citizenid, minutesThisSession, totalMinutes))
    end
    
    playerWorkTime[citizenid] = nil
end

-- Проверка и выплата зарплаты
local function CheckAndPaySalary(citizenid)
    local data = playerWorkTime[citizenid]
    if not data then return false end
    
    local minutesThisSession = math.floor((os.time() - data.startTime) / 60)
    local totalMinutes = data.minutesWorked + minutesThisSession
    
    if totalMinutes < 60 then
        return false
    end
    
    local Player = RSGCore.Functions.GetPlayerByCitizenId(citizenid)
    if not Player then return false end
    
    local business = Config.Businesses[data.businessId]
    if not business then return false end
    
    local grade = Player.PlayerData.job.grade.level or 0
    local salary = 0
    
    if salarySettings[data.businessId] and salarySettings[data.businessId][grade] then
        salary = salarySettings[data.businessId][grade]
    end
    
    if salary <= 0 then
        if Config.Debug then
            print(('[rsg-businessmenu] No salary for %s grade %d'):format(data.businessId, grade))
        end
        return false
    end
    
    -- Проверяем кассу
    local cashResult = MySQL.query.await('SELECT cash_balance FROM business_cash WHERE business_id = ?', {data.businessId})
    local cashBalance = (cashResult and cashResult[1]) and cashResult[1].cash_balance or 0
    
    if cashBalance < salary then
        TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
            title = business.label,
            description = 'Недостаточно средств в кассе для зарплаты',
            type = 'error',
            duration = 10000
        })
        return false
    end
    
    -- Определяем ближайший банк к бизнесу
    local nearestBank = GetNearestBank(data.businessId)
    
    -- Выплачиваем в банк города
    AddMoneyToPlayerBank(Player, salary, nearestBank, 'business-salary-' .. data.businessId)
    
    -- Списываем из кассы
    MySQL.update.await('UPDATE business_cash SET cash_balance = cash_balance - ? WHERE business_id = ?', 
        {salary, data.businessId})
    
    -- Сбрасываем счётчик (оставляем остаток)
    local remainingMinutes = totalMinutes - 60
    playerWorkTime[citizenid].minutesWorked = remainingMinutes
    playerWorkTime[citizenid].startTime = os.time()
    
    MySQL.update.await('UPDATE business_work_time SET minutes_worked = ? WHERE citizenid = ? AND business_id = ?',
        {remainingMinutes, citizenid, data.businessId})
    
    -- Получаем название банка для уведомления
    local bankLabel = nearestBank
    for _, bank in ipairs(Config.Banks) do
        if bank.name == nearestBank then
            bankLabel = bank.label
            break
        end
    end
    
    -- Уведомление
    TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
        title = Config.Locale.salary_received,
        description = string.format('$%s от %s (%s)', FormatMoney(salary), business.label, bankLabel),
        type = 'success',
        duration = 8000
    })
    
    if Config.Debug then
        print(('[rsg-businessmenu] Paid $%d to %s at %s bank for 1 hour at %s'):format(salary, citizenid, nearestBank, data.businessId))
    end
    
    return true
end

-- Поток проверки зарплат каждую минуту
CreateThread(function()
    Wait(10000)
    
    while true do
        for citizenid, _ in pairs(playerWorkTime) do
            CheckAndPaySalary(citizenid)
        end
        Wait(60000)
    end
end)

-- ============================================
-- ОБРАБОТЧИКИ СОБЫТИЙ ИГРОКОВ
-- ============================================

RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local job = Player.PlayerData.job.name
    if job and job ~= 'unemployed' then
        for _, business in pairs(Config.Businesses) do
            if business.job == job then
                StartTrackingWorkTime(Player.PlayerData.citizenid, job)
                break
            end
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        StopTrackingWorkTime(Player.PlayerData.citizenid)
    end
end)

RegisterNetEvent('RSGCore:Server:OnJobUpdate', function(src, job)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    StopTrackingWorkTime(citizenid)
    
    if job.name and job.name ~= 'unemployed' then
        for _, business in pairs(Config.Businesses) do
            if business.job == job.name then
                StartTrackingWorkTime(citizenid, job.name)
                break
            end
        end
    end
end)

-- ============================================
-- CALLBACKS
-- ============================================

-- Информация о бизнесе
RSGCore.Functions.CreateCallback('rsg-businessmenu:server:getBusinessInfo', function(source, cb, businessId)
    local business = Config.Businesses[businessId]
    if not business then
        cb({nextRent = nil, nextRentFormatted = "Не указано", employeesCount = 0})
        return
    end
    
    local rentData = MySQL.query.await('SELECT next_rent FROM player_businesses WHERE business_id = ?', {businessId})
    local nextRent = nil
    local nextRentFormatted = "Не указано"
    
    if rentData and rentData[1] and rentData[1].next_rent then
        nextRent = rentData[1].next_rent
        nextRentFormatted = FormatRentTime(nextRent)
    end
    
    local employeesResult = MySQL.query.await('SELECT COUNT(*) as count FROM player_jobs WHERE job = ?', {business.job})
    local employeesCount = 0
    if employeesResult and employeesResult[1] then
        employeesCount = employeesResult[1].count
    end
    
    cb({
        nextRent = nextRent,
        nextRentFormatted = nextRentFormatted,
        employeesCount = employeesCount
    })
end)

-- Проверка доступа к хранилищу
RSGCore.Functions.CreateCallback('rsg-businessmenu:server:checkStorageAccess', function(source, cb, businessId, storageIndex)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        cb(false)
        return
    end
    
    local business = Config.Businesses[businessId]
    if not business then
        cb(false)
        return
    end
    
    if Player.PlayerData.job.name ~= business.job then
        cb(false)
        return
    end
    
    local minGrade = business.storages[storageIndex].defaultMinGrade
    
    if storageAccessSettings[businessId] and storageAccessSettings[businessId][storageIndex] then
        minGrade = storageAccessSettings[businessId][storageIndex]
    end
    
    if Player.PlayerData.job.isboss then
        cb(true)
        return
    end
    
    local playerGrade = Player.PlayerData.job.grade.level or 0
    cb(playerGrade >= minGrade)
end)

-- Настройки хранилищ
RSGCore.Functions.CreateCallback('rsg-businessmenu:server:getStorageSettings', function(source, cb, businessId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end
    
    local business = Config.Businesses[businessId]
    if not business then
        cb({})
        return
    end
    
    if not Player.PlayerData.job.isboss or Player.PlayerData.job.name ~= business.job then
        cb({})
        return
    end
    
    local settings = {}
    for i, storage in ipairs(business.storages) do
        if storageAccessSettings[businessId] and storageAccessSettings[businessId][i] then
            settings[i] = storageAccessSettings[businessId][i]
        else
            settings[i] = storage.defaultMinGrade
        end
    end
    
    cb(settings)
end)

-- Баланс кассы
RSGCore.Functions.CreateCallback('rsg-businessmenu:server:getCashBalance', function(source, cb, businessId)
    local result = MySQL.query.await('SELECT cash_balance FROM business_cash WHERE business_id = ?', {businessId})
    
    if result and result[1] then
        cb(result[1].cash_balance or 0)
    else
        MySQL.insert.await('INSERT INTO business_cash (business_id, cash_balance) VALUES (?, 0) ON DUPLICATE KEY UPDATE business_id = business_id', {businessId})
        cb(0)
    end
end)

-- Грейды работы
RSGCore.Functions.CreateCallback('rsg-businessmenu:server:getJobGrades', function(source, cb, jobName)
    local grades = {}
    
    if RSGCore.Shared and RSGCore.Shared.Jobs and RSGCore.Shared.Jobs[jobName] then
        local jobData = RSGCore.Shared.Jobs[jobName]
        if jobData.grades then
            for gradeId, gradeData in pairs(jobData.grades) do
                grades[tostring(gradeId)] = gradeData.name or gradeData.label or ('Грейд ' .. gradeId)
            end
        end
    end
    
    if next(grades) == nil then
        grades = {
            ["0"] = "Сотрудник",
            ["1"] = "Старший сотрудник",
            ["2"] = "Менеджер", 
            ["3"] = "Владелец"
        }
    end
    
    cb(grades)
end)

-- Настройки зарплат
RSGCore.Functions.CreateCallback('rsg-businessmenu:server:getSalarySettings', function(source, cb, businessId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end
    
    local business = Config.Businesses[businessId]
    if not business then
        cb({})
        return
    end
    
    if not Player.PlayerData.job.isboss or Player.PlayerData.job.name ~= business.job then
        cb({})
        return
    end
    
    cb(salarySettings[businessId] or {})
end)

-- Информация о финансах
RSGCore.Functions.CreateCallback('rsg-businessmenu:server:getFinanceInfo', function(source, cb, businessId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil)
        return
    end
    
    local business = Config.Businesses[businessId]
    if not business then
        cb(nil)
        return
    end
    
    if not Player.PlayerData.job.isboss or Player.PlayerData.job.name ~= business.job then
        cb(nil)
        return
    end
    
    -- Баланс кассы
    local cashResult = MySQL.query.await('SELECT cash_balance FROM business_cash WHERE business_id = ?', {businessId})
    local cashBalance = (cashResult and cashResult[1]) and cashResult[1].cash_balance or 0
    
    -- Сотрудники онлайн и их зарплаты
    local onlinePlayers = RSGCore.Functions.GetPlayers()
    local totalHourlyPayroll = 0
    local activeEmployees = 0
    
    for _, playerId in ipairs(onlinePlayers) do
        local emp = RSGCore.Functions.GetPlayer(playerId)
        if emp and emp.PlayerData.job.name == business.job then
            activeEmployees = activeEmployees + 1
            local grade = emp.PlayerData.job.grade.level or 0
            
            if salarySettings[businessId] and salarySettings[businessId][grade] then
                totalHourlyPayroll = totalHourlyPayroll + salarySettings[businessId][grade]
            end
        end
    end
    
    -- Время до зарплаты текущего игрока
    local workTimeInfo = "Не отслеживается"
    local citizenid = Player.PlayerData.citizenid
    if playerWorkTime[citizenid] then
        local data = playerWorkTime[citizenid]
        local minutesThisSession = math.floor((os.time() - data.startTime) / 60)
        local totalMinutes = data.minutesWorked + minutesThisSession
        local minutesUntilPayday = 60 - (totalMinutes % 60)
        workTimeInfo = string.format("%d мин. до зарплаты", minutesUntilPayday)
    end
    
    cb({
        cashBalance = cashBalance,
        totalPayroll = totalHourlyPayroll,
        employeeCount = activeEmployees,
        timeUntilPayroll = workTimeInfo,
        canAffordPayroll = cashBalance >= totalHourlyPayroll
    })
end)

-- ============================================
-- СОБЫТИЯ (EVENTS)
-- ============================================

-- Открытие хранилища
RegisterNetEvent('rsg-businessmenu:server:openStorage', function(businessId, storageIndex)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local business = Config.Businesses[businessId]
    if not business then return end
    
    local storage = business.storages[storageIndex]
    if not storage then return end
    
    if Player.PlayerData.job.name ~= business.job then
        return
    end
    
    local minGrade = storage.defaultMinGrade
    if storageAccessSettings[businessId] and storageAccessSettings[businessId][storageIndex] then
        minGrade = storageAccessSettings[businessId][storageIndex]
    end
    
    local playerGrade = Player.PlayerData.job.grade.level or 0
    if not Player.PlayerData.job.isboss and playerGrade < minGrade then
        SendNotify(src, 'У вас нет доступа к этому хранилищу', 'error')
        return
    end
    
    exports['rsg-inventory']:OpenInventory(src, storage.id, {
        maxweight = storage.weight,
        slots = storage.slots,
        label = storage.label
    })
end)

-- Обновление доступа к хранилищу
RegisterNetEvent('rsg-businessmenu:server:updateStorageAccess', function(businessId, storageIndex, newGrade)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local business = Config.Businesses[businessId]
    if not business then return end
    
    if not Player.PlayerData.job.isboss or Player.PlayerData.job.name ~= business.job then
        SendNotify(src, 'Вы не являетесь владельцем бизнеса', 'error')
        return
    end
    
    if not storageAccessSettings[businessId] then
        storageAccessSettings[businessId] = {}
    end
    storageAccessSettings[businessId][storageIndex] = newGrade
    
    MySQL.insert.await([[
        INSERT INTO business_storage_access (business_id, storage_index, min_grade) 
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE min_grade = VALUES(min_grade)
    ]], {businessId, storageIndex, newGrade})
    
    SendNotify(src, 'Доступ к хранилищу обновлен', 'success')
end)

-- Внести деньги в кассу
RegisterNetEvent('rsg-businessmenu:server:depositCash', function(businessId, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local business = Config.Businesses[businessId]
    if not business then return end
    
    if Player.PlayerData.job.name ~= business.job then
        return
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        SendNotify(src, 'Неверная сумма', 'error')
        return
    end
    
    local playerCash = Player.PlayerData.money.cash or 0
    if playerCash < amount then
        SendNotify(src, 'Недостаточно средств', 'error')
        return
    end
    
    Player.Functions.RemoveMoney('cash', amount, 'business-cash-deposit')
    
    MySQL.update.await([[
        INSERT INTO business_cash (business_id, cash_balance) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE cash_balance = cash_balance + ?
    ]], {businessId, amount, amount})
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    SendNotify(src, 'Вы внесли $' .. FormatMoney(amount) .. ' в кассу', 'success')
    NotifyBusinessEmployees(businessId, playerName .. ' внёс $' .. FormatMoney(amount) .. ' в кассу', 'info', src)
end)

-- Забрать деньги из кассы
RegisterNetEvent('rsg-businessmenu:server:withdrawCash', function(businessId, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local business = Config.Businesses[businessId]
    if not business then return end
    
    if Player.PlayerData.job.name ~= business.job then
        return
    end
    
    local playerGrade = Player.PlayerData.job.grade.level or 0
    local minGrade = Config.Locale.cash_min_grade or 1
    
    if not Player.PlayerData.job.isboss and playerGrade < minGrade then
        SendNotify(src, 'У вас нет прав забирать деньги', 'error')
        return
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        SendNotify(src, 'Неверная сумма', 'error')
        return
    end
    
    local result = MySQL.query.await('SELECT cash_balance FROM business_cash WHERE business_id = ?', {businessId})
    local currentBalance = (result and result[1]) and result[1].cash_balance or 0
    
    if currentBalance < amount then
        SendNotify(src, 'Недостаточно средств в кассе', 'error')
        return
    end
    
    MySQL.update.await('UPDATE business_cash SET cash_balance = cash_balance - ? WHERE business_id = ?', {amount, businessId})
    Player.Functions.AddMoney('cash', amount, 'business-cash-withdraw')
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    SendNotify(src, 'Вы забрали $' .. FormatMoney(amount) .. ' из кассы', 'success')
    NotifyBusinessEmployees(businessId, playerName .. ' забрал $' .. FormatMoney(amount) .. ' из кассы', 'warning', src)
end)

-- Обновление зарплаты
RegisterNetEvent('rsg-businessmenu:server:updateSalary', function(businessId, grade, salary)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local business = Config.Businesses[businessId]
    if not business then return end
    
    if not Player.PlayerData.job.isboss or Player.PlayerData.job.name ~= business.job then
        SendNotify(src, 'Вы не являетесь владельцем бизнеса', 'error')
        return
    end
    
    salary = tonumber(salary) or 0
    if salary < 0 then salary = 0 end
    
    if not salarySettings[businessId] then
        salarySettings[businessId] = {}
    end
    salarySettings[businessId][grade] = salary
    
    MySQL.insert.await([[
        INSERT INTO business_salaries (business_id, grade, salary) 
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE salary = VALUES(salary)
    ]], {businessId, grade, salary})
    
    SendNotify(src, 'Зарплата обновлена', 'success')
end)

-- ============================================
-- КОМАНДЫ АДМИНИСТРАТОРА
-- ============================================

RSGCore.Commands.Add('refreshbusiness', 'Обновить настройки бизнесов (Admin)', {}, false, function(source)
    local src = source
    LoadStorageSettings()
    LoadSalarySettings()
    if src and src > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Администрирование',
            description = 'Настройки бизнесов обновлены',
            type = 'info'
        })
    end
    print('[rsg-businessmenu] Business settings reloaded')
end, 'admin')

RSGCore.Commands.Add('checkworktime', 'Проверить время работы игрока (Admin)', {{name = 'id', help = 'ID игрока'}}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    
    if not targetId then
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ошибка',
                description = 'Используйте: /checkworktime [id]',
                type = 'error'
            })
        end
        print('[rsg-businessmenu] Usage: /checkworktime [player_id]')
        return
    end
    
    local Player = RSGCore.Functions.GetPlayer(targetId)
    if not Player then
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ошибка',
                description = 'Игрок не найден',
                type = 'error'
            })
        end
        print('[rsg-businessmenu] Player not found')
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    if playerWorkTime[citizenid] then
        local data = playerWorkTime[citizenid]
        local minutesThisSession = math.floor((os.time() - data.startTime) / 60)
        local totalMinutes = data.minutesWorked + minutesThisSession
        local minutesUntilPay = 60 - (totalMinutes % 60)
        
        print('=== Work Time Info ===')
        print('Player: ' .. playerName .. ' (ID: ' .. targetId .. ')')
        print('CitizenID: ' .. citizenid)
        print('Business: ' .. data.businessId)
        print('Session time: ' .. minutesThisSession .. ' min')
        print('Total worked: ' .. totalMinutes .. ' min')
        print('Until payday: ' .. minutesUntilPay .. ' min')
        print('====================')
        
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Work Time',
                description = playerName .. ': ' .. totalMinutes .. ' мин. (до ЗП: ' .. minutesUntilPay .. ' мин.)',
                type = 'info'
            })
        end
    else
        print('[rsg-businessmenu] Player ' .. playerName .. ' is not working at any business')
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ошибка',
                description = 'Игрок не работает в бизнесе',
                type = 'error'
            })
        end
    end
end, 'admin')

RSGCore.Commands.Add('forcepayroll', 'Выплатить зарплату игроку (Admin)', {{name = 'id', help = 'ID игрока'}}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    
    if not targetId then
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ошибка',
                description = 'Используйте: /forcepayroll [id]',
                type = 'error'
            })
        end
        print('[rsg-businessmenu] Usage: /forcepayroll [player_id]')
        return
    end
    
    local Player = RSGCore.Functions.GetPlayer(targetId)
    if not Player then
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ошибка',
                description = 'Игрок не найден',
                type = 'error'
            })
        end
        print('[rsg-businessmenu] Player not found')
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    if playerWorkTime[citizenid] then
        -- Устанавливаем 60 минут для принудительной выплаты
        playerWorkTime[citizenid].minutesWorked = 60
        playerWorkTime[citizenid].startTime = os.time()
        
        if CheckAndPaySalary(citizenid) then
            print('[rsg-businessmenu] Force paid salary to ' .. playerName)
            if src and src > 0 then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Успешно',
                    description = 'Зарплата выплачена игроку ' .. playerName,
                    type = 'success'
                })
            end
        else
            print('[rsg-businessmenu] Failed to pay salary to ' .. playerName .. ' (check cash register or settings)')
            if src and src > 0 then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Ошибка',
                    description = 'Не удалось выплатить (проверьте кассу)',
                    type = 'error'
                })
            end
        end
    else
        print('[rsg-businessmenu] Player ' .. playerName .. ' is not working at any business')
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ошибка',
                description = 'Игрок не работает в бизнесе',
                type = 'error'
            })
        end
    end
end, 'admin')

RSGCore.Commands.Add('checksalaries', 'Проверить настройки зарплат (Admin)', {{name = 'business_id', help = 'ID бизнеса'}}, false, function(source, args)
    local src = source
    local businessId = args[1]
    
    if not businessId or not Config.Businesses[businessId] then
        print('=== Available businesses ===')
        for id, biz in pairs(Config.Businesses) do
            print('  - ' .. id .. ' (' .. biz.label .. ')')
        end
        print('============================')
        
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Информация',
                description = 'Список бизнесов в консоли сервера',
                type = 'info'
            })
        end
        return
    end
    
    local business = Config.Businesses[businessId]
    print('=== Salary settings for ' .. business.label .. ' ===')
    
    if salarySettings[businessId] and next(salarySettings[businessId]) then
        for grade, salary in pairs(salarySettings[businessId]) do
            print('  Grade ' .. grade .. ': $' .. salary)
        end
    else
        print('  No salaries configured')
    end
    
    -- Показываем онлайн сотрудников
    print('--- Online employees ---')
    local found = false
    for citizenid, data in pairs(playerWorkTime) do
        if data.businessId == businessId then
            local Player = RSGCore.Functions.GetPlayerByCitizenId(citizenid)
            if Player then
                local grade = Player.PlayerData.job.grade.level or 0
                local salary = (salarySettings[businessId] and salarySettings[businessId][grade]) or 0
                local minutesThisSession = math.floor((os.time() - data.startTime) / 60)
                local totalMinutes = data.minutesWorked + minutesThisSession
                
                print('  ' .. Player.PlayerData.charinfo.firstname .. ' (grade ' .. grade .. '): $' .. salary .. '/hr, worked ' .. totalMinutes .. ' min')
                found = true
            end
        end
    end
    
    if not found then
        print('  No employees online')
    end
    print('================')
    
    if src and src > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Информация',
            description = 'Данные в консоли сервера',
            type = 'info'
        })
    end
end, 'admin')

RSGCore.Commands.Add('resetworktime', 'Сбросить время работы игрока (Admin)', {{name = 'id', help = 'ID игрока'}}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    
    if not targetId then
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ошибка',
                description = 'Используйте: /resetworktime [id]',
                type = 'error'
            })
        end
        return
    end
    
    local Player = RSGCore.Functions.GetPlayer(targetId)
    if not Player then
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ошибка',
                description = 'Игрок не найден',
                type = 'error'
            })
        end
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    if playerWorkTime[citizenid] then
        playerWorkTime[citizenid].minutesWorked = 0
        playerWorkTime[citizenid].startTime = os.time()
        
        MySQL.update.await('UPDATE business_work_time SET minutes_worked = 0 WHERE citizenid = ?', {citizenid})
        
        print('[rsg-businessmenu] Reset work time for ' .. citizenid)
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Успешно',
                description = 'Время работы сброшено',
                type = 'success'
            })
        end
    else
        if src and src > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Ошибка',
                description = 'Игрок не работает в бизнесе',
                type = 'error'
            })
        end
    end
end, 'admin')

-- ============================================
-- ЭКСПОРТЫ
-- ============================================

exports('GetStorageAccess', function(businessId, storageIndex)
    if storageAccessSettings[businessId] and storageAccessSettings[businessId][storageIndex] then
        return storageAccessSettings[businessId][storageIndex]
    end
    local business = Config.Businesses[businessId]
    if business and business.storages[storageIndex] then
        return business.storages[storageIndex].defaultMinGrade
    end
    return 0
end)

exports('SetStorageAccess', function(businessId, storageIndex, grade)
    if not storageAccessSettings[businessId] then
        storageAccessSettings[businessId] = {}
    end
    storageAccessSettings[businessId][storageIndex] = grade
    
    MySQL.insert.await([[
        INSERT INTO business_storage_access (business_id, storage_index, min_grade) 
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE min_grade = VALUES(min_grade)
    ]], {businessId, storageIndex, grade})
end)

exports('GetGradeSalary', function(businessId, grade)
    if salarySettings[businessId] and salarySettings[businessId][grade] then
        return salarySettings[businessId][grade]
    end
    return 0
end)

exports('SetGradeSalary', function(businessId, grade, salary)
    if not salarySettings[businessId] then
        salarySettings[businessId] = {}
    end
    salarySettings[businessId][grade] = salary
    
    MySQL.insert.await([[
        INSERT INTO business_salaries (business_id, grade, salary) 
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE salary = VALUES(salary)
    ]], {businessId, grade, salary})
end)

exports('GetPlayerWorkTime', function(citizenid)
    if playerWorkTime[citizenid] then
        local data = playerWorkTime[citizenid]
        local minutesThisSession = math.floor((os.time() - data.startTime) / 60)
        return data.minutesWorked + minutesThisSession
    end
    return 0
end)