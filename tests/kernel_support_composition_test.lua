local S = dofile('tests/kernel_support_harness.lua')
local H, P = S.H, S.P
local env, loaded = H.environment(), {}
local modules = {['kernel.config.shared'] = 'kernel/config/shared.lua',
    ['kernel.config.server'] = 'kernel/config/server.lua', ['kernel.config.client'] = 'kernel/config/client.lua',
    ['kernel.modules.hooks'] = 'kernel/modules/hooks.lua', ['kernel.modules.logger'] = 'kernel/modules/logger.lua'}
env.require = function(name)
    local path = assert(modules[name], 'Only private support imports allowed: ' .. tostring(name))
    if not loaded[name] then loaded[name] = H.load(path, env) end
    return loaded[name]
end
local compose = H.load('kernel/support.lua', env)
local server, shared = S.config(true, 'server'), S.config(true, 'shared')
local hooks, logger = S.hooks(true), S.logger(true)
hooks.trace = {} -- discard only the explicit dependency probe in the fixture
local support = compose({side = 'server', shared = shared.ports, server = server.ports,
    hooks = hooks.ports, logger = logger.ports})
assert(#hooks.trace == 0 and #logger.trace == 0 and #logger.tasks == 0 and #server.trace == 0)
assert(support.Config.Server and support.Config.Shared and not support.Config.Client)
assert(not support.Players and not support.Storage and not support.State, 'Support must not create a second authority')
local client = S.config(true, 'client')
local clientSupport = compose({side = 'client', shared = shared.ports, client = client.ports})
assert(clientSupport.Config.Client and not clientSupport.Config.Server and not clientSupport.Hooks and not clientSupport.Logger)
assert(not pcall(compose, {side = 'wrong'}))
assert(not pcall(env.require, 'qbx_core.config.server'))

-- Bind the real local factories to the existing Player factory, not to PR framework.
local runtime = P.new(true)
local bindings = {}; for key, value in pairs(runtime.bindings) do bindings[key] = value end
bindings.config, bindings.defaultSpawn = support.Config.Server, support.Config.Shared.defaultSpawn
bindings.logger, bindings.triggerHook = support.Logger, support.Hooks.trigger
local api = H.load('kernel/server/player.lua', H.environment())(bindings)
local player = api.CheckPlayerData(1, {citizenid = 'A', license = 'license:test', userId = 101})
assert(runtime.lookup.GetPlayer(1) == player)
local called, veto = 0, true
local callback = setmetatable({}, {__call = function(_, payload)
    called = called + 1
    assert(payload.source == 1 and payload.moneyType == 'cash' and payload.amount == 25)
    return not veto
end})
local hookId = support.Hooks.registerHook('addMoney', callback)
assert(not api.AddMoney(1, 'cash', 25, 'test') and player.PlayerData.money.cash == 0)
assert(called == 1 and #logger.trace == 0)
veto = false
assert(api.AddMoney(1, 'cash', 25, 'test') and player.PlayerData.money.cash == 25 and called == 2)
assert(#logger.trace == 1 and logger.trace[1].kind == 'library', 'One local logger delivery, no HTTP by default')
support.Hooks.removeHooks(hookId)
assert(api.AddMoney(1, 'cash', 25, 'test') and player.PlayerData.money.cash == 50 and called == 2)
assert(#logger.trace == 2 and logger.requests == 0)
for _, key in ipairs({'exports', 'QBX', 'ForgeCore', 'MySQL', 'GlobalState', 'RegisterCommand'}) do
    assert(rawget(env, key) == nil, 'No ambient runtime leak ' .. key)
end
print('PASS kernel support composition: private config closures, client/server separation, no constructor effects or second authority; actual Player uses local hooks/logs')
