local Q=dofile('tests/kernel_skill_harness.lua')
local count=0
local function case(name,fn,options)Q.case(name,fn,options);count=count+1 end
case('cold construction',function(r)
    assert(not r.api.started and not r.api.schemaReady and #r.trace==0 and #r.workers==0)
    return true
end)
case('fetch full payload once',function(r)
    local ok,p=r.api.fetchPlayer(1);assert(ok and p.values.a==10 and p.values.r==5)
    assert(p.skills[2].xp==5 and p.values.unknown.legacy==42)
    return r.api.fetchPlayer(1)
end)
for _,state in ipairs({'missing','stopped','starting'})do
    case('readiness '..state,function(r)r.state=state;return r.api.fetchPlayer(1)end)
end
case('lookup exception swallowed',function(r)r.lookupError='lookup-failed';return r.api.fetchPlayer(1)end)
case('no player',function(r)r.cid=false;return r.api.fetchPlayer(1)end)
case('db not ready',function(r)r.dbReady=false;return r.api.fetchPlayer(1)end)
case('missing db',function(r)r.library.db=nil;return r.api.fetchPlayer(1)end)
case('malformed stored values',function(r)r.stored.cid1='bad';return r.api.fetchPlayer(1)end)
case('legacy data and cap archive',function(r)
    r.stored.cid1=r.m.codec.encode({a={Current=200},r={xp=12.34567},unknown=44})
    local ok,p=r.api.fetchPlayer(1);assert(ok and p.values.a==100 and p.values._previousCaps.a.Current==200)
    assert(r.api.flush(1));return p
end)
case('DDL failed acknowledgement retained',function(r)
    r.columnExists=0;r.updateResult=table.pack(false)
    local ok,p=r.api.fetchPlayer(1);assert(ok and r.api.schemaReady)
    return p
end)
case('DDL throws before schemaReady',function(r)r.columnExists=0;r.updateError='ddl-failed';return r.api.fetchPlayer(1)end)
case('select throws resolves failure',function(r)
    r.scalarHook=function(sql)if sql:find('SELECT `skills`',1,true)then error('read-failed',0)end end
    return r.api.fetchPlayer(1)
end)
for _,amount in ipairs({5,-100,1e6,0,0.123456,math.huge,-math.huge,0/0,'wrong'})do
    case('xp amount '..tostring(amount),function(r)return r.api.addXp(1,'a',amount)end)
end
case('VIP multiplier and normalized flag',function(r)
    r.multiplier=2;assert(r.api.addXp(1,'a',5));assert(r.api.getCurrentSkill(1,'a')==20)
    assert(r.api.addXp(1,'a',5,{normalizedXp=true}));assert(r.api.getCurrentSkill(1,'a')==25)
    return r.api.getCurrentLevel(1,'a'),r.api.getSkillInfo('a'),r.api.getCurrentSkill(1,'total')
end)
case('sum skill rejects direct awards',function(r)return r.api.addXp(1,'total',5)end)
case('unknown skill',function(r)return r.api.addXp(1,'missing',5)end)
case('disabled',function(r)r.registry.settings.enabled=false;return r.api.addXp(1,'a',5)end)
case('level gap produces mastery',function(r)
    assert(r.registry.upsertSkill({name='a',levels={{from=20,to=30}}}))
    return r.api.getCurrentLevel(1,'a')
end)
case('flush clean/mismatch/failure/retry/nil ack',function(r)
    assert(r.api.flush(1));assert(r.api.addXp(1,'a',2))
    assert(r.api.flush(1,'other'))
    r.updateResult=table.pack(false);assert(not r.api.flush(1))
    r.updateResult=table.pack(nil);assert(r.api.flush(1))
    return r.api.getCurrentSkill(1,'a')
end)
case('flush repeats if changed while saving',function(r)
    assert(r.api.addXp(1,'a',2))
    local changed=false
    r.updateHook=function()if not changed then changed=true;assert(r.api.addXp(1,'a',3))end end
    assert(r.api.flush(1));assert(r.api.getCurrentSkill(1,'a')==15)
    return true
end)
case('select rejects switched citizenid',function(r)
    r.scalarHook=function(sql)
        if sql:find('SELECT `skills`',1,true)then r.cid='cid2';return table.pack(nil)end
    end
    return r.api.fetchPlayer(1)
end)
case('concurrent fetch shares pending',function(r)
    local first=true
    r.scalarHook=function(sql)
        if first and sql:find('SELECT `skills`',1,true)then first=false;coroutine.yield('select')end
    end
    local a=coroutine.create(function()return r.api.fetchPlayer(1)end)
    local b=coroutine.create(function()return r.api.fetchPlayer(1)end)
    assert(coroutine.resume(a));assert(coroutine.status(a)=='suspended')
    assert(coroutine.resume(b));assert(coroutine.status(b)=='suspended')
    assert(coroutine.resume(a));local ok,got,p=coroutine.resume(b);assert(ok and got and p.values.a==10)
    return p
end)
case('CRUD permission and mutations',function(r)
    r.manage=false;local ok,err=r.api.upsertSkill(1,{name='new'});assert(not ok and err=='no_permission')
    r.manage=true;assert(r.api.upsertSkill(1,{name='new'}))
    assert(r.api.upsertReputation(1,{name='newrep',skill='new'}))
    local removed,reason=r.api.deleteSkill(1,'new');assert(not removed and reason=='skill_has_reputations')
    assert(r.api.deleteReputation(1,'newrep'));assert(r.api.deleteSkill(1,'new'))
    return r.api.getPayload()
end)
case('CRUD refused write keeps registry',function(r)
    local before=r.registry.export();r.m.onWrite=function()return false end
    local ok,err=r.api.upsertSkill(1,{name='new'});assert(not ok and err=='save_failed')
    Q.H.same(r.registry.export(),before);return ok,err
end)
case('CRUD publishes definitions to loaded session',function(r)
    assert(r.api.addXp(1,'a',1));assert(r.api.upsertSkill(1,{name='new'}))
    assert(r.packets[#r.packets].definitions.skills);return true
end)
case('reload keeps stale session values',function(r)
    assert(r.api.fetchPlayer(1));r.m.seed(r.config.Storage.file,{skills={a={maxXp=1}}})
    assert(r.api.reload());assert(r.api.getCurrentSkill(1,'a')==10)
    return r.api.fetchPlayer(1)
end)
case('start explicit idempotent',function(r)
    assert(r.api.start());assert(r.api.start());assert(#r.workers==1)
    r.workers[1]();return r.api.started,r.api.schemaReady
end)
case('start retries DB thirty times',function(r)
    r.dbReady=false;assert(r.api.start());r.workers[1]();return r.api.schemaReady
end)
case('start failed reload retains started',function(r)
    r.m.files[r.config.Storage.file]='broken'
    local ok=pcall(r.api.start);assert(not ok and r.api.started)
    return r.api.start()
end)
print('PASS skill server service differentials '..count)

