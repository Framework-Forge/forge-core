local T=dofile('tests/kernel_runtime_import_harness.lua');local r=T.provider();r.mount();assert(r.api.Open())
r.readHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(r.api.NativeCache.ped==false)end)
assert(coroutine.resume(co));assert(r.api.Progress().pending==1);r.api.CloseIngress()
assert(not pcall(function()return r.api.NativeCache.ped end)and not pcall(r.api.Translate,'x'))
assert(coroutine.resume(co));assert(r.api.Progress().pending==0,'accepted lazy read drains after close')
r.api.DuringCleanup(function()assert(r.api.NativeCache.resource=='forge-core')end)
local foreign=coroutine.create(function()assert(not pcall(r.api.Translate,'error.not_online'))end)
r.api.DuringCleanup(function()assert(coroutine.resume(foreign))end)
assert(not pcall(r.api.DuringCleanup,function()error('cleanup error',0)end)and r.api.Progress().cleanupWindows==0)
r.api.Close();assert(r.api.Progress().complete and not r.api.Open())
local event=T.provider();event.mount();assert(event.api.Open());event.translateHook=function()coroutine.yield()end
local e=coroutine.create(function()assert(event.api.Translate('error.not_online')~='error.not_online')end)
assert(coroutine.resume(e));event.api.Close();assert(not event.api.Progress().complete);assert(coroutine.resume(e));assert(event.api.Progress().complete)
local stale=T.provider();stale.mount();stale.current=false;local n=#stale.trace
assert(not pcall(function()return stale.api.NativeCache.ped end)and not pcall(stale.api.Translate,'x')and #stale.trace==n,'stale imports never call provider')
assert(#stale.threads==1,'ox owns the only native cache producer,not the view')
print('PASS lot73 scope:prepared/live/closed reads,late accepted reads/translations,pending/errors,coroutine-local cleanup,stale owner,no duplicate producer or provider cleanup')
