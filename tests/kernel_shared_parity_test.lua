local H = dofile('tests/kernel_harness.lua')
local originLogs, portLogs = {}, {}
local original = H.environment({lib = {print = {warn = function(message) originLogs[#originLogs + 1] = message end}}})
H.load(H.qbx .. 'shared/functions.lua', original)
local factory = H.load('kernel/shared/functions.lua', H.environment())
local port = factory({tableType = H.tableType, warn = function(message) portLogs[#portLogs + 1] = message end})
local cases = 0
local player = {
    citizenid = 'TEST001', job = {name = 'taxi', grade = {level = 1}},
    gang = {name = 'ballas', grade = {level = 2}},
    jobs = {taxi = 1, mechanic = 0, duplicate = 0}, gangs = {ballas = 2, duplicate = 3},
}
for _, filter in ipairs({false, 'taxi', 'ballas', 'mechanic', 'missing', 'TEST001',
    {'missing', 'mechanic'}, {'TEST001'}, {taxi = 1}, {taxi = 2}, {ballas = 2},
    {ballas = 3}, {mechanic = 0}, {duplicate = 0}, {TEST001 = 100}, {}, 42,
    {[1] = 'taxi', mechanic = 0}}) do
    for _, primary in ipairs({false, true}) do
        H.same(table.pack(port.HasPlayerGotGroup(filter, H.copy(player), primary)),
            table.pack(original.HasPlayerGotGroup(filter, H.copy(player), primary)), 'group filter')
        H.same(portLogs, originLogs, 'warnings')
        cases = cases + 1
    end
end
H.same(port.GetPlayerGroups(H.copy(player)), original.GetPlayerGroups(H.copy(player)), 'merged groups')
H.same(portLogs, originLogs, 'duplicate warning')
assert(port.GetPlayerGroups(H.copy(player)).duplicate == 0, 'Job grade zero must win over duplicate gang')
assert(not pcall(factory, {warn = function() end}), 'Missing table classifier must fail explicitly')
assert(rawget(_G, 'HasPlayerGotGroup') == nil, 'Port must not create globals')

local function seed()
    return {locations = {test = {1, 2, 3, 4}}, weapons = {[123] = {name = 'TEST_WEAPON'}}}
end
local nativeSeed, portSeed = seed(), seed()
local env = H.environment({require = function(name)
    if name == 'shared.locations' then return nativeSeed.locations end
    if name == 'shared.weapons' then return nativeSeed.weapons end
    error('Unbound shared import: ' .. tostring(name))
end})
local nativeShared = H.load(H.qbx .. 'shared/main.lua', env)
local sharedFactory = H.load('kernel/shared/main.lua', H.environment())
local shared = sharedFactory(portSeed)
assert(shared.Weapons == portSeed.weapons and shared.Locations == portSeed.locations, 'Seed references must be preserved')
local vehiclesRef, hashesRef = shared.Vehicles, shared.VehicleHashes
local function catalog(value)
    H.same(table.pack(shared.SetVehicles(H.copy(value))), table.pack(nativeShared.SetVehicles(H.copy(value))), 'catalog count')
    H.same(shared.Vehicles, nativeShared.Vehicles, 'vehicle names')
    H.same(shared.VehicleHashes, nativeShared.VehicleHashes, 'vehicle hashes')
    assert(shared.Vehicles == vehiclesRef and shared.VehicleHashes == hashesRef, 'Indexes must not be replaced')
    cases = cases + 1
end
catalog({taxi = {hash = 123, name = 'Taxi'}, bike = {hash = 456}, bad = {hash = '123'},
    [1] = {hash = 789}, invalid = false})
assert(shared.Vehicles.taxi == shared.VehicleHashes[123], 'Both indexes refer to the same entry')
catalog({bus = {hash = 987}}); catalog(false); catalog(nil)
assert(shared.ForceJobDefaultDutyAtLogin == nativeShared.ForceJobDefaultDutyAtLogin)
assert(not pcall(sharedFactory, {weapons = {}}), 'Missing explicit seed must not load another resource')
print('PASS kernel shared: ' .. cases .. ' differential filters/catalog cases, warning/grade semantics, stable indexes')
