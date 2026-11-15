local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local function runtime(ported)
    local r = {trace = {}, responses = {}, codec = {}, serial = 0, commands = {}, threads = {}}
    local function record(kind, ...) r.trace[#r.trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))} end
    local json = {encode = function(value)
        r.serial = r.serial + 1; local token = 'json:' .. r.serial; r.codec[token] = H.copy(value); return token
    end, decode = function(token)
        if token == nil then return nil end
        local value = assert(r.codec[token], 'Unknown fixture JSON: ' .. tostring(token))
        return H.copy(value)
    end}
    r.json = json
    local db = {}
    for _, name in ipairs({'query', 'insert', 'single', 'scalar', 'transaction'}) do
        local function invoke(mode, sql, params)
            record(name .. mode, sql, params)
            local queue = assert(r.responses[name], 'Unbound database double: ' .. name)
            local response = assert(table.remove(queue, 1), 'Unexpected database call: ' .. name)
            if response.error then error(response.error) end
            return H.copy(response.value)
        end
        db[name] = setmetatable({await = function(...) return invoke('.await', ...) end},
            {__call = function(_, ...) return invoke('.call', ...) end})
    end
    local groups = P.fixture()
    local logs = {}; for _, name in ipairs({'error', 'warn', 'debug', 'info'}) do
        logs[name] = function(...) record('log-' .. name, ...) end
    end
    local options = {db = db, json = json, vec4 = P.vector, defaultSpawn = P.vector(1, 2, 3, 4),
        characterDataTables = {{'players', 'citizenid'}, {'player_groups', 'citizenid'}},
        log = logs, warn = function(...) record('warn', ...) end,
        emitServer = function(...) record('event', ...) end,
        date = function(format, timestamp) record('date', format, timestamp); return '2026-10-18 12:00:00' end,
        groups = {GroupType = {JOB = 'job', GANG = 'gang'}, GetJob = function(name) return groups.jobs[name] end,
            GetGang = function(name) return groups.gangs[name] end},
        addPlayerToJob = function(...) record('convert-job', ...) end,
        addPlayerToGang = function(...) record('convert-gang', ...) end,
        cleanPlayerGroups = false}
    local env = H.environment()
    -- Cfx vectors are not reported as tables. Exercise that constructor
    -- contract without requiring the FiveM host or creating real userdata.
    local ordinaryType = env.type
    env.type = function(value)
        if rawequal(value, options.defaultSpawn) then return 'vector4' end
        return ordinaryType(value)
    end
    if ported then
        r.api = H.load('kernel/server/storage.lua', env)(options)
        r.commands, r.bootstrap = r.api.Commands, r.api.PrepareSchema
    else
        env.require = function(name)
            if name == 'config.shared' then return {defaultSpawn = options.defaultSpawn} end
            if name == 'config.server' then return {characterDataTables = options.characterDataTables} end
            error('Unbound import ' .. tostring(name))
        end
        env.MySQL, env.json, env.vec4, env.os = db, json, P.vector, {date = options.date}
        env.GroupType, env.GetJob, env.GetGang = options.groups.GroupType, options.groups.GetJob, options.groups.GetGang
        env.AddPlayerToJob, env.AddPlayerToGang = options.addPlayerToJob, options.addPlayerToGang
        env.lib, env.warn, env.TriggerEvent = {print = logs}, options.warn, options.emitServer
        env.GetConvar = function() return options.cleanPlayerGroups and 'true' or 'false' end
        env.RegisterCommand = function(name, handler, restricted) r.commands[name] = {handler = handler, restricted = restricted} end
        env.CreateThread = function(fn) r.threads[#r.threads + 1] = fn end
        r.api = P.loadOrigin('server/storage/players.lua', env)
        assert(#r.threads == 1); r.bootstrap = r.threads[1]
    end
    r.env, r.options = env, options
    assert(#r.trace == 0, 'Construction must not execute database/bootstrap')
    return r
end
local a, b = runtime(false), runtime(true)
local checks = 0
local function responses(method, values)
    a.responses[method], b.responses[method] = H.copy(values), H.copy(values)
end
local function compare()
    H.same(b.trace, a.trace, 'storage trace'); H.same(b.codec, a.codec, 'codec values')
end
local function call(name, ...)
    local args = table.pack(...)
    local ar = table.pack(a.api[name](table.unpack(H.copy(args), 1, args.n)))
    local br = table.pack(b.api[name](table.unpack(H.copy(args), 1, args.n)))
    H.same(br, ar, name .. ' returns'); compare(); checks = checks + 1
    return br
end
responses('query', {{value = true}}); call('createUsersTable')
responses('insert', {{value = 101}}); call('createUser', {username = 'Example', license = 'license:test', discord = 'discord:test'})
responses('scalar', {{value = 101}}); call('fetchUserByIdentifier', 'license:test')
call('insertBan', {})
responses('insert', {{value = 1}}); call('insertBan', {name = 'Example', license = 'license:test', reason = 'mock', expiration = 1, bannedBy = 'mock'})
responses('single', {{value = {expire = 3, reason = 'mock'}}}); call('fetchBan', {license = 'license:test', discordId = 'ignored'})
responses('query', {{value = true}}); call('deleteBan', {ip = '127.0.0.1'})
local entity = {userId = 101, citizenid = 'A', charinfo = {cid = 1, firstname = 'Example'}, license = 'license:test',
    name = 'Example', money = {cash = 7, bank = 20}, job = {name = 'unemployed'}, gang = {name = 'none'},
    metadata = {hunger = 90}, lastLoggedOut = 1792320000}
responses('insert', {{value = 0}}); assert(call('upsertPlayerEntity', {playerEntity = entity, position = P.vector(5, 6, 7, 8)})[1] == true)
responses('insert', {{}}); assert(call('upsertPlayerEntity', {playerEntity = entity, position = P.vector(5, 6, 7, 8)})[1] == false)
responses('single', {{value = {model = 'model', skin = '{}'}}}); call('fetchPlayerSkin', 'A')

local function row(r, badPosition)
    return {userId = 101, citizenid = 'A', license = 'license:test', name = 'Example',
        charinfo = r.json.encode({cid = 1, firstname = 'Example'}), money = r.json.encode({cash = 1}),
        job = r.json.encode({name = 'unemployed'}), gang = r.json.encode({name = 'none'}),
        position = r.json.encode(badPosition and {} or {x = 8, y = 9, z = 10}), metadata = r.json.encode({hunger = 95}), lastLoggedOutUnix = 123}
end
local ar, br = row(a, true), row(b, true)
a.responses.single, b.responses.single = {{value = ar}}, {{value = br}}
local fetched = call('fetchPlayerEntity', 'A'); assert(fetched[1].position.x == 1 and fetched[1].position.w == 4)
responses('single', {{}}); call('fetchPlayerEntity', 'absent')
ar, br = row(a, false), row(b, false)
a.responses.query, b.responses.query = {{value = {ar}}}, {{value = {br}}}
local all = call('fetchAllPlayerEntities', nil, 'license:test'); assert(all[1][1].position.w == 4)
responses('query', {{value = {{citizenid = 'A'}}}})
call('searchPlayerEntities', {license = 'license:test', job = 'taxi', gang = 'ballas', charinfo = {firstname = 'Example', gender = 0},
    metadata = {strict = false, hunger = 70, isdead = false, callsign = 'TEST'}})
responses('single', {{value = {count = 0}}}); assert(call('fetchIsUnique', 'PhoneNumber', 'mock-phone')[1])
responses('single', {{value = {count = 1}}}); assert(not call('fetchIsUnique', 'citizenid', 'A')[1])
responses('insert', {{value = 1}}); call('addPlayerToJob', 'A', 'taxi', 0)
responses('insert', {{value = 1}}); call('addPlayerToGang', 'A', 'ballas', 1)
responses('query', {{value = {{group = 'taxi', type = 'job', grade = 0}, {group = 'ballas', type = 'gang', grade = 1},
    {group = 'missing', type = 'job', grade = 0}, {group = 'taxi', type = 'job', grade = 99}}}})
local membership = call('fetchPlayerGroups', 'A'); assert(membership[1].taxi == 0 and membership[2].ballas == 1)
responses('query', {{value = {{citizenid = 'A', grade = 0}}}}); call('fetchGroupMembers', 'taxi', 'job')
responses('query', {{value = true}}); call('removePlayerFromJob', 'A', 'taxi')
responses('query', {{value = true}}); call('removePlayerFromGang', 'A', 'ballas')
responses('single', {{value = {['COUNT(*)'] = 1}}, {value = {['COUNT(*)'] = 0}}})
responses('transaction', {{value = true}}); assert(call('deletePlayer', 'A')[1] == true)

local command = 'convertjobs'
assert(a.commands[command].restricted and b.commands[command].restricted)
a.commands[command].handler(1); b.commands[command].handler(1); compare(); checks = checks + 1
responses('query', {{value = {{citizenid = 'A', jobName = 'taxi', jobGrade = '0', gangName = 'ballas', gangGrade = '1'}}}})
a.commands[command].handler(0); b.commands[command].handler(0); compare(); checks = checks + 1
responses('query', {{value = {{group = 'missing', type = 'job', grade = 0}, {group = 'taxi', type = 'job', grade = 99}}}, {value = true}, {value = true}})
a.commands.cleanplayergroups.handler(0); b.commands.cleanplayergroups.handler(0); compare(); checks = checks + 1
responses('single', {{value = {['COUNT(*)'] = 1}}, {value = {['COUNT(*)'] = 1}}})
a.bootstrap(); b.bootstrap(); compare(); checks = checks + 1
a.options.cleanPlayerGroups, b.options.cleanPlayerGroups = true, true
responses('single', {{value = {['COUNT(*)'] = 1}}, {value = {['COUNT(*)'] = 1}}})
responses('query', {{value = {}}})
a.bootstrap(); b.bootstrap(); compare(); checks = checks + 1
assert(rawget(b.env, 'MySQL') == nil and rawget(b.env, 'RegisterCommand') == nil)
print('PASS kernel storage: ' .. checks .. ' differential cases; SQL/parameters/codecs/users/bans/groups/deletion, explicit inactive commands/bootstrap')
