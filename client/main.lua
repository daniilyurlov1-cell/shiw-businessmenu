local RSGCore = exports['rsg-core']:GetCoreObject()
local createdBlips = {}
local isMenuOpen = false
local currentBusiness = nil
local PlayerData = {}
local isLoggedIn = false

-- Prompt
local interactionPrompt = nil
local promptGroup = GetRandomIntInRange(1, 0xffffff)

-- Предварительное объявление функций
local CreateBusinessBlips
local RemoveBusinessBlips
local CreateInteractionPrompt
local DeleteInteractionPrompt
local OpenBusinessMenu
local OpenStorageMenu
local OpenStorageSettingsMenu
local OpenCashRegisterMenu
local OpenFinancesMenu
local GetBusinessInfo
local GetCashBalance
local CheckStorageAccess

-- Дебаг функция
local function DebugPrint(msg)
    if Config.Debug then
        print('[BusinessMenu] ' .. msg)
    end
end

-- Форматирование денег с запятыми
local function FormatMoney(amount)
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Создание блипов
CreateBusinessBlips = function()
    for businessId, business in pairs(Config.Businesses) do
        if business.blip and business.blip.enabled then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, business.menuPosition.x, business.menuPosition.y, business.menuPosition.z)
            SetBlipSprite(blip, business.blip.sprite, true)
            SetBlipScale(blip, business.blip.scale)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, business.blip.name)
            createdBlips[businessId] = blip
            DebugPrint('Created blip for: ' .. businessId)
        end
    end
end

-- Удаление блипов
RemoveBusinessBlips = function()
    for _, blip in pairs(createdBlips) do
        RemoveBlip(blip)
    end
    createdBlips = {}
end

-- Создание prompt
CreateInteractionPrompt = function()
    if interactionPrompt then 
        DebugPrint('Prompt already exists')
        return 
    end
    
    local str = CreateVarString(10, "LITERAL_STRING", Config.Locale.press_to_open)
    interactionPrompt = PromptRegisterBegin()
    PromptSetControlAction(interactionPrompt, Config.InteractionKey)
    PromptSetText(interactionPrompt, str)
    PromptSetEnabled(interactionPrompt, true)
    PromptSetVisible(interactionPrompt, true)
    PromptSetHoldMode(interactionPrompt, false)
    PromptSetGroup(interactionPrompt, promptGroup, 0)
    PromptRegisterEnd(interactionPrompt)
    
    DebugPrint('Prompt created successfully')
end

-- Удаление prompt
DeleteInteractionPrompt = function()
    if interactionPrompt then
        PromptDelete(interactionPrompt)
        interactionPrompt = nil
        DebugPrint('Prompt deleted')
    end
end

-- Инициализация данных игрока
CreateThread(function()
    DebugPrint('Waiting for RSGCore...')
    
    while not RSGCore do
        Wait(100)
    end
    
    DebugPrint('RSGCore loaded, waiting for player...')
    
    while not LocalPlayer.state.isLoggedIn do
        Wait(100)
    end
    
    PlayerData = RSGCore.Functions.GetPlayerData()
    isLoggedIn = true
    
    DebugPrint('Player loaded! Job: ' .. (PlayerData.job and PlayerData.job.name or 'none'))
end)

-- Обновление данных при смене работы
RegisterNetEvent('RSGCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
    DebugPrint('Job updated to: ' .. JobInfo.name)
end)

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    PlayerData = RSGCore.Functions.GetPlayerData()
    isLoggedIn = true
    Wait(1000)
    RemoveBusinessBlips()
    CreateBusinessBlips()
    DebugPrint('Player loaded event fired')
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    PlayerData = {}
end)

-- Обновление денег игрока
RegisterNetEvent('RSGCore:Client:OnMoneyChange', function(moneyType, amount, operation)
    PlayerData = RSGCore.Functions.GetPlayerData()
end)

-- Получение данных о бизнесе
GetBusinessInfo = function(businessId, callback)
    DebugPrint('Requesting business info for: ' .. businessId)
    RSGCore.Functions.TriggerCallback('rsg-businessmenu:server:getBusinessInfo', function(data)
        DebugPrint('Received business info: employees=' .. tostring(data.employeesCount))
        callback(data)
    end, businessId)
end

-- Получение баланса кассы
GetCashBalance = function(businessId, callback)
    RSGCore.Functions.TriggerCallback('rsg-businessmenu:server:getCashBalance', function(balance)
        callback(balance)
    end, businessId)
end

-- Проверка доступа к хранилищу
CheckStorageAccess = function(businessId, storageIndex, callback)
    RSGCore.Functions.TriggerCallback('rsg-businessmenu:server:checkStorageAccess', function(hasAccess)
        callback(hasAccess)
    end, businessId, storageIndex)
end

-- Открытие хранилища
local function OpenStorage(businessId, storageIndex)
    local business = Config.Businesses[businessId]
    if not business then return end
    
    local storage = business.storages[storageIndex]
    if not storage then return end
    
    CheckStorageAccess(businessId, storageIndex, function(hasAccess)
        if hasAccess then
            TriggerServerEvent('rsg-businessmenu:server:openStorage', businessId, storageIndex)
        else
            lib.notify({
                title = Config.Locale.menu_title,
                description = Config.Locale.no_access,
                type = 'error'
            })
        end
    end)
end

-- Открытие меню владельца (rsg-bossmenu)
local function OpenOwnerMenu(job)
    DebugPrint('Opening boss menu for job: ' .. job)
    
    -- Закрываем текущее меню
    lib.hideContext(false)
    isMenuOpen = false
    currentBusiness = nil
    
    Wait(100)
    
    -- Вызываем rsg-bossmenu через событие
    TriggerEvent('rsg-bossmenu:client:mainmenu')
    
    DebugPrint('Bossmenu opened')
end

-- Меню кассы
OpenCashRegisterMenu = function(businessId)
    local business = Config.Businesses[businessId]
    if not business then return end
    
    GetCashBalance(businessId, function(balance)
        local playerCash = PlayerData.money and PlayerData.money.cash or 0
        local isOwner = PlayerData.job and PlayerData.job.name == business.job and PlayerData.job.isboss
        
        local options = {
            -- Информация о балансе
            {
                title = Config.Locale.cash_balance,
                description = '$' .. FormatMoney(balance),
                icon = 'sack-dollar',
                readOnly = true
            },
            -- Внести деньги
            {
                title = Config.Locale.cash_deposit,
                description = Config.Locale.cash_deposit_desc .. ' (' .. Config.Locale.cash_your_money .. ': $' .. FormatMoney(playerCash) .. ')',
                icon = 'arrow-down',
                iconColor = 'green',
                onSelect = function()
                    local input = lib.inputDialog(Config.Locale.cash_deposit, {
                        {
                            type = 'number',
                            label = Config.Locale.cash_enter_amount,
                            description = Config.Locale.cash_your_money .. ': $' .. FormatMoney(playerCash),
                            icon = 'dollar-sign',
                            min = 1,
                            max = playerCash,
                            required = true
                        }
                    })
                    
                    if input and input[1] then
                        TriggerServerEvent('rsg-businessmenu:server:depositCash', businessId, tonumber(input[1]))
                        Wait(300)
                        OpenCashRegisterMenu(businessId)
                    end
                end
            }
        }
        
        -- Забрать деньги (только для владельца или высоких грейдов)
        local playerGrade = PlayerData.job and PlayerData.job.grade and PlayerData.job.grade.level or 0
        local canWithdraw = isOwner or playerGrade >= (Config.Locale.cash_min_grade or 1)
        
        if canWithdraw then
            table.insert(options, {
                title = Config.Locale.cash_withdraw,
                description = Config.Locale.cash_withdraw_desc,
                icon = 'arrow-up',
                iconColor = 'red',
                onSelect = function()
                    local input = lib.inputDialog(Config.Locale.cash_withdraw, {
                        {
                            type = 'number',
                            label = Config.Locale.cash_enter_amount,
                            description = Config.Locale.cash_balance .. ': $' .. FormatMoney(balance),
                            icon = 'dollar-sign',
                            min = 1,
                            max = balance,
                            required = true
                        }
                    })
                    
                    if input and input[1] then
                        TriggerServerEvent('rsg-businessmenu:server:withdrawCash', businessId, tonumber(input[1]))
                        Wait(300)
                        OpenCashRegisterMenu(businessId)
                    end
                end
            })
        end
        
        -- Кнопка назад
        table.insert(options, {
            title = '← Назад',
            icon = 'arrow-left',
            onSelect = function()
                OpenBusinessMenu(businessId)
            end
        })
        
        lib.registerContext({
            id = 'cash_register_menu',
            title = Config.Locale.cash_register,
            options = options
        })
        
        lib.showContext('cash_register_menu')
    end)
end

-- Меню финансов (только для владельца)
OpenFinancesMenu = function(businessId)
    local business = Config.Businesses[businessId]
    if not business then 
        DebugPrint('ERROR: Business not found!')
        return 
    end
    
    -- Проверяем, является ли игрок владельцем
    if not PlayerData.job or PlayerData.job.name ~= business.job or not PlayerData.job.isboss then
        lib.notify({
            title = Config.Locale.menu_title,
            description = Config.Locale.not_owner,
            type = 'error'
        })
        DebugPrint('Not owner - cancelling')
        return
    end
    
    DebugPrint('Opening finances menu for: ' .. businessId)
    
    -- Получаем информацию о финансах
    RSGCore.Functions.TriggerCallback('rsg-businessmenu:server:getFinanceInfo', function(info)
        if not info then 
            DebugPrint('ERROR: Failed to get finance info')
            lib.notify({
                title = 'Ошибка',
                description = 'Не удалось получить данные о финансах',
                type = 'error'
            })
            return 
        end
        
        DebugPrint('Got finance info, getting salary settings...')
        
        -- Получаем настройки зарплат
        RSGCore.Functions.TriggerCallback('rsg-businessmenu:server:getSalarySettings', function(salarySettings)
            if not salarySettings then
                DebugPrint('ERROR: Failed to get salary settings')
                salarySettings = {}
            end
            
            DebugPrint('Got salary settings, getting job grades...')
            
            -- Получаем грейды работы
            RSGCore.Functions.TriggerCallback('rsg-businessmenu:server:getJobGrades', function(grades)
                if not grades then
                    DebugPrint('ERROR: Failed to get job grades')
                    lib.notify({
                        title = 'Ошибка',
                        description = 'Не удалось получить грейды работы',
                        type = 'error'
                    })
                    return
                end
                
                DebugPrint('Building finances menu...')
                
                local statusColor = info.canAffordPayroll and 'green' or 'red'
                local statusText = info.canAffordPayroll and 'Достаточно средств' or 'Недостаточно средств!'
                
                local options = {
                    -- Информация о выплатах
                    {
                        title = Config.Locale.salary_info,
                        icon = 'chart-pie',
                        readOnly = true,
                        metadata = {
                            {label = Config.Locale.cash_balance, value = '$' .. FormatMoney(info.cashBalance)},
                            {label = Config.Locale.total_payroll, value = '$' .. FormatMoney(info.totalPayroll) .. '/час'},
                            {label = Config.Locale.employees_count, value = tostring(info.employeeCount)},
                            {label = Config.Locale.next_payment, value = info.timeUntilPayroll},
                            {label = 'Статус выплат', value = statusText}
                        }
                    }
                }
                
                -- Собираем грейды в массив и сортируем
                local sortedGrades = {}
                for grade, gradeName in pairs(grades) do
                    table.insert(sortedGrades, {grade = tonumber(grade) or grade, name = gradeName})
                end
                table.sort(sortedGrades, function(a, b) 
                    if type(a.grade) == "number" and type(b.grade) == "number" then
                        return a.grade < b.grade
                    end
                    return tostring(a.grade) < tostring(b.grade)
                end)
                
                -- Добавляем настройки зарплат для каждого грейда
                for _, gradeData in ipairs(sortedGrades) do
                    local grade = gradeData.grade
                    local gradeName = gradeData.name
                    local currentSalary = salarySettings[tostring(grade)] or salarySettings[grade] or 0
                    
                    table.insert(options, {
                        title = gradeName .. ' (Грейд ' .. grade .. ')',
                        description = Config.Locale.current_salary .. ': $' .. FormatMoney(currentSalary) .. '/час',
                        icon = 'user-tie',
                        onSelect = function()
                            local input = lib.inputDialog(Config.Locale.salary_for_grade .. ': ' .. gradeName, {
                                {
                                    type = 'number',
                                    label = Config.Locale.enter_salary,
                                    description = Config.Locale.current_salary .. ': $' .. FormatMoney(currentSalary),
                                    icon = 'dollar-sign',
                                    min = 0,
                                    default = currentSalary,
                                    required = true
                                }
                            })
                            
                            if input and input[1] ~= nil then
                                TriggerServerEvent('rsg-businessmenu:server:updateSalary', businessId, grade, tonumber(input[1]))
                                Wait(300)
                                OpenFinancesMenu(businessId)
                            end
                        end
                    })
                end
                
                -- Кнопка назад
                table.insert(options, {
                    title = '← Назад',
                    icon = 'arrow-left',
                    onSelect = function()
                        OpenBusinessMenu(businessId)
                    end
                })
                
                lib.registerContext({
                    id = 'finances_menu',
                    title = Config.Locale.finances_menu,
                    options = options
                })
                
                lib.showContext('finances_menu')
            end, business.job)
        end, businessId)
    end, businessId)
end

-- Меню настроек доступа к хранилищам
OpenStorageSettingsMenu = function(businessId)
    local business = Config.Businesses[businessId]
    if not business then return end
    
    RSGCore.Functions.TriggerCallback('rsg-businessmenu:server:getStorageSettings', function(settings)
        RSGCore.Functions.TriggerCallback('rsg-businessmenu:server:getJobGrades', function(grades)
            if not grades then grades = {} end
            
            local options = {}
            
            for i, storage in ipairs(business.storages) do
                local currentGrade = settings[i] or storage.defaultMinGrade
                local gradeName = grades[tostring(currentGrade)] or grades[currentGrade] or ("Грейд " .. currentGrade)
                
                local gradeOptions = {}
                for grade, name in pairs(grades) do
                    table.insert(gradeOptions, {
                        label = name .. " (Грейд " .. grade .. ")",
                        value = tonumber(grade)
                    })
                end
                
                table.sort(gradeOptions, function(a, b) return a.value < b.value end)
                
                table.insert(options, {
                    title = storage.label,
                    description = Config.Locale.grade_access .. ": " .. gradeName,
                    icon = 'warehouse',
                    onSelect = function()
                        local input = lib.inputDialog(storage.label .. ' - Настройка доступа', {
                            {
                                type = 'select',
                                label = 'Минимальный грейд',
                                options = gradeOptions,
                                default = currentGrade,
                                required = true
                            }
                        })
                        
                        if input and input[1] ~= nil then
                            TriggerServerEvent('rsg-businessmenu:server:updateStorageAccess', businessId, i, input[1])
                            Wait(300)
                            OpenStorageSettingsMenu(businessId)
                        end
                    end
                })
            end
            
            table.insert(options, {
                title = '← Назад',
                icon = 'arrow-left',
                onSelect = function()
                    OpenBusinessMenu(businessId)
                end
            })
            
            lib.registerContext({
                id = 'storage_settings_menu',
                title = Config.Locale.storage_settings,
                options = options
            })
            
            lib.showContext('storage_settings_menu')
        end, business.job)
    end, businessId)
end

-- Меню хранилищ
OpenStorageMenu = function(businessId)
    local business = Config.Businesses[businessId]
    if not business then return end
    
    local options = {}
    
    for i, storage in ipairs(business.storages) do
        table.insert(options, {
            title = storage.label,
            description = 'Слоты: ' .. storage.slots .. ' | Вес: ' .. (storage.weight / 1000) .. ' кг',
            icon = 'box',
            onSelect = function()
                OpenStorage(businessId, i)
            end
        })
    end
    
    -- Кнопка настроек доступа (только для владельца)
    if PlayerData.job and PlayerData.job.name == business.job and PlayerData.job.isboss then
        table.insert(options, {
            title = Config.Locale.storage_settings,
            description = 'Настроить доступ к хранилищам',
            icon = 'cog',
            onSelect = function()
                OpenStorageSettingsMenu(businessId)
            end
        })
    end
    
    table.insert(options, {
        title = '← Назад',
        icon = 'arrow-left',
        onSelect = function()
            OpenBusinessMenu(businessId)
        end
    })
    
    lib.registerContext({
        id = 'storage_menu',
        title = Config.Locale.storage_menu,
        options = options
    })
    
    lib.showContext('storage_menu')
end

-- Главное меню бизнеса
OpenBusinessMenu = function(businessId)
    DebugPrint('OpenBusinessMenu called for: ' .. tostring(businessId))
    
    local business = Config.Businesses[businessId]
    if not business then 
        DebugPrint('ERROR: Business not found in config!')
        return 
    end
    
    DebugPrint('Business found: ' .. business.label)
    
    currentBusiness = businessId
    isMenuOpen = true
    
    DebugPrint('Fetching business info from server...')
    
    GetBusinessInfo(businessId, function(info)
        DebugPrint('Got info, building menu...')
        
        local isOwner = PlayerData.job and PlayerData.job.name == business.job and PlayerData.job.isboss
        local rentTimeFormatted = info.nextRentFormatted or "Не указано"
        
        DebugPrint('Building options... isOwner=' .. tostring(isOwner))
        
        local options = {
            -- Информация о бизнесе
            {
                title = Config.Locale.business_info,
                icon = 'info-circle',
                metadata = {
                    {label = Config.Locale.business_name, value = business.label},
                    {label = Config.Locale.next_rent, value = rentTimeFormatted},
                    {label = Config.Locale.employees_count, value = tostring(info.employeesCount or 0)}
                }
            },
            -- Касса
            {
                title = Config.Locale.cash_register,
                description = Config.Locale.cash_register_desc,
                icon = 'cash-register',
                arrow = true,
                onSelect = function()
                    OpenCashRegisterMenu(businessId)
                end
            },
            -- Хранилища
            {
                title = Config.Locale.storage_menu,
                description = 'Открыть хранилища бизнеса',
                icon = 'warehouse',
                arrow = true,
                onSelect = function()
                    OpenStorageMenu(businessId)
                end
            }
        }
        
        -- Финансы (только для владельца)
        if isOwner then
            table.insert(options, {
                title = Config.Locale.finances_menu,
                description = Config.Locale.finances_desc,
                icon = 'coins',
                arrow = true,
                onSelect = function()
                    OpenFinancesMenu(businessId)
                end
            })
        end
        
        -- Меню владельца (только для босса)
        if isOwner then
            DebugPrint('Player is owner, adding owner menu')
            table.insert(options, {
                title = Config.Locale.owner_menu,
                description = 'Управление сотрудниками',
                icon = 'users-cog',
                onSelect = function()
                    OpenOwnerMenu(business.job)
                end
            })
        end
        
        DebugPrint('Registering context menu...')
        
        lib.registerContext({
            id = 'business_main_menu',
            title = business.label,
            options = options,
            onExit = function()
                DebugPrint('Menu closed via onExit')
                isMenuOpen = false
                currentBusiness = nil
            end
        })
        
        DebugPrint('Showing context menu...')
        lib.showContext('business_main_menu')
        DebugPrint('Menu should be visible now!')
    end)
end

-- Проверка, находится ли игрок в зоне бизнеса
local function GetNearbyBusiness()
    if not isLoggedIn then return nil, nil end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for businessId, business in pairs(Config.Businesses) do
        local distance = #(playerCoords - business.menuPosition)
        
        if distance < Config.InteractionDistance then
            -- Если включен дебаг без проверки профессии
            if Config.DebugIgnoreJobCheck then
                return businessId, business
            end
            
            -- Проверка профессии
            if PlayerData.job and PlayerData.job.name == business.job then
                return businessId, business
            end
        end
    end
    
    return nil, nil
end

-- Отрисовка маркера
local function DrawFloorMarker(coords)
    if not Config.FloorMarker.enabled then return end
    
    local markerCoords = vector3(coords.x, coords.y, coords.z - 0.98)
    
    Citizen.InvokeNative(0x2A32FAA57B937173, 
        Config.FloorMarker.type,
        markerCoords.x, markerCoords.y, markerCoords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.FloorMarker.scale.x, Config.FloorMarker.scale.y, Config.FloorMarker.scale.z,
        Config.FloorMarker.color.r, Config.FloorMarker.color.g, Config.FloorMarker.color.b, Config.FloorMarker.color.a,
        Config.FloorMarker.bobUpAndDown, Config.FloorMarker.rotate,
        2, false, nil, nil, false
    )
end

-- Показ prompt группы
local function ShowPromptGroup(businessLabel)
    local str = CreateVarString(10, "LITERAL_STRING", businessLabel)
    PromptSetActiveGroupThisFrame(promptGroup, str, 1, 0, 0, 0)
end

-- Основной поток
CreateThread(function()
    DebugPrint('Main thread starting...')
    
    -- Ждем загрузки
    while not isLoggedIn do
        Wait(500)
    end
    
    DebugPrint('Player is logged in, waiting 2 seconds...')
    Wait(2000)
    
    CreateBusinessBlips()
    CreateInteractionPrompt()
    
    DebugPrint('Main loop started!')
    
    while true do
        local sleep = 1000
        
        if isLoggedIn then
            local businessId, business = GetNearbyBusiness()
            
            if businessId and business then
                sleep = 0
                
                -- Рисуем маркер
                DrawFloorMarker(business.menuPosition)
                
                -- Показываем prompt только если меню закрыто
                if not isMenuOpen then
                    if interactionPrompt then
                        ShowPromptGroup(business.label)
                        
                        -- Проверяем нажатие J
                        if IsControlJustReleased(0, Config.InteractionKey) then
                            DebugPrint('J key pressed!')
                            DebugPrint('Opening menu...')
                            OpenBusinessMenu(businessId)
                        end
                    end
                end
            else
                -- Игрок отошёл от бизнеса - закрываем меню
                if isMenuOpen and currentBusiness then
                    DebugPrint('Player left business area, closing menu')
                    lib.hideContext(false)
                    isMenuOpen = false
                    currentBusiness = nil
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Слушаем закрытие ox_lib меню
RegisterNetEvent('ox_lib:onContextMenuClose', function()
    DebugPrint('Context menu closed event')
    isMenuOpen = false
    currentBusiness = nil
end)

-- Очистка при выгрузке ресурса
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemoveBusinessBlips()
        DeleteInteractionPrompt()
    end
end)

-- Команда для теста меню
RegisterCommand('openbizmenu', function(source, args)
    local businessId = args[1]
    if businessId and Config.Businesses[businessId] then
        DebugPrint('Command: opening menu for ' .. businessId)
        OpenBusinessMenu(businessId)
    else
        print('Available businesses:')
        for id, _ in pairs(Config.Businesses) do
            print('  - ' .. id)
        end
    end
end, false)

-- Команда проверки статуса
RegisterCommand('bizstatus', function()
    print('=== Business Menu Status ===')
    print('isLoggedIn: ' .. tostring(isLoggedIn))
    print('isMenuOpen: ' .. tostring(isMenuOpen))
    print('currentBusiness: ' .. tostring(currentBusiness))
    print('PlayerData.job: ' .. (PlayerData.job and PlayerData.job.name or 'nil'))
    print('PlayerData.job.isboss: ' .. (PlayerData.job and tostring(PlayerData.job.isboss) or 'nil'))
    print('PlayerData.money.cash: ' .. (PlayerData.money and tostring(PlayerData.money.cash) or 'nil'))
    print('Prompt exists: ' .. tostring(interactionPrompt ~= nil))
    
    local businessId, business = GetNearbyBusiness()
    print('Nearby business: ' .. tostring(businessId))
    print('============================')
end, false)

-- Экспорты
exports('OpenBusinessMenu', OpenBusinessMenu)
exports('GetNearbyBusiness', GetNearbyBusiness)