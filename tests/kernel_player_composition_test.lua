local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local r = P.new(true)
local env, loaded = H.environment(), {}
local modules = {['kernel.server.player_lookup'] = 'kernel/server/player_lookup.lua',
    ['kernel.server.storage'] = 'kernel/server/storage.lua', ['kernel.server.player'] = 'kernel/server/player.lua'}
env.require = function(name)
    local path = assert(modules[name], 'External import forbidden: ' .. tostring(name))
    if not loaded[name] then loaded[name] = H.load(path, env) end
    return loaded[name]
end
local compose = H.load('kernel/server/player_core.lua', env)
local groupsFactory = H.load('kernel/server/groups.lua', H.environment())
local groups = groupsFactory({jobs = r.groupData.jobs, gangs = r.groupData.gangs,
    emitServer = r.platform.emitServer, emitClient = r.platform.emitClient,
    saveGroups = function() error('No real group persistence in composition test') end,
    logError = function() error('Unexpected group error') end})
local base = {Shared = r.core.Shared, Groups = groups}
local bindings = {}; for key, value in pairs(r.bindings) do bindings[key] = value end
local statusState, cacheState, dbCalls = nil, nil, 0
bindings.statusFactory = function(state) statusState = state; return r.core.Status end
bindings.cacheFactory = function(state) cacheState = state; return r.core.BridgeCache end
bindings.warn = function() error('Unexpected bootstrap/warning') end
bindings.date = function() return '2026-10-18 12:00:00' end
bindings.json = {encode = function() return '<mock-json>' end, decode = function() error('Unexpected JSON pull') end}
bindings.db = {
    query = {await = function(sql)
        dbCalls = dbCalls + 1
        assert(sql:find('SELECT `group`, type, grade FROM player_groups', 1, true), 'Unexpected query')
        return {}
    end},
    single = {await = function() dbCalls = dbCalls + 1; return {count = 0} end},
    insert = setmetatable({await = function() dbCalls = dbCalls + 1; return 1 end},
        {__call = function() dbCalls = dbCalls + 1; return 1 end}),
}
local core = compose(base, bindings)
assert(dbCalls == 0 and #r.trace == 0, 'Composition must not run queries/events/bootstrap')
assert(statusState == core.State and cacheState == core.State, 'Status/cache factories must receive the authoritative state')
assert(core.Lookup.GetQBPlayers() == core.State.Players, 'Lookups and player service must share the table')
assert(core.Shared == base.Shared and core.Groups == base.Groups and base.PlayerCore == core)
assert(not pcall(compose, base, bindings), 'Never compose a second player authority for one base')
assert(dbCalls == 0 and #r.trace == 0, 'Duplicate composition must fail before effects')

local player = core.Players.CheckPlayerData(1, {citizenid = 'A', license = 'license:test', userId = 101})
assert(core.Lookup.GetPlayer(1) == player and core.Lookup.GetPlayer('1') == player)
assert(core.Lookup.GetPlayer('license:test') == player)
assert(core.Lookup.GetSource('license:test') == 1 and core.Lookup.GetSource('absent') == 0)
assert(core.Lookup.GetUserId('license:test') == 101 and core.Lookup.GetUserId('absent') == 0)
assert(core.Lookup.GetPlayerByCitizenId('A') == player and core.Lookup.GetPlayerByCitizenId('missing') == nil)
assert(core.Lookup.GetPlayerByUserId(101) == player)
assert(core.Lookup.GetPlayerByPhone(player.PlayerData.charinfo.phone) == player)
assert(core.Players.SetJob(1, 'taxi', 0))
core.Players.SetJobDuty(1, true)
local count, ids = core.Lookup.GetDutyCountJob('taxi'); assert(count == 1 and ids[1] == 1)
count, ids = core.Lookup.GetDutyCountType('civ'); assert(count == 1 and ids[1] == 1)
groups.UpsertJobGrade('taxi', 0, {name = 'Experienced Driver', payment = 75}, false)
assert(player.PlayerData.job.grade.name == 'Experienced Driver' and player.PlayerData.job.payment == 75,
    'Internal catalog update must reach player through the same local bus')
assert(core.Players.AddMoney(1, 'cash', 30) and core.Lookup.GetPlayer(1).PlayerData.money.cash == 30)
local inventorySets = 0; for _, event in ipairs(r.trace) do if event.kind == 'inventory-SetItem' then inventorySets = inventorySets + 1 end end
assert(inventorySets == 1, 'Money mutation must synchronize inventory once')
for _, key in ipairs({'exports', 'QBX', 'ForgeCore', 'MySQL', 'GlobalState', 'RegisterCommand'}) do
    assert(rawget(env, key) == nil, 'Private composition leaked global ' .. key)
end
assert(not pcall(env.require, 'pr_lib.framework'), 'Core must not resolve its own services through framework bridge')
print('PASS kernel player composition: one authority, shared lookup/group/player state, local updates, explicit storage/status/cache/inventory boundaries')
