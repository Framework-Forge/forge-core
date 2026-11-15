-- Private port of installed QBX bridge/qb/server/events.lua and debug.lua; see NOTICE-89.md.
return function(ports)
local events={}
local function listen(name,fn)events[#events+1]={name=name,handler=fn,network=true,sourceFirst=name~='QBCore:DebugSomething'}end
-- Vehicles
listen('baseevents:enteringVehicle', function(source, veh, seat, modelName, netId)
    local src = source
    local data = {
        vehicle = veh,
        seat = seat,
        name = modelName,
        netId = netId,
        event = 'Entering'
    }
    ports.native.TriggerClientEvent('QBCore:Client:VehicleInfo', src, data)
end)

listen('baseevents:enteredVehicle', function(source, veh, seat, modelName, netId)
    local src = source
    local data = {
        vehicle = veh,
        seat = seat,
        name = modelName,
        netId = netId,
        event = 'Entered'
    }
    ports.native.TriggerClientEvent('QBCore:Client:VehicleInfo', src, data)
end)

listen('baseevents:enteringAborted', function(source)
    local src = source
    ports.native.TriggerClientEvent('QBCore:Client:AbortVehicleEntering', src)
end)

listen('baseevents:leftVehicle', function(source, veh, seat, modelName, netId)
    local src = source
    local data = {
        vehicle = veh,
        seat = seat,
        name = modelName,
        netId = netId,
        event = 'Left'
    }
    ports.native.TriggerClientEvent('QBCore:Client:VehicleInfo', src, data)
end)
---@deprecated Call ports.lib.print.debug() instead
---@param tbl any
listen('QBCore:DebugSomething', function(tbl)
    local resource = ports.native.GetInvokingResource() or 'qbx_core'
    ports.lib.print.debug(resource, tbl)
end)

return events
end
