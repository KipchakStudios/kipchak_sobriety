if Bridge.Framework ~= 'esx' then return end

local ESX = exports.es_extended:getSharedObject()

local function getPlayer(src)
    return ESX.GetPlayerFromId(src)
end

function Bridge.GetIdentifier(src)
    local xPlayer = getPlayer(src)
    return xPlayer and xPlayer.identifier
end

function Bridge.GetName(src)
    local xPlayer = getPlayer(src)
    if not xPlayer then return GetPlayerName(src) or tostring(src) end
    return xPlayer.getName()
end

function Bridge.GetJob(src)
    local xPlayer = getPlayer(src)
    if not xPlayer or not xPlayer.job then return end
    local job = xPlayer.job
    return job.name, tonumber(job.grade) or 0, job.onDuty ~= false
end

function Bridge.IsDead(src)
    if Player(src).state.isDead then return true end
    local ped = GetPlayerPed(src)
    return ped == 0 or GetEntityHealth(ped) <= 0
end

function Bridge.Notify(src, message, notifyType)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = notifyType or 'inform' })
end

Bridge.UnloadEvents = { 'esx:playerDropped', 'esx:playerLogout' }
