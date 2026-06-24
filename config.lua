Config = {}

Config.Locale = 'da'

-- FRAMEWORK:
-- 'auto', 'esx', 'qb', 'qbox', 'vrp', 'standalone'
Config.Framework = 'auto'

-- INVENTORY / MONEY:
-- 'auto', 'framework', 'ox_inventory', 'qs-inventory', 'qb-inventory', 'ps-inventory', 'codem-inventory'
Config.Inventory = 'auto'

-- Sorte penge type:
-- ESX: normalt account 'black_money'
-- QB/QBox: normalt item 'markedbills' eller 'black_money'
-- vRP: item eller wallet alt efter din vRP opsætning
Config.BlackMoneyType = 'auto' -- 'auto', 'account', 'item'
Config.BlackMoneyAccount = 'black_money'
Config.BlackMoneyItem = 'black_money'

-- Rene penge:
-- ESX: 'money' eller 'bank'
-- QB/QBox: 'cash' eller 'bank'
-- vRP: 'cash' eller 'bank', afhænger af din vRP
Config.CleanMoneyType = 'cash' -- 'cash' / 'bank'
Config.CleanMoneyAccount = 'money' -- ESX fallback. Brug 'bank' hvis det skal på bank.

-- Job
Config.JobName = 'revisor'
Config.Debug = false
Config.DebugGiveJobCommand = 'givrevisor'
Config.DebugGiveJobGrade = 2

-- ESX Society
Config.AutoRegisterSociety = true
Config.SocietyName = 'society_revisor'
Config.SocietyLabel = 'Revisor'
Config.SocietyType = 'private'

-- ox_target
Config.UseOxTarget = true
Config.TargetDistance = 2.0
Config.TargetIcon = 'fa-solid fa-computer'
Config.TargetLabel = 'Åbn revisor terminal'

-- Hvor tæt spilleren skal være på revisor-computeren
Config.InteractDistance = 2.0

-- Hvor tæt klienter skal være på revisoren for at kunne vælges i UI
Config.NearbyPlayerDistance = 5.0

-- Hvidvask settings
Config.BaseWashTime = 8000
Config.TimePer1000 = 350
Config.MaxWashTime = 45000

Config.MinFeePercent = 1
Config.MaxFeePercent = 35
Config.DefaultFeePercent = 10

Config.MinAmount = 1000
Config.MaxAmount = 250000

Config.Webhook = ''

-- Revisor computer lokationer
Config.Computers = {
    {
        label = 'Revisor Computer',
        coords = vector3(-1081.55, -247.83, 37.76),
        heading = 205.0
    }
}

Config.DrawMarker = false
Config.Marker = {
    type = 2,
    scale = vec3(0.35, 0.35, 0.35),
    color = { r = 255, g = 48, b = 70, a = 180 }
}

Config.Blip = {
    enabled = false,
    sprite = 525,
    color = 1,
    scale = 0.75,
    name = 'Revisor'
}
