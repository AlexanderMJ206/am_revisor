local PlayerData = {}
local uiOpen = false
local currentComputer = nil

CreateThread(function()
    while not Bridge.IsPlayerLoaded() do
        Wait(200)
    end

    PlayerData = Bridge.GetPlayerData()

    if Config.Blip.enabled then
        for _, computer in pairs(Config.Computers) do
            local blip = AddBlipForCoord(computer.coords.x, computer.coords.y, computer.coords.z)
            SetBlipSprite(blip, Config.Blip.sprite)
            SetBlipColour(blip, Config.Blip.color)
            SetBlipScale(blip, Config.Blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(Config.Blip.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('qbx_core:client:onJobUpdate', function(job)
    PlayerData.job = job
end)

local function IsRevisor()
    return Bridge.HasJob(PlayerData)
end

local function Notify(msg, nType)
    Bridge.Notify(msg, nType)
end

local function Draw3DText(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(235, 245, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(x, y)
end

local function GetClosestComputer()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for index, computer in pairs(Config.Computers) do
        local dist = #(coords - computer.coords)
        if dist <= Config.InteractDistance then
            return index, computer, dist
        end
    end

    return nil, nil, nil
end

local function GetNearbyPlayers()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local players = {}

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        local targetServerId = GetPlayerServerId(player)

        if targetPed ~= ped then
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(coords - targetCoords)

            if dist <= Config.NearbyPlayerDistance then
                local name = GetPlayerName(player) or ('ID ' .. targetServerId)

                players[#players + 1] = {
                    id = targetServerId,
                    name = name,
                    distance = math.floor(dist * 10) / 10
                }
            end
        end
    end

    table.sort(players, function(a, b)
        return a.distance < b.distance
    end)

    return players
end

local function OpenUI()
    if uiOpen then return end

    if not IsRevisor() then
        Notify('Du er ikke ansat som revisor.', 'error')
        return
    end

    uiOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        data = {
            config = {
                minPercent = Config.MinFeePercent,
                maxPercent = Config.MaxFeePercent,
                defaultPercent = Config.DefaultFeePercent,
                minAmount = Config.MinAmount,
                maxAmount = Config.MaxAmount
            },
            players = GetNearbyPlayers()
        }
    })
end

local function CloseUI()
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end


local function SetupOxTarget()
    if not Config.UseOxTarget then return end

    if GetResourceState('ox_target') ~= 'started' then
        print('[am_revisor] Config.UseOxTarget er true, men ox_target er ikke startet.')
        return
    end

    for index, computer in pairs(Config.Computers) do
        exports.ox_target:addSphereZone({
            coords = computer.coords,
            radius = Config.TargetDistance or 2.0,
            debug = false,
            options = {
                {
                    name = ('am_revisor_computer_%s'):format(index),
                    icon = Config.TargetIcon or 'fa-solid fa-computer',
                    label = Config.TargetLabel or 'Åbn revisor terminal',
                    distance = Config.TargetDistance or 2.0,
                    canInteract = function()
                        return IsRevisor()
                    end,
                    onSelect = function()
                        currentComputer = index
                        OpenUI()
                    end
                }
            }
        })
    end

    print('[am_revisor] ox_target zoner indlæst.')
end

CreateThread(function()
    while not Bridge.IsPlayerLoaded() do
        Wait(200)
    end

    Wait(1000)
    PlayerData = Bridge.GetPlayerData()
    SetupOxTarget()
end)

CreateThread(function()
    if Config.UseOxTarget then
        return
    end

    while true do
        local sleep = 750

        if IsRevisor() and not uiOpen then
            local index, computer = GetClosestComputer()

            if computer then
                sleep = 0

                if Config.DrawMarker then
                    DrawMarker(
                        Config.Marker.type,
                        computer.coords.x, computer.coords.y, computer.coords.z + 0.2,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        Config.Marker.scale.x, Config.Marker.scale.y, Config.Marker.scale.z,
                        Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                        false, true, 2, false, nil, nil, false
                    )
                end

                Draw3DText(computer.coords + vector3(0.0, 0.0, 0.45), '[E] Åbn revisor terminal')

                if IsControlJustPressed(0, 38) then
                    currentComputer = index
                    OpenUI()
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNUICallback('close', function(_, cb)
    CloseUI()
    cb({ ok = true })
end)

RegisterNUICallback('refreshPlayers', function(_, cb)
    cb({
        ok = true,
        players = GetNearbyPlayers()
    })
end)

RegisterNUICallback('startWash', function(data, cb)
    local targetId = tonumber(data.targetId)
    local amount = tonumber(data.amount)
    local percent = tonumber(data.percent)

    if not targetId or not amount or not percent then
        cb({ ok = false, message = 'Ugyldige oplysninger.' })
        return
    end

    if Bridge.Framework == 'esx' and Bridge.ESX then
        Bridge.ESX.TriggerServerCallback('am_revisor:startWash', function(result)
            cb(result)

            if result and result.ok then
                SendNUIMessage({
                    action = 'washingStarted',
                    data = result
                })
            end
        end, targetId, amount, percent, currentComputer)
    else
        local responded = false

        RegisterNetEvent('am_revisor:startWashResult', function(result)
            if responded then return end
            responded = true

            cb(result)

            if result and result.ok then
                SendNUIMessage({
                    action = 'washingStarted',
                    data = result
                })
            end
        end)

        TriggerServerEvent('am_revisor:startWashServer', targetId, amount, percent, currentComputer)
    end
end)

RegisterNetEvent('am_revisor:washFinished', function(data)
    SendNUIMessage({
        action = 'washingFinished',
        data = data
    })

    if data and data.message then
        Notify(data.message, 'success')
    end
end)

RegisterNetEvent('am_revisor:notify', function(msg, nType)
    Notify(msg, nType)
end)

RegisterCommand('closerevisor', function()
    if uiOpen then
        CloseUI()
    end
end)
