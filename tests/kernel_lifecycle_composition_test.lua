local L = dofile('tests/kernel_lifecycle_harness.lua')
local H = L.H
local r = L.new(true)
local env, loaded = H.environment(), {}
local allowed = {['kernel.server.functions'] = true, ['kernel.server.queue'] = true,
    ['kernel.config.queue'] = true, ['kernel.server.events'] = true}
env.require = function(name)
    assert(allowed[name], 'No external/self-framework import: ' .. tostring(name))
    if not loaded[name] then loaded[name] = H.load(name:gsub('%.', '/') .. '.lua', env) end
    return loaded[name]
end
local compose = H.load('kernel/server/lifecycle_core.lua', env)
local core = {State = r.core, Lookup = r.lookup, Storage = r.storage, Players = r.players}
local base = {PlayerCore = core, Groups = r.groups, Membership = r.membership}
local ports = {}; for k, v in pairs(r.bindings) do ports[k] = v end
ports.config = {server = r.serverConfig, logging = r.logging}
ports.serverName, ports.queue = r.serverName, {enabled = true, maxPlayers = 2}
local playerTable, bucketTable, itemsTable = core.State.Players, core.State.Player_Buckets, core.State.UsableItems
local lifecycle = compose(base, core, ports)
assert(#r.trace == 0 and #r.events == 0 and #r.tasks == 0, 'No constructor effects, registrations, SQL, hardcap stop or queries')
assert(core.State.Players == playerTable and core.State.Player_Buckets == bucketTable and core.State.UsableItems == itemsTable)
assert(core.Lifecycle == lifecycle and type(lifecycle.QueueConfig.generateCard) == 'function')
assert(not pcall(compose, base, core, ports), 'Duplicate lifecycle must be refused')
assert(not pcall(env.require, 'pr_lib.framework'), 'No framework bridge loop')
assert(lifecycle.Functions.SetPlayerBucket(1, 4) and core.State.Player_Buckets[1] == 4)
local callback = function() return 'usable' end
lifecycle.Functions.CreateUseableItem('burger', callback)
assert(lifecycle.Functions.CanUseItem('burger') == callback and itemsTable.burger == callback)
assert(lifecycle.Functions.HasGroup(1, 'taxi') and core.Lookup.GetPlayer(1) == r.core.Players[1])
assert(lifecycle.Queue.Bootstrap() and not lifecycle.Queue.Bootstrap())
local stops = 0; for _, e in ipairs(r.trace) do if e.kind == 'stop-resource' then stops = stops + 1 end end
assert(stops == 1, 'Only explicit bootstrap may simulate hardcap stop')
r.install(lifecycle.Events)
r.dispatch('QBCore:ToggleDuty', 1)
assert(core.Lookup.GetPlayer(1).PlayerData.job.onduty)
local schemas = 0; for _, e in ipairs(r.trace) do if e.kind == 'schema-query' then schemas = schemas + 1 end end
assert(schemas == 0, 'Event installation must not execute schema descriptor')
for _, key in ipairs({'QBX', 'ForgeCore', 'GlobalState', 'MySQL', 'exports', 'RegisterNetEvent', 'AddEventHandler'}) do
    assert(rawget(env, key) == nil, 'Ambient runtime leaked: ' .. key)
end
print('PASS kernel lifecycle composition: same Players/storage/groups/items/buckets, no constructor effects, duplicate attachment refused, explicit bootstrap only')
