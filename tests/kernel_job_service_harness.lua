-- Test-only reference/port harness. No ambient IO/SQL/FiveM in loaded production code.
local J = dofile('tests/kernel_job_catalog_harness.lua')
local H, P = J.H, J.P
local S = {H = H, P = P, J = J}
function S.new(ported, options)
    local r = {trace = {}, events = {}, timers = {}, currentSource = 0, state = 'started',
        aces = {}, players = {}, connected = {'1','2','3'}, rows = {}, transactionResult = true,
        societyResult = table.pack(true, 'exists'), chargeResult = table.pack(true),
        refundResult = true, settings = {mei = {enabled = true, openingCost = 5000}},
        syncResult = true, saveResult = nil, points = true, business = true}
    function r.record(kind, ...) r.trace[#r.trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))} end
    r.memory = J.persistence()
    local config = J.config(true).config
    r.config = config
    r.registry = J.new(ported, 'registry').api
    r.registry.setAll({taxi = {label = 'Taxi', grades = {['0'] = {name = 'Driver', payment = 50}}}},
        {ballas = {label = 'Ballas', grades = {['0'] = {name = 'Member'}}}})
    local function seed()
        r.memory.seed(config.Storage.jobsFile, r.registry.getJobs())
        r.memory.seed(config.Storage.gangsFile, r.registry.getGangs())
    end
    r.seed = seed; seed()
    r.nativeJobs, r.nativeGangs = r.registry.getJobs(), r.registry.getGangs()
    local library = {}; for k,v in pairs(r.memory.api) do library[k] = v end
    r.library = library
    library.debug = {}
    for _, level in ipairs({'info','warn','error','success'}) do
        library.debug[level] = function(...) r.record('log-' .. level, ...) end
    end
    r.translate = function(key, args) r.record('translate', key, args); return key end
    library.notify = {NotifyPlayer = function(...) r.record('notify', ...) end}
    library.banking = {EnsureJobAccount = function(...)
        r.record('society', ...)
        if r.societyError then error('society-exception', 0) end
        return table.unpack(r.societyResult, 1, r.societyResult.n)
    end}
    library.database = {
        query = function(sql)
            r.record('query', sql)
            if r.queryError then error('query-exception', 0) end
            if r.queryHook then r.queryHook() end
            return H.copy(r.rows)
        end,
        transaction = function(queries) r.record('transaction', queries); return r.transactionResult end,
    }
    local batch = library.saveJsonBatch
    library.saveJsonBatch = function(changes)
        r.record('save', changes)
        if r.saveHook then r.saveHook(changes) end
        if r.saveResult then return table.unpack(r.saveResult, 1, r.saveResult.n) end
        return batch(changes)
    end
    local wrap = library.wrapJsonMutations
    library.wrapJsonMutations = function(path, service, names) r.record('wrap', path, names); wrap(path, service, names) end
    r.storage = H.load('kernel/server/jobs/storage.lua', H.environment())({config = config, library = library, translate = r.translate})
    r.projection = {syncAll = function()
        r.record('sync')
        if r.syncError then error('sync-exception', 0) end
        if r.syncHook then r.syncHook() end
        if r.syncResult then r.nativeJobs, r.nativeGangs = r.registry.getJobs(), r.registry.getGangs() end
        return r.syncResult
    end}
    r.payments = {
        getSettings = function() r.record('settings'); return H.copy(r.settings) end,
        chargeMeiOpening = function(player, settings)
            r.record('charge', player.PlayerData, settings)
            if r.chargeHook then r.chargeHook() end
            return table.unpack(r.chargeResult, 1, r.chargeResult.n)
        end,
        refundMeiOpening = function(player, settings) r.record('refund', player.PlayerData, settings); return r.refundResult end,
    }
    r.services = {JobRegistry = r.registry, JobStorage = r.storage, JobQbxSync = r.projection, JobPayments = r.payments,
        JobPoints = {registerAll = function() r.record('points') end},
        JobBusiness = {registerAll = function() r.record('business') end}}
    r.players[1] = {PlayerData = {source = 1, citizenid = 'A', job = {name = 'taxi', onduty = true}}}
    r.players[2] = {PlayerData = {source = 2, citizenid = 'B', job = {name = 'police', onduty = true}}}
    r.kernel = {
        GetJobs = function() r.record('getJobs'); if r.catalogError then error('catalog-exception', 0) end; return r.nativeJobs end,
        GetGangs = function() r.record('getGangs'); return r.nativeGangs end,
        HasPermission = function(src, permissions)
            r.record('permission', src, permissions); if r.permissionError then error('permission-exception', 0) end
            return r.hasPermission
        end,
        GetPlayer = function(src) r.record('getPlayer', src); return r.players[src] end,
        SetJob = function(src, name, grade)
            r.record('setJob', src, name, grade)
            if r.setJobError then error('set-job-exception', 0) end
            local player = r.players[src]; if player then player.PlayerData.job = {name = name, grade = {level = grade}} end
            return r.setJobResult
        end,
    }
    r.playerAccess = {
        GetAllPlayers = function()
            r.record('connected')
            local result = {}; for _, source in ipairs(r.connected) do result[#result + 1] = tonumber(source) end
            return result
        end,
        GetPlayerJob = function(src)
            r.record('player-job', src); local player = r.players[src]; return player and player.PlayerData.job or nil
        end,
        SetPlayerDuty = function(src, value)
            r.record('duty', src, value); local player = r.players[src]; if player then player.PlayerData.job.onduty = value == true end
            return true
        end,
    }
    r.native = {
        isAceAllowed = function(src, permission) r.record('ace', src, permission); return (r.aces[src] or {})[permission] == true end,
        emitClient = function(...) r.record('client', ...) end,
        setTimeout = function(ms, fn) r.record('timer', ms); r.timers[#r.timers + 1] = {ms = ms, fn = fn} end,
        getSource = function() return r.currentSource end,
        getPlayers = function() return r.connected end,
    }
    local function ready() r.record('ready-strict'); return r.state == 'started' end
    local function available() r.record('ready-available'); return r.state:find('start') ~= nil end
    if options then options(r) end
    local env = H.environment()
    if ported then
        r.api = H.load('kernel/server/jobs/service.lua', env)({config = config, services = r.services,
            library = library, translate = r.translate, kernel = r.kernel, playerAccess = r.playerAccess,
            native = r.native, isReady = ready, isAvailable = available, time = function() return 1792320000 end,
            command = r.command, adminAce = r.adminAce, notifyPosition = 'top-right'})
        r.events = r.api.Events
    else
        env.PR = {Job = config, Command = r.command, AdminAce = r.adminAce, NotifyPos = 'top-right'}
        env.ForgeCore = r.services; r.services.t = r.translate; env.pr_lib = library
        library.framework = r.playerAccess
        env.GetResourceState = function(name)
            assert(name == 'qbx_core')
            -- The two guards are read-only; distinguish by current method in the action.
            r.record(r.availabilityCheck and 'ready-available' or 'ready-strict'); return r.state
        end
        local qbx = {}; for name, fn in pairs(r.kernel) do qbx[name] = function(_, ...) return fn(...) end end
        env.exports = {qbx_core = qbx}
        env.IsPlayerAceAllowed, env.TriggerClientEvent, env.SetTimeout = r.native.isAceAllowed, r.native.emitClient, r.native.setTimeout
        env.os = {time = function() return 1792320000 end}
        env.RegisterNetEvent = function(name, handler) r.events[#r.events + 1] = {name = name, handler = handler, network = true} end
        env.AddEventHandler = function(name, handler) r.events[#r.events + 1] = {name = name, handler = handler, network = false} end
        env.source = 0
        H.load('server/job/service.lua', env); r.api = r.services.JobService
    end
    r.env = env
    function r.canManage(src) r.availabilityCheck = true; local result = table.pack(r.api.canManage(src)); r.availabilityCheck = false; return table.unpack(result, 1, result.n) end
    -- Methods call canManage internally; normalize only read-boundary tracing, not values/effects.
    function r.dispatch(name, src, ...)
        r.currentSource = src; if not ported then env.source = src end
        for _, event in ipairs(r.events) do if event.name == name then event.handler(...) end end
    end
    function r.runTimers() local timers = r.timers; r.timers = {}; for _, timer in ipairs(timers) do timer.fn() end end
    function r.stateSnapshot()
        return P.snapshot({jobs = r.registry.jobs, gangs = r.registry.gangs, revision = r.registry.revision,
            started = r.api.started, blocked = r.api.persistenceBlocked, incidents = r.api.incidents,
            players = r.players, files = r.memory.files, memory = r.memory.trace, events = r.events,
            nativeJobs = r.nativeJobs, nativeGangs = r.nativeGangs})
    end
    return r
end
local function normalizeTrace(trace)
    local out = H.copy(trace)
    for _, entry in ipairs(out) do if entry.kind == 'ready-strict' or entry.kind == 'ready-available' then entry.kind = 'ready' end end
    return out
end
function S.case(label, action, options)
    local a,b = S.new(false, options),S.new(true, options)
    local function run(r)
        local result = table.pack(pcall(action, r))
        if not result[1] then
            -- PR xpcall retains a traceback; compare the actual error, not migrated file/line paths.
            result[2] = tostring(result[2]):gsub('\nstack traceback:.*', ''):gsub('^.-:%d+: ', '')
        end
        return P.snapshot(result)
    end
    H.same(run(b), run(a), label .. ': return/error')
    H.same(normalizeTrace(b.trace), normalizeTrace(a.trace), label .. ': effects')
    H.same(b.stateSnapshot(), a.stateSnapshot(), label .. ': state/files')
end
function S.compose(base, ports)
    local env = H.environment({require = function(name)
        assert(name == 'kernel.server.jobs.service')
        return H.load('kernel/server/jobs/service.lua', H.environment())
    end})
    return H.load('kernel/server/jobs/service_core.lua', env)(base, ports)
end
return S
