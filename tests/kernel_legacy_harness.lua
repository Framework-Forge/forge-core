-- Legacy/native/library doubles, never real schedulers or resource/inventory access.
local T = dofile('tests/kernel_helpers_harness.lua')
local H, P = T.H, T.P
local V = {T = T, H = H, P = P}
local vecMeta = {}
function V.vector(x, y, z, w)
    return setmetatable({__kind = w and 'vector4' or 'vector3', x = x, y = y, z = z, w = w,
        r = x, g = y, b = z, a = w}, vecMeta)
end
vecMeta.__sub = function(a, b) return V.vector(a.x - b.x, a.y - b.y, a.z - b.z) end
vecMeta.__len = function(a) return math.sqrt(a.x*a.x + a.y*a.y + a.z*a.z) end
function V.strsplit(delimiter, value)
    local result, start = {}, 1
    while true do
        local first, last = value:find(delimiter, start, true)
        if not first then result[#result + 1] = value:sub(start); break end
        result[#result + 1] = value:sub(start, first - 1); start = last + 1
    end
    return table.unpack(result)
end

function V.new(ported, side)
    local r = T.new(ported, side)
    local helperEnv = r.env
    r.helpers, r.tasks, r.randomIndex = r.api, {}, 0
    r.searchResult, r.ping = 5, 10
    r.minute, r.hour, r.groundFound, r.groundZ = 5, 13, true, 42
    r.coords = {[10] = V.vector(0, 0, 0), [20] = V.vector(3, 0, 0), [30] = V.vector(10, 0, 0)}
    r.pools = {CVehicle = {20,30}, CObject = {20,30}, CPed = {10,20,30}, CPickups = {30}}
    r.activePlayers, r.players = {1,2,3}, {'1','2'}
    r.identifiers = {['1'] = {license = 'license:A', license2 = 'license2:A'}, ['2'] = {license = 'license:B'}}
    local n = r.native
    n.vec3, n.vec4 = V.vector, V.vector
    n.GetEntityCoords = function(entity) r.record('coords', entity); return r.coords[entity] or V.vector(0,0,0) end
    n.GetPlayerPed = function(source) r.record('getPed', source); return 10 end
    n.GetPlayerPing = function(source) r.record('ping', source); return r.ping end
    n.GetPlayers = function() r.record('players'); return r.players end
    n.GetPlayerIdentifierByType = function(source, kind) r.record('identifier',source,kind); return (r.identifiers[source] or {})[kind] end
    n.GetGamePool = function(pool) r.record('pool',pool); return r.pools[pool] end
    n.GetActivePlayers = function() r.record('active'); return r.activePlayers end
    n.GetEntityType = function(entity) r.record('entityType',entity); return r.entityType or 1 end
    n.GetWorldPositionOfEntityBone = function(entity,bone) r.record('boneCoords',entity,bone); return V.vector(bone or 0, 0, 0) end
    n.GetPedBoneIndex = function(entity,bone) r.record('pedBone',entity,bone); return r.boneIndex or 2 end
    n.GetEntityBoneIndexByName = function(entity,bone) r.record('nameBone',entity,bone); return r.boneIndex or 2 end
    n.GetClockMinutes = function() r.record('minute'); return r.minute end
    n.GetClockHours = function() r.record('hour'); return r.hour end
    n.GetGroundZFor_3dCoord = function(...) r.record('ground',...); return r.groundFound,r.groundZ end
    for _, name in ipairs({'AttachEntityToEntity','DropPlayer','SetModelAsNoLongerNeeded','SetParticleFxLoopedAlpha',
        'SetParticleFxLoopedColour','SetParticleFxLoopedEvolution','SetParticleFxNonLoopedAlpha','SetParticleFxNonLoopedColour',
        'SetPtfxAssetNextCall','StopParticleFxLooped','UseParticleFxAssetNextCall'}) do
        n[name] = function(...) r.record(name,...) end
    end
    for _, name in ipairs({'CreateObject','StartParticleFxLoopedAtCoord','StartParticleFxLoopedOnEntity',
        'StartParticleFxLoopedOnEntityBone','StartParticleFxNonLoopedAtCoord','StartParticleFxNonLoopedOnEntity','StartParticleFxNonLoopedOnPedBone'}) do
        n[name] = function(...) r.record(name,...); return 88 end
    end
    n.CreateThread = function(fn) r.record('thread'); r.tasks[#r.tasks+1] = coroutine.create(fn) end
    n.Wait = function(ms) r.record('wait',ms); if r.yielding then return coroutine.yield(ms) end end
    local library = r.library
    library.print.warn = function(...) r.record('warn',...) end
    library.print.verbose = function(...) r.record('verbose',...) end
    library.math = {groupdigits = function(value) r.record('groupdigits',value); return 'GROUPED_' .. value end}
    library.getClosestPlayer = function(...) r.record('closestPlayer',...); return r.closestPlayer,r.closestPed,r.closestCoords end
    library.getNearbyPlayers = function(...) r.record('nearbyPlayers',...); return H.copy(r.nearby or {}) end
    for _, name in ipairs({'playAnim','requestModel','requestNamedPtfxAsset'}) do library[name] = function(...) r.record(name,...) end end
    local random = function(low, high) r.randomIndex = r.randomIndex+1; r.record('rng',low,high); return r.randomIndex % 2 + 1 end
    local search = function(...) r.record('search',...); return r.searchResult end
    -- Both original globals and the port's native table see the same test boundary.
    if not ported then for name, fn in pairs(n) do helperEnv[name] = fn end end
    local env = T.env()
    r.bindings = {isServer = side == 'server',native = n, library = library, helpers = r.helpers,
        cache = r.cache, searchInventory = search, random = random, strsplit = V.strsplit, discordLink = 'mock://discord'}
    if ported then
        r.api = H.load('kernel/modules/utils.lua',env)(r.bindings)
        assert(#r.trace == 0 and #r.tasks == 0, 'No runtime effects in legacy constructor')
        assert(r.api.Initialize() and not r.api.Initialize())
    else
        for name, fn in pairs(n) do env[name] = fn end
        env.lib,env.cache = library,r.cache
        env.qbx = {old = true}; local previous = env.qbx
        env.require = function(name) assert(name == 'modules.lib'); env.qbx = r.helpers end
        env.IsDuplicityVersion = function() return side == 'server' end
        env.GetConvar = function(name,default) assert(name == 'qbx:discordlink' and default == 'discord.gg/qbox'); return 'mock://discord' end
        env.exports = {ox_inventory = {Search = function(_,...) return search(...) end}}
        env.string.strsplit,env.math.random = V.strsplit,random
        local source = P.source('modules/utils.lua'):gsub('`([%w_]+)`','joaat("%1")')
        P.loadOrigin('modules/utils.lua',env,source)
        assert(env.qbx == previous, 'Installed helper must restore old qbx namespace')
        r.api = env; r.api.String,r.api.Math = env.string,env.math
    end
    r.env = env
    function r.step(index)
        local co = assert(r.tasks[index or 1]); r.yielding = true
        local ok, value = coroutine.resume(co); r.yielding = false
        assert(ok,value); return coroutine.status(co),value
    end
    return r
end

function V.compare(side,name,action)
    local a,b = V.new(false,side),V.new(true,side)
    H.same(P.snapshot(table.pack(action(b))),P.snapshot(table.pack(action(a))),name .. ': returns')
    H.same(b.trace,a.trace,name .. ': calls')
end

function V.client(ported)
    local r = {trace = {},core = {PlayerData = {citizenid = 'A',job = {name = 'taxi',grade = {level = 1}},
        gang = {name = 'none',grade = {level = 0}},jobs = {taxi = 1,police = 2},gangs = {none = 0}}}}
    r.membership = H.load('kernel/shared/functions.lua',H.environment())({tableType=H.tableType,
        warn=function(...) r.trace[#r.trace+1]=table.pack(...) end})
    local notify=function(value) r.trace[#r.trace+1]=H.copy(value) end
    r.bindings={core=r.core,membership=r.membership,notify=notify,notifyPosition='center-left'}
    local env=H.environment()
    if ported then r.api=H.load('kernel/client/functions.lua',env)(r.bindings)
    else
        env.QBX=r.core; env.lib={notify=notify}
        env.require=function(name) assert(name=='config.shared'); return {notifyPosition='center-left'} end
        env.HasPlayerGotGroup=r.membership.HasPlayerGotGroup; env.GetPlayerGroups=r.membership.GetPlayerGroups
        r.api={}; env.exports=function(name,fn) r.api[name]=fn end
        P.loadOrigin('client/functions.lua',env)
    end
    r.env=env; assert(#r.trace==0); return r
end

return V
