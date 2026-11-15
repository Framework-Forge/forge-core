local J = dofile('tests/kernel_job_catalog_harness.lua')
local H, count = J.H, 0
local function case(label, action, options) J.case('storage', label, action, options); count = count + 1 end
case('missing files', function(r) return r.api.load(), r.api.loadPayments() end)
case('configured files and counts', function(r)
    r.files['fixture/jobs.json'] = {taxi = {name = 'taxi'}, police = {stashes = {{id = 'duty'}}}}
    r.files['fixture/gangs.json'] = {ballas = {name = 'ballas'}}
    return r.api.load()
end, function(r) r.config.Storage = {jobsFile = 'fixture/jobs.json', gangsFile = 'fixture/gangs.json'} end)
for _, value in ipairs({false, 0, 'scalar', {name = 'value'}}) do
    case('recovery value ' .. type(value), function(r)
        r.loadResult[r.config.Storage.jobsFile] = table.pack(H.copy(value), 'recovered_backup')
        r.loadResult[r.config.Payments.file] = table.pack(H.copy(value), 'recovered_backup')
        return r.api.load(), r.api.loadPayments()
    end)
end
case('corruption error', function(r) r.loadError = 'invalid fixture JSON and recovery copy'; return r.api.load() end)
case('batch preserves all fields', function(r) return r.api.save({taxi = {stashes = {{id = 'duty'}}}}, {ballas = {grades = {['4'] = {name = 'Boss'}}}}) end)
case('nil fallback batch', function(r) return r.api.save(nil, false) end)
case('batch error returns', function(r) r.batchResult = table.pack(false, 'reconciliation_required', nil, 3); return r.api.save({}, {}) end)
case('payments returns', function(r) r.saveResult = table.pack(true, {bytes = 20}, nil, 4); return r.api.savePayments({intervalMinutes = 15}) end)
case('payments nil fallback', function(r) return r.api.savePayments(nil) end)
case('without debug', function(r) return r.api.load() end, function(r) r.library.debug = nil end)
case('inherited function debug indexing error', function(r) return r.api.load() end, function(r) r.library.debug = function() end end)

-- Actual installed PR implementation: no native file API escapes this memory fixture.
local function storage(memory)
    return H.load('kernel/server/jobs/storage.lua', H.environment())({config = J.config(true).config,
        library = memory.api, translate = function(key) return key end})
end
local m = J.persistence(); local s = storage(m)
m.seed('data/jobs.json', {taxi = {name = 'taxi'}}); m.seed('data/gangs.json', {ballas = {name = 'ballas'}})
local oldJobs, oldGangs = m.files['data/jobs.json'], m.files['data/gangs.json']
assert(s.save({police = {}}, {yacuza = {}})); assert(m.files['data/jobs.json.bak'] == oldJobs and m.files['data/gangs.json.bak'] == oldGangs)
local jobs, gangs = s.load(); assert(jobs.police and gangs.yacuza)
m.files['data/jobs.json'] = 'broken'; jobs = s.load(); assert(jobs.taxi, 'recover installed backup rather than install defaults')
m.files['data/jobs.json.bak'] = 'broken too'; assert(not pcall(s.load))

for _, bool in ipairs({true, 1, false, 0, 'throw'}) do
    local fixture = J.persistence()
    fixture.onWrite = function() if bool == 'throw' then error('write failed', 0) end; return bool end
    local ok, reason = storage(fixture).savePayments({enabled = true})
    assert(ok == (bool == true or bool == 1)); if not ok then assert(reason == 'save_failed') end
end
local rollback = J.persistence(); local rs = storage(rollback)
rollback.seed('data/jobs.json', {oldJob = {}}); rollback.seed('data/gangs.json', {oldGang = {}})
local beforeJobs, beforeGangs = rollback.files['data/jobs.json'], rollback.files['data/gangs.json']
rollback.onWrite = function(path, bytes)
    if path == 'data/jobs.json' and bytes ~= beforeJobs then return false end
    return true
end
local ok, reason = rs.save({newJob = {}}, {newGang = {}})
assert(not ok and reason == 'save_failed')
assert(rollback.files['data/jobs.json'] == beforeJobs and rollback.files['data/gangs.json'] == beforeGangs, 'restore previously committed file')
rollback.onWrite = function(path, bytes)
    if path == 'data/jobs.json' and bytes ~= beforeJobs then return false end
    if path == 'data/gangs.json' and bytes == beforeGangs then return false end
    return true
end
ok, reason = rs.save({newJob = {}}, {newGang = {}})
assert(not ok and reason == 'reconciliation_required')
local journal = rollback.codec.decode(assert(rollback.files['data/gangs.json.incidents.json']))
assert(journal.batch and journal.batch.error == 'save_failed')

local lock = J.persistence()
local co = coroutine.create(function()
    return lock.api.withJsonLock('fixture.json', function()
        assert(lock.api.withJsonLock('fixture.json', function() return true end)) -- reentrant
        coroutine.yield('held'); return true
    end)
end)
local resumed, held = coroutine.resume(co); assert(resumed and held == 'held')
ok, reason = lock.api.withJsonLock('fixture.json', function() error('must not run') end)
assert(not ok and reason == 'busy'); assert(coroutine.resume(co))
assert(lock.api.withJsonLock('fixture.json', function() return true end))
assert(not pcall(function() lock.api.withJsonLock('fixture.json', function() error('fixture', 0) end) end))
assert(lock.api.withJsonLock('fixture.json', function() return true end), 'lock released after exception')
print(('PASS job catalog storage: %d differential cases; installed PR recovery, BOOL handling, rollback/journal and locks in memory only'):format(count))
