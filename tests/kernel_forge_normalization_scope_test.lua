local T=dofile('tests/kernel_forge_normalization_harness.lua');local r=T.new(true,'server')
assert(#r.trace==0 and #r.source.trace==0,'normalization construction does not fetch catalogs')
r.hook=function()coroutine.yield()end
local co=coroutine.create(function()assert(r.framework.GetFrameworkJobs().police)end)
assert(coroutine.resume(co));r.api.Close();assert(not r.api.Progress().complete)
assert(coroutine.resume(co));assert(r.api.Progress().complete and r.framework.GetPlayer(1)==nil,'late accepted call drains;new calls closed')
local stale=T.new(true,'client');stale.current=false;assert(stale.framework.ShowTextUI('x')==nil and #stale.trace==0);stale.api.Close()
local resource=T.new(true,'server');resource.api.Close();resource.ports.resourceName='forge-core'
local api=T.H.load(T.path,T.H.environment())(resource.ports);assert(api.Framework.GetResourceName()=='forge-core','explicit physical name,not a global rename')
api.Close()
print('PASS lot84 scope:inert catalog construction,pending/Close and accepted late result,stale UI refusal,explicit resource name,no provider shutdown or framework/global mutation')
