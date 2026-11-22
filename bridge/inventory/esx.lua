if Bridge.Inventory ~= 'esx' then return end

InventoryBridge = {}

function InventoryBridge.ItemExists(name)
    if GetResourceState('es_extended') ~= 'started' then return true end
    local ESX = exports.es_extended:getSharedObject()
    local items = ESX.Items
    if type(items) ~= 'table' or next(items) == nil then return true end
    return items[name] ~= nil
end
