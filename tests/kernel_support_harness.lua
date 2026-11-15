-- Test-only boundaries; no real scheduler, resource, network, JSON file or database.
local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local S = {P = P, H = H}

function S.config(ported, side)
    local r = {trace = {}, states = {}, caller = 'test', randomIndex = 0, tempResult = 'BARCODE'}
    function r.record(kind, ...)
        r.trace[#r.trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))}
    end
    local function invoke(name, ...)
        r.record(name, ...)
        if r.fail == name then error('simulated key failure') end
        if r.keyResult ~= nil then return r.keyResult end
        if name == 'pr.createTempKeyItem' then return r.tempResult end
        return 'KEY_RESULT'
    end
    local function random(minimum, maximum)
        r.randomIndex = r.randomIndex + 1
        r.record('random', minimum, maximum)
        return minimum + r.randomIndex % (maximum - minimum + 1)
    end
    local function randomString(pattern) r.record('randomString', pattern); return 'STR_' .. pattern end
    r.ports = {
        vec4 = P.vector, joaat = function(value) return 'HASH_' .. value end,
        getResourceState = function(name) r.record('state', name); return r.states[name] or 'stopped' end,
        getVehicleNumberPlateText = function(vehicle) r.record('plate', vehicle); return '  NATIVE  ' end,
        setVehicleDoorsLocked = function(...) r.record('nativeLock', ...) end,
        random = random, randomString = randomString,
        vehicleKeys = {pr = {}, qbx = {}},
    }
    for _, name in ipairs({'buyOriginalKey', 'createTempKeyItem', 'giveTempKey', 'setLockState', 'haveKey'}) do
        r.ports.vehicleKeys.pr[name] = function(...) return invoke('pr.' .. name, ...) end
    end
    for _, name in ipairs({'giveKeys', 'setLockState', 'hasKeys'}) do
        r.ports.vehicleKeys.qbx[name] = function(...) return invoke('qbx.' .. name, ...) end
    end
    local env = H.environment()
    if ported then
        r.api = H.load('kernel/config/' .. side .. '.lua', env)(r.ports)
    else
        env.vec4, env.joaat = r.ports.vec4, r.ports.joaat
        env.GetResourceState, env.GetVehicleNumberPlateText = r.ports.getResourceState, r.ports.getVehicleNumberPlateText
        env.SetVehicleDoorsLocked = r.ports.setVehicleDoorsLocked
        env.lib = {string = {random = randomString}}
        env.math.random = random
        local function proxy(provider, aliases)
            local result = {}
            for public, private in pairs(aliases) do
                result[public] = function(_, ...) return r.ports.vehicleKeys[provider][private](...) end
            end
            return result
        end
        env.exports = {
            pr_carkeys = proxy('pr', {BuyOriginalKey = 'buyOriginalKey', CreateTempKeyItem = 'createTempKeyItem',
                GiveTempKey = 'giveTempKey', SetLockState = 'setLockState', HaveKey = 'haveKey'}),
            qbx_vehiclekeys = proxy('qbx', {GiveKeys = 'giveKeys', SetLockState = 'setLockState', HasKeys = 'hasKeys'}),
        }
        r.api = P.loadOrigin('config/' .. side .. '.lua', env)
    end
    r.env = env
    assert(#r.trace == 0, 'Config construction must not consult resources or invoke integration/RNG')
    return r
end

function S.hooks(ported)
    local r = {trace = {}, caller = 'A', tick = 0, duration = 10, exported = {}, events = {}, dependency = true}
    function r.record(kind, ...) r.trace[#r.trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))} end
    r.ports = {
        resource = 'forge-core', getInvokingResource = function() return r.caller end,
        warn = function(...) r.record('warn', ...) end,
        microtime = function() r.tick = r.tick + r.duration; return r.tick end,
        checkDependency = function(...) r.record('dependency', ...); return r.dependency end,
    }
    local env = H.environment()
    if ported then
        r.api = H.load('kernel/modules/hooks.lua', env)(r.ports)
        assert(#r.trace == 0, 'No dependency checks at construction')
        assert(r.api.CheckDependencies())
        r.exported = r.api.Exports
        for _, event in ipairs(r.api.Events) do r.events[event.name] = event.handler end
    else
        env.lib = {checkDependency = r.ports.checkDependency}
        env.os = {microtime = r.ports.microtime}
        env.warn, env.GetInvokingResource = r.ports.warn, r.ports.getInvokingResource
        env.cache = {resource = 'forge-core'}
        env.exports = function(name, fn) r.exported[name] = fn end
        env.AddEventHandler = function(name, fn) r.events[name] = fn end
        r.api = {trigger = P.loadOrigin('modules/hooks.lua', env)}
    end
    function r.callback(name, response, mode)
        local cb = {}
        setmetatable(cb, {__index = function() error('old index') end,
            __newindex = function() error('old newindex') end,
            __call = function(_, payload)
                r.record('hook-' .. name, payload)
                if mode == 'error' then error(response) end
                return response
            end})
        return cb
    end
    return r
end

function S.logger(ported, isServer)
    local r = {trace = {}, tasks = {}, tick = 0, status = 204, headers = {}, requests = 0}
    function r.record(kind, ...) r.trace[#r.trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))} end
    r.ports = {
        isServer = isServer ~= false,
        printError = function(...) r.record('error', ...) end,
        getGameTimer = function() return r.tick end,
        wait = function(delay) r.record('wait', delay); r.tick = r.tick + delay end,
        thread = function(fn) r.tasks[#r.tasks + 1] = fn end,
        time = function() return 1000 end,
        date = function(format) r.record('date', format); return '12:00:00 10-18-2026' end,
        encode = function(value) r.record('encode', value); return '<mock-json>' end,
        libraryLogger = function(...) r.record('library', ...) end,
        httpRequest = function(url, callback, method, body, headers)
            r.requests = r.requests + 1
            r.record('http', url, method, body, headers)
            if r.onHttp then r.onHttp(callback) else callback(r.status, '', r.headers) end
        end,
    }
    local env = H.environment()
    if ported then r.api = H.load('kernel/modules/logger.lua', env)(r.ports)
    else
        env.IsDuplicityVersion = function() return r.ports.isServer end
        env.GetGameTimer, env.Wait = r.ports.getGameTimer, r.ports.wait
        env.CreateThread, env.PerformHttpRequest = r.ports.thread, r.ports.httpRequest
        env.os = {time = r.ports.time, date = r.ports.date}
        env.json = {encode = r.ports.encode}
        env.lib = {logger = r.ports.libraryLogger, print = {error = r.ports.printError}}
        r.api = P.loadOrigin('modules/logger.lua', env)
    end
    assert(#r.tasks == 0 and r.requests == 0, 'Logger construction must not install a thread or send HTTP')
    function r.pump()
        while #r.tasks > 0 do table.remove(r.tasks, 1)() end
    end
    return r
end

return S
