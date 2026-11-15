-- Port of installed qbx_core/shared/main.lua; see ../NOTICE.md and LICENSE-QBX.
return function(ports)
assert(type(ports) == 'table', 'shared seeds required')
assert(type(ports.locations) == 'table' and type(ports.weapons) == 'table', 'explicit shared seeds required')
local qbShared = {}
qbShared.ForceJobDefaultDutyAtLogin = true -- true: Force duty state to jobdefaultDuty | false: set duty state from database last saved
qbShared.Locations = ports.locations
qbShared.Vehicles = {}
qbShared.Weapons = ports.weapons

---@type table<number, Vehicle>
qbShared.VehicleHashes = {}

---@param vehicles table<string, Vehicle>?
---@return number count
function qbShared.SetVehicles(vehicles)
    for key in pairs(qbShared.Vehicles) do
        qbShared.Vehicles[key] = nil
    end

    for hash in pairs(qbShared.VehicleHashes) do
        qbShared.VehicleHashes[hash] = nil
    end

    local count = 0
    for key, vehicle in pairs(type(vehicles) == 'table' and vehicles or {}) do
        if type(key) == 'string' and type(vehicle) == 'table' and type(vehicle.hash) == 'number' then
            qbShared.Vehicles[key] = vehicle
            qbShared.VehicleHashes[vehicle.hash] = vehicle
            count = count + 1
        end
    end

    return count
end

return qbShared

end
