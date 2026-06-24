local ActiveWashes = {}

CreateThread(function()
    Wait(2000)
    Bridge.RegisterSociety()
end)

RegisterCommand(Config.DebugGiveJobCommand or 'givrevisor', function(src)
    if not Config.Debug then
        if src > 0 then
            Bridge.Notify(src, 'Debug er slået fra i config.lua.', 'error')
        end
        return
    end

    if src <= 0 then
        print('[am_revisor] Denne command skal bruges ingame.')
        return
    end

    if Bridge.SetJob(src, Config.JobName, Config.DebugGiveJobGrade or 2) then
        Bridge.Notify(src, ('Du fik jobbet %s grade %s.'):format(Config.JobName, Config.DebugGiveJobGrade or 2), 'success')
    end
end, false)

local function ClampNumber(value, min, max)
    value = tonumber(value)
    if not value then return nil end
    value = math.floor(value)
    if value < min then return nil end
    if value > max then return nil end
    return value
end

local function SendWebhook(title, description, color)
    if not Config.Webhook or Config.Webhook == '' then return end

    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({
        username = 'Revisor Logs',
        embeds = {{
            title = title,
            description = description,
            color = color or 3447003,
            footer = { text = os.date('%d/%m/%Y %H:%M:%S') }
        }}
    }), { ['Content-Type'] = 'application/json' })
end

local function IsNearComputer(src, computerIndex)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    local computer = Config.Computers[tonumber(computerIndex or 0)]

    if not computer then return false end

    return #(coords - computer.coords) <= (Config.InteractDistance + 2.0)
end

local function IsTargetNear(src, target)
    local ped = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)

    if not ped or ped == 0 or not targetPed or targetPed == 0 then
        return false
    end

    local coords = GetEntityCoords(ped)
    local targetCoords = GetEntityCoords(targetPed)

    return #(coords - targetCoords) <= (Config.NearbyPlayerDistance + 2.0)
end

local function StartWash(src, cb, targetId, amount, percent, computerIndex)
    targetId = tonumber(targetId)

    if not Bridge.HasJob(src) then
        cb({ ok = false, message = 'Du er ikke revisor.' })
        return
    end

    if not targetId or not GetPlayerName(targetId) then
        cb({ ok = false, message = 'Klienten blev ikke fundet.' })
        return
    end

    if targetId == src then
        cb({ ok = false, message = 'Du kan ikke hvidvaske for dig selv.' })
        return
    end

    if not IsNearComputer(src, computerIndex) then
        cb({ ok = false, message = 'Du er ikke ved en revisor-computer.' })
        return
    end

    if not IsTargetNear(src, targetId) then
        cb({ ok = false, message = 'Klienten er for langt væk.' })
        return
    end

    if ActiveWashes[src] then
        cb({ ok = false, message = 'Du har allerede en aktiv transaktion.' })
        return
    end

    if ActiveWashes[targetId] then
        cb({ ok = false, message = 'Klienten har allerede en aktiv transaktion.' })
        return
    end

    amount = ClampNumber(amount, Config.MinAmount, Config.MaxAmount)
    percent = ClampNumber(percent, Config.MinFeePercent, Config.MaxFeePercent)

    if not amount or not percent then
        cb({ ok = false, message = 'Beløb eller procent er udenfor grænsen.' })
        return
    end

    local blackMoney = Bridge.GetBlackMoney(targetId)
    if blackMoney < amount then
        cb({ ok = false, message = 'Klienten har ikke nok sorte penge.' })
        return
    end

    local revisorCut = math.floor(amount * (percent / 100))
    local cleanPayout = amount - revisorCut
    local duration = math.min(Config.BaseWashTime + math.floor((amount / 1000) * Config.TimePer1000), Config.MaxWashTime)

    if not Bridge.RemoveBlackMoney(targetId, amount) then
        cb({ ok = false, message = 'Kunne ikke fjerne sorte penge fra klienten.' })
        return
    end

    ActiveWashes[src] = true
    ActiveWashes[targetId] = true

    local revisorName = Bridge.GetName(src)
    local clientName = Bridge.GetName(targetId)

    Bridge.Notify(src, ('Hvidvask startet for %s.'):format(clientName), 'inform')
    Bridge.Notify(targetId, ('Din revisor behandler %s sorte penge.'):format(Bridge.GroupDigits(amount)), 'inform')

    SendWebhook(
        'Hvidvask startet',
        ('**Revisor:** %s [%s]\n**Klient:** %s [%s]\n**Beløb:** %s\n**Gebyr:** %s%%\n**Revisor får:** %s\n**Klient får:** %s\n**Framework:** %s\n**Inventory:** %s'):format(
            revisorName, src,
            clientName, targetId,
            Bridge.GroupDigits(amount),
            percent,
            Bridge.GroupDigits(revisorCut),
            Bridge.GroupDigits(cleanPayout),
            Bridge.Framework,
            Bridge.Inventory
        ),
        15844367
    )

    SetTimeout(duration, function()
        if GetPlayerName(targetId) then
            Bridge.AddCleanMoney(targetId, cleanPayout)
            Bridge.Notify(targetId, ('Du modtog %s rene penge efter hvidvask.'):format(Bridge.GroupDigits(cleanPayout)), 'success')
        end

        if GetPlayerName(src) then
            Bridge.AddCleanMoney(src, revisorCut)

            TriggerClientEvent('am_revisor:washFinished', src, {
                amount = amount,
                percent = percent,
                revisorCut = revisorCut,
                cleanPayout = cleanPayout,
                clientName = clientName,
                message = ('Transaktion færdig. Du modtog %s.'):format(Bridge.GroupDigits(revisorCut))
            })
        end

        ActiveWashes[src] = nil
        ActiveWashes[targetId] = nil

        SendWebhook(
            'Hvidvask færdig',
            ('**Revisor:** %s [%s]\n**Klient:** %s [%s]\n**Beløb:** %s\n**Gebyr:** %s%%\n**Revisor fik:** %s\n**Klient fik:** %s'):format(
                GetPlayerName(src) and Bridge.GetName(src) or 'Offline', src,
                GetPlayerName(targetId) and Bridge.GetName(targetId) or 'Offline', targetId,
                Bridge.GroupDigits(amount),
                percent,
                Bridge.GroupDigits(revisorCut),
                Bridge.GroupDigits(cleanPayout)
            ),
            5763719
        )
    end)

    cb({
        ok = true,
        message = 'Transaktionen er startet.',
        amount = amount,
        percent = percent,
        revisorCut = revisorCut,
        cleanPayout = cleanPayout,
        duration = duration,
        clientName = clientName
    })
end

if GetResourceState('es_extended') == 'started' then
    CreateThread(function()
        while not Bridge.ESX do Wait(250) end

        Bridge.ESX.RegisterServerCallback('am_revisor:startWash', function(src, cb, targetId, amount, percent, computerIndex)
            StartWash(src, cb, targetId, amount, percent, computerIndex)
        end)
    end)
end

RegisterNetEvent('am_revisor:startWashServer', function(targetId, amount, percent, computerIndex)
    local src = source

    StartWash(src, function(result)
        TriggerClientEvent('am_revisor:startWashResult', src, result)
    end, targetId, amount, percent, computerIndex)
end)

AddEventHandler('playerDropped', function()
    local src = source
    ActiveWashes[src] = nil
end)
