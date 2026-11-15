-- Internal half of runtime10's setter. The public caller guard remains in runtime10.
-- No second catalog: both paths mutate the exact same Shared tables in place.
return function(ports)
    local core,native=assert(ports.state),assert(ports.native)
    assert(type(core.Shared.SetVehicles)=='function','canonical Shared vehicle setter required')
    local function setVehicleCatalog(vehicles)
        local count = core.Shared.SetVehicles(vehicles)
        native.TriggerClientEvent('qbx_core:client:setVehicleCatalog', -1, core.Shared.Vehicles)
        return true, count
    end
    return {SetVehicleCatalog=setVehicleCatalog,State=core,Shared=core.Shared}
end
