-- Test-only bounded native/scheduler doubles. No FiveM, network, media or SQL.
local V = dofile('tests/kernel_legacy_harness.lua')
local H, P = V.H, V.P
local R = {H = H, P = P, V = V}
function R.new(ported, module, options)
    options = options or {}
    local r = {trace = {}, events = {}, callbacks = {}, bags = {}, entities = {}, threads = {}, timers = {},
        clock = 0, groundCalls = 0, propertyCalls = 0, tutorial = 0, vehicle = 0, heading = 90,
        marker = true, foundGround = true, groundAfter = 1, groundZ = 7, collision = true,
        active = true, playerId = 1, exists = true, worldCollision = false, propertySuccess = true,
        owners = {[20] = 1, [21] = 1, [22] = 2}, seats = {[-1] = 10, [0] = 21, [1] = 22, [2] = 0},
        coords = {[10] = V.vector(1, 2, 3), [11] = V.vector(3, 2, 3)}, nearby = {{vehicle = 20}, {vehicle = 30}}}
    function r.record(kind, ...) r.trace[#r.trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))} end
    local n, c = {}, {ped = 10, playerId = 1, resource = 'forge-core'}
    r.native, r.cache = n, c
    n.joaat = function(value)
        if type(value) == 'number' then return value end
        local result = 0; for i = 1, #value do result = (result * 31 + value:byte(i)) % 1000000 end; return result
    end
    local shared = H.load('kernel/shared/main.lua', H.environment())({weapons = {[3] = {label = 'Weapon'}},
        locations = {shop = V.vector(1,2,3)}, vehicles = {}})
    shared.SetVehicles({car = {model = 'car', hash = n.joaat('car'), name = 'Car', category = 'cars'}})
    r.core = {PlayerData = {}, Shared = shared, IsLoggedIn = false, Status = {hunger = 100, thirst = 100}}
    r.core.BridgeCache = {refreshContext = function(...) r.record('context', ...) end,
        player = function(...) r.record('player', ...) end}
    r.core.Session = {refresh = function() r.record('session') end,
        isDead = function() r.record('dead'); return r.dead == true end}
    r.config = {pauseMapText = options.mapText, statusIntervalSeconds = 2,
        teleport = {fadeDuration = 5, groundSearchMaxZ = 100, groundSearchStartZ = 5, groundSearchStep = -1,
            loadSceneRadius = 50, timeout = 3}, getVehiclesInRadius = {defaultRadius = 30},
        meCommand = {distance = 20, displayTime = 4}, setVehicleProperties = {timeout = 4, waitInterval = 1},
        initVehicle = {seats = {-1,0,1,2}}, discord = {enabled = options.enabled ~= false, appId = '123',
            largeIcon = {icon = 'large', text = 'Large'}, smallIcon = {icon = 'small', text = 'Small'},
            firstButton = {text = 'One', link = 'mock://one'}, secondButton = {text = 'Two', link = 'mock://two'}}}
    r.globalState = {PVPEnabled = options.pvp == true, MaxPlayers = options.maxPlayers or 64}
    local function effect(name) return function(...) r.record(name, ...) end end
    for _, name in ipairs({'AddTextEntry','AddTextEntryByHash','TriggerServerEvent','ShutdownLoadingScreenNui',
        'SetCanAttackFriendly','NetworkSetFriendlyFireOption','NetworkEndTutorialSession',
        'DoScreenFadeOut','DoScreenFadeIn','FreezeEntityPosition','NewLoadSceneStart','NewLoadSceneStop',
        'RequestCollisionAtCoord','DeleteEntity','SetVehicleOnGroundProperly','SetRichPresence','SetDiscordAppId',
        'SetDiscordRichPresenceAsset','SetDiscordRichPresenceAssetText','SetDiscordRichPresenceAssetSmall',
        'SetDiscordRichPresenceAssetSmallText','SetDiscordRichPresenceAction','TriggerEvent'}) do n[name] = effect(name) end
    n.Wait = function(ms)
        r.record('Wait', ms); r.clock = r.clock + math.max(1, ms)
        if r.yielding then return coroutine.yield(ms) end
    end
    n.CreateThread = function(fn) r.record('CreateThread'); r.threads[#r.threads+1] = fn end
    n.SetTimeout = function(ms, fn) r.record('SetTimeout', ms); r.timers[#r.timers+1] = fn end
    n.GetGameTimer = function() r.record('GetGameTimer'); r.clock = r.clock + 1; return r.clock end
    n.GetDisplayNameFromVehicleModel = function(hash) r.record('display', hash); return r.displayName or 'CAR' end
    n.GetAllVehicleModels = function() r.record('models'); return {'car','truck'} end
    n.GetVehicleClassFromName = function(model) r.record('class', model); return model == 'car' and 1 or 2 end
    n.GetEntityHealth = function(ped) r.record('health', ped); return r.health or 200 end
    n.SetEntityHealth = function(ped, health) r.record('SetEntityHealth', ped, health); r.health = health end
    n.GetInvokingResource = function() r.record('caller'); return r.caller end
    n.NetworkIsInTutorialSession = function() r.record('tutorial'); r.tutorial = r.tutorial-1; return r.tutorial >= 0 end
    n.GetConvar = function(name, default) r.record('convar', name, default); return r.motd or '' end
    n.GetEntityHeading = function(ped) r.record('heading', ped); return r.heading end
    n.SetEntityHeading = function(...) r.record('SetEntityHeading', ...) end
    n.GetEntityCoords = function(ped) r.record('coords', ped); return r.coords[ped] or V.vector(0,0,0) end
    n.SetPedCoordsKeepVehicle = function(ped,x,y,z) r.record('SetPedCoordsKeepVehicle',ped,x,y,z); r.coords[ped] = V.vector(x,y,z) end
    n.GetFirstBlipInfoId = function(kind) r.record('blip', kind); return 8 end
    n.DoesBlipExist = function(blip) r.record('blipExists', blip); return r.marker end
    n.GetBlipInfoIdCoord = function(blip) r.record('blipCoords', blip); return V.vector(12,13,0) end
    n.IsScreenFadedOut = function() r.record('faded'); if (r.fadeWaits or 0) > 0 then r.fadeWaits = r.fadeWaits-1; return false end; return true end
    n.GetVehiclePedIsIn = function(...) r.record('inVehicle', ...); return r.vehicle end
    n.IsNetworkLoadingScene = function() r.record('loading'); return r.loading == true end
    n.HasCollisionLoadedAroundEntity = function(ped) r.record('collision', ped); return r.collision end
    n.GetGroundZFor_3dCoord = function(...) r.record('ground', ...); r.groundCalls = r.groundCalls+1; return r.foundGround and r.groundCalls >= r.groundAfter,r.groundZ end
    n.VehToNet = function(vehicle) r.record('net', vehicle); return vehicle + 100 end
    n.GetPlayerFromStateBagName = function(bag) r.record('bagPlayer', bag); return r.playerId end
    n.NetworkIsPlayerActive = function(id) r.record('active', id); return r.active end
    n.GetPlayerPed = function(id) r.record('ped', id); return 11 end
    n.DoesEntityExist = function(entity) r.record('exists', entity); return r.exists end
    n.NetworkGetEntityFromNetworkId = function(id) r.record('fromNet', id); return 20 end
    n.NetworkGetEntityOwner = function(entity) r.record('owner', entity); if r.ownerHook then return r.ownerHook(entity) end; return r.owners[entity] or 2 end
    n.GetPedInVehicleSeat = function(vehicle, seat) r.record('seat', vehicle, seat); return r.seats[seat] or 0 end
    n.IsEntityWaitingForWorldCollision = function(vehicle) r.record('worldCollision', vehicle); return r.worldCollision end
    n.Entity = function(vehicle) r.record('Entity', vehicle); return {state = {set = function(_, ...) r.record('state', ...) end}} end
    local library = {}
    library.getNearbyVehicles = function(...) r.record('nearby', ...); return H.copy(r.nearby) end
    library.setVehicleProperties = function(...) r.record('properties', ...); r.propertyCalls = r.propertyCalls+1; return r.propertySuccess and r.propertyCalls >= (r.propertyAfter or 1) end
    library.waitFor = function(fn)
        r.record('waitFor'); for _ = 1, 5 do local value = fn(); if value then return value end; n.Wait(1) end
        error('simulated waitFor timeout', 0)
    end
    local helpers = {table = {mapBySubfield = function(items, field)
        local result = {}; for _,item in pairs(items) do if item[field] then local key = item[field]; result[key] = result[key] or {}; table.insert(result[key], item) end end; return result
    end}, drawText3d = function(...) r.record('draw3d', ...) end}
    local notify = function(...) r.record('notify', ...) end
    local locale = function(key) r.record('locale', key); return key end
    local random = function(a,b) r.record('random',a,b); return r.randomValue or 7 end
    r.library, r.helpers = library, helpers
    r.bindings = {core = r.core, native = n, cache = c, config = r.config, globalState = r.globalState,
        helpers = helpers, library = library, notify = notify, locale = locale, random = random}
    local env = H.environment()
    if ported then
        r.api = H.load('kernel/client/'..module..'.lua',env)(r.bindings)
        assert(#r.trace == 0 and #r.threads == 0 and #r.timers == 0, 'Constructor effects forbidden')
        for _,e in ipairs(r.api.Events) do r.events[e.name] = e.handler end
        for _,e in ipairs(r.api.StateBags) do r.bags[e.key] = e.handler end
        for _,e in ipairs(r.api.EntityStateHandlers) do r.entities[e.key] = e.handler end
        for _,fn in ipairs(r.api.Threads) do r.threads[#r.threads+1] = fn end
        r.callbacks = r.api.Callbacks
        r.initialize = r.api.Initialize or function() return false end
    else
        for name,fn in pairs(n) do env[name] = fn end
        env.QBX, env.qbx, env.cache, env.GlobalState = r.core, helpers, c, r.globalState
        env.Notify, env.locale = notify, locale; env.math.random = random
        env.exports = function(name,fn) r.api[name] = fn end
        env.RegisterNetEvent = function(name,fn) r.events[name] = fn end
        env.AddEventHandler = env.RegisterNetEvent
        env.AddStateBagChangeHandler = function(key,filter,fn) r.bags[key] = fn end
        env.require = function(name) if name == 'config.client' then return r.config elseif name == 'shared.main' then return shared end; error(name) end
        library.callback = {register = function(name,fn) r.callbacks[name] = fn end}; env.lib = library
        helpers.entityStateHandler = function(key,fn) r.entities[key] = fn end
        r.api = {}
        r.initialize = function()
            local source = P.source('client/'..module..'.lua')
            if module == 'main' then
                local previous = r.core
                P.loadOrigin('client/main.lua',env,source)
                r.core, r.bindings.core = env.QBX, env.QBX
                r.core.BridgeCache, r.core.Session, r.core.Status = previous.BridgeCache, previous.Session, previous.Status
            else P.loadOrigin('client/'..module..'.lua',env,source) end
        end
    end
    r.env = env
    function r.start(index) return coroutine.create(assert(r.threads[index or 1])) end
    function r.step(co) r.yielding = true; local ok,value = coroutine.resume(co); r.yielding = false; assert(ok,value); return coroutine.status(co),value end
    return r
end
function R.compare(module, name, action, options)
    local a,b = R.new(false,module,options),R.new(true,module,options)
    a.initialize(); b.initialize()
    -- Only normalize scheduling at original module load, never handler-created threads.
    local function withoutScheduling(trace)
        local result = {}; for _,entry in ipairs(trace) do if entry.kind ~= 'CreateThread' then result[#result+1] = entry end end; return result
    end
    a.trace = withoutScheduling(a.trace)
    H.same(P.snapshot(table.pack(action(b))),P.snapshot(table.pack(action(a))),name..': returns')
    H.same(b.trace,a.trace,name..': effects')
    assert(#b.threads == #a.threads and #b.timers == #a.timers, name..': scheduler descriptors')
    H.same(P.snapshot(b.core),P.snapshot(a.core),name..': state')
end
return R
