local T=dofile('tests/kernel_consumer_allocation_harness.lua');local count=0
local function one(fn)local r=T.new();fn(r);r.finish();count=count+1 end
one(function(r)r.localResource='foreign';assert(not pcall(r.allocate))end)
one(function(r)r.localServer=false;assert(not pcall(r.allocate))end)
one(function(r)r.allocate();r.pr.forgeRouting={foreign=true};assert(not pcall(r.allocation.Prepare)and r.pr.forgeConsumerOwner==nil)end)
one(function(r)r.allocate();r.allocationPorts.createRouting=function()r.allocation.Close();error('routing116')end
    assert(not r.allocation.Prepare()and next(r.pr)==nil and r.allocation.Progress().complete)end)
one(function(r)r.allocate();assert(r.allocation.Prepare());r.readiness=false;assert(not r.allocation.Attach()and next(r.pr)==nil)end)
one(function(r)r.allocate();assert(r.allocation.Prepare());r.pr.forgeNormalizedFacade={foreign=true}
    assert(not r.allocation.Attach()and r.pr.forgeNormalizedFacade.foreign)end)
one(function(r)r.allocate();assert(r.allocation.Prepare());r.normalHook=function()coroutine.yield('normal116')end
    local co=coroutine.create(function()assert(not r.allocation.Attach())end);assert(coroutine.resume(co));assert(not r.allocation.Close())
    assert(coroutine.resume(co));assert(r.allocation.Close()and r.allocation.Progress().complete)end)
one(function(r)r.allocate();assert(r.allocation.Prepare()and r.allocation.Attach());r.ox.refuseRemove=true
    assert(not r.allocation.Close()and not r.allocation.Progress().complete);r.ox.refuseRemove=false;assert(r.allocation.Close()and next(r.pr)==nil)end)
assert(count==8)
print('PASS lot116 eight native identity/side/foreign slots/partial construction/readiness/replacement/Close in-flight/removal retry cases')
