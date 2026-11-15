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
    local emit = assert(ports.emit, 'local event port required')
    local emitClient = assert(ports.emitClient, 'client delivery port required')
    local awaitSnapshot = assert(ports.awaitSnapshot, 'client snapshot callback required')
    local getInvokingResource = assert(ports.getInvokingResource, 'caller port required')
    local wait = assert(ports.wait, 'scheduler port required')
    local save = assert(ports.save, 'internal save port required')
local config = assert(ports.config, 'status configuration required')

local STATUS_KEYS = {
    health = true,
    armor = true,
    hunger = true,
    thirst = true,
    stress = true,
    oxygen = true,
}

local statusCache = {}
local sessions, generation = {}, 0
local decayIntervalSeconds = math.max(60, math.floor((config.decayIntervalMinutes or 5) * 60))
local checkpointCycleMs = math.max(60000, math.floor((config.checkpointMinutes or 15) * 60000))

local function clamp(value)
    value = tonumber(value) or 0
    return math.max(0, math.min(100, value))
end

local function healthToPercent(value)
    value = tonumber(value) or 200
    return clamp(value - 100)
end

local function healthToNative(value)
    return math.floor(100 + clamp(value) + 0.5)
end

local function getPlayer(source)
    return core.Players[tonumber(source)]
end

local function ownsSession(source, session)
    local player = getPlayer(source)
    return session ~= nil and player == session.player and player.PlayerData == session.data
        and player.PlayerData.citizenid == session.character and statusCache[tonumber(source)] == session.status
end

local function updateMetadata(source, status)
    local player = getPlayer(source)
    if not player or not status then return end
    local metadata = player.PlayerData.metadata
    metadata.health = healthToNative(status.health)
    metadata.armor = status.armor
    metadata.hunger = status.hunger
    metadata.thirst = status.thirst
    metadata.stress = status.stress
    metadata.oxygen = status.oxygen
    if core.BridgeCache then core.BridgeCache.player(player, 'status-checkpoint') end
end

local function initialize(source, metadata)
    source = tonumber(source)
    if not source then return end
    local player = getPlayer(source)
    metadata = metadata or (player and player.PlayerData.metadata) or {}
    statusCache[source] = {
        health = healthToPercent(metadata.health),
        armor = clamp(metadata.armor or 0),
        hunger = clamp(metadata.hunger or 100),
        thirst = clamp(metadata.thirst or 100),
        stress = clamp(metadata.stress or 0),
        oxygen = clamp(metadata.oxygen or 100),
        revision = 0,
        savedRevision = 0,
    }
    generation = generation + 1
    sessions[source] = player and {player = player, data = player.PlayerData,
        character = player.PlayerData.citizenid, generation = generation, status = statusCache[source]} or nil
    updateMetadata(source, statusCache[source])
    return statusCache[source]
end

local function resolve(source)
    source = tonumber(source)
    if not source then return end
    if statusCache[source] and getPlayer(source) and not ownsSession(source, sessions[source]) then
        return initialize(source)
    end
    return statusCache[source] or initialize(source)
end

local function snapshot(source)
    local status = resolve(source)
    if not status then return end
    return {
        health = status.health,
        armor = status.armor,
        hunger = status.hunger,
        thirst = status.thirst,
        stress = status.stress,
        oxygen = status.oxygen,
        hungerRate = config.hungerRate or 0,
        thirstRate = config.thirstRate or 0,
        decayIntervalSeconds = decayIntervalSeconds,
        nextDecaySeconds = decayIntervalSeconds,
    }
end

-- Character-owned extension data is isolated from server-authoritative fields
-- (money, job, permissions, inventory). Bound depth/size and reject cycles,
-- functions, handles/userdata and non-finite numbers before JSON persistence.
local function copyCharacterState(input)
    local seen, budget, bytes = {}, 2048, 0
    local function copy(value, depth)
        budget = budget - 1
        if budget < 0 or depth > 8 then error('character_state_limit') end
        local kind = type(value)
        if kind == 'boolean' then return value end
        if kind == 'number' and value == value and math.abs(value) < math.huge then return value end
        if kind == 'string' then
            bytes = bytes + #value
            if #value > 4096 or bytes > 32768 then error('character_state_limit') end
            return value
        end
        if kind ~= 'table' or seen[value] or getmetatable(value) then error('invalid_character_state') end
        seen[value] = true
        local out = {}
        for k, v in pairs(value) do
            if type(k) ~= 'string' or #k > 64 then
                if type(k) ~= 'number' or k < 1 or k > 2048 or k % 1 ~= 0 then error('invalid_character_state_key') end
            end
            out[k] = copy(v, depth + 1)
        end
        seen[value] = nil
        return out
    end
    local ok, result = pcall(copy, input, 0)
    return ok and result or nil
end

local function acceptSnapshot(source, values)
    source = tonumber(source)
    if not source or type(values) ~= 'table' or not getPlayer(source) then return false end
    local status = resolve(source)
    local changed = false
    for key in pairs(STATUS_KEYS) do
        if values[key] ~= nil then
            local value = clamp(values[key])
            if status[key] ~= value then
                status[key] = value
                changed = true
            end
        end
    end
    if changed then status.revision = status.revision + 1 end
    if type(values.extensions) == 'table' and type(values.extensions.clientState) == 'table' then
        local clean = copyCharacterState(values.extensions.clientState)
        if clean then
            local metadata = getPlayer(source).PlayerData.metadata
            local merged = {}
            for k,v in pairs(type(metadata.clientState)=='table' and metadata.clientState or {}) do merged[k]=v end
            for namespace, data in pairs(clean) do
                if type(namespace) == 'string' and #namespace <= 64
                    and namespace:match('^[%w_%-]+$') and type(data) == 'table' then
                    merged[namespace] = data
                end
            end
            local bounded=copyCharacterState(merged)
            if bounded then metadata.clientState=bounded end
        end
    end
    updateMetadata(source, status)
    if type(values.extensions) == 'table' then
        emit('qbx_core:server:statusExtensions', source, values.extensions)
    end
    return true
end

-- Transport identity is transient; never add it to PlayerData/metadata or SQL.
local function protocolSnapshot(source)
    if not getPlayer(source) then return end
    local data = snapshot(source)
    local session = sessions[tonumber(source)]
    if not ownsSession(source, session) then return end
    data._session, data._character = session.generation, session.character
    return data
end

local function matchesProtocol(source, values, session)
    return type(values) == 'table' and ownsSession(source, session)
        and values._session == session.generation and values._character == session.character
end

local function sync(source)
    local data = protocolSnapshot(source)
    if data then emitClient('qbx_core:client:statusUpdated', source, data) end
    return data and snapshot(source) or nil
end

-- Compatibilidade: o servidor apenas autoriza a alteração; o cálculo ocorre no cliente.
local function set(source, key, value)
    source = tonumber(source)
    if not source or not STATUS_KEYS[key] or not getPlayer(source) then return false end
    emitClient('qbx_core:client:setStatus', source, key, clamp(value))
    return true
end

local function add(source, key, amount)
    source = tonumber(source)
    if not source or not STATUS_KEYS[key] or not getPlayer(source) then return false end
    emitClient('qbx_core:client:addStatus', source, key, tonumber(amount) or 0)
    return true
end

local function addMany(source, values)
    source = tonumber(source)
    if not source or type(values) ~= 'table' or not getPlayer(source) then return false end
    local sanitized = {}
    for key, value in pairs(values) do
        if STATUS_KEYS[key] then sanitized[key] = tonumber(value) or 0 end
    end
    emitClient('qbx_core:client:applyStatusEffects', source, sanitized)
    return true
end

local function get(source, key)
    local status = resolve(source)
    if not status then return end
    if key == nil then return snapshot(source) end
    return STATUS_KEYS[key] and status[key] or nil
end

local function prepareSave(source)
    local status = resolve(source)
    if not status then return end
    updateMetadata(source, status)
    return status.revision
end

local function markSaved(source, revision)
    local status = statusCache[tonumber(source)]
    local player = getPlayer(source)
    if player then emit('qbx_core:server:progressionCheckpoint', source, player.PlayerData.citizenid) end
    if not status or status.revision ~= revision then return false end
    status.savedRevision = revision
    return true
end

local function remove(source)
    statusCache[tonumber(source)] = nil
    sessions[tonumber(source)] = nil
end

local function requestClientSnapshot(source)
    if not getPlayer(source) then return false end
    resolve(source)
    local session = sessions[tonumber(source)]
    local ok, values = pcall(function()
        return awaitSnapshot('qbx_core:client:getStatusSnapshot', source)
    end)
    if not ok or not matchesProtocol(source, values, session) then return false end
    return acceptSnapshot(source, values)
end

api.Status = {
    IsStatusKey = function(key) return STATUS_KEYS[key] == true end,
    Initialize = initialize,
    Resolve = resolve,
    Snapshot = snapshot,
    ProtocolSnapshot = protocolSnapshot,
    Sync = sync,
    Set = set,
    Add = add,
    AddMany = addMany,
    Get = get,
    AcceptSnapshot = acceptSnapshot,
    RequestClientSnapshot = requestClientSnapshot,
    PrepareSave = prepareSave,
    MarkSaved = markSaved,
    Remove = remove,
}

describeExport('GetStatus', get)
describeExport('GetStatusSnapshot', snapshot)
describeExport('SetStatus', set)
describeExport('AddStatus', add)
describeExport('AddStatuses', addMany)

network('qbx_core:server:requestStatus', function(eventSource)
    if getInvokingResource() then return end
    sync(eventSource)
end)

network('qbx_core:server:receiveStatusSnapshot', function(eventSource, values, reason)
    if getInvokingResource() then return end
    local src = eventSource
    local session = sessions[tonumber(src)]
    if not matchesProtocol(src, values, session) then return end
    if not acceptSnapshot(src, values) then return end
    if (reason == 'death' or reason == 'logout') and save and ownsSession(src, session) then
        save(src)
    end
end)

thread(function()
    while true do
        local sources = {}
        for source in pairs(core.Players) do sources[#sources + 1] = source end
        if #sources == 0 then
            wait(5000)
        else
            local waitBetweenSaves = math.max(250, math.floor(checkpointCycleMs / #sources))
            for i = 1, #sources do
                local source = sources[i]
                if core.Players[source] and save then
                    resolve(source)
                    local session = sessions[tonumber(source)]
                    requestClientSnapshot(source)
                    if ownsSession(source, session) then save(source) end
                end
                wait(waitBetweenSaves)
            end
        end
    end
end)
    return api
end
