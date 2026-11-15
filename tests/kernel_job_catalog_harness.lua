-- Test-only: installed Forge files vs private factories. All runtime boundaries are explicit doubles.
local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local J = {P = P, H = H}
local files = {config = 'shared/job.lua', registry = 'server/job/registry.lua',
    storage = 'server/job/storage.lua', projection = 'server/job/qbx_sync.lua'}
local private = {config = 'kernel/config/forge_jobs.lua', registry = 'kernel/server/jobs/registry.lua',
    storage = 'kernel/server/jobs/storage.lua', projection = 'kernel/server/jobs/projection.lua'}

function J.config(ported, options)
    options = options or {}
    local trace, seed = {}, H.copy(options.seed or {})
    local function record(kind, ...) trace[#trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))} end
    local ports = {seed = seed, command = options.command, adminAce = options.adminAce,
        translate = function(...) record('translate', ...); return select(1, ...) end,
        getConvar = function(key, fallback)
            record('convar', key, fallback)
            if options.convars and options.convars[key] ~= nil then return options.convars[key] end
            return fallback
        end,
        vec3 = function(...) record('vec3', ...); return P.vector(...) end}
    local env = H.environment()
    local config
    if ported then config = H.load(private.config, env)(ports)
    else
        env.PR = {Job = seed, Command = options.command, AdminAce = options.adminAce}
        env.ForgeCore = {t = ports.translate}; env.GetConvar = ports.getConvar; env.vec3 = ports.vec3
        H.load(files.config, env); config = env.PR.Job
    end
    return {config = config, trace = trace, seed = seed, ports = ports}
end

function J.new(ported, domain, options)
    local r = {trace = {}, files = {}, results = {}, failures = {}, state = 'started',
        jobs = {}, gangs = {}, loadResult = {}, batchResult = table.pack(true), saveResult = table.pack(true)}
    r.config = J.config(true).config
    function r.record(kind, ...) r.trace[#r.trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))} end
    r.translate = function(key, params) r.record('translate', key, params); return key end
    r.library = {debug = {}}
    for _, level in ipairs({'info', 'warn', 'error'}) do
        r.library.debug[level] = function(...) r.record('log-' .. level, ...) end
    end
    r.library.loadJsonRecovery = function(path)
        r.record('load', path)
        if r.loadError then error(r.loadError, 0) end
        local result = r.loadResult[path]
        if result then return table.unpack(result, 1, result.n) end
        return H.copy(r.files[path])
    end
    r.library.saveJsonBatch = function(changes)
        r.record('batch', changes); return table.unpack(r.batchResult, 1, r.batchResult.n)
    end
    r.library.saveJsonRecovery = function(path, value)
        r.record('save', path, value); return table.unpack(r.saveResult, 1, r.saveResult.n)
    end
    r.registry = {
        getJobs = function() return H.copy(r.jobs) end,
        getGangs = function() return H.copy(r.gangs) end,
        list = function(kind)
            local values = {}; for _, item in pairs(kind == 'gang' and r.gangs or r.jobs) do values[#values + 1] = H.copy(item) end
            return values
        end,
    }
    r.groups = {}
    for _, method in ipairs({'CreateJobs', 'CreateGangs', 'RemoveJob', 'RemoveGang'}) do
        r.groups[method] = function(...)
            r.record(method, ...)
            if r.failures[method] then error('fixture-failure', 0) end
            local result = r.results[method]
            if result then return table.unpack(result, 1, result.n) end
            return true
        end
    end
    local function ready() r.record('ready'); return r.state:find('start') ~= nil end
    if options then options(r) end
    local env = H.environment()
    if ported then
        r.api = H.load(private[domain], env)({config = r.config, library = r.library,
            translate = r.translate, groups = r.groups, isReady = ready, getRegistry = function() return r.registry end})
    else
        env.PR = {Job = r.config}; env.ForgeCore = {t = r.translate, JobRegistry = r.registry}
        env.pr_lib = r.library
        env.GetCurrentResourceName = function() return 'forge-core' end -- unused legacy local, no behavior
        env.GetResourceState = function(name) assert(name == 'qbx_core'); r.record('ready'); return r.state end
        local legacy = {}
        for method, fn in pairs(r.groups) do legacy[method] = function(_, ...) return fn(...) end end
        env.exports = {qbx_core = legacy}
        H.load(files[domain], env)
        r.api = env.ForgeCore[({registry = 'JobRegistry', storage = 'JobStorage', projection = 'JobQbxSync'})[domain]]
        r.setRegistry = function(value) r.registry = value; env.ForgeCore.JobRegistry = value end
    end
    r.setRegistry = r.setRegistry or function(value) r.registry = value end
    r.env = env
    return r
end

local function outcome(action, runtime)
    local out = table.pack(pcall(action, runtime))
    if not out[1] then out[2] = tostring(out[2]):gsub('^.-:%d+: ', '') end
    return P.snapshot(out)
end

function J.case(domain, label, action, options)
    local a, b = J.new(false, domain, options), J.new(true, domain, options)
    H.same(outcome(action, b), outcome(action, a), label .. ': returns/error')
    H.same(b.trace, a.trace, label .. ': effects')
    if domain == 'registry' then
        H.same(P.snapshot(b.api), P.snapshot(a.api), label .. ': registry')
    elseif domain == 'projection' then
        H.same(b.api.registeredJobs, a.api.registeredJobs, label .. ': tracking jobs')
        H.same(b.api.registeredGangs, a.api.registeredGangs, label .. ': tracking gangs')
    end
end

function J.composition(base, ports)
    local env = H.environment({require = function(name)
        assert(name:match('^kernel%.server%.jobs%.[%w_]+$'), 'Unexpected composition import')
        return H.load(name:gsub('%.', '/') .. '.lua', H.environment())
    end})
    return H.load('kernel/server/jobs/catalog_core.lua', env)(base, ports)
end

-- The installed PR persistence code executes unchanged, with an in-memory file API.
-- Codec is a deterministic data double, not a test of a Cfx JSON parser or crash durability.
function J.persistence()
    local r = {files = {}, trace = {}, encoded = {}, fail = nil}
    local function encode(value, seen)
        if type(value) ~= 'table' then return type(value) .. ':' .. tostring(value) end
        seen = seen or {}; assert(not seen[value], 'cyclic fixture'); seen[value] = true
        local entries = {}
        for k, v in pairs(value) do entries[#entries + 1] = encode(k, seen) .. '=' .. encode(v, seen) end
        table.sort(entries); seen[value] = nil
        return '{' .. table.concat(entries, ',') .. '}'
    end
    r.codec = {
        encode = function(value)
            local bytes = encode(value); r.encoded[bytes] = H.copy(value); return bytes
        end,
        decode = function(bytes) assert(r.encoded[bytes] ~= nil, 'invalid fixture JSON'); return H.copy(r.encoded[bytes]) end,
    }
    function r.seed(path, value) r.files[path] = r.codec.encode(value) end
    local env = H.environment({json = r.codec, coroutine = coroutine, debug = {traceback = debug.traceback},
        os = {time = function() return 1792320000 end}, print = function(...) r.trace[#r.trace + 1] = {'log', ...} end,
        LoadResourceFile = function(resource, name)
            assert(resource == 'forge-core'); r.trace[#r.trace + 1] = {'read', name}; return r.files[name]
        end,
        SaveResourceFile = function(resource, name, bytes, size)
            assert(resource == 'forge-core' and size == #bytes)
            r.trace[#r.trace + 1] = {'write', name, bytes}
            local result = true
            if r.onWrite then result = r.onWrite(name, bytes) end
            if result == true or result == 1 then r.files[name] = bytes end
            return result
        end})
    r.api = {resource = 'forge-core'}
    H.load('../pr_bridge/bridge/persistence.lua', env)(r.api, function(path, extension, write)
        assert(extension == '.json' and write == true); return 'forge-core', path
    end)
    r.api.debug = {}
    return r
end

return J
