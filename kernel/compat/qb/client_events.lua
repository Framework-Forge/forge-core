-- Private port of installed QBX bridge/qb/client/events.lua; see NOTICE-91.md and LICENSE-QBX.
return function(ports)
assert(type(ports.config)=='table'and type(ports.config.hasKeys)=='function','canonical client key configuration required')
assert(type(ports.helpers)=='table'and type(ports.native)=='table','internal helpers/platform required')
local events={}
local function listen(name,fn)events[#events+1]={name=name,handler=fn,network=true}end
local config = ports.config

-- Trigger Command
--- @deprecated
listen('QBCore:Command:CallCommand', function(command)
    ports.native.ExecuteCommand(command)
end)

listen('QBCore:Client:VehicleInfo', function(info)
    local vehicle = ports.native.NetworkGetEntityFromNetworkId(info.netId)
    local plate = ports.helpers.getVehiclePlate(vehicle)
    local hasKeys = config.hasKeys(plate, vehicle)

    local data = {
        vehicle = vehicle,
        seat = info.seat,
        name = info.modelName,
        plate = plate,
        driver = ports.native.GetPedInVehicleSeat(vehicle, -1),
        inseat = ports.native.GetPedInVehicleSeat(vehicle, info.seat),
        haskeys = hasKeys
    }

    ports.native.TriggerEvent('QBCore:Client:'..info.event..'Vehicle', data)
end)

return events
end
