local M=dofile('tests/kernel_native_registration_harness.lua');local count=0
local function check(fn)fn();count=count+1 end
check(function()local r=M.new();r.resource='other';assert(not pcall(r.allocate));assert(r.calls==0)end)
check(function()local r=M.new();r.spec.side='client';assert(not pcall(r.allocate));assert(r.calls==0)end)
check(function()local r=M.new();local a=r.allocate();r.readyHook=function()a.Close()end;assert(not a.Open());assert(a.Progress().complete)end)
check(function()local r=M.new();local a=r.allocate();assert(a.Open());r.addHook=function()coroutine.yield()end
    local co=coroutine.create(function()a.Events.listen('late99',function()error('closed')end)end);assert(coroutine.resume(co));assert(not a.Close());assert(a.Progress().pending==1)
    assert(coroutine.resume(co));assert(r.bus[1].removed and a.Progress().complete)
end)
check(function()local r=M.new();local a=r.allocate();assert(a.Open());local t=a.Events.listen('retry99',function()error('closed')end)
    r.removeHook=function()return false end;assert(not a.Close());assert(a.Progress().listenerRemaining==1);r.fire('retry99',1)
    r.removeHook=nil;assert(a.Poll());assert(a.Events.remove(t))
end)
check(function()local r=M.new();local a=r.allocate();assert(a.Open());a.Events.listen('nested-close99',function()end)
    r.removeHook=function()assert(not a.Close())end;assert(a.Close())
end)
check(function()local r=M.new();local a=r.allocate();assert(a.Open());r.foreign['export:foreign99']=true
    assert(a.Public.publishExport('foreign99',function()end)==false and not r.published.foreign99)
end)
check(function()local r=M.new();local a=r.allocate();assert(a.Open());a.Events.listen('yield99',function()
    assert(a.Events.source()==44);coroutine.yield();assert(a.Events.source()==44);assert(not a.Close())
end)
    local co=coroutine.create(function()r.fire('yield99',44)end);assert(coroutine.resume(co));r.origin=0;assert(coroutine.resume(co));assert(a.Poll())
end)
check(function()local r=M.new();local a=r.allocate();assert(a.Open());a.Events.listen('error99',function()error('expected99')end)
    assert(not pcall(r.fire,'error99',56));r.origin=77;assert(a.Events.source()==77 and a.Progress().pending==0);assert(a.Close())
end)
check(function()local r=M.new();local a=r.allocate();assert(a.Open());r.availableHook=function()a.Close()end
    assert(a.Public.publishExport('closing99',function()end)==false and not r.published.closing99)
end)
check(function()local r=M.new();local a=r.allocate();assert(a.Open());r.publishHook=function()a.Close();return false end
    assert(a.Public.publishExport('uncertain99',function()error('closed')end)==false);assert(r.published.uncertain99()==nil)
    assert(a.Progress().publicWrappersRetained and not a.Open())
end)
check(function()local r=M.new('client');local a=r.allocate();assert(a.Open());r.current=false
    assert(a.Events.listen('stale99',function()end)==nil);assert(a.Close())
end)
check(function()local r=M.new();local a=r.allocate();assert(a.Open());r.addHook=function()error('lost token99')end
    assert(not pcall(a.Events.listen,'uncertain-event99',function()error('closed')end));assert(not a.Close());r.fire('uncertain-event99',1)
    assert(a.Progress().uncertainRegistrations==1 and not a.Progress().complete)
end)
assert(count==13);print('PASS lot99 scope:13 checks;side/resource/readiness,late registration,removal retry/reentry,source across yield,error restoration,foreign names,uncertain publication/registration and stale scope;all virtual')
