Config = {}

-- Основные настройки
Config.Debug = true
Config.DebugIgnoreJobCheck = false  -- Временно игнорируем проверку профессии для теста
Config.InteractionKey = 0xF3830D8E -- J key
Config.InteractionDistance = 0.5

-- Настройки зарплат
Config.SalaryInterval = 60 -- Интервал выплаты зарплат в минутах (60 = 1 час)

-- Настройки маркера на полу
Config.FloorMarker = {
    enabled = false,
    type = 0x94FDAE17, -- ring marker
    scale = vector3(1.0, 1.0, 0.5),
    color = {r = 255, g = 200, b = 0, a = 150},
    bobUpAndDown = false,
    rotate = true
}

-- Локализация
Config.Locale = {
    menu_title = "Меню бизнеса",
    business_info = "Информация о бизнесе",
    business_name = "Название",
    next_rent = "До аренды",
    employees_count = "Сотрудников",
    storage_menu = "Хранилища",
    storage_1 = "Хранилище 1",
    storage_2 = "Хранилище 2",
    storage_3 = "Хранилище 3",
    owner_menu = "Меню владельца",
    storage_settings = "Настройки доступа",
    no_access = "У вас нет доступа к этому хранилищу",
    not_owner = "Вы не являетесь владельцем бизнеса",
    days = "дн.",
    hours = "ч.",
    minutes = "мин.",
    press_to_open = "Открыть меню бизнеса",
    grade_access = "Мин. грейд для доступа",
    access_updated = "Доступ к хранилищу обновлен",
    
    -- Касса
    cash_register = "Касса",
    cash_register_desc = "Управление деньгами бизнеса",
    cash_balance = "Баланс кассы",
    cash_deposit = "Внести деньги",
    cash_deposit_desc = "Положить деньги в кассу",
    cash_withdraw = "Забрать деньги",
    cash_withdraw_desc = "Забрать деньги из кассы",
    cash_enter_amount = "Введите сумму",
    cash_your_money = "Ваши наличные",
    cash_success_deposit = "Вы внесли $%s в кассу",
    cash_success_withdraw = "Вы забрали $%s из кассы",
    cash_not_enough = "Недостаточно средств",
    cash_invalid_amount = "Неверная сумма",
    cash_min_grade = 1,  -- Минимальный грейд для доступа к кассе (0 = все, 1+ = ограничено)
    
    -- Финансы
    finances_menu = "Финансы",
    finances_desc = "Управление зарплатами сотрудников",
    salary_settings = "Настройка зарплат",
    salary_for_grade = "Зарплата для грейда",
    current_salary = "Текущая зарплата",
    enter_salary = "Введите сумму зарплаты",
    salary_updated = "Зарплата обновлена",
    salary_info = "Информация о выплатах",
    total_payroll = "Общий фонд зарплат",
    next_payment = "До выплаты",
    salary_received = "Вы получили зарплату",
    salary_not_enough = "Недостаточно средств в кассе для выплаты зарплат"
}
-- Банки (синхронизировано с rsg-banking)
Config.Banks = {
    {
        name = 'valbank',
        label = 'Банк Валентайна',
        moneytype = 'valbank',
        coords = vector3(-308.4189, 775.8842, 118.7017)
    },
    {
        name = 'rhobank',
        label = 'Банк Роудса',
        moneytype = 'rhobank',
        coords = vector3(1292.307, -1301.539, 77.04012)
    },
    {
        name = 'bank',
        label = 'Банк Сан-Дени',
        moneytype = 'bank',
        coords = vector3(2644.579, -1292.313, 52.24956)
    },
    {
        name = 'blkbank',
        label = 'Банк Блеквотер',
        moneytype = 'blkbank',
        coords = vector3(-813.1633, -1277.486, 43.63771)
    },
    {
        name = 'armbank',
        label = 'Банк Армадилло',
        moneytype = 'armbank',
        coords = vector3(-3666.25, -2626.57, -13.59)
    },
}
-- Конфигурация бизнесов
Config.Businesses = {
    -- Салун Валентайн
    ['valsaloon'] = {
        label = 'Салун Валентайн',
        job = 'valsaloon',
        city = 'valentine', -- Город для банка
        
        -- Настройки блипа на карте
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Салун Валентайн'
        },
        
        -- Позиция меню (маркер на полу)
        menuPosition = vec3(-313.21, 804.73, 118.98),
        
        -- Хранилища
        storages = {
            {
                id = 'valsaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0  -- Доступно всем сотрудникам
            },
            {
                id = 'valsaloon_2',
                label = 'Склад материалов',
                slots = 75,
                weight = 300000,
                defaultMinGrade = 1  -- Минимум грейд 1
            },
            {
                id = 'valsaloon_3',
                label = 'Сейф',
                slots = 50,
                weight = 200000,
                defaultMinGrade = 2  -- Минимум грейд 2 (для руководства)
            }
        }
    },
    ['strwsaloon'] = {
        label = 'Салун Строуберри',
        job = 'strwsaloon',
        city = 'blackwater', -- Город для банка
        
        -- Настройки блипа на карте
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Салун Строуберри'
        },
        
        -- Позиция меню (маркер на полу)
        menuPosition = vec3(-1718.48, -438.86, 152.20),
        
        -- Хранилища
        storages = {
            {
                id = 'valsaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0  -- Доступно всем сотрудникам
            },
            {
                id = 'valsaloon_2',
                label = 'Склад материалов',
                slots = 75,
                weight = 300000,
                defaultMinGrade = 1  -- Минимум грейд 1
            },
            {
                id = 'valsaloon_3',
                label = 'Сейф',
                slots = 50,
                weight = 200000,
                defaultMinGrade = 2  -- Минимум грейд 2 (для руководства)
            }
        }
    },
    ['strtaxidermy'] = {
        label = 'Таксидермист',
        job = 'strtaxidermy',
        city = 'blackwater', -- Город для банка
        
        -- Настройки блипа на карте
        blip = {
            enabled = true,
            sprite = joaat('blip_shop_animal_trapper'),
            scale = 0.5,
            name = 'Таксидермист'
        },
        
        -- Позиция меню (маркер на полу)
        menuPosition = vec3(-1681.93, -338.27, 174.00),
        
        -- Хранилища
        storages = {
            {
                id = 'valsaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0  -- Доступно всем сотрудникам
            },
            {
                id = 'valsaloon_2',
                label = 'Склад материалов',
                slots = 75,
                weight = 300000,
                defaultMinGrade = 1  -- Минимум грейд 1
            },
            {
                id = 'valsaloon_3',
                label = 'Сейф',
                slots = 50,
                weight = 200000,
                defaultMinGrade = 2  -- Минимум грейд 2 (для руководства)
            }
        }
    },
    
    ['escsaloon'] = {
        label = 'Салун Эскалеры',
        job = 'escsaloon',
        city = 'armadillo', -- Город для банка
        
        -- Настройки блипа на карте
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Салун Эскалеры'
        },
        
        -- Позиция меню (маркер на полу)
        menuPosition = vec3(-5738.70, -4488.83, -3.39),
        
        -- Хранилища
        storages = {
            {
                id = 'valsaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0  -- Доступно всем сотрудникам
            },
            {
                id = 'valsaloon_2',
                label = 'Склад материалов',
                slots = 75,
                weight = 300000,
                defaultMinGrade = 1  -- Минимум грейд 1
            },
            {
                id = 'valsaloon_3',
                label = 'Сейф',
                slots = 50,
                weight = 200000,
                defaultMinGrade = 2  -- Минимум грейд 2 (для руководства)
            }
        }
    },
    -- Салун Блеквотер
    ['blasaloon'] = {
        label = 'Салун Блеквотер',
        job = 'blasaloon',
        city = 'blackwater',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Салун Блеквотер'
        },
        
        menuPosition = vec3(-817.60, -1320.49, 43.68),
        
        storages = {
            {
                id = 'blasaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'blasaloon_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'blasaloon_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
    
    ['strwsaloon'] = {
        label = 'Салун Строуберри',
        job = 'strwsaloon',
        city = 'blackwater',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Салун Строуберри'
        },
        
        menuPosition = vec3(-1766.07, -390.98, 160.68),
        
        storages = {
            {
                id = 'strwsaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'strwsaloon_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'strwsaloon_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['oldsaloon'] = {
        label = 'Салун Ван-Хорн',
        job = 'oldsaloon',
        city = 'saintdenis',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Салун Ван-Хорн'
        },
        
        menuPosition = vec3(2947.93, 528.09, 45.34),
        
        storages = {
            {
                id = 'oldsaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'oldsaloon_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'oldsaloon_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['rhosaloon'] = {
        label = 'Салун Роудс',
        job = 'rhosaloon',
        city = 'rhodes',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Салун Роудс'
        },
        
        menuPosition = vec3(1338.76, -1375.29, 80.48),
        
        storages = {
            {
                id = 'rhosaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'rhosaloon_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'rhosaloon_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['doysaloon'] = {
        label = 'Таверна Дойля',
        job = 'doysaloon',
        city = 'saintdenis',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Таверна Дойля'
        },
        
        menuPosition = vec3(2792.27, -1168.64, 47.93),
        
        storages = {
            {
                id = 'doysaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'doysaloon_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'doysaloon_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['bassaloon'] = {
        label = 'Салун Бастилия',
        job = 'bassaloon',
        city = 'saintdenis',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Салун Бастилия'
        },
        
        menuPosition = vec3(2639.91, -1222.98, 53.38),
        
        storages = {
            {
                id = 'bassaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'bassaloon_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'bassaloon_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['armsaloon'] = {
        label = 'Салун Армадилло',
        job = 'armsaloon',
        city = 'armadillo',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Салун Армадилло'
        },
        
        menuPosition = vec3(-3697.94, -2600.66, -13.32),
        
        storages = {
            {
                id = 'armsaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'armsaloon_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'armsaloon_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['tumsaloon'] = {
        label = 'Салун Тамблвид',
        job = 'tumsaloon',
        city = 'armadillo',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_saloon'),
            scale = 0.5,
            name = 'Салун Тамблвид'
        },
        
        menuPosition = vec3(-5520.05, -2907.42, -1.75),
        
        storages = {
            {
                id = 'tumsaloon_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'tumsaloon_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'tumsaloon_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['valblacksmith'] = {
        label = 'Кузня Валентайн',
        job = 'valblacksmith',
        city = 'valentine',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_blacksmith'),
            scale = 0.5,
            name = 'Кузня Валентайн'
        },
        
        menuPosition = vec3(-364.98, 798.70, 116.19),
        
        storages = {
            {
                id = 'valblacksmith_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'valblacksmith_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'valblacksmith_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['blkblacksmith'] = {
        label = 'Кузня Блеквотер',
        job = 'blkblacksmith',
        city = 'blackwater',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_blacksmith'),
            scale = 0.5,
            name = 'Кузня Блеквотер'
        },
        
        menuPosition = vec3(-868.73, -1391.09, 43.45),
        
        storages = {
            {
                id = 'blkblacksmith_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'blkblacksmith_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'blkblacksmith_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['vanblacksmith'] = {
        label = 'Кузня Ван-Хорн',
        job = 'vanblacksmith',
        city = 'vanhorn',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_blacksmith'),
            scale = 0.5,
            name = 'Кузня Ван-Хорн'
        },
        
        menuPosition = vec3(2935.94, 561.44, 44.90),
        
        storages = {
            {
                id = 'vanblacksmith_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'vanblacksmith_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'vanblacksmith_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['stdblacksmith'] = {
        label = 'Кузня Сан-Дени',
        job = 'stdblacksmith',
        city = 'saintdenis',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_blacksmith'),
            scale = 0.5,
            name = 'Кузня Сан-Дени'
        },
        
        menuPosition = vec3(2513.98, -1459.61, 46.26),
        
        storages = {
            {
                id = 'stdblacksmith_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'stdblacksmith_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'stdblacksmith_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },

    ['strblacksmith'] = {
        label = 'Кузня Строуберри',
        job = 'strblacksmith',
        city = 'strawberry',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_blacksmith'),
            scale = 0.5,
            name = 'Кузня Строуберри'
        },
        
        menuPosition = vec3(-1808.12, -428.21, 158.04),
        
        storages = {
            {
                id = 'strblacksmith_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'strblacksmith_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'strblacksmith_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['spiblacksmith'] = {
        label = 'Кузня Колтер',
        job = 'spiblacksmith',
        city = 'colter',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_blacksmith'),
            scale = 0.5,
            name = 'Кузня Колтер'
        },
        
        menuPosition = vec3(-1344.55, 2405.18, 307.02),
        
        storages = {
            {
                id = 'spiblacksmith_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'spiblacksmith_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'spiblacksmith_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['annesburgminer'] = {
        label = 'Шахта Аннесбурга',
        job = 'annesburgminer',
        city = 'annesburg',
        
        blip = {
            enabled = false,
            sprite = joaat('blip_blacksmith'),
            scale = 0.5,
            name = 'Шахта Аннесбурга'
        },
        
        menuPosition = vec3(2817.35, 1359.42, 70.70),
        
        storages = {
            {
                id = 'annesburgminer_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'annesburgminer_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'annesburgminer_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['gaptoothminer'] = {
        label = 'Шахта Нью-Остин',
        job = 'gaptoothminer',
        city = 'armadillo',
        
        blip = {
            enabled = false,
            sprite = joaat('blip_blacksmith'),
            scale = 0.5,
            name = 'Шахта Нью-Остин'
        },
        
        menuPosition = vec3(-6048.42, -3254.84, -14.36),
        
        storages = {
            {
                id = 'gaptoothminer_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'gaptoothminer_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'gaptoothminer_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['rhohorsetrainer'] = {
        label = 'Укротитель лошадей, Роудс',
        job = 'rhohorsetrainer',
        city = 'rhodes',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_shop_horse_saddle'),
            scale = 0.5,
            name = 'Укротитель лошадей, Роудс'
        },
        
        menuPosition = vec3(1458.28, -1364.21, 78.81),
        
        storages = {
            {
                id = 'rhohorsetrainer_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'rhohorsetrainer_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'rhohorsetrainer_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['valhorsetrainer'] = {
        label = 'Укротитель лошадей, Колтер',
        job = 'valhorsetrainer',
        city = 'colter',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_shop_horse_saddle'),
            scale = 0.5,
            name = 'Укротитель лошадей, Колтер'
        },
        
        menuPosition = vec3(-1335.44, 2394.08, 306.93),
        
        storages = {
            {
                id = 'valhorsetrainer_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'valhorsetrainer_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'valhorsetrainer_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['macfarranch'] = {
        label = 'Ранчо Макфарлейнс',
        job = 'macfarranch',
        city = 'armadillo',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_ambient_herd'),
            scale = 0.5,
            name = 'Ранчо Макфарлейнс'
        },
        
        menuPosition = vec3(-2402.51, -2376.16, 61.13),
        
        storages = {
            {
                id = 'macfarranch_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'macfarranch_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'macfarranch_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['emeraldranch'] = {
        label = 'Изумрудное Ранчо',
        job = 'emeraldranch',
        city = 'valentine',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_ambient_herd'),
            scale = 0.5,
            name = 'Изумрудное Ранчо'
        },
        
        menuPosition = vec3(1413.06, 273.71, 89.48),
        
        storages = {
            {
                id = 'emeraldranch_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'emeraldranch_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'emeraldranch_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },

    ['pronghornranch'] = {
        label = 'Ранчо Праунхорн',
        job = 'pronghornranch',
        city = 'strawberry',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_ambient_herd'),
            scale = 0.5,
            name = 'Ранчо Праунхорн'
        },
        
        menuPosition = vec3(-2570.02, 353.61, 151.43),
        
        storages = {
            {
                id = 'pronghornranch_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'pronghornranch_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'pronghornranch_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['downesranch'] = {
        label = 'Ранчо Даунс',
        job = 'downesranch',
        city = 'valentine',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_ambient_herd'),
            scale = 0.5,
            name = 'Ранчо Даунс'
        },
        
        menuPosition = vec3(-861.82, 332.00, 96.36),
        
        storages = {
            {
                id = 'downesranch_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'downesranch_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'downesranch_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    ['hillhavenranch'] = {
        label = 'Ранчо Хилл-Хейвен',
        job = 'hillhavenranch',
        city = 'rhodes',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_ambient_herd'),
            scale = 0.5,
            name = 'Ранчо Хилл-Хейвен'
        },
        
        menuPosition = vec3(1369.14, -870.95, 70.08),
        
        storages = {
            {
                id = 'hillhavenranch_1',
                label = 'Основное хранилище',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 0
            },
            {
                id = 'hillhavenranch_2',
                label = 'Склад материалов',
                slots = 80,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'hillhavenranch_3',
                label = 'Сейф',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    },
	
    -- Шериф Valentine
    ['sheriff_valentine'] = {
        label = 'Офис шерифа Valentine',
        job = 'sheriff',
        city = 'valentine',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_sheriff'),
            scale = 0.2,
            name = 'Офис шерифа'
        },
        
        menuPosition = vector3(-279.15, 803.67, 119.38),
        
        storages = {
            {
                id = 'sheriff_val_storage_1',
                label = 'Оружейная',
                slots = 100,
                weight = 500000,
                defaultMinGrade = 1
            },
            {
                id = 'sheriff_val_storage_2',
                label = 'Улики',
                slots = 50,
                weight = 200000,
                defaultMinGrade = 2
            },
            {
                id = 'sheriff_val_storage_3',
                label = 'Сейф шерифа',
                slots = 30,
                weight = 100000,
                defaultMinGrade = 3
            }
        }
    },

    -- Доктор Valentine
    ['doctor_valentine'] = {
        label = 'Клиника Valentine',
        job = 'doctor',
        city = 'valentine',
        
        blip = {
            enabled = true,
            sprite = joaat('blip_shop_doctor'),
            scale = 0.2,
            name = 'Клиника'
        },
        
        menuPosition = vector3(-288.45, 810.23, 119.12),
        
        storages = {
            {
                id = 'doctor_val_storage_1',
                label = 'Медикаменты',
                slots = 100,
                weight = 300000,
                defaultMinGrade = 0
            },
            {
                id = 'doctor_val_storage_2',
                label = 'Инструменты',
                slots = 50,
                weight = 200000,
                defaultMinGrade = 1
            },
            {
                id = 'doctor_val_storage_3',
                label = 'Редкие препараты',
                slots = 25,
                weight = 50000,
                defaultMinGrade = 2
            }
        }
    }
}

-- Функция для получения грейдов профессии (для меню настроек)
-- Эта функция используется как fallback, основные грейды берутся из БД
Config.GetJobGrades = function(job)
    local grades = {
        ['sheriff'] = {
            [0] = 'Помощник',
            [1] = 'Депутат',
            [2] = 'Старший депутат',
            [3] = 'Шериф'
        },
        ['doctor'] = {
            [0] = 'Медсестра',
            [1] = 'Фельдшер',
            [2] = 'Доктор',
            [3] = 'Главврач'
        }
    }
    -- Возвращаем стандартные грейды если не найдены специфичные
    return grades[job] or {[0] = 'Сотрудник', [1] = 'Старший', [2] = 'Менеджер', [3] = 'Владелец'}
end