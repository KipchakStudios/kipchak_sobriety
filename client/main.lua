local resultVisible = false
local displayId = 0
local progressToken = nil
local meTexts = {}
local meDrawing = false

local function hideResult()
    if not resultVisible then return end
    resultVisible = false
    SendNUIMessage({ action = 'hide' })
end

RegisterNetEvent('kipchak_sobriety:result', function(data)
    if type(data) ~= 'table' then return end
    displayId = displayId + 1
    local id = displayId
    resultVisible = true
    SendNUIMessage({ action = 'show', position = Config.Result.Position, data = data })
    if Config.Result.Duration and Config.Result.Duration > 0 then
        SetTimeout(Config.Result.Duration, function()
            if displayId == id then hideResult() end
        end)
    end
end)

lib.addKeybind({
    name = 'kipchak_sobriety_close',
    description = L('keybind_close'),
    defaultKey = Config.Result.CloseKey,
    onPressed = hideResult
})

RegisterNetEvent('kipchak_sobriety:consent', function(token, kind, timeout)
    CreateThread(function()
        local answer = lib.alertDialog({
            header = L('consent_title'),
            content = L(kind == 'alcohol' and 'consent_alcohol' or 'consent_drug', tonumber(timeout) or 0),
            centered = true,
            cancel = true,
            labels = { confirm = L('accept'), cancel = L('decline') }
        })
        TriggerServerEvent('kipchak_sobriety:consentReply', token, answer == 'confirm')
    end)
end)

RegisterNetEvent('kipchak_sobriety:consentClose', function()
    lib.closeAlertDialog()
end)

local function animEntry(source, kind)
    local entry = source[kind == 'alcohol' and 'Alcohol' or 'Drug']
    if entry == nil and source == Config.Animation and source.Dict then
        entry = { Dict = source.Dict, Clip = source.Clip, Flag = 49, Prop = source.Prop }
    end
    if type(entry) ~= 'table' or type(entry.Dict) ~= 'string' or entry.Dict == '' or not entry.Clip then return end
    return entry
end

local targetAnimToken = 0

RegisterNetEvent('kipchak_sobriety:targetAnim', function(kind, duration)
    local target = Config.Animation.Target
    if not Config.Animation.Enabled or type(target) ~= 'table' or not target.Enabled then return end
    local entry = animEntry(target, kind)
    if not entry then return end
    local ped = cache.ped
    if cache.vehicle or IsEntityDead(ped) then return end
    targetAnimToken = targetAnimToken + 1
    local token = targetAnimToken
    CreateThread(function()
        if not pcall(lib.requestAnimDict, entry.Dict, 3000) then return end
        if token ~= targetAnimToken then return RemoveAnimDict(entry.Dict) end
        TaskPlayAnim(ped, entry.Dict, entry.Clip, 3.0, 3.0, -1, entry.Flag or 49, 0, false, false, false)
        local stopAt = GetGameTimer() + (tonumber(duration) or 5000)
        while token == targetAnimToken and GetGameTimer() < stopAt and not cache.vehicle do
            Wait(100)
        end
        StopAnimTask(ped, entry.Dict, entry.Clip, 1.0)
        RemoveAnimDict(entry.Dict)
    end)
end)

RegisterNetEvent('kipchak_sobriety:targetStop', function()
    targetAnimToken = targetAnimToken + 1
end)

RegisterNetEvent('kipchak_sobriety:progress', function(token, kind, duration)
    progressToken = token
    CreateThread(function()
        local entry = not cache.vehicle and animEntry(Config.Animation, kind) or nil
        local completed = lib.progressBar({
            duration = duration,
            label = L(kind == 'alcohol' and 'progress_alcohol' or 'progress_drug'),
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, combat = true },
            anim = entry and { dict = entry.Dict, clip = entry.Clip, flag = entry.Flag or 49 } or nil,
            prop = entry and type(entry.Prop) == 'table' and entry.Prop or nil
        })
        if not completed and progressToken == token then
            TriggerServerEvent('kipchak_sobriety:cancel', token)
        end
        if progressToken == token then progressToken = nil end
    end)
end)

RegisterNetEvent('kipchak_sobriety:stopTest', function()
    if not progressToken then return end
    progressToken = nil
    if lib.progressActive() then lib.cancelProgress() end
end)

local function drawText3D(coords, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(220, 200, 255, 230)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function startMeLoop()
    if meDrawing then return end
    meDrawing = true
    CreateThread(function()
        while next(meTexts) do
            local now = GetGameTimer()
            for serverId, entry in pairs(meTexts) do
                if now > entry.expires then
                    meTexts[serverId] = nil
                else
                    local player = GetPlayerFromServerId(serverId)
                    if player ~= -1 then
                        local ped = GetPlayerPed(player)
                        if ped ~= 0 then
                            drawText3D(GetEntityCoords(ped) + vec3(0.0, 0.0, 1.0), entry.text)
                        end
                    end
                end
            end
            Wait(0)
        end
        meDrawing = false
    end)
end

RegisterNetEvent('kipchak_sobriety:me', function(serverId, text, duration)
    if type(text) ~= 'string' then return end
    meTexts[serverId] = { text = '* ' .. text .. ' *', expires = GetGameTimer() + (tonumber(duration) or 5000) }
    startMeLoop()
end)

if Config.DrunkEffect.Enabled then
    CreateThread(function()
        local current, appliedPed
        while true do
            local value = LocalPlayer.state.kipchak_alcohol or 0
            local level
            for _, entry in ipairs(Config.DrunkEffect.Levels) do
                if value >= entry.min then level = entry end
            end
            local ped = PlayerPedId()
            if level ~= current or (level and ped ~= appliedPed) then
                if level then
                    lib.requestAnimSet(level.walk)
                    SetPedMovementClipset(ped, level.walk, 1.0)
                    RemoveAnimSet(level.walk)
                    ShakeGameplayCam('DRUNK_SHAKE', level.shake)
                    SetTimecycleModifier('spectator5')
                    SetTimecycleModifierStrength(level.strength)
                elseif current then
                    ResetPedMovementClipset(ped, 1.0)
                    StopGameplayCamShaking(true)
                    ClearTimecycleModifier()
                end
                current, appliedPed = level, ped
            end
            Wait(2000)
        end
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if Config.DrunkEffect.Enabled then
        ResetPedMovementClipset(PlayerPedId(), 1.0)
        StopGameplayCamShaking(true)
        ClearTimecycleModifier()
    end
end)
