local P = dofile('tests/kernel_player_harness.lua')
local H, viewCount, persistenceCount = P.H, 0, 0
local function viewRuntime(ported, server, initial)
    local r = {events = {}, pulls = 0, initial = initial}
    local get = function() r.pulls = r.pulls + 1; return r.initial end
    local env = H.environment()
    if ported then
        local factory = H.load('kernel/modules/playerdata.lua', env)
        r.api = factory({isServer = server, getPlayerData = get})
        assert(r.pulls == 0, 'No automatic view pull')
        if r.api then
            for _, event in ipairs(r.api.Events) do r.events[event.name] = event.handler end
            assert(r.api.Initialize() and not r.api.Initialize()); r.view = r.api.View
        end
        assert(rawget(env, 'QBX') == nil)
    else
        env.IsDuplicityVersion = function() return server end
        env.exports = {qbx_core = {GetPlayerData = function() return get() end}}
        env.RegisterNetEvent = function(name, fn) r.events[name] = fn end
        P.loadOrigin('modules/playerdata.lua', env); r.view = rawget(env, 'QBX')
    end
    return r
end
local cases = {
    server = function(ported) local r = viewRuntime(ported, true); return r.view, r.pulls, next(r.events) end,
    missing = function(ported) local r = viewRuntime(ported, false); return r.view, r.pulls end,
    falseData = function(ported) local r = viewRuntime(ported, false, false); return r.view, r.pulls end,
    initialReference = function(ported)
        local data = {citizenid = 'A'}; local r = viewRuntime(ported, false, data)
        assert(r.view.PlayerData == data); return r.view, r.pulls
    end,
    setReference = function(ported)
        local r = viewRuntime(ported, false, {citizenid = 'A'}); local data = {citizenid = 'B'}
        r.events['QBCore:Player:SetPlayerData'](data)
        assert(r.view.PlayerData == data); return r.view, r.pulls
    end,
    unload = function(ported)
        local data = {citizenid = 'A'}; local r = viewRuntime(ported, false, data)
        r.events['QBCore:Client:OnPlayerUnload'](); assert(data.citizenid == 'A')
        return r.view, r.pulls
    end,
    nilPayload = function(ported)
        local r = viewRuntime(ported, false, {}); r.events['QBCore:Player:SetPlayerData'](nil); return r.view, r.pulls
    end,
}
for name, action in pairs(cases) do
    H.same(P.snapshot(table.pack(action(true))), P.snapshot(table.pack(action(false))), name)
    viewCount = viewCount + 1
end

local function persistenceRuntime(ported)
    local r = {trace = {}, exists = true}
    local native = {
        DoesEntityExist = function(entity) r.trace[#r.trace + 1] = {'exists', entity}; return r.exists end,
        Entity = function(entity)
            r.trace[#r.trace + 1] = {'entity', entity}
            if r.noEntity then return nil end
            if r.noState then return {} end
            return {state = {set = function(_, ...) r.trace[#r.trace + 1] = {'set', entity, table.pack(...)} end}}
        end,
    }
    local env = H.environment()
    if ported then r.api = H.load('kernel/server/vehicle_persistence_compat.lua', env)({native = native})
    else
        for name, fn in pairs(native) do env[name] = fn end
        r.api = {}; env.exports = function(name, fn) r.api[name] = fn end
        P.loadOrigin('server/vehicle-persistence-compat.lua', env)
    end
    assert(#r.trace == 0); return r
end
for _, method in ipairs({'EnablePersistence', 'DisablePersistence'}) do
    for _, case in ipairs({'nil','zero','bad','absent','noEntity','noState','number','numericString'}) do
        local function action(r)
            if case == 'absent' then r.exists = false end
            r.noEntity, r.noState = case == 'noEntity', case == 'noState'
            local value = case == 'nil' and nil or case == 'zero' and 0 or case == 'bad' and 'oops'
                or case == 'numericString' and '12' or 12
            if case == 'nil' then value = nil end
            return r.api[method](value)
        end
        local a, b = persistenceRuntime(false), persistenceRuntime(true)
        H.same(table.pack(action(b)), table.pack(action(a)), method .. '/' .. case)
        H.same(b.trace, a.trace, method .. '/' .. case .. ': trace'); persistenceCount = persistenceCount + 1
    end
end
assert(viewCount == 7 and persistenceCount == 16)
print('PASS kernel helper boundaries: 7 PlayerData-view and 16 persistence differential cases; explicit initialization, reference/clear semantics, native validity and statebag true/nil')
