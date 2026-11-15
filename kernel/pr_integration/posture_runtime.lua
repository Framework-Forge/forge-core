-- Forge posture is a private domain. Reuse the active session, PR input owner and native RPC.
return function(e, rpc, entry)
    local server = e.IsDuplicityVersion()
    local providers, graph = assert(entry.Providers), assert(entry.Bootstrap.Graph)
    local library = assert(providers.Library)
    local closed, started = false, false
    local listeners, stops, leases, keys = {}, {}, {}, {}
    local cancelled = {}
    local api = {}
    local function copy(value)
        if type(value) ~= 'table' then return value end
        local out = {}; for k, v in pairs(value) do out[k] = copy(v) end; return out
    end
    local function live() return not closed and entry.IsCurrent() end
    local env = setmetatable({}, {__index=e})
    -- Providers.Library.cache is the read-only native import view on the client.
    -- Posture records belong to the existing passive data cache owned by the seed.
    local dataCache = assert(entry.Foundation.Seed.Library.Cache, 'posture data cache required')
    for _, method in ipairs({'get', 'set', 'clear', 'clearPrefix'}) do
        assert(type(dataCache[method]) == 'function', 'posture data cache missing '..method)
    end
    local lib = setmetatable({callback=rpc.Native, cache=dataCache}, {__index=library})
    local core = {Client={}, State={copy=copy}, t=providers.DomainConfiguration.Translate}
    env.PR = copy(providers.DomainConfiguration.Config)
    env.ForgeCore, env.pr_lib = core, lib
    local function loadModule(path)
        return e.PRCore.load('@forge-core/'..path, env)
    end
    env.AddEventHandler = function(name, fn)
        if name == 'onResourceStop' then stops[#stops+1] = fn; return end
        local token = e.AddEventHandler(name, function(...) if live() then return fn(...) end end)
        assert(token ~= nil and token ~= false, 'posture listener refused: '..name)
        listeners[#listeners+1] = token; return token
    end
    env.RegisterNetEvent = function(name, fn)
        e.RegisterNetEvent(name)
        if fn then return env.AddEventHandler(name, fn) end
    end
    env.Wait = function(ms)
        if not live() then error(cancelled, 0) end
        e.Wait(ms)
        if not live() then error(cancelled, 0) end
    end
    env.CreateThread = function(fn)
        e.CreateThread(function()
            if not live() then return end
            local ok, reason = pcall(fn)
            if not ok and reason ~= cancelled then error(reason, 0) end
        end)
    end
    env.SetTimeout = function(ms, fn) e.SetTimeout(ms, function() if live() then fn() end end) end
    env.exports = function(name, fn)
        return e.exports(name, function(...) if live() then return fn(...) end end)
    end
    function api.Start()
        assert(not started and not closed, 'posture already started/closed'); started = true
        if server then
            core.Session = assert(graph.Base.ForgeSession.Session)
            -- Resolve player authority internally, never Forge -> PR framework -> Forge.
            lib.cache = setmetatable({GetPlayer=graph.Base.PlayerCore.Lookup.GetPlayer}, {__index=dataCache})
            local callbackLibrary = {callback={register=function(name, fn)
                local lease = rpc.Owners.native.Reserve(name); leases[#leases+1] = lease
                assert(rpc.Owners.native.Bind(lease, function(...) if live() then return fn(...) end end))
                return true
            end}}
            core.Callbacks = loadModule('kernel/server/callback_security')({services={}, library=callbackLibrary,
                config=env.PR, json=e.json, native={getGameTimer=e.GetGameTimer, getPlayerPing=e.GetPlayerPing,
                print=e.print, isPlayerAceAllowed=e.IsPlayerAceAllowed, getSource=function() return e.source end}})
            for _, event in ipairs(core.Callbacks.Events) do env.AddEventHandler(event.name, event.handler) end
        else
            core.Session = assert(graph.Parts.AutoMedic.Session.Session)
            core.Hospital = assert(graph.Parts.AutoMedic.Hospital.Hospital)
            lib.fivem = {streaming=e.PRCore.load('@pr_bridge/bridge/fivem/streaming/client', env)}
            local owner = assert(e.PRCore.forgeKeybindScope.Keybind)
            lib.addKeybind = function(data)
                assert(owner.get(data.name) == nil, 'posture keybind collision: '..data.name)
                local pressed = data.onPressed
                data.onPressed = function(...) if live() then return pressed(...) end end
                keys[#keys+1] = data.name
                return owner(data)
            end
            lib.addCommand = function(name, options, fn)
                local result = library.command(name, options, function(...) if live() then return fn(...) end end)
                assert(result ~= false, 'posture command refused: '..name)
                return result
            end
        end
        loadModule('kernel/posture/config')(env)
        loadModule('kernel/posture/contract')(env)
        loadModule(server and 'kernel/posture/server' or 'kernel/posture/client')(env)
        if not server then loadModule('kernel/posture/interactions')(env) end
        return true
    end
    function api.Close()
        if closed then return true end
        -- Release animations while the session and PR services are still available.
        for i=#stops,1,-1 do stops[i]('forge-core') end
        closed = true
        for i=#keys,1,-1 do e.PRCore.forgeKeybindScope.Keybind.remove(keys[i]) end
        for i=#leases,1,-1 do assert(rpc.Owners.native.Release(leases[i])) end
        for i=#listeners,1,-1 do assert(e.RemoveEventHandler(listeners[i]) ~= false) end
        return true
    end
    return api
end
