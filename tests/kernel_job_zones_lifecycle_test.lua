local Z=dofile('tests/kernel_job_zones_harness.lua')
local total=0
for _,mode in ipairs({'points','business'})do
    local p=Z.pair(mode)
    p.run('initial '..mode,function(r)r.refresh()end)
    p.run('same access avoids refresh',function(r)r.dispatch('QBCore:Player:SetPlayerData');assert(#r.timers==0)end)
    p.run('duty omitted in signature',function(r)r.data.job.onduty=true;r.dispatch('QBCore:Player:SetPlayerData');assert(#r.timers==0)end)
    p.run('job grade change schedules once',function(r)r.data.job.grade={level=0};r.dispatch('QBCore:Player:SetPlayerData');r.dispatch('QBCore:Client:OnJobUpdate');assert(#r.timers==1)end)
    p.run('coalesced latest state',function(r)r.data.job.grade={level=4};r.flush();return #r.api.zones end)
    for _,event in ipairs({'QBCore:Client:OnJobUpdate','QBCore:Client:OnGangUpdate','esx:setJob','forge-core:client:jobPoints:refresh'})do
        p.run(event,function(r)r.dispatch(event);r.flush()end)
    end
    p.run('unload not observed, old zones retained',function(r)
        local before=#r.api.zones;r.dispatch('QBCore:Client:OnPlayerUnload');assert(#r.api.zones==before)
    end)
    p.run('stop other ignored',function(r)local n=#r.api.zones;r.dispatch('onResourceStop','other');assert(#r.api.zones==n)end)
    p.run('pending stop clears zones',function(r)r.api.refreshCurrent();r.dispatch('onResourceStop','forge-core');assert(#r.api.zones==0 and #r.timers==1)end)
    p.run('late timer recreates after stop inherited',function(r)r.flush();assert(#r.api.zones>0)end)
    p.run('invalid payload clears but retains lastPayload',function(r)local prior=r.api.lastPayload;r.api.refresh(nil);assert(r.api.lastPayload==prior and #r.api.zones==0)end)
    p.run('retained payload resurrects later',function(r)r.api.refreshCurrent();r.flush();assert(#r.api.zones>0)end)
    p.run('remove provider missing drops IDs leaving live zones',function(r)
        r.library.target.removeZone=nil;r.api.refresh(nil);assert(#r.api.zones==0 and next(r.zones)~=nil)
    end)
    total=total+p.count
    p=Z.pair(mode)
    p.run('removal exception keeps partial state',function(r)
        r.refresh();r.removeError=true;local ok=pcall(r.api.refresh,r.payload);assert(not ok);return ok
    end)
    p.run('timer error resets pending before failure',function(r)
        r.api.refreshCurrent();local ok=pcall(r.flush);assert(not ok and not r.api.refreshPending);return ok
    end)
    total=total+p.count
    p=Z.pair(mode,function(r)r.addHook=function()error('fixture-add',0)end end)
    p.run('creation exception preserves payload',function(r)local ok=pcall(r.refresh);assert(not ok and r.api.lastPayload==r.payload);return ok end)
    total=total+p.count
end
print('PASS '..total..' client zone lifecycle differential cases; exact debounce250/signature/events, no unload reset, late stop resurrection/provider failures retained')

