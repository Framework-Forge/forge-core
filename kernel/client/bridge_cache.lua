-- Inactive port of installed QBX source; see NOTICE-03.md and LICENSE-QBX.
-- Event descriptors are not runtime registrations. Server handlers take eventSource first.
return function(ports)
    assert(type(ports) == 'table', 'explicit producer ports required')
    local api = {Events = {}, Threads = {}, Exports = {}, Callbacks = {}}
    local function listen(name, handler, network)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = network == true}
    end
    local function describeExport(name, handler) api.Exports[name] = handler end
    local function thread(handler) api.Threads[#api.Threads + 1] = handler end
    local function callback(name, handler) api.Callbacks[name] = handler end
    local function network(name, handler) listen(name, handler, true) end
    local core = assert(ports.core, 'core state required')
    local native = assert(ports.native, 'native platform ports required')
    local PlayerId = assert(native.PlayerId, 'PlayerId port required')
    local PlayerPedId = assert(native.PlayerPedId, 'PlayerPedId port required')
    local GetVehiclePedIsIn = assert(native.GetVehiclePedIsIn, 'GetVehiclePedIsIn port required')
    local GetVehicleMaxNumberOfPassengers = assert(native.GetVehicleMaxNumberOfPassengers, 'GetVehicleMaxNumberOfPassengers port required')
    local GetPedInVehicleSeat = assert(native.GetPedInVehicleSeat, 'GetPedInVehicleSeat port required')
    local GetPlayerServerId = assert(native.GetPlayerServerId, 'GetPlayerServerId port required')
    local GetSelectedPedWeapon = assert(native.GetSelectedPedWeapon, 'GetSelectedPedWeapon port required')
    local GetEntityCoords = assert(native.GetEntityCoords, 'GetEntityCoords port required')
    local GetInteriorFromEntity = assert(native.GetInteriorFromEntity, 'GetInteriorFromEntity port required')
    local TriggerEvent = assert(native.TriggerEvent, 'TriggerEvent port required')

-- The framework is the producer. PR Bridge only receives these explicit writes.
local writer = assert(ports.writer, 'delivery writer required')
local Producer = {}
api.Producer = Producer
local loaded = false
local authenticated = false

function Producer.context(values, reason)
    for _, key in ipairs({ 'game', 'playerId', 'serverId', 'ped', 'vehicle', 'seat', 'weapon', 'coords', 'interior' }) do
        if values[key] ~= nil then writer.stage(key, values[key]) end
    end
    return writer.flush(reason or 'context')
end
function Producer.refreshContext(reason)
    local id, ped = PlayerId(), PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local seat = false
    if vehicle ~= 0 then
        for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
            if GetPedInVehicleSeat(vehicle, i) == ped then seat = i; break end
        end
    end
    return Producer.context({ game = 'gta5', playerId = id, serverId = GetPlayerServerId(id), ped = ped,
        vehicle = vehicle ~= 0 and vehicle or false, seat = seat,
        weapon = GetSelectedPedWeapon(ped), coords = GetEntityCoords(ped), interior = GetInteriorFromEntity(ped) }, reason)
end
function Producer.player(data, reason)
    data = type(data) == 'table' and data or {}
    authenticated = data.citizenid ~= nil
    writer.record('playerData', data)
    writer.record('player:self', data)
    local id = GetPlayerServerId(PlayerId())
    writer.stage('serverId', id)
    writer.record('player:' .. id, data)
    writer.fields(('player:%s:'):format(id), data)
    local metadata = data.metadata or {}
    writer.fields('metadata:self:', metadata)
    local money = data.money or {}
    writer.stage('cash', money.cash or 0); writer.stage('bank', money.bank or 0)
    writer.stage('job', data.job or false); writer.stage('gang', data.gang or false)
    local groups = {}
    for name, grade in pairs(data.jobs or {}) do groups[name] = grade end
    for name, grade in pairs(data.gangs or {}) do groups[name] = grade end
    writer.stage('groups', groups)
    local dead = metadata.isdead == true or metadata.inlaststand == true
    writer.stage('isDead', dead); writer.stage('dead', dead)
    writer.stage('resource:qbx_core:session', { loaded = loaded, authenticated = authenticated,
        character = data.citizenid, dead = dead, cuffed = metadata.ishandcuffed == true })
    if not loaded then
        for _, key in ipairs({ 'armor', 'hunger', 'thirst', 'stress', 'oxygen' }) do
            if metadata[key] ~= nil then writer.stage(key, metadata[key]) end
        end
        writer.stage('health', math.max(0, math.min(100, (tonumber(metadata.health) or 200) - 100)))
    end
    writer.flush(reason or 'playerData')
end
function Producer.status(status, changes)
    local id = GetPlayerServerId(PlayerId())
    for key, value in pairs(changes or status) do
        if status[key] ~= nil then
            writer.stage(key, status[key])
            local meta = core.PlayerData.metadata or {}
            writer.stage('metadata:self:' .. key, meta[key] ~= nil and meta[key] or value)
        end
    end
    writer.stage('playerStatus', status)
    local metadata = core.PlayerData.metadata or {}
    writer.stage(('player:%s:metadata'):format(id), metadata)
    for _, key in ipairs({ 'playerData', 'player:self', 'player:' .. id }) do writer.patch(key, { metadata = metadata }) end
    writer.flush('status')
end
function Producer.session(isLoaded, ending)
    local previous = loaded
    loaded = isLoaded == true
    if ending then authenticated = false end
    writer.stage('playerLoaded', loaded)
    writer.stage('resource:qbx_core:session', { loaded = loaded, authenticated = authenticated, character = core.PlayerData.citizenid,
        dead = (core.PlayerData.metadata or {}).isdead == true or (core.PlayerData.metadata or {}).inlaststand == true,
        cuffed = (core.PlayerData.metadata or {}).ishandcuffed == true })
    writer.flush('session')
    if previous ~= loaded then
        -- Deprecated names are emitted by QBX, never by the passive library.
        TriggerEvent(loaded and 'pr_bridge:client:OnPlayerLoaded' or 'pr_bridge:client:OnPlayerUnloaded')
    end
end
describeExport('PublishClientContext', function(values)
    if type(values) ~= 'table' then return false end
    Producer.context(values, 'context'); return true
end)
describeExport('RefreshClientContext', Producer.refreshContext)
listen('qbx_core:client:statusChanged', Producer.status)
listen('onClientResourceStart', function(resource)
    if resource == 'pr_bridge' then writer.flush('bridge-start', true) end
end)
local initialized = false
function api.Initialize()
    if initialized then return false end
    initialized = true
    Producer.refreshContext('initialize')
    Producer.player(core.PlayerData, 'initialize')
    writer.stage('playerLoaded', false); writer.flush('initialize')
    return true
end
    return api
end
