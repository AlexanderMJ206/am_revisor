Bridge = Bridge or {}

Bridge.Framework = 'standalone'
Bridge.ESX = nil
Bridge.QBCore = nil

CreateThread(function()
    if Config.Framework == 'esx' or (Config.Framework == 'auto' and GetResourceState('es_extended') == 'started') then
        Bridge.Framework = 'esx'
        Bridge.ESX = exports['es_extended']:getSharedObject()
        return
    end

    if Config.Framework == 'qbox' or (Config.Framework == 'auto' and GetResourceState('qbx_core') == 'started') then
        Bridge.Framework = 'qbox'
        return
    end

    if Config.Framework == 'qb' or (Config.Framework == 'auto' and GetResourceState('qb-core') == 'started') then
        Bridge.Framework = 'qb'
        Bridge.QBCore = exports['qb-core']:GetCoreObject()
        return
    end

    if Config.Framework == 'vrp' then
        Bridge.Framework = 'vrp'
        return
    end

    Bridge.Framework = 'standalone'
end)

function Bridge.IsPlayerLoaded()
    if Bridge.Framework == 'esx' then
        return Bridge.ESX and Bridge.ESX.IsPlayerLoaded()
    end

    return true
end

function Bridge.GetPlayerData()
    if Bridge.Framework == 'esx' and Bridge.ESX then
        return Bridge.ESX.GetPlayerData()
    end

    if Bridge.Framework == 'qb' and Bridge.QBCore then
        return Bridge.QBCore.Functions.GetPlayerData()
    end

    if Bridge.Framework == 'qbox' and exports.qbx_core then
        return exports.qbx_core:GetPlayerData()
    end

    return {}
end

function Bridge.Notify(msg, nType)
    if GetResourceState('ox_lib') == 'started' and lib and lib.notify then
        lib.notify({
            title = 'Revisor',
            description = msg,
            type = nType or 'inform'
        })
        return
    end

    if Bridge.Framework == 'esx' and Bridge.ESX then
        Bridge.ESX.ShowNotification(msg)
        return
    end

    if Bridge.Framework == 'qb' and Bridge.QBCore then
        Bridge.QBCore.Functions.Notify(msg, nType or 'primary')
        return
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

function Bridge.HasJob(playerData)
    if Config.Debug then return true end

    playerData = playerData or Bridge.GetPlayerData()

    if Bridge.Framework == 'esx' then
        return playerData.job and playerData.job.name == Config.JobName
    end

    if Bridge.Framework == 'qb' or Bridge.Framework == 'qbox' then
        return playerData.job and playerData.job.name == Config.JobName
    end

    return true
end
