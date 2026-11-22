Bridge = {}

local function isStarted(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function detectFramework()
    if Config.Framework and Config.Framework ~= 'auto' then
        return Config.Framework
    end
    if isStarted('qbx_core') then return 'qbox' end
    if isStarted('qb-core') then return 'qbcore' end
    if isStarted('es_extended') then return 'esx' end
end

local function detectInventory()
    if Config.Inventory and Config.Inventory ~= 'auto' then
        return Config.Inventory
    end
    if isStarted('ox_inventory') then return 'ox' end
    if isStarted('qb-inventory') then return 'qb' end
    if Bridge.Framework == 'esx' then return 'esx' end
end

Bridge.Framework = detectFramework()
Bridge.Inventory = detectInventory()
