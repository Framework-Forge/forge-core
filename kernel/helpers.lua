-- Inactive composition; internal services stay internal, external delivery uses PR ports.
local createLib = require 'kernel.modules.lib'
local createLocale = require 'kernel.shared.locale'
local createPersistence = require 'kernel.server.vehicle_persistence_compat'
local createPlayerView = require 'kernel.modules.playerdata'

return function(ports)
    assert(type(ports) == 'table' and type(ports.isServer) == 'boolean', 'helper side required')
    local library, native = assert(ports.library), assert(ports.native)
    local bindings = {isServer = ports.isServer, native = native, library = library,
        cache = assert(ports.cache), audio = assert(ports.audio), warn = assert(ports.warn)}
    local result = {Locale = createLocale({warn = ports.warn})}
    if ports.isServer then
        local shared, functions = assert(ports.shared), assert(ports.functions)
        assert(type(shared.VehicleHashes) == 'table' and type(functions.SetEntityBucket) == 'function',
            'existing internal vehicle catalog/bucket functions required')
        result.Persistence = createPersistence({native = native})
        bindings.core = {
            getVehiclesByHash = function(key) return shared.VehicleHashes[key] or shared.VehicleHashes end,
            setEntityBucket = functions.SetEntityBucket,
            enablePersistence = result.Persistence.EnablePersistence,
        }
    end
    result.Lib = createLib(bindings)
    -- Explicit creation only for future legacy consumers; never replaces core.PlayerData.
    function result.CreatePlayerDataView(getPlayerData)
        return createPlayerView({isServer = ports.isServer, getPlayerData = getPlayerData})
    end
    return result
end
