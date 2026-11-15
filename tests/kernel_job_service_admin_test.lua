local S = dofile('tests/kernel_job_service_harness.lua')
local H, count = S.H, 0
local function case(label, action, options) S.case(label, action, options); count = count + 1 end
case('console permission', function(r) return r.canManage(0) end)
for _, state in ipairs({'started','starting','stopped','missing'}) do
    for _, result in ipairs({false,true}) do
        case('core permission ' .. state .. tostring(result), function(r) r.state = state; r.hasPermission = result; return r.canManage(1) end)
    end
end
for _, ace in ipairs({'forge-core.admin','command.config','admin'}) do
    case('ACE ' .. ace, function(r) r.aces[1] = {[ace] = true}; return r.canManage(1) end,
        function(r) r.command = 'config' end)
end
case('permission exception', function(r) r.permissionError = true; return r.canManage(1) end)
case('payload and target', function(r) r.api.sendTo(3); r.api.broadcast(); return r.api.getPayload() end)
case('payload without payments', function(r) return r.api.getPayload() end, function(r) r.services.JobPayments = nil end)
for _, result in ipairs({table.pack(false,'save_failed'),table.pack(false,'reconciliation_required'),table.pack(nil),table.pack(true),table.pack(1)}) do
    case('save ' .. tostring(result[1]) .. tostring(result[2]), function(r)
        r.saveResult = result
        local before = r.registry.jobs
        local draft = r.library.jsonDraft(r.registry,{jobs=true,gangs=true})
        r.registry.upsert({name = 'new'},nil,draft)
        local out = table.pack(r.api.save(draft))
        assert((r.registry.jobs == before) == not not (not result[1]))
        return out, r.api.save(draft)
    end)
end
case('save nil draft', function(r) return r.api.save() end)
case('saveAndSync order', function(r)
    local draft = r.library.jsonDraft(r.registry,{jobs=true,gangs=true})
    r.registry.upsert({name='police',defaultDuty=true,stashes={{duty={enabled=true}}}},nil,draft)
    assert(r.api.saveAndSync(draft)); assert(r.registry.jobs.police.defaultDuty == false)
    local order = {}; for _,e in ipairs(r.trace) do if ({save=true,sync=true,query=true,points=true,business=true,client=true})[e.kind] then order[#order+1]=e.kind end end
    H.same(order,{'save','sync','query','points','business','client'})
    return r.api.getPayload()
end)
case('failed save has no runtime publication', function(r)
    r.saveResult=table.pack(false,'save_failed'); local before=r.registry.jobs
    local draft=r.library.jsonDraft(r.registry,{jobs=true,gangs=true}); r.registry.upsert({name='new'},nil,draft)
    assert(not r.api.saveAndSync(draft)); assert(before==r.registry.jobs)
    for _,e in ipairs(r.trace) do assert(e.kind~='sync' and e.kind~='query' and e.kind~='client') end
    return r.api.getPayload()
end)
case('ignored sync refusal inherited', function(r) r.syncResult=false; return r.api.saveAndSync() end)
case('ignored reconcile refusal inherited', function(r) r.rows=false; return r.api.saveAndSync() end)
case('sync exception interrupts after commit', function(r) r.syncError=true; return r.api.saveAndSync() end)
case('reload batch incident refuses', function(r)
    r.memory.seed(r.config.Storage.jobsFile..'.incidents.json',{batch={error='fixture'}})
    return r.api.reload()
end)
case('reload without optional publishers', function(r) return r.api.reload() end,
    function(r) r.services.JobPayments=nil;r.services.JobPoints=nil;r.services.JobBusiness=nil end)
case('reload duty copy inherited', function(r)
    r.memory.seed(r.config.Storage.jobsFile,{police={name='police',defaultDuty=true,stashes={{duty={enabled=true}}}}})
    assert(r.api.reload()); assert(r.registry.jobs.police.defaultDuty==true,'getJobs defensive copy means installed reload rule does not commit change')
    return r.api.getPayload()
end)
case('reload ignores failed duty save inherited', function(r)
    r.memory.seed(r.config.Storage.jobsFile,{police={name='police',defaultDuty=true,stashes={{duty={enabled=true}}}}})
    r.saveResult=table.pack(false,'save_failed'); return r.api.reload()
end)
case('start once', function(r) assert(r.api.start());return r.api.start() end)
case('failed start stays started inherited', function(r)
    r.memory.files[r.config.Storage.jobsFile]='broken'
    assert(not pcall(r.api.start));assert(r.api.started);return r.api.start()
end)
case('upsert denied', function(r) return r.api.upsert(1,{name='new'}) end)
case('upsert invalid', function(r) return r.api.upsert(0,{name='!!!'}) end)
case('upsert new society', function(r) return r.api.upsert(0,{name='police',label='Police',stashes={{duty={enabled=true}}}}) end)
case('upsert existing no society', function(r) return r.api.upsert(0,{name='taxi',label='Taxi edited'}) end)
case('upsert gang no society', function(r) return r.api.upsert(0,{name='yacuza'},'gang') end)
case('upsert society unavailable allowed', function(r) return r.api.upsert(0,{name='new'}) end,function(r) r.library.banking=nil end)
for _, result in ipairs({table.pack(false,'denied'),table.pack(true,'created'),table.pack(nil)}) do
    case('society result '..tostring(result[1]),function(r)r.societyResult=result;return r.api.upsert(0,{name='new'})end)
end
case('society exception',function(r)r.societyError=true;return r.api.upsert(0,{name='new'})end)
case('upsert save failed account remains external',function(r)r.saveResult=table.pack(false);return r.api.upsert(0,{name='new'})end)
case('upsert notify remote',function(r)r.aces[1]={admin=true};return r.api.upsert(1,{name='new'})end)
case('delete denied',function(r)return r.api.delete(1,'job','taxi')end)
case('delete missing',function(r)return r.api.delete(0,'job','missing')end)
case('delete protected',function(r)return r.api.delete(0,'job','unemployed')end)
case('delete protected gang',function(r)return r.api.delete(0,'gang','none')end)
case('delete existing',function(r)return r.api.delete(0,'job','TAXI')end)
case('delete failure',function(r)r.saveResult=table.pack(false);return r.api.delete(0,'job','taxi')end)
case('whitespace protected bypass inherited',function(r)
    r.registry.upsert({name='unemployed'});r.seed()
    local ok=r.api.delete(0,'job',' unemployed ')
    assert(ok and not r.registry.exists('job','unemployed'));return ok
end)
print(('PASS JobService admin: %d differential cases, permissions/drafts/commit/order/incidents/society/publication and inherited reload/start/protected behavior'):format(count))
