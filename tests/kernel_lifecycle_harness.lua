-- Simulated platform/Promise/deferral boundaries for the installed QBX and private port.
local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local L = {H = H, P = P}
local hostLoad = load
local function original(file, env)
    local source = P.source(file):gsub('([%w_.%[%]]+)%s*([%+%-])=%s*([^\r\n]+)', function(lhs, op, rhs)
        return lhs .. ' = ' .. lhs .. ' ' .. op .. ' ' .. rhs
    end)
    return assert(hostLoad(source, '@' .. H.qbx .. file, 't', env))()
end
L.original = original
function L.new(ported)
    local r = {ported = ported, trace = {}, events = {}, tasks = {}, exported = {}, now = 1000,
        currentSource = 0, aces = {}, ids = {[1] = {'license2:L1', 'license:L1', 'discord:D1', 'ip:127.0.0.1'},
            [2] = {'license:L2'}, [3] = {'license:L3'}}, exists = {[1] = true, [2] = true, [3] = true},
        bans = {}, search = {}, offline = {}, numPlayers = 0, saveResult = true, banned = false,
        userId = 101, serverName = 'Simulated Forge', resource = 'forge-core', hardcap = 'started', maxPlayers = 2}
    function r.record(kind, ...) r.trace[#r.trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))} end
    r.core = {Players = {}, Player_Buckets = {}, Entity_Buckets = {}, UsableItems = {}}
    r.globalState = {PlayerCount = 0}
    r.serverConfig = {whitelist = false, whitelistPermission = 'admin', requireOptIn = false,
        checkDuplicateLicense = false, closed = false, closedReason = 'Closed', discord = 'mock', permissions = {'god', 'admin', 'mod'}}
    r.logging = {webhook = {joinleave = 'mock', anticheat = 'mock'}, role = {}}
    function r.makePlayer(src, citizenid)
        local player = {PlayerData = {source = src, citizenid = citizenid, license = 'license:L' .. src, userId = 101,
            charinfo = {phone = '555'}, metadata = {optin = false},
            job = {name = 'taxi', onduty = false, grade = {level = 0}}, gang = {name = 'none', grade = {level = 0}},
            jobs = {taxi = 0}, gangs = {}}}
        player.Functions = {
            Save = function() r.record('save-player', src); if r.saveHook then r.saveHook() end; return r.saveResult end,
            SetMetaData = function(k, v) player.PlayerData.metadata[k] = v; r.record('metadata', src, k, v) end,
            SetJobDuty = function(v) player.PlayerData.job.onduty = v; r.record('duty', src, v) end,
        }
        return player
    end
    r.core.Players[1] = r.makePlayer(1, 'A')
    r.core.Status = {Remove = function(src) r.record('status-remove', src) end}
    r.core.BridgeCache = {logout = function(src, reason) r.record('cache-logout', src, reason) end}
    local function effect(name) return function(...) r.record(name, ...) end end
    function r.emit(name, ...) r.record('local', name, ...); r.dispatch(name, 0, ...) end
    local function getIdentifier(src, kind)
        for _, id in ipairs(r.ids[tonumber(src)] or {}) do if id:match('^([^:]+)') == kind then return id end end
    end
    local native = {
        setPlayerBucket = effect('player-bucket'), setEntityBucket = effect('entity-bucket'),
        emit = r.emit, emitClient = effect('client'),
        isAceAllowed = function(src, permission) return (r.aces[tonumber(src)] or {})[permission] == true end,
        getIdentifier = getIdentifier, getResourceMetadata = function() return '1.2.3' end,
        getPlayerName = function(src) return 'Player ' .. tostring(src) end, dropPlayer = effect('drop'),
        entityExists = function(id) return id ~= 0 end, deleteEntity = effect('delete'),
        locale = function(key, arg) return arg and key .. ':' .. arg or key end,
        cancelEvent = effect('cancel'), getNumPlayerIndices = function() return r.numPlayers end,
        getNumIdentifiers = function(src) return #(r.ids[tonumber(src)] or {}) end,
        getIdentifierAt = function(src, index) return (r.ids[tonumber(src)] or {})[index + 1] end,
        wait = function(ms) r.record('wait', ms); return coroutine.yield(ms) end,
        doesPlayerExist = function(src) return r.exists[tonumber(src)] == true end,
        getResourceState = function() return r.hardcap end, stopResource = effect('stop-resource'),
    }
    function r.spawn(fn)
        local task = {co = coroutine.create(fn), source = r.currentSource}
        r.tasks[#r.tasks + 1] = task
        return task
    end
    native.spawn = r.spawn
    r.native = native
    r.library = {addPrincipal = effect('add-principal'), addAce = effect('add-ace'),
        removePrincipal = effect('remove-principal'), removeAce = effect('remove-ace'),
        print = {debug = effect('debug'), error = effect('error'), info = effect('info')}}
    r.logger = {log = effect('log')}
    local fixture = P.fixture()
    r.groups = {GetJob = function(name) return fixture.jobs[name] end, GetGang = function(name) return fixture.gangs[name] end}
    r.membership = H.load('kernel/shared/functions.lua', H.environment())({tableType = H.tableType, warn = effect('warn')})
    r.storage = {
        fetchBan = function(filter) r.record('fetch-ban', filter); return r.bans[filter.license] end,
        deleteBan = function(filter) r.record('delete-ban', filter); r.bans[filter.license] = nil end,
        insertBan = function(data) r.record('insert-ban', data); return r.banInsert ~= false, 'insert-refused' end,
        searchPlayerEntities = function(filters) r.record('search', filters); return r.search end,
        fetchGroupMembers = function(...) r.record('group-members', ...); return {{citizenid = 'A', grade = 0}} end,
        fetchUserByIdentifier = function(id) r.record('fetch-user', id); if r.userError then error('simulated user query error') end; return r.userId end,
        createUser = function(data) r.record('create-user', data) end,
        createUsersTable = effect('create-users-schema'),
    }
    r.players = {GetOfflinePlayer = function(id) r.record('get-offline', id); return r.offline[id] end,
        SaveAllPlayers = effect('save-all')}
    r.lookup = H.load('kernel/server/player_lookup.lua', H.environment())({core = r.core,
        getIdentifiers = function(src) return r.ids[tonumber(src)] or {} end})
    local newPromise
    newPromise = function()
        local p = {state = 0, subscribers = {}}
        local function dispatch(fn) r.spawn(fn) end
        local function settle(self, state, value)
            if self.state ~= 0 then return end
            self.state, self.value = state, value
            for _, fn in ipairs(self.subscribers) do dispatch(fn) end
            self.subscribers = {}
        end
        function p:resolve(value) settle(self, 1, value) end
        function p:reject(value) settle(self, 2, value) end
        function p:next(onOk, onError)
            local child = newPromise()
            local function proceed()
                local fn = self.state == 1 and onOk or onError
                if not fn then
                    if self.state == 1 then child:resolve(self.value) else child:reject(self.value) end
                    return
                end
                local ok, value = pcall(fn, self.value)
                if ok then child:resolve(value) else child:reject(value) end
            end
            if self.state == 0 then self.subscribers[#self.subscribers + 1] = proceed else dispatch(proceed) end
            return child
        end
        return p
    end
    r.newPromise = newPromise
    r.bindings = {core = r.core, native = native, config = r.serverConfig, notifyPosition = 'top',
        storage = r.storage, lookup = r.lookup, players = r.players, groups = r.groups, membership = r.membership,
        disablePersistence = effect('disable-persistence'), library = r.library, logger = r.logger, logging = r.logging,
        notify = effect('notify'), time = function() return r.now end,
        date = function() return {day = 1, month = 2, year = 2026, hour = 12, min = 30} end,
        resource = r.resource, globalState = r.globalState, newPromise = newPromise, clock = function() return r.now end,
        querySchema = effect('schema-query')}
    local env = H.environment({QBX = r.core, source = 0, GlobalState = r.globalState,
        cache = {resource = r.resource}, lib = r.library, MySQL = {query = r.bindings.querySchema},
        os = {time = r.bindings.time, date = r.bindings.date, clock = r.bindings.clock}, promise = {new = newPromise}})
    r.env = env
    local aliases = {SetPlayerRoutingBucket = 'setPlayerBucket', SetEntityRoutingBucket = 'setEntityBucket',
        TriggerEvent = 'emit', TriggerClientEvent = 'emitClient', IsPlayerAceAllowed = 'isAceAllowed',
        GetPlayerIdentifierByType = 'getIdentifier', GetResourceMetadata = 'getResourceMetadata',
        GetPlayerName = 'getPlayerName', DropPlayer = 'dropPlayer', DoesEntityExist = 'entityExists',
        DeleteEntity = 'deleteEntity', CreateThread = 'spawn', locale = 'locale', CancelEvent = 'cancelEvent',
        GetNumPlayerIndices = 'getNumPlayerIndices', GetNumPlayerIdentifiers = 'getNumIdentifiers',
        GetPlayerIdentifier = 'getIdentifierAt', Wait = 'wait', DoesPlayerExist = 'doesPlayerExist',
        GetResourceState = 'getResourceState', StopResource = 'stopResource'}
    for from, to in pairs(aliases) do env[from] = native[to] end
    env.TriggerClientEvent = function(name, src, ...)
        if name == 'ox_lib:notify' then r.record('notify', src, ...) else native.emitClient(name, src, ...) end
    end
    env.DisablePersistence = r.bindings.disablePersistence
    env.GetPlayerIdentifiers = function(src) return r.ids[tonumber(src)] or {} end
    env.GetPlayer = r.lookup.GetPlayer
    env.GetOfflinePlayer = r.players.GetOfflinePlayer
    env.GetJob, env.GetGang = r.groups.GetJob, r.groups.GetGang
    env.HasPlayerGotGroup, env.GetPlayerGroups = r.membership.HasPlayerGotGroup, r.membership.GetPlayerGroups
    env.SaveAllPlayers = r.players.SaveAllPlayers
    env.GetConvar = function() return r.queueEnabled == false and 'false' or 'true' end
    env.GetConvarInt = function() return r.maxPlayers end
    env.exports = function(name, fn) r.exported[name] = fn end
    function r.listen(name, fn, network) r.events[#r.events + 1] = {name = name, handler = fn, network = network == true} end
    env.AddEventHandler = function(name, fn) r.listen(name, fn) end
    env.RegisterNetEvent = function(name, fn) r.listen(name, fn, true) end
    env.require = function(name)
        if name == 'config.server' then return {server = r.serverConfig, logging = r.logging} end
        if name == 'config.shared' then return {notifyPosition = 'top', serverName = r.serverName} end
        if name == 'modules.logger' then return r.logger end
        if name == 'server.storage.main' then return r.storage end
        if name == 'server.queue' then return r.queue or false end
        if name == 'config.queue' then return r.queueConfig end
        error('Unexpected lifecycle import: ' .. tostring(name))
    end
    function r.install(module)
        for _, e in ipairs(module.Events) do r.listen(e.name, e.handler, e.network) end
        for name, fn in pairs(module.Exports) do r.exported[name] = fn end
    end
    function r.loadFunctions()
        if ported then r.functions = H.load('kernel/server/functions.lua', H.environment())(r.bindings); r.install(r.functions)
        else original('server/functions.lua', env); r.functions = r.exported end
    end
    function r.loadQueue()
        if ported then
            r.queueConfig = H.load('kernel/config/queue.lua', H.environment())({serverName = r.serverName, isAceAllowed = native.isAceAllowed})
        else r.queueConfig = original('config/queue.lua', env) end
        if r.queueConfigHook then r.queueConfigHook(r.queueConfig) end
        if ported then
            r.queue = H.load('kernel/server/queue.lua', H.environment())({enabled = r.queueEnabled, config = r.queueConfig,
                maxPlayers = r.maxPlayers, native = native, library = r.library, time = r.bindings.time})
            if r.queue then r.install(r.queue); assert(r.queue.Bootstrap() and not r.queue.Bootstrap()) end
        else r.queue = original('server/queue.lua', env) end
    end
    function r.loadEvents()
        if ported then
            local b = {}; for k, v in pairs(r.bindings) do b[k] = v end
            b.queue, b.functions = r.queue or false, r.functions
            r.eventModule = H.load('kernel/server/events.lua', H.environment())(b); r.install(r.eventModule)
        else original('server/events.lua', env) end
    end
    function r.dispatch(name, src, ...)
        r.currentSource = src; env.source = src
        for _, e in ipairs(r.events) do if e.name == name then
            if ported then e.handler(src, ...) else e.handler(...) end
        end end
    end
    function r.fork(fn, src)
        return {co = coroutine.create(fn), source = src or 0}
    end
    function r.step(task)
        r.currentSource, env.source = task.source, task.source
        local ok, result = coroutine.resume(task.co)
        return ok, result, coroutine.status(task.co)
    end
    function r.runTasks()
        local tasks = #r.tasks
        for i = 1, tasks do
            local task = r.tasks[i]
            if coroutine.status(task.co) ~= 'dead' then local ok, err = r.step(task); assert(ok, err) end
        end
    end
    function r.deferrals(label)
        return {defer = function() r.record('defer', label) end,
            done = function(reason) r.record('done', label, reason) end,
            presentCard = function(card) r.record('card', label, card) end}
    end
    function r.connect(label, src)
        r.connection = r.fork(function() r.dispatch('playerConnecting', src, label, nil, r.deferrals(label)) end, src)
        return r.step(r.connection)
    end
    function r.pump(count)
        for _ = 1, count or 8 do
            if r.connection and coroutine.status(r.connection.co) ~= 'dead' then
                local ok, err = r.step(r.connection); assert(ok, err)
            end
            r.runTasks()
        end
    end
    return r
end
function L.pair(domains)
    local a, b = L.new(false), L.new(true)
    for _, domain in ipairs(domains or {}) do a['load' .. domain](); b['load' .. domain]() end
    local p = {a = a, b = b, count = 0}
    function p.run(label, fn)
        local av, bv = table.pack(fn(a)), table.pack(fn(b))
        H.same(P.snapshot(bv), P.snapshot(av), label .. ': return')
        H.same(P.snapshot(b.trace), P.snapshot(a.trace), label .. ': effects')
        H.same(P.snapshot(b.core), P.snapshot(a.core), label .. ': core')
        H.same(b.globalState, a.globalState, label .. ': replicated state')
        p.count = p.count + 1
        return bv
    end
    return p
end
return L
