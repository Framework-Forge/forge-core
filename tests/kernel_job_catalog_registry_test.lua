local J = dofile('tests/kernel_job_catalog_harness.lua')
local H, count = J.H, 0
local function case(label, action) J.case('registry', label, action); count = count + 1 end
local samples = {
    {name = ' Police Unit! ', label = '  Police  ', typejob = 'leo',
        grades = {['0'] = {name = 'Cadet', payment = 10}, ['4'] = {name = 'Chief', isboss = false, bankAuth = false}},
        stashes = {{id = 'duty', type = 'dutyPoint', coords = {1, 2, 3}}, {id = 'stash'}},
        craftings = {1}, registers = {1}, alarms = {1}, bossMenus = {1}, applications = {1}, owner = 'owner'},
    {job = 'Ballas', type = 'gang', grades = {['1'] = {name = 'Member'}, ['9'] = {name = 'Boss'}}},
    {name = 'new', grades = {}}, {name = 'new', grades = false, stashes = false},
    {name = 123, label = 42, defaultDuty = false, offDutyPay = 'true', jobtype = 'none'},
    {name = 'odd', grades = {named = {name = 'Named'}, [-2] = {name = 'Negative'}}},
    {}, {name = '!!!'}, false, 3, 'bad',
    {name = 'malformed', grades = {['4'] = 9}},
}
for i, sample in ipairs(samples) do
    case('normalize ' .. i, function(r) return r.api.normalizeGroup(H.copy(sample)) end)
    case('upsert ' .. i, function(r) return r.api.upsert(H.copy(sample), i % 2 == 0 and 'gang' or nil) end)
end
case('nil group', function(r) return r.api.upsert(nil) end)
case('set maps and fallback names', function(r)
    r.api.setAll({Taxi = {label = 'Taxi', grades = {['0'] = {name = 'Driver'}}}, invalid = false},
        {{name = 'Ballas'}, {job = 'Yacuza'}})
    return r.api.payload(), r.api.exists('job', ' taxi '), r.api.get('gang', 'BALLAS')
end)
case('cycles and defensive copies', function(r)
    local cycle = {}; cycle.self = cycle
    r.api.setAll({taxi = {label = 'Taxi', metadata = cycle}}, {})
    local value = r.api.get('job', 'taxi')
    assert(value.metadata.self == value.metadata)
    value.label = 'Changed'; value.metadata.change = true
    assert(r.api.jobs.taxi.label == 'Taxi' and not r.api.jobs.taxi.metadata.change)
    local jobs = r.api.getJobs(); jobs.taxi.grades[0].payment = 999
    assert(r.api.jobs.taxi.grades[0].payment == 0)
    return r.api.payload()
end)
case('draft mutators do not commit', function(r)
    local draft = {jobs = {}, gangs = {}, revision = 20}
    local ok, result = r.api.upsert({name = 'Taxi'}, nil, draft)
    assert(ok and result == draft.jobs.taxi and r.api.revision == 0 and draft.revision == 21)
    result.label = 'Live return'; assert(draft.jobs.taxi.label == 'Live return')
    return r.api.remove('job', 'TAXI', draft), draft, r.api.payload()
end)
case('remove not found', function(r) return r.api.remove('gang', 'missing') end)
case('remove normalized', function(r)
    r.api.upsert({name = 'Taxi Unit'}); return r.api.remove('anything', ' taxi unit '), r.api.payload()
end)
case('list ordering and clone', function(r)
    r.api.setAll({a = {label = 'Zulu'}, b = {label = 'Alpha'}}, {z = {label = 'Gang'}})
    local list = r.api.list('job'); assert(list[1].name == 'b'); list[1].label = 'Mutated'
    return r.api.list('job'), r.api.list('gang'), r.api.getGangs(), r.api.exists('job', 'b')
end)
case('partial state on malformed gangs inherited', function(r)
    return r.api.setAll({taxi = {}}, {ballas = {grades = {['1'] = 4}}})
end)
case('scalar list entry error inherited', function(r) return r.api.setAll({7}, {}) end)
case('nil setAll', function(r) return r.api.setAll(nil, nil), r.api.payload() end)
case('forced type and default isolation', function(r)
    local value = r.api.normalizeGroup({name = 'one', type = 'gang'}, 'job')
    value.grades[0].name = 'Changed'
    assert(r.config.Defaults.job.grades[0].name ~= 'Changed')
    return r.api.normalizeGroup({name = 'two', type = 'job'}, 'gang')
end)
print(('PASS job catalog registry: %d differential cases; all ten APIs, drafts/cycles/copies/grades and inherited malformed-input behavior'):format(count))
