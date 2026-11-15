local H = dofile('tests/kernel_harness.lua')
local env = H.environment()
local allowed = {['kernel.shared.main'] = 'kernel/shared/main.lua',
    ['kernel.shared.functions'] = 'kernel/shared/functions.lua',
    ['kernel.server.groups'] = 'kernel/server/groups.lua'}
local loaded = {}
env.require = function(name)
    local file = assert(allowed[name], 'Non-private import: ' .. tostring(name))
    if not loaded[name] then loaded[name] = H.load(file, env) end
    return loaded[name]
end
local create = H.load('kernel/init.lua', env)
local effects = 0
local function forbidden() effects = effects + 1; error('Unexpected side effect') end
local function bindings()
    local fixture = H.groupsFixture()
    return {shared = {locations = {}, weapons = {}},
        membership = {tableType = H.tableType, warn = forbidden},
        groups = {jobs = fixture.jobs, gangs = fixture.gangs,
            emitServer = forbidden, emitClient = forbidden,
            saveGroups = forbidden, logError = forbidden}}
end
local one, two = create(bindings()), create(bindings())
assert(effects == 0, 'Construction must not emit/register/write anything')
assert(one.Groups.GetJob('unemployed').label == 'Civilian')
one.Groups.GetJob('unemployed').label = 'Changed locally'
assert(two.Groups.GetJob('unemployed').label == 'Civilian', 'Cross-instance state leak')
one.Shared.SetVehicles({test = {hash = 1}})
assert(two.Shared.VehicleHashes[1] == nil)
local before = bindings()
before.groups.emitClient = nil
assert(not pcall(create, before), 'Incomplete bindings must fail at construction')
assert(effects == 0, 'Incomplete bindings must fail before effects')
for _, key in ipairs({'ForgeCore', 'QBX', 'GroupType', 'GetJob', 'HasPlayerGotGroup', 'exports'}) do
    assert(rawget(env, key) == nil, 'Namespace leak: ' .. key)
end
for _, boundary in ipairs({'MySQL', 'io', 'os', 'package', 'debug', 'ExecuteCommand',
    'SaveResourceFile', 'PerformHttpRequest', 'CreateThread', 'RegisterNetEvent', 'DropPlayer'}) do
    assert(not pcall(function() return env[boundary] end), 'Forbidden boundary exposed: ' .. boundary)
end
assert(not pcall(env.require, 'shared.main'), 'Legacy global module import must not resolve')
assert(not pcall(env.require, '@qbx_core/modules/lib'), 'External QBX import must not resolve')
print('PASS kernel isolation: private imports/state, no globals/runtime registrations, explicit binding guards')
