local T=dofile('tests/kernel_server_delivery_harness.lua');local r=T.context();local f=r.fixture;local before=f.snapshot()
r.prepareDelivery();T.H.same(f.snapshot(),before,'server72 construction inert');assert(#r.cacheDelivery.trace==0)
local libraries=0;for name,library in pairs(r.boundLibraries)do
    assert(library.cache==r.api.Boundary.Cache,'one passive server cache captured before consumer '..name);libraries=libraries+1
end;assert(libraries>=18,'all18 server domains plus central consumers captured')
r.startDelivery();local pc=r.graph.PlayerCore;local c=r.cacheDelivery
local player=pc.Players.CheckPlayerData(2,{citizenid='S72A',license='license:test',userId=101})
local other=pc.Players.CheckPlayerData(3,{citizenid='S72B',license='license:three',userId=102})
assert(c.host.GetPlayer(2).citizenid=='S72A'and c.host.GetPlayer(3).citizenid=='S72B','loaded players project by source')
assert(not pc.State.Session.isLoaded(2)and f.base.ForgeSession.Session.isLoaded(2),'ForgeSession view is not normalized into core readiness')
player.Functions.SetMetaData('delivery72',55)
assert(c.host.GetMetadata(2,'delivery72')==55,'canonical metadata reaches passive PR projection')
local hunger=c.host.GetMetadata(2,'hunger');assert(player.Functions.SetStatus('hunger',55))
assert(c.host.GetMetadata(2,'hunger')==hunger,'status setter remains client-authorized,not fabricated server checkpoint')
local status=pc.State.Status.ProtocolSnapshot(2);status.hunger=55
r.emit('qbx_core:server:receiveStatusSnapshot',status,'periodic')
assert(c.host.GetMetadata(2,'hunger')==55,'identity-checked status acknowledgement projects into PR cache')
pc.State.Session.setLoaded(2,true)
assert(c.host.GetResourceState('qbx_core','session:2').loaded and c.host.get('player:2:loaded'))
assert(c.localCache.get('forge-core:session:2')==true,'explicit PlayerLoaded reaches private ForgeSession cache')
c.host.clear();r.emit('onResourceStart','pr_bridge')
assert(c.host.GetPlayer(2).citizenid=='S72A'and c.host.GetPlayer(3).citizenid=='S72B','bridge start replays existing server queue,not a framework pull')
local offline={Offline=true,PlayerData={source=4,citizenid='OFF'}};pc.Producers.Cache.Producer.player(offline)
assert(c.host.GetPlayer(4)==nil,'offline player never published')
r.emit('QBCore:Server:OnPlayerUnload',3)
assert(c.localCache.get('forge-core:session:3')==false and not pc.State.Session.isLoaded(3),'explicit unload reaches same ForgeSession cache')
c.localCache.set('foreign:keep',{value=1});c.localCache.set('forge-core:world:test',{owned=true})
r.api.Stop();r.clock.advance(1200000);r.api.Poll();assert(r.api.Progress().complete,'manual Stop completes with server cache cleanup')
assert(c.localCache.get('foreign:keep').value==1 and c.localCache.get('forge-core:world:test')==nil,'only owned server domain cleanup')
assert(c.localCache.get('forge-core:session:self').loaded==false and c.localCache.get('forge-core:session:2')==true,'Stop keeps installed self-only session cleanup')
assert(c.host.GetPlayer(2).citizenid=='S72A','Stop does not invent server namespace cleanup')
assert(not pcall(pc.Producers.Cache.Producer.player,player,'late'),'closed producer cannot publish')
assert(r.active('onResourceStop')==0 and r.surface.exports.GetJobs()==nil)
local pending=T.context();pending.prepareDelivery();assert(pending.deliveryInstall())
pending.cacheDelivery.accessHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(pending.api.Boundary.Delivery.writeCache('set','player:2:cash',8))end)
assert(coroutine.resume(co));assert(not pending.api.Stop())
assert(pending.fixture.base.ServerLifecycleContext.Progress().phase=='draining','pending cache captured before60/58 snapshot')
assert(coroutine.resume(co));pending.cacheDelivery.accessHook=nil;pending.clock.advance(1200000)
assert(pending.api.Poll()and pending.api.Progress().complete,'accepted publication drains before manual cleanup')
local event=T.context();event.prepareDelivery();assert(event.deliveryInstall())
event.cacheDelivery.eventHook=function()coroutine.yield();return'late'end
local e=coroutine.create(function()assert(event.api.Boundary.EmitLocal('accepted')=='late')end)
assert(coroutine.resume(e));assert(not event.api.Stop());event.cacheDelivery.eventHook=nil
assert(coroutine.resume(e));event.clock.advance(1200000);assert(event.api.Poll()and event.api.Progress().complete)
for _,change in ipairs({'owner','cache','write','emit','player','domain','config'})do
    local stale=T.context();stale.prepareDelivery();stale.startDelivery();local publish=stale.api.Boundary.Delivery.writeCache
    if change=='owner'then stale.fixture.base.ServerDeliveryContext={}
    elseif change=='cache'then stale.api.Boundary.Cache={}
    elseif change=='write'then stale.api.Boundary.Delivery.writeCache=function()return true end
    elseif change=='emit'then stale.api.Boundary.EmitLocal=function()return true end
    elseif change=='player'then stale.graph.PlayerCore.State.Players={}
    elseif change=='domain'then stale.graph.Parts.World={}
    else stale.fixture.base.ServerConfigurationContext.Config.Server.server={}end
    assert(not stale.api.IsCurrent()and stale.surface.exports.GetJobs()==nil and stale.surface.exports.registerHook('x',{})==nil,change..' stale ingress')
    assert(not pcall(publish,'set','player:2:cash',1),change..' stale cache')
    local events=#stale.media.events
    assert(stale.api.Context.Media.Audio.PlayNativeSound(2,{})==nil and #stale.media.events==events,change..' stale media')
    assert(not stale.api.Stop()and not stale.api.Progress().complete,change..' stale Stop diagnostic')
end
local native=T.context();native.prepareDelivery();native.startDelivery();assert(native.active('onResourceStop')==1)
native.emit('onResourceStop','forge-core');native.clock.advance(1200000);native.api.Poll()
assert(native.api.Progress().complete,'one native Stop cleans same60 with cache window')
local staleNative=T.context();staleNative.prepareDelivery();assert(staleNative.deliveryInstall());staleNative.fixture.base.ServerDeliveryContext={}
assert(pcall(staleNative.emit,'onResourceStop','forge-core')and not staleNative.api.Progress().complete)
local fail=T.context();fail.prepareDelivery();fail.dbReady=false
assert(not fail.deliveryInstall()and fail.api.Progress().boundary.complete,'preflight failure closes delivery')
local interrupt=T.context();interrupt.prepareDelivery();assert(interrupt.deliveryInstall())
interrupt.readyHook=function()interrupt.emit('onResourceStop','forge-core')end
interrupt.begin();if coroutine.status(interrupt.co)~='dead'then interrupt.resume()end;interrupt.clock.advance(1200000);interrupt.api.Poll()
assert(interrupt.api.Progress().complete,'Stop during Start cannot reopen delivery')
local registration=T.context();registration.prepareDelivery();registration.onListen=function()registration.api.Stop()end
assert(not registration.deliveryInstall()and registration.api.Progress().boundary.complete,'Stop during registration closes delivery')
local construction=T.context();construction.configurationPorts.shared.vec4=function()error('virtual construction failure',0)end
assert(not pcall(construction.prepareDelivery)and construction.fixture.base.ServerDeliveryContext.Boundary.Progress().complete,'construction failure closes delivery boundary')
print('PASS lot72 actual68/67/66/60/59/48:one server player/session/cache,metadata/replay/offline,owned cleanup and retained records,pending drain,stale/failure/native/start-stop guards;virtual only')
