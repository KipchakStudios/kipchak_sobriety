Levels = {}

local states = {}
local identifiers = {}
local detection = {}
local kvpPrefix = 'kipchak_sobriety:'

for _, category in ipairs(Config.Drugs.Categories) do
    detection[category.name] = (tonumber(category.minutes) or 60) * 60
end

local function resolve(src)
    local identifier = Bridge.GetIdentifier and Bridge.GetIdentifier(src)
    if identifier then
        identifiers[src] = identifier
    end
    return identifier
end

local function loadState(identifier)
    local state = states[identifier]
    if state then return state end
    state = { alcohol = 0.0, alcoholAt = os.time(), drugs = {} }
    if Config.Persistence then
        local raw = GetResourceKvpString(kvpPrefix .. identifier)
        if raw then
            local ok, data = pcall(json.decode, raw)
            if ok and type(data) == 'table' then
                state.alcohol = tonumber(data.alcohol) or 0.0
                state.alcoholAt = tonumber(data.alcoholAt) or os.time()
                if type(data.drugs) == 'table' then
                    for name, usedAt in pairs(data.drugs) do
                        if detection[name] and type(usedAt) == 'number' then
                            state.drugs[name] = usedAt
                        end
                    end
                end
            end
        end
    end
    states[identifier] = state
    return state
end

local function refresh(state)
    local now = os.time()
    local elapsed = (now - state.alcoholAt) / 60
    if elapsed > 0 then
        state.alcohol = math.max(0.0, state.alcohol - elapsed * Config.Alcohol.DecayPerMinute)
        state.alcoholAt = now
    end
    for name, usedAt in pairs(state.drugs) do
        if not detection[name] or now - usedAt >= detection[name] then
            state.drugs[name] = nil
        end
    end
    return state
end

local function save(identifier, state)
    if not Config.Persistence then return end
    if state.alcohol <= 0 and next(state.drugs) == nil then
        DeleteResourceKvp(kvpPrefix .. identifier)
        return
    end
    SetResourceKvp(kvpPrefix .. identifier, json.encode({
        alcohol = state.alcohol,
        alcoholAt = state.alcoholAt,
        drugs = state.drugs
    }))
end

local function syncEffect(src, value)
    if not Config.DrunkEffect.Enabled then return end
    local rounded = math.floor(value * 100 + 0.5) / 100
    if Player(src).state.kipchak_alcohol ~= rounded then
        Player(src).state:set('kipchak_alcohol', rounded, true)
    end
end

local function getState(src)
    local identifier = resolve(src)
    if not identifier then return end
    return refresh(loadState(identifier)), identifier
end

function Levels.GetAlcohol(src)
    local state = getState(src)
    return state and state.alcohol or 0.0
end

function Levels.SetAlcohol(src, value)
    local state, identifier = getState(src)
    if not state then return false end
    state.alcohol = math.min(math.max(0.0, value), Config.Alcohol.Max)
    state.alcoholAt = os.time()
    save(identifier, state)
    syncEffect(src, state.alcohol)
    DebugPrint(('alcohol of %s set to %.3f'):format(src, state.alcohol))
    return state.alcohol
end

function Levels.AddAlcohol(src, amount)
    local state = getState(src)
    if not state then return false end
    return Levels.SetAlcohol(src, state.alcohol + amount)
end

function Levels.AddDrug(src, category)
    if not detection[category] then return false end
    local state, identifier = getState(src)
    if not state then return false end
    state.drugs[category] = os.time()
    save(identifier, state)
    DebugPrint(('drug %s registered for %s'):format(category, src))
    return true
end

function Levels.GetDrugs(src)
    local result = {}
    local state = getState(src)
    for _, category in ipairs(Config.Drugs.Categories) do
        result[category.name] = state and state.drugs[category.name] ~= nil or false
    end
    return result
end

function Levels.IsCategory(category)
    return detection[category] ~= nil
end

function Levels.Reset(src)
    local state, identifier = getState(src)
    if not state then return false end
    state.alcohol = 0.0
    state.alcoholAt = os.time()
    state.drugs = {}
    save(identifier, state)
    syncEffect(src, 0.0)
    DebugPrint(('values reset for %s'):format(src))
    return true
end

function Levels.Unload(src)
    local identifier = identifiers[src]
    identifiers[src] = nil
    if not identifier then return end
    local state = states[identifier]
    if state then
        save(identifier, refresh(state))
    end
    states[identifier] = nil
    if Config.DrunkEffect.Enabled and GetPlayerName(src) then
        Player(src).state:set('kipchak_alcohol', 0.0, true)
    end
end

if Config.DrunkEffect.Enabled then
    CreateThread(function()
        while true do
            Wait(20000)
            for src in pairs(identifiers) do
                if GetPlayerName(src) then
                    syncEffect(src, Levels.GetAlcohol(src))
                end
            end
        end
    end)
end
