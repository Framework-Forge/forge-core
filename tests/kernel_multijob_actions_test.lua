local N=dofile('tests/kernel_multijob_harness.lua')
local function own(r,name,grade)
    r.players[1].PlayerData.metadata.multijob={{name=name or'taxi',grade=grade or 0,label='Taxi',addedAt=1}}
end
for _,target in ipairs({1,2,0,999,'1','bad'})do
    N.case('add target '..tostring(target),function(r)return r.api.addJob(1,target,'taxi',0)end)
end
N.case('admin add/clamp grade',function(r)return r.api.addJob(2,1,' TAXI ',999)end)
N.case('console add',function(r)return r.api.addJob(0,1,'taxi',0)end)
N.case('update stored even at capacity',function(r)own(r);r.api.settings={maxJobs=1};return r.api.addJob(2,1,'taxi',2)end)
N.case('capacity denied',function(r)own(r,'police');r.api.settings={maxJobs=1};return r.api.addJob(2,1,'taxi',0)end)
N.case('unlimited capacity',function(r)own(r,'police');r.api.settings={maxJobs=-1};return r.api.addJob(2,1,'taxi',0)end)
N.case('current does not consume stored quota',function(r)r.api.settings={maxJobs=1};return r.api.addJob(2,1,'taxi',0)end)
for _,name in ipairs({'','missing','unemployed','taxi'})do
    N.case('blocked/invalid add '..name,function(r)r.api.settings={blockedJobs={'taxi'}};return r.api.addJob(2,1,name,0)end)
end
N.case('disabled add',function(r)r.api.settings={enabled=false};return r.api.addJob(2,1,'taxi',0)end)
N.case('metadata setter nil acknowledges',function(r)
    r.skipMetadata=true
    local ok=r.api.addJob(2,1,'taxi',0);assert(ok and #r.players[1].PlayerData.metadata.multijob==0);return ok
end)
N.case('metadata setter false discarded by installed PR',function(r)r.metadataResult=false;r.skipMetadata=true;return r.api.addJob(2,1,'taxi',0)end)
N.case('metadata setter throws',function(r)r.metadataError=true;return r.api.addJob(2,1,'taxi',0)end)
N.case('concurrent metadata update overwritten',function(r)
    r.metadataHook=function()r.players[1].PlayerData.metadata.multijob={{name='police',grade=4}}end
    return r.api.addJob(2,1,'taxi',0)
end)
N.case('self remove allowed',function(r)own(r);return r.api.removeJob(1,999,'taxi',true)end)
N.case('self remove disabled',function(r)own(r);r.api.settings={allowPlayerRemove=false};return r.api.removeJob(1,1,'taxi',true)end)
N.case('remove other denied',function(r)own(r);return r.api.removeJob(1,2,'taxi',false)end)
N.case('admin remove',function(r)own(r);return r.api.removeJob(2,1,'taxi',false)end)
N.case('remove active retained in runtime/UI',function(r)
    own(r,'police');local ok,result=r.api.removeJob(1,1,'police',true)
    assert(ok and #r.players[1].PlayerData.metadata.multijob==0 and result.jobs[1].active);return ok,result
end)
N.case('remove blocked is not found',function(r)own(r);r.api.settings={blockedJobs={'taxi'}};return r.api.removeJob(1,1,'taxi',true)end)
N.case('remove missing',function(r)return r.api.removeJob(2,1,'taxi',false)end)
N.case('remove disabled',function(r)r.api.settings={enabled=false};return r.api.removeJob(2,1,'taxi',false)end)
N.case('remove invalid target',function(r)return r.api.removeJob(2,999,'taxi',false)end)
N.case('activate not owned',function(r)return r.api.setActiveJob(1,'taxi')end)
N.case('activate stored forces off at enabled duty point',function(r)own(r);return r.api.setActiveJob(1,'taxi')end)
N.case('activate current allowed',function(r)return r.api.setActiveJob(1,'police')end)
N.case('activate blocked',function(r)own(r);r.api.settings={blockedJobs={'taxi'}};return r.api.setActiveJob(1,'taxi')end)
N.case('activate disabled',function(r)r.api.settings={enabled=false};return r.api.setActiveJob(1,'police')end)
N.case('activate invalid player',function(r)return r.api.setActiveJob(999,'taxi')end)
N.case('activate prison metadata denial',function(r)own(r);r.players[1].PlayerData.metadata.injail=3;return r.api.setActiveJob(1,'taxi')end)
N.case('activate provider jailed denial',function(r)own(r);r.prisonState='started';r.prisonStatus={jailed=true};return r.api.setActiveJob(1,'taxi')end)
N.case('activate provider transition denial',function(r)own(r);r.prisonState='started';r.prisonStatus=nil;return r.api.setActiveJob(1,'taxi')end)
N.case('set failure code',function(r)own(r);r.setResult=table.pack(false,{code='denied'});return r.api.setActiveJob(1,'taxi')end)
N.case('set failure message',function(r)own(r);r.setResult=table.pack(false,{message='denied'});return r.api.setActiveJob(1,'taxi')end)
N.case('set nil considered failure',function(r)own(r);r.setResult=table.pack(nil);return r.api.setActiveJob(1,'taxi')end)
N.case('set exception caught',function(r)own(r);r.setError=true;return r.api.setActiveJob(1,'taxi')end)
N.case('duty false ignored',function(r)own(r);r.skipDuty=true;r.dutyResult=table.pack(false);return r.api.setActiveJob(1,'taxi')end)
N.case('duty exception caught but ignored',function(r)own(r);r.dutyError=true;return r.api.setActiveJob(1,'taxi')end)
N.case('disabled duty point not forced',function(r)own(r);r.jobs.taxi.stashes[1].enabled=false;return r.api.setActiveJob(1,'taxi')end)
N.case('malformed stash error after SetJob',function(r)own(r);r.jobs.taxi.stashes={'invalid'};return r.api.setActiveJob(1,'taxi')end)
N.case('permission revoked mid set not rechecked',function(r)own(r);r.setHook=function()r.players[1].PlayerData.metadata.injail=5 end;return r.api.setActiveJob(1,'taxi')end)
print('PASS multijob actions: '..N.count..' differential cases; ownership/quota/metadata/activation/duty/prison and inherited acknowledgement/race behavior, no real jobs/SQL')

