local T=dofile('tests/kernel_runtime_import_harness.lua');local r=T.context();local before=r.fixture.snapshot()
r.prepareImports();T.H.same(r.fixture.snapshot(),before,'client73 construction preserves graph footprint')
local native=r.api.Imports.NativeCache;local captures=0
for _,name in ipairs({'kernel.helpers','kernel.modules.lib','kernel.modules.utils','kernel.client.runtime_core',
    'kernel.client.main','kernel.client.events','kernel.client.loops','kernel.client.character_core','kernel.client.character_renderer','kernel.client.character'})do
    local p=assert(r.importCaptures[name],name);assert(p.cache==native,'one native cache captured before '..name);captures=captures+1
end;assert(captures==10)
assert(r.importCaptures['kernel.client.runtime_core'].locale==r.api.Imports.Translate and r.importCaptures['kernel.client.character'].locale==r.api.Imports.Translate)
assert(r.api.Context.Boundary.Cache~=native,'native cache never becomes passive PR projection')
assert(r.installImports());r.runtimeImports.pollNative();assert(r.api.Start(),'actual57 Start with explicit native/locale imports')
r.runtimeImports.ped=22;r.runtimeImports.pollNative();assert(native.ped==22)
local events=r.graph.Central.Parts.Runtime.Events
events.StateBags[1].handler('global',nil,true)
local effects=r.fixture.central.runtime.trace;local seen=false
for _,entry in ipairs(effects)do if entry.kind=='SetCanAttackFriendly'and entry.args[1]==22 then seen=true end end
assert(seen,'existing PVP consumer uses changed native ped')
r.runtimeImports.setLanguage('pt-br')
assert(r.importCaptures['kernel.client.runtime_core'].locale('error.not_online')==r.runtimeImports.env.locale('error.not_online'),'runtime and character share positional locale dictionary')
local data=r.fixture.state.PlayerData;data.citizenid='IMPORT73';data.metadata={health=190};data.money={cash=7}
r.graph.Central.Parts.Producers.Cache.Producer.player(data,'test')
assert(r.cacheDelivery.host.get('playerData').citizenid=='IMPORT73'and native.ped==22,'passive PlayerData and native cache remain separate')
r.api.Stop();r.clock.advance(120000);r.api.Poll();assert(r.api.Progress().complete,'same58 completes with imports cleanup window')
assert(#r.runtimeImports.threads==1 and #r.runtimeImports.handlers['ox_lib:setLocale']==1,'no duplicate native producer or locale subscription')
assert(not pcall(function()return native.ped end)and not pcall(r.api.Imports.Translate,'x'),'old runtime imports closed')
assert(r.cacheDelivery.host.get('playerData').citizenid=='IMPORT73','Stop preserves71 cache retention')
local pending=T.context();pending.prepareImports();assert(pending.installImports())
pending.runtimeImports.readHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(pending.api.Imports.NativeCache.pendingRead==false)end)
assert(coroutine.resume(co));assert(not pending.api.Stop())
assert(#pending.api.Progress().context.context.context.sequence.ledger==0,'imports pending captured before58 progress snapshot')
assert(coroutine.resume(co));pending.runtimeImports.readHook=nil
assert(pending.api.Poll()and pending.api.Progress().complete,'accepted native read drains before domain cleanup')
local translate=T.context();translate.prepareImports();assert(translate.installImports())
translate.runtimeImports.translateHook=function()coroutine.yield()end
local tr=coroutine.create(function()return translate.api.Imports.Translate('error.not_online')end)
assert(coroutine.resume(tr));assert(not translate.api.Stop());assert(coroutine.resume(tr));translate.runtimeImports.translateHook=nil
assert(translate.api.Poll()and translate.api.Progress().complete,'pending translation also postpones cleanup')
for _,change in ipairs({'owner','cache','locale','graph'})do
    local stale=T.context();stale.prepareImports();assert(stale.installImports());local imp=stale.api.Imports;local cache,locale=imp.NativeCache,imp.Translate
    if change=='owner'then stale.fixture.state.ClientRuntimeImportContext={}
    elseif change=='cache'then imp.NativeCache={}
    elseif change=='locale'then imp.Translate=function()return'x'end
    else stale.fixture.state.ClientDomainAssembly={}end
    assert(not stale.api.IsCurrent()and stale.surface.exports.GetPlayerData()==nil,change..' revokes public ingress')
    assert(not pcall(function()return cache.ped end)and not pcall(locale,'x'),change..' closes old imports')
    assert(not pcall(stale.api.Context.Boundary.Delivery.writeCache,'set','cash',1),change..' closes passive delivery too')
    assert(not pcall(stale.api.Context.Context.Config.Client.hasKeys,'ABC',42),change..' closes old config scope')
    assert(not stale.api.Stop()and not stale.api.Progress().complete,change..' stale Stop remains diagnostic')
end
local nativeStop=T.context();nativeStop.prepareImports();assert(nativeStop.installImports());assert(nativeStop.active('onResourceStop')==1)
nativeStop.emit('onResourceStop','forge-core');assert(nativeStop.api.Progress().complete,'one native Stop owns same16 cleanups')
local fail=T.context();fail.prepareImports();fail.surface.failAt=1
assert(not fail.installImports()and fail.api.Progress().imports.complete,'installation failure closes imports')
local stop=T.context();stop.prepareImports();assert(stop.installImports());stop.readyHook=function()stop.emit('onResourceStop','forge-core')end
local ok,value=pcall(stop.api.Start);assert(ok and value==false and stop.api.Progress().complete,'Stop during Start never reopens imports')
local registration=T.context();registration.prepareImports();registration.onListen=function()registration.api.Stop()end
assert(not registration.installImports()and registration.api.Progress().imports.complete,'Stop during registration closes imports')
local construction=T.context();construction.configuration.ports.vec4=function()error('virtual construction failure',0)end
assert(not pcall(construction.prepareImports)and construction.fixture.state.ClientRuntimeImportContext.Imports.Progress().complete)
print('PASS lot73 actual71/70/69/57/58/49:ten native-cache captures,runtime/character positional locale,passive cache separation,changed ped/Start,pending drain,stale/error/native Stop,16 cleanups;virtual only')
