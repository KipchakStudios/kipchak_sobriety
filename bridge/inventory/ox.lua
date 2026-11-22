if Bridge.Inventory ~= 'ox' then return end

InventoryBridge = {}

function InventoryBridge.ItemExists(name)
    return exports.ox_inventory:Items(name) ~= nil
end

local function countOf(src, name)
    return exports.ox_inventory:GetItemCount(src, name) or 0
end

function InventoryBridge.Listen(isTracked, onConsumed)
    local hookPending = {}
    local watchers = {}

    local hookId = exports.ox_inventory:registerHook('usingItem', function(payload)
        local item = payload.item
        if item and isTracked(item.name) then
            hookPending[payload.source] = { name = item.name, at = os.time() }
        end
        return true
    end)

    AddEventHandler(hookId, function(success, payload)
        local item = payload and payload.item
        if not item or not isTracked(item.name) then return end
        if success then
            DebugPrint(('ox hook confirmed %s for %s'):format(item.name, payload.source))
            onConsumed(payload.source, item.name)
        else
            hookPending[payload.source] = nil
        end
    end)

    local function watch(src, name)
        local key = src .. ':' .. name
        local watcher = watchers[key]
        if watcher then
            watcher.expected = watcher.expected + 1
            watcher.deadline = os.time() + Config.ItemDetection.ConfirmWindow
            return
        end
        watcher = { expected = 1, baseline = countOf(src, name), deadline = os.time() + Config.ItemDetection.ConfirmWindow }
        watchers[key] = watcher
        CreateThread(function()
            while watcher.expected > 0 and os.time() < watcher.deadline and GetPlayerName(src) do
                Wait(500)
                local current = countOf(src, name)
                if current < watcher.baseline then
                    local consumed = math.min(watcher.baseline - current, watcher.expected)
                    watcher.expected = watcher.expected - consumed
                    for _ = 1, consumed do
                        onConsumed(src, name)
                    end
                    DebugPrint(('ox watcher confirmed %dx %s for %s'):format(consumed, name, src))
                end
                watcher.baseline = current
            end
            watchers[key] = nil
        end)
    end

    AddEventHandler('ox_inventory:usedItem', function(playerId, name, slot)
        if type(playerId) ~= 'number' or not isTracked(name) then return end
        local pending = hookPending[playerId]
        if pending and pending.name == name and os.time() - pending.at < 10 then
            hookPending[playerId] = nil
            return
        end
        local ok, inventory = pcall(exports.ox_inventory.GetInventory, exports.ox_inventory, playerId)
        local using = ok and inventory and inventory.usingItem
        local startCount = using and using.name == name and using.slot == slot and using.count
        local slotData = exports.ox_inventory:GetSlot(playerId, slot)
        local slotCount = slotData and slotData.name == name and slotData.count or 0
        if startCount and slotCount < startCount then
            DebugPrint(('ox usedItem confirmed %s for %s'):format(name, playerId))
            onConsumed(playerId, name)
            return
        end
        watch(playerId, name)
    end)

    AddEventHandler('playerDropped', function()
        hookPending[source] = nil
    end)
end
