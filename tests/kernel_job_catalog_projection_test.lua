local J = dofile('tests/kernel_job_catalog_harness.lua')
local H, count = J.H, 0
local function case(label, action, options) J.case('projection', label, action, options); count = count + 1 end
local function seed(r)
    r.jobs = {police = {label = 'Police', jobtype = 'leo', defaultDuty = false, offDutyPay = true,
        stashes = {{id = 'duty'}}, owner = 'owner', grades = {['0'] = {name = 'Cadet', payment = 20},
            ['4'] = {name = 'Chief', payment = 100, isboss = false, bankAuth = false}}}}
    r.gangs = {ballas = {grades = {['0'] = {name = 'Member'}, ['7'] = {name = 'Boss'}}}}
end
case('missing registry', function(r) r.setRegistry(nil); return r.api.syncAll() end)
case('empty registry', function(r) return r.api.syncAll() end)
case('full payload', function(r)
    seed(r); assert(r.api.syncAll()); local jobs, gangs
    for _, entry in ipairs(r.trace) do
        if entry.kind == 'CreateJobs' then jobs = entry.args[1] end
        if entry.kind == 'CreateGangs' then gangs = entry.args[1] end
    end
    assert(jobs.police.type == 'leo' and jobs.police.defaultDuty == false and jobs.police.offDutyPay)
    assert(jobs.police.stashes == nil and jobs.police.owner == nil)
    assert(jobs.police.grades[4].isboss == false and jobs.police.grades[4].bankAuth == false)
    assert(gangs.ballas.grades[7].isboss and gangs.ballas.grades[7].bankAuth)
    return jobs, gangs
end)
for _, state in ipairs({'started', 'starting', 'stopped', 'missing'}) do
    case('readiness ' .. state, function(r) seed(r); r.state = state; return r.api.syncAll() end)
end
for _, method in ipairs({'CreateJobs', 'CreateGangs'}) do
    for _, result in ipairs({table.pack(false, 'rejected'), table.pack(nil), table.pack(0)}) do
        case(method .. ' ignored return', function(r) seed(r); r.results[method] = result; return r.api.syncAll() end)
    end
end
case('caught internal exception', function(r) seed(r); r.failures.CreateJobs = true; return r.api.syncAll() end)
case('remove previously tracked and keep protected', function(r)
    seed(r); r.jobs.unemployed = {grades = {}}; r.gangs.none = {grades = {}}
    r.api.syncAll(); r.jobs, r.gangs = {}, {}; assert(r.api.syncAll())
    local removed = {}
    for _, entry in ipairs(r.trace) do if entry.kind:match('^Remove') then removed[entry.args[1]] = true end end
    assert(removed.police and removed.ballas and not removed.unemployed and not removed.none)
    return r.api.syncAll()
end)
case('failed removal forgets tracking inherited', function(r)
    seed(r); r.api.syncAll(); r.jobs, r.gangs = {}, {}; r.results.RemoveJob = table.pack(false)
    assert(r.api.syncAll()); assert(not next(r.api.registeredJobs)); return r.api.syncAll()
end)
case('raw fields and named/negative grades', function(r)
    r.jobs = {odd = {offDutyPay = 'true', defaultDuty = 0, grades = {label = {name = 'Named'}, [-3] = {name = 'Negative'}}}}
    r.gangs = {}; return r.api.syncAll()
end)
case('malformed grade error inherited', function(r) r.jobs = {bad = {grades = {[0] = 4}}}; return r.api.syncAll() end)
print(('PASS job catalog projection: %d differential cases; internal payloads/removal/readiness plus inherited ignored failures/tracking'):format(count))
