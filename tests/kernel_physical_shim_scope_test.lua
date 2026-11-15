local T=dofile('tests/kernel_physical_shim_harness.lua');local count=0
local function check(fn)local r=T.new('client');fn(r);r.stopPhysical();r.finish();count=count+1 end
check(function(r)r.physicalName='wrong';assert(not pcall(r.loadPhysical)and next(r.published)==nil and #r.readPhysical==0)end)
check(function(r)r.forgeState='starting';assert(not pcall(r.loadPhysical)and #r.readPhysical==0)end)
check(function(r)r.gatewayReady=false;assert(not pcall(r.loadPhysical)and next(r.published)==nil)end)
check(function(r)r.physicalReadHook=function()error('missing local source')end;assert(not pcall(r.loadPhysical)and #r.physicalEvents==0)end)
check(function(r)r.physicalListenHook=function(token)token.fn('qbx_core')end;assert(not pcall(r.loadPhysical)and next(r.published)==nil);assert(r.physicalEvents[1].removed)end)
check(function(r)local n=0;r.physicalPublishHook=function()n=n+1;if n==2 then error('publish-failure105')end end
    assert(not pcall(r.loadPhysical));for _,fn in pairs(r.published)do assert(not pcall(fn))end;assert(r.api.IsCurrent())
end)
check(function(r)r.loadPhysical();r.refusePhysicalRemove=true;r.stopPhysical();assert(not r.physicalEvents[1].removed)
    assert(not pcall(r.published.GetJobs));r.refusePhysicalRemove=false;r.stopPhysical();assert(r.physicalEvents[1].removed)
end)
assert(count==7);print('PASS lot105 scope:7 physical-entry cases;identity/start/readiness/source failures,stop during listen,partial publication and removal retry;no native activation')
