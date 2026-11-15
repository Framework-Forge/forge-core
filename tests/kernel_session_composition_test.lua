local P = dofile('tests/kernel_player_harness.lua')
local T = dofile('tests/kernel_session_harness.lua')
local H = P.H
local function moduleEnvironment()
    local env, loaded = H.environment(), {}
    local allowed = {['kernel.server.player_core'] = true, ['kernel.server.player_lookup'] = true,
        ['kernel.server.storage'] = true, ['kernel.server.player'] = true,
        ['kernel.shared.bridge_cache'] = true, ['kernel.server.bridge_cache'] = true,
        ['kernel.server.status'] = true, ['kernel.server.session'] = true,
        ['kernel.client.bridge_cache'] = true, ['kernel.client.status'] = true, ['kernel.client.session'] = true}
    env.require = function(name)
        assert(allowed[name], 'External import forbidden: ' .. tostring(name))
        if not loaded[name] then loaded[name] = H.load(name:gsub('%.', '/') .. '.lua', env) end
        return loaded[name]
    end
    return env
end
local r = P.new(true)
local groups = H.load('kernel/server/groups.lua', H.environment())({jobs = r.groupData.jobs, gangs = r.groupData.gangs,
    emitServer = r.platform.emitServer, emitClient = r.platform.emitClient,
    saveGroups = function() error('Persistence not expected') end, logError = function() error('Unexpected group error') end})
local bindings = {}; for k, v in pairs(r.bindings) do bindings[k] = v end
local dbCalls = 0
bindings.warn = function() error('Unexpected warning') end
bindings.date = function() return '2026-10-18 12:00:00' end
bindings.json = {encode = function() return '<mock-json>' end, decode = function() error('No data pull expected') end}
bindings.db = {query = {await = function() dbCalls = dbCalls + 1; return {} end},
    single = {await = function() dbCalls = dbCalls + 1; return {count = 0} end},
    insert = setmetatable({await = function() dbCalls = dbCalls + 1; return 1 end},
        {__call = function() dbCalls = dbCalls + 1; return 1 end})}
local deliveryCount = 0
local ports = {player = bindings, getBucket = function() return 42 end,
    delivery = {getResourceState = function() return 'stopped' end,
        writeCache = function() deliveryCount = deliveryCount + 1 end, emit = r.platform.emitServer},
    status = {config = {checkpointMinutes = 1}, awaitSnapshot = function() return {hunger = 45} end}}
local compose = H.load('kernel/server/session_core.lua', moduleEnvironment())
local base = {Shared = r.core.Shared, Groups = groups}
local core = compose(base, ports)
assert(dbCalls == 0 and #r.trace == 0 and deliveryCount == 0, 'Construction must not install, publish or query')
assert(core.State.BridgeCache == core.Producers.Cache.Producer and core.State.Status == core.Producers.Status.Status)
assert(core.State.Session == core.Producers.Session.Session and core.Lookup.GetQBPlayers() == core.State.Players)
assert(not pcall(compose, base, ports), 'A second authoritative core must be refused')
for _, module in pairs(core.Producers) do
    for _, e in ipairs(module.Events) do r.platform.on(e.name, function(...) return e.handler(0, ...) end) end
end
local player = core.Players.CheckPlayerData(1, {citizenid = 'A', license = 'license:test', userId = 101})
assert(core.Lookup.GetPlayer(1) == player)
assert(core.State.Session.snapshot(1).data.instance == 42)
assert(core.State.Session.setLoaded(1, true) and core.State.Session.isLoaded(1))
assert(core.State.Status.AcceptSnapshot(1, {hunger = 25}))
assert(core.Lookup.GetPlayer(1).PlayerData.metadata.hunger == 25)
assert(core.State.Status.Get(1, 'hunger') == 25 and deliveryCount == 0)
local clientRuntime = T.new(true, 'client')
local clientCompose = H.load('kernel/client/session_core.lua', moduleEnvironment())
local state = clientRuntime.core
local clientPorts = {native = clientRuntime.native, delivery = clientRuntime.delivery, statusConfig = clientRuntime.clientConfig}
local client = clientCompose(state, clientPorts)
assert(#clientRuntime.trace == 0 and #clientRuntime.events == 0 and #clientRuntime.threads == 0)
assert(state.BridgeCache == client.Cache.Producer and state.Session == client.Session.Session)
assert(not pcall(clientCompose, state, clientPorts), 'Refuse duplicate client composition')
assert(client.Initialize() and not client.Initialize(), 'Explicit initialization must happen once')
for _, module in ipairs({client.Cache, client.Session, client.Status}) do clientRuntime.install(module) end
assert(#clientRuntime.threads == 4)
clientRuntime.dispatch('QBCore:Client:OnPlayerLoaded', 0)
assert(state.Session.isLoaded())
assert(client.Status.Exports.SetStatus('hunger', 38))
assert(state.Status.hunger == 38 and state.PlayerData.metadata.hunger == 38)
clientRuntime.dispatch('QBCore:Client:OnPlayerUnload', 0)
assert(not state.Session.isLoaded() and state.Status.hunger == 100)
assert(not pcall(clientCompose, {PlayerData = {}}, {}), 'Missing boundaries must fail closed')
print('PASS kernel producer composition: one state, internal lookup/status/session, no ambient QBX/PR framework, no automatic events/threads/SQL')
