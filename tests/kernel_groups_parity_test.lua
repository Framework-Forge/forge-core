local H = dofile('tests/kernel_harness.lua')
local original, port = H.groupRuntime(false), H.groupRuntime(true)
local checks = 0
local function compareState()
    H.same(port.fixture, original.fixture, 'catalogs')
    H.same(port.out, original.out, 'events')
    H.same(port.writes, original.writes, 'simulated writes')
    H.same(port.logs, original.logs, 'logs')
end
local function call(name, ...)
    local args = table.pack(...)
    local a = table.pack(original.api[name](table.unpack(H.copy(args), 1, args.n)))
    local b = table.pack(port.api[name](table.unpack(H.copy(args), 1, args.n)))
    H.same(b, a, name .. ' returns')
    compareState()
    checks = checks + 1
    return b
end

for name in pairs(original.exported) do assert(type(port.api[name]) == 'function', 'Missing API ' .. name) end
assert(next(port.out) == nil and next(port.writes) == nil, 'Construction must be side-effect free for valid fixtures')
call('GetJobs'); call('GetGangs'); call('GetJob', 'missing'); call('GetGang', 'none')
call('CreateJob', nil, {}); call('CreateJob', '  ', {}); call('CreateJob', 'bad', false)
call('CreateJobs', false)
call('CreateJob', 'taxi', {label = 'Taxi', defaultDuty = true, offDutyPay = false,
    type = 'civ', grades = {[0] = {name = 'Driver', payment = 50}}}, false)
call('CreateJobs', {taxi = {label = 'New Taxi', defaultDuty = false,
    grades = {[0] = {name = 'Junior', payment = 40}, [1] = {name = 'Boss', payment = 90, isboss = true, bankAuth = true}}}}, true)
call('CreateJobs', {['  '] = {}}, false)
call('UpsertJobData', 'taxi', {label = "Taxi's \\ desk\nnew", defaultDuty = true, offDutyPay = false, type = 'civ'}, true)
call('UpsertJobData', 'mechanic', {label = 'Mechanic', defaultDuty = false, offDutyPay = true}, false)
call('UpsertJobGrade', 'missing', 0, {name = 'Missing', payment = 1}, true)
call('UpsertJobGrade', 'mechanic', 0, {name = 'Worker', payment = 75}, true)
call('RemoveJobGrade', 'missing', 0, true); call('RemoveJobGrade', 'taxi', 1, true)
call('CreateGangs', {ballas = {label = 'Ballas', grades = {[0] = {name = 'Member'}, [1] = {name = 'Leader', isboss = true}}}}, true)
call('UpsertGangData', 'ballas', {label = "Gang's\tName"}, true)
call('UpsertGangData', 'vagos', {label = 'Vagos'}, false)
call('UpsertGangGrade', 'missing', 0, {name = 'Missing'}, true)
call('UpsertGangGrade', 'vagos', 0, {name = 'Recruit'}, true)
call('RemoveGangGrade', 'missing', 0, true); call('RemoveGangGrade', 'ballas', 1, true)
call('RemoveJob', 1, true); call('RemoveJob', 'missing', true); call('RemoveJob', 'taxi', true)
call('RemoveGang', false, true); call('RemoveGang', 'missing', true); call('RemoveGang', 'ballas', true)

-- Preserve installed semantics: a write returning false is not currently surfaced.
-- Do not silently fix that behavior during a parity port; no actual file is written.
original.writeResult, port.writeResult = false, false
local result = call('CreateJob', 'write_failure', {label = 'Stored in memory', grades = {}}, true)
assert(result[1] == true and port.fixture.jobs.write_failure, 'Documented baseline semantics changed')
local cb = 'qbx_core:server:getGroups'
H.same(port.callbacks[cb](), original.callbacks[cb](), 'callback payload')
checks = checks + 1

local other = H.groupRuntime(true)
assert(other.api.GetJob('write_failure') == nil, 'Kernel instances must not share state')
assert(original.env.GroupType.JOB == port.api.GroupType.JOB and port.api.GroupType.GANG == 'gang')
assert(rawget(port.env, 'CreateJob') == nil and rawget(port.env, 'GroupType') == nil, 'Global namespace leaked')
assert(not pcall(function() return port.env.ExecuteCommand('quit immediately') end), 'Commands must be unavailable')
assert(not pcall(function() return port.env.io.open('should-not-exist', 'w') end), 'IO must be unavailable')
compareState()
print('PASS kernel groups: ' .. checks .. ' differential cases, state/events/returns/simulated persistence, isolation')
