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
    local core = assert(ports.core, 'core state required')
    local emit = assert(ports.emit, 'local event port required')
-- Publish only the players/data that QBX has already loaded; no extra DB query.
local writer = assert(ports.writer, 'delivery writer required')
local Producer = {}
api.Producer = Producer
function Producer.player(player, reason, connected)
    if not player or player.Offline or type(player.PlayerData) ~= 'table' then return end
    local data = player.PlayerData
    local src = tonumber(data.source)
    if not src then return end
    writer.record('player:' .. src, data)
    writer.fields(('player:%s:'):format(src), data)
    writer.fields(('metadata:%s:'):format(src), data.metadata or {})
    writer.stage(('player:%s:connected'):format(src), connected ~= false)
    writer.record('resource:qbx_core:character:' .. data.citizenid, data)
    writer.flush(reason or 'playerData')
end
function Producer.session(src, data)
    if not src or type(data) ~= 'table' then return end
    writer.stage('resource:qbx_core:session:' .. src, data)
    writer.stage(('player:%s:loaded'):format(src), data.loaded == true)
    writer.flush('session')
end
function Producer.logout(src, reason)
    src = tonumber(src)
    local player = src and core.Players[src]
    if player then Producer.player(player, reason or 'logout', false) end
    Producer.session(src, { loaded = false, connected = false,
        character = player and player.PlayerData.citizenid })
end
listen('QBCore:Server:PlayerLoaded', function(_, player)
    Producer.player(player, 'login')
    emit('pr_bridge:server:OnPlayerLoaded', player.PlayerData.source)
end)
listen('QBCore:Server:OnPlayerUnload', function(_, src)
    Producer.logout(src, 'logout')
    emit('pr_bridge:server:OnPlayerUnloaded', src)
end)
listen('onResourceStart', function(_, resource)
    if resource ~= 'pr_bridge' then return end
    -- Re-deliver QBX's existing records once, not a recurring player scan.
    writer.flush('bridge-start', true)
end)
    return api
end
