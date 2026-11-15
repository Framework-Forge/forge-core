local T=dofile('tests/kernel_locale_runtime_harness.lua');local r=T.server();local f=r.fixture;local before=f.snapshot()
r.allocate();T.H.same(f.snapshot(),before,'server74 allocation inert');assert(#r.locales.reads==0 and r.api.Graph==nil)
r.prepareImports('pt-br');assert(#r.locales.reads==2 and r.api.Graph and not r.api.Prepare(),'explicit locale Prepare before all server consumers')
local translate=r.api.Imports.Translate
assert(r.serverCaptures['kernel.server.player'].platform.locale==translate)
assert(r.serverCaptures['kernel.server.functions'].native.locale==translate)
assert(r.serverCaptures['kernel.server.commands'].locale==translate and r.serverCaptures['kernel.server.character'].locale==translate,'four server translator capture paths')
assert(r.serverCaptures['kernel.helpers'].cache==r.api.Imports.NativeCache and r.api.Imports.NativeCache.resource=='forge-core')
r.startImports();assert(r.active('ox_lib:setLocale')==1 and r.active('onResourceStop')==1)
assert(r.surface.exports.getLocale('error.not_online')==translate('error.not_online'),'installed locale export reaches local Forge dictionary')
local pc=r.graph.PlayerCore;pc.Players.CheckPlayerData(2,{citizenid='LANG74',license='license:test',userId=101})
pc.Players.SetMetadata(2,'languageTest',74);assert(r.cacheDelivery.host.GetMetadata(2,'languageTest')==74,'Player and passive cache72 unchanged')
r.emit('ox_lib:setLocale','en');assert(r.surface.exports.getLocale('error.not_online')=='Player not online','one owned locale event reloads local datasets')
r.emit('ox_lib:setLocale','pt-br');local retained=r.api.Locale.GetLocales()
r.api.Stop();r.clock.advance(1200000);r.api.Poll();assert(r.api.Progress().complete and r.active('ox_lib:setLocale')==0,'same60 cleanup retires only owned locale listener')
assert(retained['error.not_online']and r.surface.exports.getLocale('error.not_online')==nil and r.surface.exports.GetJobs()==nil)
local pending=T.server();pending.prepareImports('en');assert(pending.installImports())
pending.locales.readHook=function()coroutine.yield()end
local co=coroutine.create(function()pending.emit('ox_lib:setLocale','pt-br')end)
assert(coroutine.resume(co));assert(not pending.api.Stop());assert(pending.fixture.base.ServerLifecycleContext.Progress().phase=='draining','locale IO counted before60 snapshot')
pending.locales.readHook=nil;assert(coroutine.resume(co));pending.clock.advance(1200000)
assert(pending.api.Poll()and pending.api.Progress().complete,'pending local dictionary load drains before core cleanup')
for _,change in ipairs({'owner','locale','cache','player'})do
    local stale=T.server();stale.prepareImports();assert(stale.installImports());local fn=stale.api.Imports.Translate
    if change=='owner'then stale.fixture.base.ServerRuntimeImportContext={}
    elseif change=='locale'then stale.api.Locale.Translate=function()return'x'end
    elseif change=='cache'then stale.api.Imports.NativeCache={}
    else stale.graph.PlayerCore.State.Players={}end
    assert(not stale.api.IsCurrent()and stale.surface.exports.GetJobs()==nil and stale.surface.exports.getLocale('x')==nil)
    assert(not pcall(fn,'x')and not pcall(stale.api.Context.Boundary.Delivery.writeCache,'set','x',1))
    assert(not stale.api.Stop()and not stale.api.Progress().complete,'stale imports stay diagnostic')
end
local native=T.server();native.prepareImports();native.startImports();native.emit('onResourceStop','forge-core');native.clock.advance(1200000);native.api.Poll()
assert(native.api.Progress().complete and native.active('ox_lib:setLocale')==0,'native Stop shares74 cleanup ownership')
local collision=T.server();collision.prepareImports();collision.surface.exports.getLocale=function()return'foreign'end
assert(not collision.installImports()and collision.surface.exports.getLocale()=='foreign'and collision.api.Progress().locale.complete,'export collision preserves foreign registration')
local broken=T.server();broken.locales.override={en='{broken'};broken.allocate()
assert(not pcall(broken.api.Prepare)and broken.api.Graph==nil and broken.api.Progress().locale.complete,'bad locale never constructs graph')
local registration=T.server();registration.prepareImports();registration.onListen=function(entry)if entry.name=='ox_lib:setLocale'then registration.api.Stop()end end
assert(not registration.installImports()and registration.active('ox_lib:setLocale')==0,'listener received after interrupted registration retired')
local retainedListener=T.server();retainedListener.prepareImports();assert(retainedListener.installImports())
for _,entry in ipairs(retainedListener.bus)do if entry.name=='ox_lib:setLocale'then retainedListener.failRemove=entry end end
retainedListener.api.Stop();retainedListener.clock.advance(1200000);retainedListener.api.Poll()
assert(not retainedListener.api.Progress().complete and retainedListener.api.Progress().localeListenerRemaining,'failed physical removal stays diagnostic')
retainedListener.failRemove=nil;retainedListener.api.Poll();assert(retainedListener.api.Progress().complete)
print('PASS lot74 server72:explicit locale load before four consumers,one Player/cache/config,native cache separate,owned getLocale/event/pending before60,native/stale/foreign/cancel/error cleanup;virtual only')
