local T = dofile('tests/kernel_helpers_harness.lua')
local H, P = T.H, T.P
local L = dofile('tests/kernel_lifecycle_harness.lua')
local runtime = L.new(true); runtime.loadFunctions()
local nativeFixture = T.new(true, 'server')
local env, loaded = T.env(), {}
local paths = {['kernel.modules.lib'] = 'kernel/modules/lib.lua', ['kernel.shared.locale'] = 'kernel/shared/locale.lua',
    ['kernel.server.vehicle_persistence_compat'] = 'kernel/server/vehicle_persistence_compat.lua',
    ['kernel.modules.playerdata'] = 'kernel/modules/playerdata.lua'}
env.require = function(name)
    local file = assert(paths[name], 'External import forbidden: ' .. tostring(name))
    if not loaded[name] then loaded[name] = H.load(file, env) end
    return loaded[name]
end
local compose = H.load('kernel/helpers.lua', env)
local shared = H.load('kernel/shared/main.lua', H.environment())({weapons = {}, locations = {}, vehicles = {}})
assert(shared.SetVehicles({car = {model = 'car', hash = nativeFixture.native.joaat('car'), type = 'automobile'}}) == 1)
local bindings = {}; for key, value in pairs(nativeFixture.ports) do bindings[key] = value end
bindings.shared, bindings.functions = shared, runtime.functions
local beforeTrace = #runtime.trace
local helpers = compose(bindings)
assert(#runtime.trace == beforeTrace and #nativeFixture.trace == 0 and next(nativeFixture.callbacks) == nil)
assert(helpers.Lib and helpers.Locale and helpers.Persistence)
assert(not helpers.Players and not helpers.Storage and not helpers.State, 'No second authority')
local netId, vehicle = helpers.Lib.spawnVehicle({model = 'car', spawnSource = 10, bucket = 7})
assert(netId == 1101 and vehicle == 101)
assert(runtime.core.Entity_Buckets[101] == 7,
    'Spawn must use the existing internal bucket authority')
local persistCount = 0
for _, call in ipairs(nativeFixture.trace) do
    if call.kind == 'state' and call.args[2] == 'persisted' then
        assert(call.args[3] == true and call.args[4] == true); persistCount = persistCount + 1
    end
    assert(call.kind ~= 'catalog' and call.kind ~= 'bucket' and call.kind ~= 'persistence', 'No stub/external core forwarder used')
end
assert(persistCount == 1, 'One actual private persistence call')

local playerRuntime = P.new(true)
local playerBindings = {}; for key, value in pairs(playerRuntime.bindings) do playerBindings[key] = value end
playerBindings.utils = helpers.Lib
local players = H.load('kernel/server/player.lua', H.environment())(playerBindings)
local player = players.CheckPlayerData(1, {citizenid = 'A', license = 'license:test', userId = 101})
assert(playerRuntime.lookup.GetPlayer(1) == player)
assert(players.AddMoney(1, 'cash', 12.6) and player.PlayerData.money.cash == 13, 'Player must use the local full helper implementation')
assert(helpers.CreatePlayerDataView() == nil, 'No imported client view on server')

local clientFixture = T.new(true, 'client')
local client = compose(clientFixture.ports)
assert(not client.Persistence and client.Lib and client.Locale)
local canonical = {PlayerData = {citizenid = 'A'}}
local pulls = 0
local view = client.CreatePlayerDataView(function() pulls = pulls + 1; return canonical.PlayerData end)
assert(pulls == 0); assert(view.Initialize() and pulls == 1)
assert(view.View.PlayerData == canonical.PlayerData)
view.Events[2].handler({citizenid = 'B'})
assert(canonical.PlayerData.citizenid == 'A' and view.View.PlayerData.citizenid == 'B', 'Legacy view must never become a core write endpoint')
view.Events[1].handler(); assert(canonical.PlayerData.citizenid == 'A')
assert(not pcall(env.require, 'qbx_core.modules.lib'))
for _, name in ipairs({'QBX','qbx','Locale','exports','MySQL','RegisterNetEvent','AddEventHandler'}) do
    assert(rawget(env, name) == nil, 'No ambient runtime/global ' .. name)
end
print('PASS kernel helper composition: actual internal Shared/catalog/bucket/persistence and Player helpers; legacy view cannot overwrite canonical PlayerData; no automatic registration or second authority')
