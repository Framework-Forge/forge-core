-- Inactive installed-QBX port; see NOTICE-09.md and LICENSE-QBX.
return function(ports)
    assert(type(ports) == 'table', 'explicit runtime ports required')
    local core = assert(ports.core, 'canonical client state required')
    local native = assert(ports.native, 'platform ports required')
    local cache = assert(ports.cache, 'cache port required')
    local config = assert(ports.config, 'local client configuration required')
    local api = {Events = {}, Callbacks = {}, Threads = {}, Exports = {}, StateBags = {}, EntityStateHandlers = {}}
    local function listen(name, handler, network)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = network == true}
    end
    local function network(name, handler) listen(name, handler, true) end
    local function callback(name, handler) api.Callbacks[name] = handler end
    local function thread(handler) api.Threads[#api.Threads + 1] = handler end
    local function describeExport(name, handler) api.Exports[name] = handler end
    local helpers = assert(ports.helpers, 'local Lib required')
    assert(type(core.PlayerData) == 'table' and type(core.Shared) == 'table', 'existing canonical state/shared required')

local function registerVehicleLabels()
    for _, vehicle in pairs(core.Shared.Vehicles) do
        if vehicle.model and vehicle.name then
            local modelHash = type(vehicle.model) == 'number' and vehicle.model or native.joaat(vehicle.model)
            local gameName = native.GetDisplayNameFromVehicleModel(modelHash)
            if gameName and gameName ~= 'CARNOTFOUND' then
                native.AddTextEntryByHash(native.joaat(gameName), vehicle.name)
            end
        end
    end
end

local function setVehicleCatalog(vehicles)
    local count = core.Shared.SetVehicles(vehicles)
    registerVehicleLabels()
    return count
end

network('qbx_core:client:setVehicleCatalog', setVehicleCatalog)

local function requestVehicleCatalog()
    native.TriggerServerEvent('qbx_core:server:requestVehicleCatalog')
end

thread(function()
    native.Wait(0)
    requestVehicleCatalog()
end)

listen('QBCore:Client:OnPlayerLoaded', requestVehicleCatalog)

---@return table<string, Vehicle>
---@overload fun(key: string): Vehicle
local function GetVehiclesByName(key)
    local vehicles = core.Shared.Vehicles
    return vehicles[key] or vehicles
end

api.GetVehiclesByName = GetVehiclesByName
describeExport('GetVehiclesByName', GetVehiclesByName)

---@return table<number, Vehicle>
---@overload fun(key: number): Vehicle
local function GetVehiclesByHash(key)
    local vehicles = core.Shared.VehicleHashes
    return vehicles[key] or vehicles
end

api.GetVehiclesByHash = GetVehiclesByHash
describeExport('GetVehiclesByHash', GetVehiclesByHash)

---@return table<string, Vehicle[]>
local function GetVehiclesByCategory()
    return helpers.table.mapBySubfield(core.Shared.Vehicles, 'category')
end

api.GetVehiclesByCategory = GetVehiclesByCategory
describeExport('GetVehiclesByCategory', GetVehiclesByCategory)

---@return table<number, Weapon>
---@overload fun(key: number): Weapon
local function GetWeapons(key)
    local weapons = core.Shared.Weapons
    return weapons[key] or weapons
end

api.GetWeapons = GetWeapons
describeExport('GetWeapons', GetWeapons)

---@deprecated
---@return table<string, vector4>
local function GetLocations()
    return core.Shared.Locations
end

---@diagnostic disable-next-line: deprecated
api.GetLocations = GetLocations
describeExport('GetLocations', GetLocations)

callback('qbx_core:client:setHealth', function(health)
    core.BridgeCache.refreshContext('health')
    native.SetEntityHealth(cache.ped, health)
end)

local mapText = config.pauseMapText
if mapText == '' or type(mapText) ~= 'string' then mapText = 'FiveM' end
local initialized = false
function api.Initialize()
    if initialized then return false end
    native.AddTextEntry('FE_THDR_GTAO', mapText)
    initialized = true
    return true
end

thread(function()
    registerVehicleLabels()
end)

callback('qbx_core:client:getVehicleClasses', function()
    local models = native.GetAllVehicleModels()
    local classes = {}
    for i = 1, #models do
        local model = models[i]
        local class = native.GetVehicleClassFromName(model)
        classes[native.joaat(model)] = class
    end
    return classes
end)

    return api
end

