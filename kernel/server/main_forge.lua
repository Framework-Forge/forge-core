-- Inactive installed-QBX port; see NOTICE-10.md and LICENSE-QBX.
return function(ports)
    assert(type(ports) == 'table', 'explicit server runtime ports required')
    local core = assert(ports.core, 'canonical server state required')
    local native = assert(ports.native, 'platform ports required')
    local api = {Events = {}, Exports = {}}
    local function describeExport(name, handler) api.Exports[name] = handler; api[name] = handler end
    local function network(name, handler)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = true}
    end
    assert(type(core.Shared) == 'table' and type(core.Players) == 'table', 'existing Shared/Players required')
    assert(type(core.Player_Buckets) == 'table' and type(core.Entity_Buckets) == 'table' and type(core.UsableItems) == 'table', 'existing bucket/item authority required')
    local library = assert(ports.library, 'explicit library ports required')
    local helpers = assert(ports.helpers, 'internal Lib required')
    local globalState = assert(ports.globalState, 'global state delivery required')
    local newPromise = assert(ports.newPromise, 'promise factory required')
    local awaitPromise = assert(ports.awaitPromise, 'promise wait port required')
    local random = assert(ports.random, 'RNG port required')
    local initialized, initializing = false, false
    function api.Initialize()
        if initialized or initializing then return false end
        initializing = true
        local ok, err = pcall(function()
            local startupErrors, errorMessage
            if not library.checkDependency('ox_lib', '3.20.0', true) then
                startupErrors, errorMessage = true, 'ox_lib version 3.20.0 or higher is required'
            elseif not library.checkDependency('ox_inventory', '2.42.1', true) then
                startupErrors, errorMessage = true, 'ox_inventory version 2.42.1 or higher is required'
            elseif native.GetConvar('inventory:framework', '') ~= 'forge' then
                startupErrors, errorMessage = true, 'inventory:framework must be set to "forge" in order to use Forge'
            elseif native.GetConvarInt('onesync_enableInfinity', 0) ~= 1 then
                startupErrors, errorMessage = true, 'OneSync Infinity is not enabled. You can do so in txAdmin settings or add +set onesync on to your server startup command line'
            end
            if startupErrors then
                library.print.error('Startup errors detected, shutting down server...')
                native.ExecuteCommand('quit immediately')
                for _ = 1, 100 do
                    library.print.error(errorMessage)
                end
                error(errorMessage)
            end
            
            ---@type 'strict'|'relaxed'|'inactive'
            local bucketLockDownMode = native.GetConvar('qbx:bucketlockdownmode', 'inactive')
            native.SetRoutingBucketEntityLockdownMode(0, bucketLockDownMode)
            
            
            globalState.PlayerCount = 0
            globalState.MaxPlayers = native.GetConvarInt('sv_maxclients', 48)
        end)
        initializing = false
        if not ok then error(err, 0) end
        initialized = true
        return true
    end

---@alias Model number
---@alias VehicleClass integer see https://docs.fivem.net/natives/?_0x29439776AAA00A62
---@type table<Model, VehicleClass>
local vehicleClasses
local vehicleClassesPromise

local currentSessionId = 0

---Sets a unique sessionId statebag on the entity.
---If the entity already has a sessionId, this will return it rather than overwrite.
---@param entity number
---@return integer sessionId
local function createSessionId(entity)
    local existingSessionId = native.Entity(entity).state.sessionId
    if existingSessionId then
        return existingSessionId
    end
    currentSessionId = currentSessionId + 1
    local sessionId = currentSessionId
    native.Entity(entity).state:set('sessionId', sessionId, true)
    return sessionId
end

describeExport('CreateSessionId', createSessionId)

---Caches the vehicle classes the first time this is called by getting the data from a random client.
---Throws an error if there is no cache and no client is connected to get the data from.
---@param model number
---@return VehicleClass
local function GetVehicleClass(model)
    if not vehicleClasses then
        if vehicleClassesPromise then
            awaitPromise(vehicleClassesPromise)
        else
            -- library.callback.await is async, so let additional callers wait along instead of awaiting new callbacks
            vehicleClassesPromise = newPromise()

            -- keep asking different players until we get an answer or until there are no players
            repeat
                local players = native.GetPlayers()
                if #players == 0 then break end
                local playerId = players[random(#players)]
                -- this *may* fail, but we still need to resolve our promise
                pcall(function()
                    vehicleClasses = library.callback.await('qbx_core:client:getVehicleClasses', playerId)
                end)
            until vehicleClasses

            if not vehicleClasses then
                local message = 'no clients online'
                vehicleClassesPromise:reject(message)
                vehicleClassesPromise = nil
                error(message)
            end

            vehicleClassesPromise:resolve()
        end
    end
    return vehicleClasses[model]
end

describeExport('GetVehicleClass', GetVehicleClass)

local function setVehicleCatalog(vehicles)
    local invokingResource = native.GetInvokingResource()
    if invokingResource and invokingResource ~= 'forge-core' and invokingResource ~= native.GetCurrentResourceName() then
        return false, 'unauthorized_resource'
    end

    local count = core.Shared.SetVehicles(vehicles)
    native.TriggerClientEvent('qbx_core:client:setVehicleCatalog', -1, core.Shared.Vehicles)
    return true, count
end

describeExport('SetVehicles', setVehicleCatalog)
describeExport('SetVehicleCatalog', setVehicleCatalog)

network('qbx_core:server:requestVehicleCatalog', function(source)
    native.TriggerClientEvent('qbx_core:client:setVehicleCatalog', source, core.Shared.Vehicles)
end)
---@return table<string, Vehicle>
---@overload fun(key: string): Vehicle
local function GetVehiclesByName(key)
    local vehicles = core.Shared.Vehicles
    return vehicles[key] or vehicles
end

describeExport('GetVehiclesByName', GetVehiclesByName)

---@return table<number, Vehicle>
---@overload fun(key: number): Vehicle
local function GetVehiclesByHash(key)
    local vehicles = core.Shared.VehicleHashes
    return vehicles[key] or vehicles
end

describeExport('GetVehiclesByHash', GetVehiclesByHash)

---@return table<string, Vehicle[]>
local function GetVehiclesByCategory()
    return helpers.table.mapBySubfield(core.Shared.Vehicles, 'category')
end

describeExport('GetVehiclesByCategory', GetVehiclesByCategory)

---@return table<number, Weapon>
---@overload fun(key: number): Weapon
local function GetWeapons(key)
    local weapons = core.Shared.Weapons
    return weapons[key] or weapons
end

describeExport('GetWeapons', GetWeapons)

---@deprecated
---@return table<string, vector4>
local function GetLocations()
    return core.Shared.Locations
end

---@diagnostic disable-next-line: deprecated
describeExport('GetLocations', GetLocations)

    return api
end

