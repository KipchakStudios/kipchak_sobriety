if Bridge.Inventory ~= 'qb' then return end

InventoryBridge = {}

function InventoryBridge.ItemExists(name)
    if GetResourceState('qb-core') ~= 'started' then return true end
    local QBCore = exports['qb-core']:GetCoreObject()
    return QBCore.Shared.Items[name] ~= nil or QBCore.Shared.Items[name:lower()] ~= nil
end
