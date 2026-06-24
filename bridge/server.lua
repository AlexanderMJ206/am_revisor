Bridge = Bridge or {}

Bridge.Framework = 'standalone'
Bridge.Inventory = 'framework'
Bridge.ESX = nil
Bridge.QBCore = nil
Bridge.vRP = nil

CreateThread(function()
    Wait(500)

    if Config.Framework == 'esx' or (Config.Framework == 'auto' and GetResourceState('es_extended') == 'started') then
        Bridge.Framework = 'esx'
        Bridge.ESX = exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qbox' or (Config.Framework == 'auto' and GetResourceState('qbx_core') == 'started') then
        Bridge.Framework = 'qbox'
    elseif Config.Framework == 'qb' or (Config.Framework == 'auto' and GetResourceState('qb-core') == 'started') then
        Bridge.Framework = 'qb'
        Bridge.QBCore = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'vrp' or (Config.Framework == 'auto' and GetResourceState('vrp') == 'started') then
        Bridge.Framework = 'vrp'
        local Proxy = module and module('vrp', 'lib/Proxy')
        if Proxy then
            Bridge.vRP = Proxy.getInterface('vRP')
        end
    else
        Bridge.Framework = 'standalone'
    end

    if Config.Inventory ~= 'auto' then
        Bridge.Inventory = Config.Inventory
    elseif GetResourceState('ox_inventory') == 'started' then
        Bridge.Inventory = 'ox_inventory'
    elseif GetResourceState('qs-inventory') == 'started' then
        Bridge.Inventory = 'qs-inventory'
    elseif GetResourceState('ps-inventory') == 'started' then
        Bridge.Inventory = 'ps-inventory'
    elseif GetResourceState('qb-inventory') == 'started' then
        Bridge.Inventory = 'qb-inventory'
    elseif GetResourceState('codem-inventory') == 'started' then
        Bridge.Inventory = 'codem-inventory'
    else
        Bridge.Inventory = 'framework'
    end

    print(('[am_revisor] Framework: %s | Inventory: %s'):format(Bridge.Framework, Bridge.Inventory))
end)

function Bridge.Notify(src, msg, nType)
    TriggerClientEvent('am_revisor:notify', src, msg, nType or 'inform')
end

function Bridge.GetPlayer(src)
    if Bridge.Framework == 'esx' and Bridge.ESX then
        return Bridge.ESX.GetPlayerFromId(src)
    end

    if Bridge.Framework == 'qb' and Bridge.QBCore then
        return Bridge.QBCore.Functions.GetPlayer(src)
    end

    if Bridge.Framework == 'qbox' and exports.qbx_core then
        return exports.qbx_core:GetPlayer(src)
    end

    if Bridge.Framework == 'vrp' and Bridge.vRP then
        local user_id = Bridge.vRP.getUserId({src})
        if user_id then return { source = src, user_id = user_id } end
    end

    return { source = src }
end

function Bridge.GetName(src)
    local player = Bridge.GetPlayer(src)

    if Bridge.Framework == 'esx' and player and player.getName then
        return player.getName()
    end

    if (Bridge.Framework == 'qb' or Bridge.Framework == 'qbox') and player and player.PlayerData then
        local c = player.PlayerData.charinfo or {}
        return ((c.firstname or '') .. ' ' .. (c.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
    end

    return GetPlayerName(src) or ('ID ' .. tostring(src))
end

function Bridge.HasJob(src)
    if Config.Debug then return true end

    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if Bridge.Framework == 'esx' then
        return player.job and player.job.name == Config.JobName
    end

    if Bridge.Framework == 'qb' or Bridge.Framework == 'qbox' then
        return player.PlayerData and player.PlayerData.job and player.PlayerData.job.name == Config.JobName
    end

    if Bridge.Framework == 'vrp' and Bridge.vRP then
        local user_id = player.user_id
        return user_id and Bridge.vRP.hasPermission({user_id, Config.JobName .. '.permission'})
    end

    return true
end

function Bridge.SetJob(src, job, grade)
    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if Bridge.Framework == 'esx' and player.setJob then
        player.setJob(job, grade)
        return true
    end

    if Bridge.Framework == 'qb' and player.Functions and player.Functions.SetJob then
        player.Functions.SetJob(job, grade)
        return true
    end

    if Bridge.Framework == 'qbox' and exports.qbx_core then
        exports.qbx_core:SetJob(src, job, grade)
        return true
    end

    Bridge.Notify(src, 'Framework understøtter ikke automatisk setJob her. Giv jobbet manuelt.', 'error')
    return false
end

function Bridge.GetMoney(src, account)
    local player = Bridge.GetPlayer(src)
    if not player then return 0 end

    if Bridge.Framework == 'esx' then
        if account == 'money' or account == 'cash' then
            return player.getMoney()
        end

        local acc = player.getAccount(account)
        return acc and acc.money or 0
    end

    if Bridge.Framework == 'qb' or Bridge.Framework == 'qbox' then
        local moneyType = account == 'money' and 'cash' or account
        return player.PlayerData and player.PlayerData.money and player.PlayerData.money[moneyType] or 0
    end

    if Bridge.Framework == 'vrp' and Bridge.vRP then
        if account == 'bank' then
            return Bridge.vRP.getBankMoney({player.user_id}) or 0
        end
        return Bridge.vRP.getMoney({player.user_id}) or 0
    end

    return 0
end

function Bridge.AddMoney(src, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if Bridge.Framework == 'esx' then
        if account == 'money' or account == 'cash' then
            player.addMoney(amount)
        else
            player.addAccountMoney(account, amount)
        end
        return true
    end

    if Bridge.Framework == 'qb' or Bridge.Framework == 'qbox' then
        local moneyType = account == 'money' and 'cash' or account
        player.Functions.AddMoney(moneyType, amount, 'revisor-wash')
        return true
    end

    if Bridge.Framework == 'vrp' and Bridge.vRP then
        if account == 'bank' then
            Bridge.vRP.giveBankMoney({player.user_id, amount})
        else
            Bridge.vRP.giveMoney({player.user_id, amount})
        end
        return true
    end

    return false
end

function Bridge.RemoveMoney(src, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if Bridge.Framework == 'esx' then
        if account == 'money' or account == 'cash' then
            if player.getMoney() < amount then return false end
            player.removeMoney(amount)
        else
            local acc = player.getAccount(account)
            if not acc or acc.money < amount then return false end
            player.removeAccountMoney(account, amount)
        end
        return true
    end

    if Bridge.Framework == 'qb' or Bridge.Framework == 'qbox' then
        local moneyType = account == 'money' and 'cash' or account
        local current = player.PlayerData and player.PlayerData.money and player.PlayerData.money[moneyType] or 0
        if current < amount then return false end
        player.Functions.RemoveMoney(moneyType, amount, 'revisor-wash')
        return true
    end

    if Bridge.Framework == 'vrp' and Bridge.vRP then
        if account == 'bank' then
            if (Bridge.vRP.getBankMoney({player.user_id}) or 0) < amount then return false end
            Bridge.vRP.setBankMoney({player.user_id, (Bridge.vRP.getBankMoney({player.user_id}) or 0) - amount})
            return true
        end

        return Bridge.vRP.tryPayment({player.user_id, amount})
    end

    return false
end

function Bridge.GetItemCount(src, item)
    if not item or item == '' then return 0 end

    if Bridge.Inventory == 'ox_inventory' then
        return exports.ox_inventory:GetItemCount(src, item) or 0
    end

    if Bridge.Framework == 'qb' or Bridge.Framework == 'qbox' then
        local player = Bridge.GetPlayer(src)
        local invItem = player and player.Functions and player.Functions.GetItemByName and player.Functions.GetItemByName(item)
        return invItem and invItem.amount or 0
    end

    if Bridge.Framework == 'esx' then
        local player = Bridge.GetPlayer(src)
        local invItem = player and player.getInventoryItem and player.getInventoryItem(item)
        return invItem and invItem.count or 0
    end

    if Bridge.Framework == 'vrp' and Bridge.vRP then
        local player = Bridge.GetPlayer(src)
        return Bridge.vRP.getInventoryItemAmount({player.user_id, item}) or 0
    end

    return 0
end

function Bridge.RemoveItem(src, item, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    if Bridge.GetItemCount(src, item) < amount then return false end

    if Bridge.Inventory == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(src, item, amount)
    end

    local player = Bridge.GetPlayer(src)

    if (Bridge.Framework == 'qb' or Bridge.Framework == 'qbox') and player and player.Functions then
        return player.Functions.RemoveItem(item, amount)
    end

    if Bridge.Framework == 'esx' and player and player.removeInventoryItem then
        player.removeInventoryItem(item, amount)
        return true
    end

    if Bridge.Framework == 'vrp' and Bridge.vRP then
        return Bridge.vRP.tryGetInventoryItem({player.user_id, item, amount, true})
    end

    return false
end

function Bridge.AddItem(src, item, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    if Bridge.Inventory == 'ox_inventory' then
        return exports.ox_inventory:AddItem(src, item, amount)
    end

    local player = Bridge.GetPlayer(src)

    if (Bridge.Framework == 'qb' or Bridge.Framework == 'qbox') and player and player.Functions then
        return player.Functions.AddItem(item, amount)
    end

    if Bridge.Framework == 'esx' and player and player.addInventoryItem then
        player.addInventoryItem(item, amount)
        return true
    end

    if Bridge.Framework == 'vrp' and Bridge.vRP then
        Bridge.vRP.giveInventoryItem({player.user_id, item, amount, true})
        return true
    end

    return false
end

function Bridge.GetBlackMoney(src)
    local blackType = Config.BlackMoneyType

    if blackType == 'auto' then
        if Bridge.Framework == 'esx' then blackType = 'account' else blackType = 'item' end
    end

    if blackType == 'item' then
        return Bridge.GetItemCount(src, Config.BlackMoneyItem)
    end

    return Bridge.GetMoney(src, Config.BlackMoneyAccount)
end

function Bridge.RemoveBlackMoney(src, amount)
    local blackType = Config.BlackMoneyType

    if blackType == 'auto' then
        if Bridge.Framework == 'esx' then blackType = 'account' else blackType = 'item' end
    end

    if blackType == 'item' then
        return Bridge.RemoveItem(src, Config.BlackMoneyItem, amount)
    end

    return Bridge.RemoveMoney(src, Config.BlackMoneyAccount, amount)
end

function Bridge.AddCleanMoney(src, amount)
    local account = Config.CleanMoneyAccount

    if Bridge.Framework == 'qb' or Bridge.Framework == 'qbox' then
        account = Config.CleanMoneyType == 'bank' and 'bank' or 'cash'
    elseif Bridge.Framework == 'vrp' then
        account = Config.CleanMoneyType == 'bank' and 'bank' or 'cash'
    end

    return Bridge.AddMoney(src, account, amount)
end

function Bridge.GroupDigits(value)
    value = tostring(math.floor(tonumber(value) or 0))
    local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1.'):reverse()) .. right
end

function Bridge.RegisterSociety()
    if Bridge.Framework ~= 'esx' then return end
    if not Config.AutoRegisterSociety then return end

    if GetResourceState('esx_society') == 'started' then
        TriggerEvent('esx_society:registerSociety',
            Config.JobName,
            Config.SocietyLabel,
            Config.SocietyName,
            Config.SocietyName,
            Config.SocietyName,
            { type = Config.SocietyType }
        )

        print(('[am_revisor] ESX society registered: %s'):format(Config.SocietyName))
    end
end
