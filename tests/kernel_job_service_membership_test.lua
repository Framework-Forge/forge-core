local S = dofile('tests/kernel_job_service_harness.lua')
local H, count = S.H, 0
local function case(label, action, options) S.case(label, action, options); count = count + 1 end
local function rows(r, list) r.rows=list;return r.api.saveAndSync() end
for i,row in ipairs({
    {citizenid='A',group='taxi',type='job',grade=0},
    {citizenid='B',group='ballas',type='gang',grade='0'},
    {citizenid='C',group='gone',type='job',grade=3},
    {citizenid='D',group='gone',type='gang',grade=3},
    {citizenid='E',group='taxi',type='custom',grade=9},
    {citizenid='F',group='taxi',type='job',grade=-2},
    {citizenid='G',group='taxi',type='job',grade='bad'},
    {citizenid='H',group='taxi',type='job'},
}) do case('membership row '..i,function(r)return rows(r,{row})end) end
case('nearest grade and lowest',function(r)
    r.registry.setAll({taxi={grades={['2']={name='Junior'},['4']={name='Senior'},['8']={name='Chief'}}}}, {})
    return rows(r,{{citizenid='A',group='taxi',type='job',grade=6},{citizenid='B',group='taxi',type='job',grade=1}})
end)
case('empty named grades no fallback',function(r)
    r.registry.setAll({taxi={grades={named={name='Named'}}}},{});return rows(r,{{citizenid='A',group='taxi',type='job',grade=3}})
end)
case('string catalog grade remains valid',function(r)
    r.syncHook=function()r.nativeJobs={taxi={grades={['2']={name='String'}}}}end;r.syncResult=false
    return rows(r,{{citizenid='A',group='taxi',type='job',grade=2}})
end)
for _, state in ipairs({'stopped','starting','missing'}) do
    case('membership strict readiness '..state,function(r)r.state=state;return rows(r,{{citizenid='A',group='gone',type='job'}})end)
end
for _, missing in ipairs({'database','query','transaction'}) do
    case('missing '..missing,function(r)return r.api.saveAndSync()end,function(r)
        if missing=='database' then r.library.database=nil else r.library.database[missing]=nil end
    end)
end
case('catalog error caught',function(r)r.catalogError=true;return r.api.saveAndSync()end)
case('catalog invalid',function(r)r.syncResult=false;r.nativeJobs=false;return r.api.saveAndSync()end)
case('query invalid ignored',function(r)r.rows=false;return r.api.saveAndSync()end)
case('query throws not swallowed',function(r)r.queryError=true;return r.api.saveAndSync()end)
case('transaction failed ignored by caller',function(r)r.transactionResult=false;return rows(r,{{citizenid='A',group='gone',type='job'}})end)
case('combined changes one transaction',function(r)
    rows(r,{{citizenid='A',group='gone',type='job',grade=0},{citizenid='B',group='taxi',type='job',grade=9}})
    local tx;for _,e in ipairs(r.trace)do if e.kind=='transaction'then assert(not tx);tx=e.args[1]end end
    assert(tx and #tx==2 and tx[1].query:match('^DELETE') and tx[2].query:match('^UPDATE'));return tx
end)
local dutyFixtures={
    {{duty={enabled=true}}},{{enabled=false,duty={enabled=true}}},{{duty={enabled=false}}},
    {{duty=true}},{{duty={enabled='true'}}},{{duty={enabled=true}},{enabled=false,duty={enabled=true}}},
}
for i,stashes in ipairs(dutyFixtures) do
    case('duty point '..i,function(r)
        return r.api.upsert(0,{name='taxi',stashes=stashes,defaultDuty=true})
    end)
end
case('loaded and job timers',function(r)
    r.registry.upsert({name='taxi',stashes={{duty={enabled=true}}}})
    r.dispatch('QBCore:Server:OnPlayerLoaded',1)
    r.dispatch('QBCore:Server:OnJobUpdate',0,1)
    assert(#r.timers==2 and r.timers[1].ms==1500 and r.timers[2].ms==500)
    assert(r.players[1].PlayerData.job.onduty);r.runTimers();assert(not r.players[1].PlayerData.job.onduty)
end)
case('invalid source no duty',function(r)
    r.dispatch('QBCore:Server:OnPlayerLoaded',0);r.runTimers()
end)
case('no player before timer',function(r)
    r.dispatch('QBCore:Server:OnPlayerLoaded',8);r.runTimers()
end)
case('late timer affects new character inherited',function(r)
    r.registry.upsert({name='taxi',stashes={{duty={enabled=true}}}})
    r.dispatch('QBCore:Server:OnPlayerLoaded',1)
    r.players[1]={PlayerData={source=1,citizenid='NEW',job={name='taxi',onduty=true}}}
    r.runTimers();assert(r.players[1].PlayerData.job.onduty==false)
end)
case('duties optional adapter guards',function(r)
    r.registry.upsert({name='taxi',stashes={{duty={enabled=true}}}})
    r.dispatch('QBCore:Server:OnPlayerLoaded',1);r.runTimers();return r.api.upsert(0,{name='taxi',stashes={{duty={enabled=true}}}})
end,function(r)r.playerAccess.SetPlayerDuty=nil end)
print(('PASS JobService membership/duty: %d differential cases; exact SQL/grades/transaction/readiness and delayed duty with retained source-reuse behavior'):format(count))
