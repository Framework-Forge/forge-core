-- Test-only Lua 5.4 harness. No inherited _G, IO, SQL, commands or real events.
local H = {}
local hostLoadfile = loadfile

function H.copy(value, seen)
    if type(value) ~= 'table' then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, item in pairs(value) do result[H.copy(key, seen)] = H.copy(item, seen) end
    return result
end

function H.same(actual, expected, where, seen)
    where = where or 'value'
    assert(type(actual) == type(expected), where .. ': different types')
    if type(actual) ~= 'table' then
        assert(actual == expected, where .. ': ' .. tostring(actual) .. ' ~= ' .. tostring(expected))
        return
    end
    seen = seen or {}
    if seen[actual] == expected then return end
    seen[actual] = expected
    for key, item in pairs(expected) do H.same(actual[key], item, where .. '.' .. tostring(key), seen) end
    for key in pairs(actual) do assert(expected[key] ~= nil, where .. ': unexpected key ' .. tostring(key)) end
end

-- Double for Cfx table.type. It is not a proof of native Cfx implementation.
function H.tableType(value)
    assert(type(value) == 'table')
    local numeric, hash, count, max = false, false, 0, 0
    for key in pairs(value) do
        count = count + 1
        if type(key) == 'number' and key > 0 and key % 1 == 0 then
            numeric = true
            max = math.max(max, key)
        else
            hash = true
        end
    end
    if count == 0 then return 'empty' end
    if numeric and not hash and max == count then return 'array' end
    return numeric and hash and 'mixed' or 'hash'
end

function H.environment(extra)
    local env = {
        assert = assert, error = error, type = type, pairs = pairs, ipairs = ipairs,
        next = next, tonumber = tonumber, tostring = tostring, select = select,
        pcall = pcall, xpcall = xpcall, setmetatable = setmetatable,
        getmetatable = getmetatable, rawget = rawget, rawset = rawset, rawequal = rawequal,
        string = H.copy(string), table = H.copy(table), math = H.copy(math),
    }
    env.table.type = H.tableType
    for key, value in pairs(extra or {}) do env[key] = value end
    return setmetatable(env, {__index = function(_, key)
        error('Unbound test boundary: ' .. tostring(key), 2)
    end})
end

function H.load(path, env)
    -- Only the harness can read files; the loaded code has no loader/IO access.
    return assert(hostLoadfile(path, 't', env))()
end

H.qbx = '../../../[qbx]/qbx_core/'

function H.groupsFixture()
    return {
        jobs = {unemployed = {label = 'Civilian', defaultDuty = true, offDutyPay = false,
            grades = {[0] = {name = 'Citizen', payment = 10}}}},
        gangs = {none = {label = 'None', grades = {[0] = {name = 'None'}}}},
    }
end

function H.groupRuntime(ported)
    local fixture = H.groupsFixture()
    local r = {out = {}, writes = {}, logs = {}, callbacks = {}, exported = {}, writeResult = true}
    local function record(kind, ...)
        r.out[#r.out + 1] = {kind = kind, args = H.copy(table.pack(...))}
    end
    local function log(...)
        r.logs[#r.logs + 1] = H.copy(table.pack(...))
    end
    local function save(kind, text)
        r.writes[#r.writes + 1] = {kind = kind, text = text}
        return r.writeResult
    end
    local env = H.environment()
    if ported then
        local factory = H.load('kernel/server/groups.lua', env)
        r.api = factory({jobs = fixture.jobs, gangs = fixture.gangs, logError = log,
            emitServer = function(...) record('server', ...) end,
            emitClient = function(...) record('client', ...) end, saveGroups = save})
        r.callbacks = r.api.Callbacks
    else
        env.require = function(name)
            if name == 'shared.jobs' then return fixture.jobs end
            if name == 'shared.gangs' then return fixture.gangs end
            error('Unbound require: ' .. tostring(name))
        end
        env.lib = {print = {error = log}, callback = {register = function(name, fn) r.callbacks[name] = fn end}}
        env.TriggerEvent = function(...) record('server', ...) end
        env.TriggerClientEvent = function(...) record('client', ...) end
        env.GetCurrentResourceName = function() return 'qbx_core' end
        env.SaveResourceFile = function(resource, path, text, size)
            assert(resource == 'qbx_core' and size == -1)
            local kind = ({['shared/jobs.lua'] = 'job', ['shared/gangs.lua'] = 'gang'})[path]
            assert(kind, 'Unexpected simulated path: ' .. tostring(path))
            return save(kind, text)
        end
        env.exports = function(name, fn)
            assert(not r.exported[name], 'Duplicate export ' .. name)
            r.exported[name] = fn
        end
        H.load(H.qbx .. 'server/groups.lua', env)
        r.api = r.exported
    end
    r.env, r.fixture = env, fixture
    return r
end

return H
