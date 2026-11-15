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
    local getPlayer = assert(ports.getPlayer, 'internal player lookup required')
    local getBucket = assert(ports.getBucket, 'routing bucket port required')
    local emit = assert(ports.emit, 'local event port required')
-- Lightweight QBX-owned records. Metadata/bucket remain authoritative; no
-- polling, broadcasts or PRBridge dependency during framework startup.
local Session = {}
local records, readyPlayers = {}, {}
local revision = 0
local function copy(record)
    if not record then return nil end
    local data = {}; for key, value in pairs(record.data) do data[key] = value end
    return {revision=record.revision,data=data}
end
local function refresh(src, publish)
    src = tonumber(src)
    if not src then return nil end
    local player = getPlayer(src)
    local data = player and player.PlayerData
    if not data or not data.citizenid then records[src], readyPlayers[src] = nil, nil; return nil end
    local metadata = data.metadata or {}
    local state = {
        character = data.citizenid,
        loaded = Session.canSavePosition(src, player),
        dead = metadata.isdead == true or metadata.inlaststand == true,
        cuffed = metadata.ishandcuffed == true,
        instance = getBucket(src),
    }
    local previous, changed = records[src], false
    for key, value in pairs(state) do
        if not previous or previous.data[key] ~= value then changed = true end
    end
    if changed then
        revision = revision + 1
        records[src] = {revision=revision,data=state}
        if core.BridgeCache then core.BridgeCache.session(src, state) end
        if publish then emit('pr_bridge:resourceState:changed', 'qbx_core', 'session:' .. src, copy(records[src])) end
    end
    return records[src]
end
function Session.snapshot(src) return copy(refresh(src, false)) end
-- Use the exact Player object for persistence, including the final save on drop.
function Session.canSavePosition(src, player)
    local ready = readyPlayers[src]
    return ready ~= nil and ready.player == player and ready.character == player.PlayerData.citizenid
end
function Session.isLoaded(src)
    local record = refresh(src, false)
    return record ~= nil and record.data.loaded == true
end
function Session.setLoaded(src, loaded)
    src = tonumber(src)
    local player = src and getPlayer(src)
    if not player or not player.PlayerData.citizenid then return false end
    readyPlayers[src] = loaded == true and {player = player, character = player.PlayerData.citizenid} or nil
    refresh(src, true)
    return true
end
function Session.clear(src)
    src = tonumber(src)
    if not src then return end
    local exists = records[src] or readyPlayers[src]
    records[src], readyPlayers[src] = nil, nil
    if exists then emit('pr_bridge:resourceState:changed', 'qbx_core', 'session:' .. src, nil) end
end
api.Session = Session
listen('QBCore:Server:PlayerLoaded', function(_, player)
    if player and player.PlayerData then Session.setLoaded(player.PlayerData.source, false) end
end)
network('QBCore:Server:OnPlayerLoaded', function(eventSource) Session.setLoaded(eventSource, true) end)
listen('QBCore:Server:OnPlayerUnload', function(_, src) Session.setLoaded(src, false) end)
listen('qbx_core:server:playerLoggedOut', function(_, src) Session.clear(src) end)
listen('qbx_core:server:onSetMetaData', function(eventSource, key, oldValue, newValue, src)
    if key == 'isdead' or key == 'inlaststand' or key == 'ishandcuffed' then refresh(src, true) end
end)
listen('qbx_core:server:bucketChanged', function(_, src) refresh(src, true) end)
describeExport('IsPlayerLoaded', Session.isLoaded)
describeExport('GetCachedState', function(domain)
    local src = type(domain) == 'string' and domain:match('^session:(%d+)$')
    return src and Session.snapshot(src) or nil
end)
    return api
end
