local T=dofile('tests/kernel_qbx_delivery_harness.lua');local count=0
local function check(fn)local r=T.new('client');fn(r);r.package.Close();r.finish();count=count+1 end
check(function(r)r.readPackageHook=function()coroutine.yield()end
    local co=coroutine.create(function()assert(not pcall(r.package.Prepare))end);assert(coroutine.resume(co));assert(not r.package.Close())
    r.readPackageHook=nil;assert(coroutine.resume(co));assert(r.package.Progress().complete and next(r.published)==nil)
end)
check(function(r)r.compilePackageHook=function()r.package.Close()end;assert(not pcall(r.package.Prepare));assert(r.package.Progress().complete)end)
check(function(r)assert(r.package.Prepare());r.resource='foreign';assert(not pcall(r.package.AttachRelay,r.relayPorts));assert(next(r.published)==nil)end)
check(function(r)assert(r.package.Prepare());local c=r.package.AttachConsumer('script104',r.deliver.deliveryPorts)
    assert(c.Prepare());r.readPackageHook=function()r.package.Close()end;assert(c.Install());assert(not pcall(c.ExecuteEntry,'modules.lib'))
end)
check(function(r)assert(r.package.Prepare());r.packageCurrent=false;assert(not pcall(r.package.AttachRelay,r.relayPorts));assert(next(r.published)==nil)end)
check(function(r)assert(r.package.Prepare());local c=r.package.AttachConsumer('script104',r.deliver.deliveryPorts);assert(c.Prepare()and c.Install())
    assert(not pcall(c.ExecuteEntry,'../server/main'));assert(not pcall(r.package.AttachConsumer,'../another',r.deliver.deliveryPorts))
end)
check(function(r)assert(r.package.Prepare());r.relayPorts.getCurrentResourceName=function()coroutine.yield();return'qbx_core'end
    local co=coroutine.create(function()r.package.AttachRelay(r.relayPorts)end);assert(coroutine.resume(co))
    assert(not pcall(r.package.AttachRelay,r.relayPorts),'a second relay cannot enter while the first is being constructed')
    assert(coroutine.resume(co));assert(r.package.Progress().relay and next(r.published)==nil)
end)
check(function(r)assert(r.package.Prepare());r.relayPorts.getCurrentResourceName=function()coroutine.yield();return'qbx_core'end
    local co=coroutine.create(function()assert(not pcall(r.package.AttachRelay,r.relayPorts))end);assert(coroutine.resume(co));assert(not r.package.Close())
    assert(coroutine.resume(co));assert(r.package.Progress().complete and next(r.published)==nil)
end)
assert(count==8);print('PASS lot104 delivery scope:8 cases;Close during read/compile/entry/relay construction,foreign resource,stale package,duplicate/path/concurrent relay refusal;no manifest or operational writes')
