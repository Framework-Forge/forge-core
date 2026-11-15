-- Strict simulated producer boundaries; no DB, network or real Cfx scheduler.
local H = dofile('tests/kernel_harness.lua')
local T = {H = H}
function T.new(ported, side)
    local r = {ported = ported, side = side, modules = {}, events = {}, threads = {}, callbacks = {}, exported = {},
        trace = {}, cache = {}, bridge = 'stopped', source = 1, bucket = 0, now = 0, health = 200, armor = 0,
        ped = 10, vehicle = 0, dead = false, injured = false, water = false, stamina = 65, underwater = 8,
        weapon = 0, shooting = false, vehicleClass = 0, speed = 40, invoking = nil}
    r.core = {Players = {}, PlayerData = {citizenid = 'A', metadata = {}, job = {name = 'taxi'}}, IsLoggedIn = false}
    r.core.Players[1] = {PlayerData = {source = 1, citizenid = 'A', metadata = {health = 170, hunger = 80}}}
    r.config = {decayIntervalMinutes = 2, checkpointMinutes = 1, hungerRate = 3, thirstRate = 4}
    r.clientConfig = {snapshotDebounceMs = 500, stress = {disablePoliceStress = true, chance = 1,
        minimumSpeedBuckled = 100, minimumSpeedUnbuckled = 50, vehicleClasses = {[0] = true}}}
    function r.record(kind, ...) r.trace[#r.trace + 1] = {kind = kind, args = H.copy(table.pack(...))} end
    function r.write(mode, key, value)
        r.record('cache', mode, key, value)
        if mode == 'patch' then
            assert(type(r.cache[key]) == 'table', 'patch without delivered record')
            for k, v in pairs(value) do r.cache[key][k] = H.copy(v) end
        else r.cache[key] = H.copy(value) end
    end
    function r.listen(name, fn, network)
        r.events[#r.events + 1] = {name = name, handler = fn, network = network == true}
    end
    function r.dispatch(name, src, ...)
        for _, event in ipairs(r.events) do
            if event.name == name then
                if ported and side == 'server' then event.handler(src, ...)
                else r.env.source = src; event.handler(...) end
            end
        end
    end
    function r.emit(name, ...)
        r.record('local', name, ...)
        r.dispatch(name, 0, ...)
    end
    r.delivery = {getResourceState = function() return r.bridge end, writeCache = r.write, emit = r.emit}
    local function effect(name) return function(...) r.record(name, ...) end end
    local native = {
        PlayerId = function() return 7 end, PlayerPedId = function() return r.ped end,
        GetPlayerServerId = function() return 1 end, GetVehiclePedIsIn = function() return r.vehicle end,
        GetVehicleMaxNumberOfPassengers = function() return 3 end,
        GetPedInVehicleSeat = function(_, seat) return seat == -1 and r.ped or 0 end,
        GetSelectedPedWeapon = function() return r.weapon end,
        GetEntityCoords = function() return {x = 1, y = 2, z = 3} end,
        GetInteriorFromEntity = function() return 0 end,
        DoesEntityExist = function(ped) return ped ~= 0 end,
        IsEntityDead = function() return r.dead end, IsPedFatallyInjured = function() return r.injured end,
        GetEntityMaxHealth = function() return 200 end, GetEntityHealth = function() return r.health end,
        GetPedArmour = function() return r.armor end, IsEntityInWater = function() return r.water end,
        GetGameTimer = function() return r.now end, GetInvokingResource = function() return r.invoking end,
        GetCurrentResourceName = function() return 'forge-core' end,
        SetEntityHealth = function(ped, value) r.health = value; r.record('health', ped, value) end,
        SetPedArmour = function(ped, value) r.armor = value; r.record('armor', ped, value) end,
        SetPlayerUnderwaterTimeRemaining = function(id, value) r.underwater = value; r.record('underwater', id, value) end,
        GetPlayerUnderwaterTimeRemaining = function() return r.underwater end,
        GetPlayerSprintStaminaRemaining = function() return r.stamina end,
        GetVehicleClass = function() return r.vehicleClass end, GetEntitySpeed = function() return r.speed end,
        GetHashKey = function() return 0 end, IsPedShooting = function() return r.shooting end,
        TriggerEvent = r.emit, TriggerServerEvent = effect('server'),
        DisableControlAction = effect('disable-control'), DisablePlayerFiring = effect('disable-firing'),
        SetPedToRagdoll = effect('ragdoll'), SetPlayerHealthRechargeMultiplier = effect('recharge-multiplier'),
        SetPlayerHealthRechargeLimit = effect('recharge-limit'), Wait = function(ms) return coroutine.yield(ms) end,
    }
    r.native = native
    function r.await(name, src)
        r.record('await', name, src)
        if r.awaitHook then return r.awaitHook(name, src) end
        if r.awaitError then error('simulated callback refusal') end
        local response = H.copy(r.response or {hunger = 65, oxygen = 100})
        if ported and side == 'server' then
            local identity = r.core.Status.ProtocolSnapshot(src)
            response._session, response._character = identity._session, identity._character
        end
        return response
    end
    function r.save(src) r.record('save', src); return r.saveResult ~= false end
    r.env = H.environment({QBX = r.core, source = 0})
    local env = r.env
    env.math.random = function(a) return a and 2 or 0.05 end
    for name, fn in pairs(native) do env[name] = fn end
    env.GetResourceState = r.delivery.getResourceState
    env.GetPlayer = function(src) return r.core.Players[tonumber(src)] end
    env.GetPlayerRoutingBucket = function() return r.bucket end
    env.TriggerClientEvent = effect('client')
    env.Save = r.save
    local exported = setmetatable({pr_bridge = {accessCacheState = function(_, ...) return r.write(...) end}},
        {__call = function(_, name, fn) r.exported[name] = fn end})
    env.exports = exported
    env.AddEventHandler = function(name, fn) r.listen(name, fn, false) end
    env.RegisterNetEvent = function(name, fn) r.listen(name, fn, true) end
    env.CreateThread = function(fn) r.threads[#r.threads + 1] = fn end
    env.lib = {callback = {await = r.await, register = function(name, fn) r.callbacks[name] = fn end}}
    env.require = function(name)
        if name == 'modules.bridge-cache' then return H.load(H.qbx .. 'modules/bridge-cache.lua', env) end
        if name == 'config.server' then return {player = {status = r.config}} end
        if name == 'config.client' then return {playerStatus = r.clientConfig} end
        error('Unexpected producer import: ' .. tostring(name))
    end
    function r.install(module)
        for _, e in ipairs(module.Events) do r.listen(e.name, e.handler, e.network) end
        for _, fn in ipairs(module.Threads) do r.threads[#r.threads + 1] = fn end
        for name, fn in pairs(module.Exports) do r.exported[name] = fn end
        for name, fn in pairs(module.Callbacks) do r.callbacks[name] = fn end
    end
    function r.load(domain)
        if not ported then H.load(H.qbx .. side .. '/' .. domain:gsub('_', '-') .. '.lua', env); return end
        local moduleEnv = H.environment(); moduleEnv.math.random = env.math.random
        local factory = H.load('kernel/' .. side .. '/' .. domain .. '.lua', moduleEnv)
        local bindings = {core = r.core, emit = r.emit, native = native, config = side == 'server' and r.config or r.clientConfig,
            getPlayer = env.GetPlayer, getBucket = env.GetPlayerRoutingBucket, save = r.save,
            emitClient = env.TriggerClientEvent, getInvokingResource = native.GetInvokingResource,
            wait = native.Wait, awaitSnapshot = r.await}
        if domain == 'bridge_cache' then
            bindings.writer = H.load('kernel/shared/bridge_cache.lua', H.environment())(r.delivery, 'qbx_core:' .. side .. ':cacheChanged')
        end
        local count = #r.trace
        local module = factory(bindings)
        assert(#r.trace == count, 'Factory must not publish, poll, register or start a thread')
        r.modules[domain] = module
        r.install(module) -- mock bus only; not runtime registration
        if domain == 'bridge_cache' then r.core.BridgeCache = module.Producer end
        if domain == 'session' then r.core.Session = module.Session end
        if domain == 'status' and side == 'server' then r.core.Status = module.Status end
        if module.Initialize then module.Initialize() end
    end
    function r.step(index)
        r.coroutines = r.coroutines or {}
        local co = r.coroutines[index] or coroutine.create(assert(r.threads[index], 'Missing thread descriptor'))
        r.coroutines[index] = co
        local ok, delay = coroutine.resume(co)
        assert(ok, delay)
        assert(coroutine.status(co) == 'suspended', 'Scheduler step must yield')
        return delay
    end
    return r
end
function T.pair(side, domains)
    local a, b = T.new(false, side), T.new(true, side)
    for _, domain in ipairs(domains) do a.load(domain); b.load(domain) end
    local pair = {a = a, b = b, count = 0}
    -- Only additive transport identity is excluded from legacy return/effect comparisons.
    -- Authoritative data/cache comparisons remain unfiltered; protocol is asserted in its own suite.
    local function withoutTransport(value)
        if type(value) ~= 'table' then return value end
        local result = {}
        for k, v in pairs(value) do
            if k ~= '_session' and k ~= '_character' then result[k] = withoutTransport(v) end
        end
        return result
    end
    function pair.run(label, action)
        local av, bv = table.pack(action(a)), table.pack(action(b))
        H.same(withoutTransport(bv), withoutTransport(av), label .. ': returns')
        -- Forge's additive funcref collector has no legacy equivalent. Its
        -- payload/lifecycle/guards are covered by character_state_persistence_test.
        local function legacyTrace(trace)
            local result={}
            for _,entry in ipairs(trace) do
                if not(entry.kind=='local' and entry.args[1]=='forge-core:client:collectCharacterState') then
                    result[#result+1]=entry
                end
            end
            return withoutTransport(result)
        end
        H.same(legacyTrace(b.trace), legacyTrace(a.trace), label .. ': effects')
        H.same(b.cache, a.cache, label .. ': cache')
        H.same(b.core.PlayerData, a.core.PlayerData, label .. ': playerData')
        H.same(b.core.Players, a.core.Players, label .. ': players')
        pair.count = pair.count + 1
        return bv
    end
    return pair
end
return T
