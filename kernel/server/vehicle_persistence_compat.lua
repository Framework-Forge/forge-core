-- Private installed-QBX port. Inactive; see kernel/NOTICE-07.md.
return function(ports)
    assert(type(ports) == 'table', 'explicit helper ports required')
    local native = assert(ports.native, 'native persistence ports required')
-- Contrato mínimo de persistência veicular usado pelo próprio qbx_core.
-- O fluxo antigo de respawn dependia do qbx_vehicles, removido desta base.

local function setPersistence(vehicle, enabled)
    vehicle = tonumber(vehicle)
    if not vehicle or vehicle == 0 or not native.DoesEntityExist(vehicle) then
        return false
    end

    local entity = native.Entity(vehicle)
    if not entity or not entity.state then return false end

    entity.state:set("persisted", enabled and true or nil, true)
    return true
end

local function EnablePersistence(vehicle)
    return setPersistence(vehicle, true)
end

local function DisablePersistence(vehicle)
    return setPersistence(vehicle, false)
end


return {EnablePersistence = EnablePersistence, DisablePersistence = DisablePersistence,
    Exports = {EnablePersistence = EnablePersistence, DisablePersistence = DisablePersistence}}
end
