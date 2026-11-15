local T=dofile('tests/kernel_forge_native_host_harness.lua')
local r=T.new(true);assert(#r.calls==0,'host allocation inert');r.readyHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(not pcall(r.get))end)
assert(coroutine.resume(co));r.api.Close();assert(not r.api.Progress().complete)
assert(coroutine.resume(co));assert(r.api.Progress().complete and #r.calls==0,'no getter after closed readiness')
local late=T.new(true);late.getterHook=function()coroutine.yield()end
local cl=coroutine.create(function()assert(late.get()==late.object)end)
assert(coroutine.resume(cl));late.api.Close();assert(not late.api.Progress().complete)
assert(coroutine.resume(cl));assert(late.api.Progress().complete and late.object.Functions,'accepted native object is not revoked')
local stale=T.new(true);stale.current=false;assert(not pcall(stale.get)and #stale.calls==0);stale.api.Close()
print('PASS lot86 scope:readiness/getter await accounting,Close before getter,accepted native object retention,stale refusal;no host publication/global teardown')
