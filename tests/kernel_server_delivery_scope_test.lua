local T=dofile('tests/kernel_server_delivery_harness.lua')
local r=T.provider();r.mount();assert(not pcall(r.api.Delivery.writeCache,'set','cash',1));assert(r.api.Open())
r.accessHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(r.api.Delivery.writeCache('set','cash',7))end)
assert(coroutine.resume(co));assert(r.api.Progress().pending==1);r.api.CloseIngress()
assert(not pcall(r.api.Cache.get,'cash'));assert(coroutine.resume(co))
assert(r.host.get('cash')==7,'accepted cache publication can finish after ingress closes')
r.accessHook=nil
r.api.DuringCleanup(function()assert(r.api.Cache.set('forge-core:session:self',{loaded=false}))end)
local foreign=coroutine.create(function()assert(not pcall(r.api.Cache.clear,'forge-core:session:self'))end)
r.api.DuringCleanup(function()assert(coroutine.resume(foreign))end)
assert(r.localCache.get('forge-core:session:self').loaded==false,'cleanup is coroutine-local and retains explicit owned result')
r.api.Close();assert(r.api.Progress().complete and not r.api.Open())
local stale=T.provider();stale.mount();assert(stale.api.Open());stale.current=false;local n=#stale.trace
assert(not pcall(stale.api.Cache.get,'player:1')and not pcall(stale.api.EmitLocal,'qbx_core:client:cacheChanged',{}))
assert(#stale.trace==n,'stale owner cannot read/write/emit through old boundary')
local failed=T.provider();failed.mount();assert(failed.api.Open());failed.failAccess=true
assert(not pcall(failed.api.Delivery.writeCache,'set','cash',9)and failed.api.Progress().pending==0)
failed.api.CloseIngress();assert(not pcall(failed.api.DuringCleanup,function()error('cleanup error',0)end))
assert(failed.api.Progress().cleanupWindows==0);failed.api.Close();assert(failed.api.Progress().complete)
local event=T.provider();event.mount();assert(event.api.Open());event.eventHook=function()coroutine.yield();return nil,false,17 end
local e=coroutine.create(function()local a,b,c=event.api.EmitLocal('accepted',1);assert(a==nil and b==false and c==17)end)
assert(coroutine.resume(e));event.api.Close();assert(not event.api.Progress().complete);assert(coroutine.resume(e));assert(event.api.Progress().complete)
print('PASS lot72 scope:pending writes/events,accepted late effects,closed reads/publications,stale owner,coroutine-local cleanup and error release;virtual only')
