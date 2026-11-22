local sessions = {}
local sessionsByTarget = {}
local cooldowns = {}
local lastEvent = {}
local tokenSeq = 0

if not Bridge.Framework or not Bridge.GetIdentifier then
    print('^1[kipchak_sobriety] No supported framework found. Set Config.Framework or check your ensure order.^7')
end

local function notify(src, key, notifyType, ...)
    Bridge.Notify(src, L(key, ...), notifyType)
end

local function rateLimited(src)
    local now = GetGameTimer()
    if lastEvent[src] and now - lastEvent[src] < 300 then
        return true
    end
    lastEvent[src] = now
    return false
end

local function isAllowed(src)
    if not Bridge.GetJob then return false end
    local job, grade, onDuty = Bridge.GetJob(src)
    if not job then return false end
    local minGrade = Config.AllowedJobs[job]
    if not minGrade or (grade or 0) < minGrade then return false end
    if Config.RequireOnDuty and not onDuty then return false end
    return true
end

local function distanceBetween(a, b)
    if GetPlayerRoutingBucket(a) ~= GetPlayerRoutingBucket(b) then return math.huge end
    local pedA, pedB = GetPlayerPed(a), GetPlayerPed(b)
    if pedA == 0 or pedB == 0 then return math.huge end
    return #(GetEntityCoords(pedA) - GetEntityCoords(pedB))
end

local function findNearest(src)
    local best, bestDistance
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if id ~= src then
            local dist = distanceBetween(src, id)
            if dist <= Config.MaxDistance and (not bestDistance or dist < bestDistance) then
                best, bestDistance = id, dist
            end
        end
    end
    return best
end

local function sendLog(title, color, fields)
    if not Config.Logs.Enabled or not SvConfig.Webhook or SvConfig.Webhook == '' then return end
    PerformHttpRequest(SvConfig.Webhook, function() end, 'POST', json.encode({
        username = Config.Logs.Username,
        embeds = { {
            title = title,
            color = color,
            fields = fields,
            footer = { text = 'Kipchak Studios' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        } }
    }), { ['Content-Type'] = 'application/json' })
end

local function describe(src)
    return ('%s (%s)'):format(Bridge.GetName(src), src)
end

local function finish(session)
    session.done = true
    if sessions[session.officer] == session then sessions[session.officer] = nil end
    if sessionsByTarget[session.target] == session then sessionsByTarget[session.target] = nil end
end

local function cancel(session, reason)
    if GetPlayerName(session.officer) then
        TriggerClientEvent('kipchak_sobriety:stopTest', session.officer)
        notify(session.officer, reason or 'test_cancelled', 'error')
    end
    if GetPlayerName(session.target) then
        TriggerClientEvent('kipchak_sobriety:consentClose', session.target)
    end
    DebugPrint(('test %s cancelled (%s)'):format(session.token, reason or 'test_cancelled'))
    finish(session)
end

local function validate(session)
    if session.cancelled then return false, session.cancelReason end
    if not GetPlayerName(session.officer) or not GetPlayerName(session.target) then return false, 'test_cancelled' end
    if Bridge.IsDead(session.officer) or Bridge.IsDead(session.target) then return false, 'test_cancelled' end
    if session.officer ~= session.target and distanceBetween(session.officer, session.target) > Config.MaxDistance then return false, 'too_far' end
    return true
end

local function round(value, precision)
    local factor = 10 ^ precision
    return math.floor(value * factor + 0.5) / factor
end

local function baseResult(session)
    return {
        kind = session.kind,
        title = L(session.kind == 'alcohol' and 'title_alcohol' or 'title_drug'),
        subject = Bridge.GetName(session.target),
        officer = Bridge.GetName(session.officer),
        date = os.date('%d.%m.%Y %H:%M'),
        labels = {
            subject = L('label_subject'),
            officer = L('label_officer'),
            date = L('label_date'),
            close = L('close_hint', Config.Result.CloseKey)
        },
        branding = Config.Result.Branding
    }
end

local function alcoholResult(session)
    local cfg = Config.Alcohol
    local value = Levels.GetAlcohol(session.target)
    local variance = tonumber(cfg.RandomVariance) or 0
    if variance > 0 and value > 0 then
        value = math.max(0.0, value + (math.random() * 2 - 1) * variance)
    end
    local precision = cfg.Precision or 2
    value = round(value, precision)
    local result = baseResult(session)
    if value <= 0 then
        result.status, result.statusText = 'neutral', L('negative')
    elseif value >= cfg.LegalLimit then
        result.status, result.statusText = 'danger', L('above_limit')
    else
        result.status, result.statusText = 'ok', L('below_limit')
    end
    if cfg.Unit == 'bac' then
        result.value = ('%.' .. (precision + 1) .. 'f'):format(value / 10)
        result.unit = L('unit_bac')
    else
        result.value = ('%.' .. precision .. 'f'):format(value)
        result.unit = L('unit_permille')
    end
    return result
end

local function drugResult(session)
    local drugs = Levels.GetDrugs(session.target)
    local result = baseResult(session)
    result.rows = {}
    local anyPositive = false
    for _, category in ipairs(Config.Drugs.Categories) do
        local positive = drugs[category.name] == true
        anyPositive = anyPositive or positive
        result.rows[#result.rows + 1] = {
            label = L('drug_' .. category.name),
            positive = positive,
            text = L(positive and 'positive' or 'negative')
        }
    end
    result.status = anyPositive and 'danger' or 'ok'
    result.statusText = L(anyPositive and 'positive' or 'negative')
    return result
end

local function resultSummary(result)
    if result.kind == 'alcohol' then
        return ('%s %s - %s'):format(result.value, result.unit, result.statusText)
    end
    local lines = {}
    for _, row in ipairs(result.rows) do
        lines[#lines + 1] = ('%s: %s'):format(row.label, row.text)
    end
    return table.concat(lines, '\n')
end

local function broadcastMe(session)
    local text = L(session.kind == 'alcohol' and 'auto_me_alcohol' or 'auto_me_drug')
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if id == session.officer or distanceBetween(session.officer, id) <= Config.AutoMe.Range then
            TriggerClientEvent('kipchak_sobriety:me', id, session.officer, text, Config.AutoMe.Duration)
        end
    end
end

local function waitFor(session, durationMs, check)
    local deadline = GetGameTimer() + durationMs
    while GetGameTimer() < deadline do
        local ok, reason = validate(session)
        if ok and check then ok, reason = check() end
        if not ok then return false, reason end
        if session.consent ~= nil and session.state == 'consent' then return true end
        Wait(200)
    end
    return true
end

local function runTest(session)
    if Config.Consent.Enabled then
        session.state = 'consent'
        notify(session.officer, 'waiting_consent', 'inform')
        TriggerClientEvent('kipchak_sobriety:consent', session.target, session.token, session.kind, Config.Consent.Timeout)
        local ok, reason = waitFor(session, Config.Consent.Timeout * 1000)
        if not ok then return cancel(session, reason) end
        if session.consent ~= true then
            TriggerClientEvent('kipchak_sobriety:consentClose', session.target)
            notify(session.officer, 'test_refused', 'error')
            notify(session.target, 'test_refused_target', 'inform')
            sendLog(L('log_title_refused'), 15105570, {
                { name = L('log_officer'), value = describe(session.officer), inline = true },
                { name = L('log_subject'), value = describe(session.target), inline = true },
                { name = L('log_type'), value = L(session.kind == 'alcohol' and 'log_title_alcohol' or 'log_title_drug'), inline = true }
            })
            return finish(session)
        end
    end

    session.state = 'testing'
    if Config.AutoMe.Enabled then
        broadcastMe(session)
    end

    if Config.Animation.Enabled then
        local officerPed = GetPlayerPed(session.officer)
        local startCoords = GetEntityCoords(officerPed)
        TriggerClientEvent('kipchak_sobriety:progress', session.officer, session.token, session.kind, Config.Animation.Duration)
        local ok, reason = waitFor(session, Config.Animation.Duration, function()
            if #(GetEntityCoords(GetPlayerPed(session.officer)) - startCoords) > Config.Animation.MaxMove then
                return false, 'test_cancelled'
            end
            return true
        end)
        if not ok then return cancel(session, reason) end
    end

    local ok, reason = validate(session)
    if not ok then return cancel(session, reason) end

    local result = session.kind == 'alcohol' and alcoholResult(session) or drugResult(session)
    TriggerClientEvent('kipchak_sobriety:result', session.officer, result)
    if session.target == session.officer then
        DebugPrint(('test %s was a self test'):format(session.token))
    elseif Config.ShowResultToTarget then
        TriggerClientEvent('kipchak_sobriety:result', session.target, result)
    else
        notify(session.target, session.kind == 'alcohol' and 'tested_alcohol_target' or 'tested_drug_target', 'inform')
    end

    sendLog(L(session.kind == 'alcohol' and 'log_title_alcohol' or 'log_title_drug'), result.status == 'danger' and 15158332 or 3066993, {
        { name = L('log_officer'), value = describe(session.officer), inline = true },
        { name = L('log_subject'), value = describe(session.target), inline = true },
        { name = L('log_result'), value = resultSummary(result), inline = false }
    })
    DebugPrint(('test %s finished: %s'):format(session.token, resultSummary(result)))
    finish(session)
end

local function startTest(src, args, kind)
    if not isAllowed(src) then return notify(src, 'no_permission', 'error') end
    if sessions[src] then return notify(src, 'officer_busy', 'error') end

    local remaining = (cooldowns[src] or 0) - os.time()
    if remaining > 0 then return notify(src, 'cooldown', 'error', remaining) end

    local target = args.id and tonumber(args.id)
    if not target then
        target = Config.AutoNearest and findNearest(src) or nil
        if not target then
            if not Config.AllowSelfTest then
                return notify(src, Config.AutoNearest and 'no_player_nearby' or 'invalid_target', 'error')
            end
            target = src
            notify(src, 'self_test_notice', 'inform')
        end
    end

    local isSelf = target == src
    if isSelf and not Config.AllowSelfTest then return notify(src, 'self_test', 'error') end
    if not GetPlayerName(target) or not Bridge.GetIdentifier(target) then return notify(src, 'invalid_target', 'error') end
    if not isSelf and distanceBetween(src, target) > Config.MaxDistance then return notify(src, 'too_far', 'error') end
    if sessionsByTarget[target] or sessions[target] then return notify(src, 'target_busy', 'error') end
    if Bridge.IsDead(target) then return notify(src, 'target_unavailable', 'error') end

    cooldowns[src] = os.time() + Config.Cooldown
    tokenSeq = tokenSeq + 1
    local session = { token = tokenSeq, officer = src, target = target, kind = kind }
    sessions[src] = session
    sessionsByTarget[target] = session
    DebugPrint(('test %s started: %s -> %s (%s)'):format(session.token, src, target, kind))
    CreateThread(function()
        runTest(session)
    end)
end

local commandParams = {
    { name = 'id', type = 'playerId', help = L('cmd_arg_id'), optional = true }
}

lib.addCommand(Config.Commands.alcohol, { help = L('cmd_alcohol'), params = commandParams }, function(src, args)
    if src <= 0 then return end
    startTest(src, args, 'alcohol')
end)

lib.addCommand(Config.Commands.drug, { help = L('cmd_drug'), params = commandParams }, function(src, args)
    if src <= 0 then return end
    startTest(src, args, 'drug')
end)

RegisterNetEvent('kipchak_sobriety:consentReply', function(token, accepted)
    local src = source
    if rateLimited(src) then return end
    local session = sessionsByTarget[src]
    if not session or session.done or session.token ~= token or session.state ~= 'consent' or session.consent ~= nil then return end
    session.consent = accepted == true
end)

RegisterNetEvent('kipchak_sobriety:cancel', function(token)
    local src = source
    if rateLimited(src) then return end
    local session = sessions[src]
    if not session or session.done or session.token ~= token then return end
    session.cancelled = true
    session.cancelReason = 'test_cancelled'
end)

local function dropSessions(src)
    local session = sessions[src] or sessionsByTarget[src]
    if session and not session.done then
        session.cancelled = true
        session.cancelReason = 'test_cancelled'
    end
end

AddEventHandler('playerDropped', function()
    local src = source
    dropSessions(src)
    Levels.Unload(src)
    cooldowns[src] = nil
    lastEvent[src] = nil
end)

for _, eventName in ipairs(Bridge.UnloadEvents or {}) do
    AddEventHandler(eventName, function(src)
        local caller = tonumber(source)
        if caller and caller > 0 then return end
        src = tonumber(src)
        if not src then return end
        dropSessions(src)
        Levels.Unload(src)
    end)
end

exports('AddAlcohol', function(src, amount)
    src, amount = tonumber(src), tonumber(amount)
    if not src or not amount or amount <= 0 then return false end
    return Levels.AddAlcohol(src, amount)
end)

exports('AddDrug', function(src, category)
    src = tonumber(src)
    if not src or type(category) ~= 'string' then return false end
    return Levels.AddDrug(src, category)
end)

exports('GetAlcohol', function(src)
    src = tonumber(src)
    if not src then return 0.0 end
    return Levels.GetAlcohol(src)
end)

exports('GetDrugs', function(src)
    src = tonumber(src)
    if not src then return {} end
    return Levels.GetDrugs(src)
end)

exports('Reset', function(src)
    src = tonumber(src)
    if not src then return false end
    return Levels.Reset(src)
end)

if Config.AdminCommands.Enabled then
    local function adminAllowed(src)
        return src == 0 or IsPlayerAceAllowed(src, 'kipchak_sobriety.admin')
    end

    local function reply(src, message)
        if src == 0 then
            print('[kipchak_sobriety] ' .. message)
        else
            Bridge.Notify(src, message, 'inform')
        end
    end

    local function validTarget(id)
        return id and GetPlayerName(id) and Bridge.GetIdentifier(id)
    end

    RegisterCommand(Config.AdminCommands.SetAlcohol, function(src, args)
        if not adminAllowed(src) then return end
        local target, value = tonumber(args[1]), tonumber(args[2])
        if not validTarget(target) or not value then return reply(src, L('admin_invalid')) end
        local newValue = Levels.SetAlcohol(target, value)
        reply(src, L('admin_set', Bridge.GetName(target), newValue or 0))
    end, false)

    RegisterCommand(Config.AdminCommands.AddDrug, function(src, args)
        if not adminAllowed(src) then return end
        local target, category = tonumber(args[1]), args[2]
        if not validTarget(target) or not category then return reply(src, L('admin_invalid')) end
        if not Levels.IsCategory(category) then return reply(src, L('admin_category', category)) end
        Levels.AddDrug(target, category)
        reply(src, L('admin_drug', category, Bridge.GetName(target)))
    end, false)

    RegisterCommand(Config.AdminCommands.Reset, function(src, args)
        if not adminAllowed(src) then return end
        local target = tonumber(args[1])
        if not validTarget(target) then return reply(src, L('admin_invalid')) end
        Levels.Reset(target)
        reply(src, L('admin_reset', Bridge.GetName(target)))
    end, false)
end

CreateThread(function()
    if not InventoryBridge then
        print('^3[kipchak_sobriety] No supported inventory found. Automatic item detection and item check are disabled.^7')
        return
    end
    if Config.ItemDetection.Enabled and InventoryBridge.Listen then
        InventoryBridge.Listen(Items.IsTracked, Items.Consume)
    end
    if Config.StartupItemCheck then
        Wait(5000)
        Items.CheckDefinitions()
    end
end)
