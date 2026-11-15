-- Isolated fixtures for the installed QBX implementation and the private port.
local H = dofile('tests/kernel_harness.lua')
local P = {H = H}
local hostOpen, hostLoad = io.open, load

function P.source(file)
    local stream = assert(hostOpen(H.qbx .. file, 'rb'))
    local text = stream:read('a'); stream:close()
    return text
end

-- These are the only Cfx dialect forms in this slice. No source is changed.
function P.lua54(text)
    text = text:gsub('playerData%.(%w+)%?%.(%w+)', '(playerData.%1 and playerData.%1.%2)')
    text = text:gsub('validGroup%.grades%?%[group%.grade%]', '(validGroup.grades and validGroup.grades[group.grade])')
    text = text:gsub('([%w_.]+%b[])%s*%+=%s*([^\r\n]+)', '%1 = %1 + %2')
    text = text:gsub('([%w_.]+%b[])%s*%-=%s*([^\r\n]+)', '%1 = %1 - %2')
    text = text:gsub('([%w_.]+)%s*%+=%s*([^\r\n]+)', '%1 = %1 + %2')
    text = text:gsub('([%w_.]+)%s*%-=%s*([^\r\n]+)', '%1 = %1 - %2')
    return text
end

function P.loadOrigin(file, env, text)
    return assert(hostLoad(P.lua54(text or P.source(file)), '@' .. H.qbx .. file, 't', env))()
end

function P.snapshot(value, seen)
    if type(value) == 'function' then return '<function>' end
    if type(value) ~= 'table' then return value end
    seen = seen or {}
    if seen[value] then return '<cycle>' end
    seen[value] = true
    local result = {}
    for key, item in pairs(value) do result[key] = P.snapshot(item, seen) end
    seen[value] = nil
    return result
end

function P.vector(x, y, z, w)
    return {x = x, y = y, z = z, w = w, xyz = {x = x, y = y, z = z}}
end

function P.fixture()
    local groups = H.groupsFixture()
    groups.jobs.taxi = {label = 'Taxi', type = 'civ', defaultDuty = false,
        grades = {[0] = {name = 'Driver', payment = 50}, [1] = {name = 'Senior', payment = 100, isboss = true, bankAuth = true}}}
    groups.jobs.mechanic = {label = 'Mechanic', grades = {[0] = {name = 'Mechanic', payment = 60}}}
    groups.gangs.ballas = {label = 'Ballas', grades = {[0] = {name = 'Member'}, [1] = {name = 'Boss', isboss = true}}}
    local config = {money = {moneyTypes = {cash = 0, bank = 0, crypto = 0}, dontAllowMinus = {'cash', 'crypto'}},
        player = {bloodTypes = {'O+'}, identifierTypes = {}},
        logging = {webhook = {anticheat = 'mock', playermoney = 'mock', joinleave = 'mock'}, role = {'test'}},
        characterDataTables = {{'players', 'citizenid'}, {'player_groups', 'citizenid'}}}
    for _, kind in ipairs({'citizenid', 'PhoneNumber', 'AccountNumber', 'FingerId', 'WalletId', 'SerialNumber'}) do
        config.player.identifierTypes[kind] = {valueFunction = function() return 'AUTO_' .. kind end}
    end
    return groups, config
end

function P.new(ported)
    local r = {trace = {}, events = {}, tasks = {}, exported = {}, callbacks = {}, offline = {},
        users = {['license:test'] = 101}, memberships = {}, upsertResults = {},
        statuses = {}, statusRevision = 7, saveAttempts = 0, allowHooks = true, slotAllowed = true,
        state = {inApartment = false, inProperty = false}, pedExists = true, writeResult = true}
    local function record(kind, ...)
        r.trace[#r.trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))}
    end
    r.record = record
    local groups, config = P.fixture()
    r.config, r.groupData = config, groups
    local function getJob(name) return groups.jobs[name] end
    local function getGang(name) return groups.gangs[name] end
    local core = {Players = {}, Shared = {ForceJobDefaultDutyAtLogin = true}, Status = {}, BridgeCache = {}}
    r.core = core
    core.BridgeCache.player = function(player, reason) record('cache', player.PlayerData, reason) end
    core.Status = {
        Initialize = function(src, metadata) r.statuses[src] = H.copy(metadata); record('status-init', src, metadata) end,
        Remove = function(src) r.statuses[src] = nil; record('status-remove', src) end,
        RequestClientSnapshot = function(src) record('status-snapshot', src); return true end,
        PrepareSave = function(src) record('status-prepare', src); return r.statusRevision end,
        MarkSaved = function(src, revision) record('status-saved', src, revision); return revision == r.statusRevision end,
        IsStatusKey = function(key) return ({health = true, armor = true, hunger = true, thirst = true, oxygen = true, stress = true})[key] == true end,
        Set = function(src, key, value) record('status-set', src, key, value); return true end,
        Add = function(src, key, value) record('status-add', src, key, value); return true end,
        Get = function(src, key) return r.statuses[src] and r.statuses[src][key] end,
    }
    local platform = {
        getInvokingResource = function() return 'test-caller' end,
        getPlayerName = function(src) return 'Test ' .. tostring(src) end,
        getIdentifier = function(src, kind) return kind == 'license' and 'license:test' or nil end,
        getIdentifiers = function(src) return r.identifiers and r.identifiers[src] or {'license:test'} end,
        dropPlayer = function(...) record('drop', ...) end,
        locale = function(key) return key end,
        wait = function(ms)
            r.waitCount = (r.waitCount or 0) + 1
            assert(r.waitCount < 3000, 'Runaway wait/lock in test')
            record('wait', ms); if r.yielding then return coroutine.yield(ms) end
        end,
        emitClient = function(...) record('client', ...) end,
        emitServer = function(name, ...)
            record('server', name, ...)
            for _, fn in ipairs(r.events[name] or {}) do fn(...) end
        end,
        on = function(name, fn)
            r.events[name] = r.events[name] or {}; r.events[name][#r.events[name] + 1] = fn
            record('handler', name)
        end,
        thread = function(fn) r.tasks[#r.tasks + 1] = fn end,
        getPed = function(src) if r.pedError then error('mock ped failure') end; return r.pedExists and src or 0 end,
        setArmour = function(...) record('armour', ...) end,
        player = function() return {state = r.state} end,
        entityExists = function() return r.pedExists end,
        getCoords = function() return {x = 10, y = 20, z = 30} end,
        getHeading = function() return 90 end,
        vec4 = P.vector,
        time = function() return 1792320000 end,
    }
    r.platform = platform
    local logs = {}
    for _, name in ipairs({'error', 'warn', 'verbose', 'info', 'debug'}) do
        logs[name] = function(...) record('log-' .. name, ...) end
    end
    local library = {print = logs, callback = {await = function(...) record('callback', ...); return true end}}
    local storage = {
        fetchUserByIdentifier = function(id) record('fetch-user', id); return r.users[id] end,
        fetchPlayerEntity = function(id) record('fetch-player', id); return H.copy(r.offline[id]) end,
        fetchPlayerGroups = function(id)
            local data = r.memberships[id] or {jobs = {}, gangs = {}}
            return H.copy(data.jobs), H.copy(data.gangs)
        end,
        fetchIsUnique = function(kind, value) record('unique', kind, value); return true end,
        deletePlayer = function(id) record('delete', id); return r.writeResult end,
        upsertPlayerEntity = function(request)
            r.saveAttempts = r.saveAttempts + 1; record('upsert', request)
            if r.upsertHook then return r.upsertHook(request) end
            local result = table.remove(r.upsertResults, 1)
            if result == 'error' then error('mock database failure') end
            if result == 'false' then return false end
            return r.writeResult
        end,
    }
    for _, kind in ipairs({'Job', 'Gang'}) do
        storage['addPlayerTo' .. kind] = function(id, name, grade) record('add-' .. kind, id, name, grade) end
        storage['removePlayerFrom' .. kind] = function(id, name) record('remove-' .. kind, id, name) end
    end
    r.storage = storage
    local inventory = {}
    for _, name in ipairs({'AddItem', 'RemoveItem', 'GetSlot', 'GetSlotWithItem', 'GetSlotsWithItem', 'ClearInventory', 'SetItem'}) do
        inventory[name] = function(...)
            record('inventory-' .. name, ...)
            if name:match('^Get') then return {name = 'test', metadata = {test = true}, count = 2} end
            return true, 'inventory-result'
        end
    end
    local counters = {PlayerCount = 0}
    local utils = {math = {round = function(num, decimal)
        if not decimal then return math.floor(num + 0.5) end
        local power = 10 ^ decimal; return math.floor(num * power + 0.5) / power
    end}, table = {size = function(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end}}
    local slots = {canLoad = function(...) record('slot-check', ...); return r.slotAllowed, 'slot-denied' end,
        handleCharacterDeleted = function(...) record('slot-delete', ...) end}
    local hook = function(...) record('hook', ...); return r.allowHooks end
    local logger = {log = function(...) record('logger', ...) end}
    local env = H.environment()
    r.env, r.counters = env, counters
    local function originRegister(name, fn) r.exported[name] = fn end
    r.bindings = {core = core, config = config, defaultSpawn = P.vector(1, 2, 3, 4),
        storage = storage, groups = {GetJob = getJob, GetGang = getGang}, logger = logger,
        triggerHook = hook, characterSlots = slots, library = library, utils = utils, inventory = inventory,
        platform = platform, counters = counters, settings = {maxJobs = 2, maxGangs = 2,
            setJobReplaces = true, setGangReplaces = true, accounts = {'money'}}, resource = 'qbx_core'}
    if ported then
        r.lookup = H.load('kernel/server/player_lookup.lua', env)({core = core, getIdentifiers = platform.getIdentifiers})
        r.bindings.lookup = r.lookup
        r.api = H.load('kernel/server/player.lua', env)(r.bindings)
        r.callbacks = r.api.Callbacks
    else
        local map = {GetInvokingResource = 'getInvokingResource', GetPlayerName = 'getPlayerName', GetPlayerIdentifierByType = 'getIdentifier',
            GetPlayerIdentifiers = 'getIdentifiers', DropPlayer = 'dropPlayer', locale = 'locale', Wait = 'wait',
            TriggerClientEvent = 'emitClient', TriggerEvent = 'emitServer', AddEventHandler = 'on', CreateThread = 'thread',
            GetPlayerPed = 'getPed', SetPedArmour = 'setArmour', Player = 'player', DoesEntityExist = 'entityExists',
            GetEntityCoords = 'getCoords', GetEntityHeading = 'getHeading', vec4 = 'vec4'}
        for key, binding in pairs(map) do env[key] = platform[binding] end
        env.QBX, env.QBXCharacterSlots, env.lib, env.qbx = core, slots, library, utils
        env.os, env.cache, env.GlobalState = {time = platform.time}, {resource = 'qbx_core'}, counters
        env.GetJob, env.GetGang = getJob, getGang
        env.GetConvarInt = function() return 2 end
        env.GetConvar = function(key, default) return default end
        env.json = {decode = function(text) assert(text == '["money"]'); return {'money'} end}
        env.table.create = function() return {} end
        env.require = function(name)
            if name == 'config.server' then return config end
            if name == 'config.shared' then return {defaultSpawn = P.vector(1, 2, 3, 4)} end
            if name == 'modules.logger' then return logger end
            if name == 'server.storage.main' then return storage end
            if name == 'modules.hooks' then return hook end
            error('Unbound import ' .. tostring(name))
        end
        local ox = {}; for name, fn in pairs(inventory) do ox[name] = function(_, ...) return fn(...) end end
        env.exports = setmetatable({ox_inventory = ox}, {__call = function(_, ...) originRegister(...) end})
        library.callback.register = function(name, fn) r.callbacks[name] = fn end
        local prefix = P.source('server/functions.lua'):match('([%s%S]-)%-%- Routing buckets')
        assert(prefix, 'Lookup slice boundary changed')
        P.loadOrigin('server/functions.lua', env, prefix)
        r.lookup = {}; for name, fn in pairs(r.exported) do r.lookup[name] = fn end
        P.loadOrigin('server/player.lua', env)
        r.api = r.exported
        r.api.CheckPlayerData = env.CheckPlayerData
    end
    return r
end

function P.compare(a, b)
    H.same(P.snapshot(b.trace), P.snapshot(a.trace), 'trace')
    H.same(P.snapshot(b.counters), P.snapshot(a.counters), 'counters')
    local function players(runtime)
        local out = {}; for src, player in pairs(runtime.core.Players) do out[src] = P.snapshot(player) end; return out
    end
    H.same(players(b), players(a), 'players')
end

return P
