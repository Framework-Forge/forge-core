local T=dofile('tests/kernel_cache_delivery_harness.lua');local r=T.context();local before=r.fixture.snapshot()
r.prepareDelivery();T.H.same(r.fixture.snapshot(),before,'client71 construction inert');assert(#r.cacheDelivery.trace==0 and r.configConstructions==1)
local libraries=0;for name,library in pairs(r.boundLibraries)do
    assert(library.cache==r.api.Boundary.Cache,'one passive cache captured before consumer '..name);libraries=libraries+1
end;assert(libraries>=23,'all23 domain constructors plus central consumers captured')
assert(r.installDelivery());assert(r.api.Poll()==false,'Poll cannot initiate Stop')
local producer=r.graph.Central.Parts.Producers;local data=r.fixture.state.PlayerData
data.citizenid='C71';data.metadata={health=190,hunger=70};data.job={name='taxi'};data.jobs={taxi=0};data.money={cash=7,bank=12}
producer.Cache.Producer.player(data,'test')
local c=r.cacheDelivery;assert(c.host.get('playerData').citizenid=='C71'and c.host.get('cash')==7)
assert(c.host.get('resource:qbx_core:session').authenticated==true,'producer owns projection')
producer.Session.Session.setLoaded(true)
assert(c.host.get('playerLoaded')and c.localCache.get('forge-core:session:self').loaded,'session publication reaches canonical ForgeSession through same cache')
data.metadata.health=175;producer.Cache.Producer.status({health=75},{health=75})
assert(c.host.GetMetadata('health')==175 and c.host.GetPlayer().metadata.health==175)
data.job={name='police'};producer.Cache.Producer.player(data,'job')
assert(c.localCache.get('forge-core:session:self').job.name=='police','cacheChanged is explicitly emitted by producer')
c.host.clear();r.emit('onClientResourceStart','pr_bridge')
assert(c.host.get('playerData').citizenid=='C71'and c.host.get('playerLoaded'),'bridge start replays existing queue,not a framework pull')
producer.Session.Session.setLoaded(false)
assert(c.host.get('resource:qbx_core:session').authenticated==false and not c.localCache.get('forge-core:session:self').loaded)
c.localCache.set('foreign:keep',{value=1});c.localCache.set('forge-core:skills',{x=1})
for _,entry in ipairs(r.graph.Parts.Skills.Runtime.Events)do if entry.name=='QBCore:Client:OnPlayerUnload'then entry.handler()end end
assert(c.localCache.get('forge-core:skills')==nil,'installed skills unload clears the shared private projection')
c.localCache.set('forge-core:skills',{x=2});c.localCache.set('forge-core:world:test',{owned=true})
assert(r.api.Stop());local p=r.api.Progress();assert(p.complete and #p.context.context.sequence.ledger==16,'same58 cleanup with one cache projection')
assert(c.localCache.get('foreign:keep').value==1 and c.localCache.get('forge-core:world:test')==nil,'only explicit domain records cleaned')
assert(c.localCache.get('forge-core:skills').x==2,'skills has unload cleanup,not a new Stop handler')
assert(c.host.get('playerData').citizenid=='C71','Stop does not invent namespace cleanup')
local n=#c.trace;assert(not pcall(producer.Cache.Producer.player,data,'late')and #c.trace==n,'old producer cannot publish after close')
assert(r.active()==0 and r.surface.exports.GetPlayerData()==nil)
local pending=T.context();pending.prepareDelivery();assert(pending.installDelivery())
pending.cacheDelivery.accessHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(pending.api.Boundary.Delivery.writeCache('set','cash',8))end)
assert(coroutine.resume(co));assert(not pending.api.Stop())
assert(#pending.api.Progress().context.context.sequence.ledger==0,'pending cache call postpones cleanup before58 snapshot')
assert(coroutine.resume(co));pending.cacheDelivery.accessHook=nil;assert(pending.api.Poll()and pending.api.Progress().complete)
local event=T.context();event.prepareDelivery();assert(event.installDelivery())
event.cacheDelivery.eventHook=function()coroutine.yield();return'late'end
local e=coroutine.create(function()assert(event.api.Boundary.EmitLocal('accepted')=='late')end)
assert(coroutine.resume(e));assert(not event.api.Stop());assert(#event.api.Progress().context.context.sequence.ledger==0)
event.cacheDelivery.eventHook=nil;assert(coroutine.resume(e));assert(event.api.Poll()and event.api.Progress().complete,'pending local event postpones cleanup')
local started=T.context();started.prepareDelivery();assert(started.installDelivery());assert(started.api.Start(),'actual57 Start with one PR projection')
assert(started.cacheDelivery.host.get('serverId')~=nil)
started.api.Stop();started.clock.advance(120000);started.api.Poll();assert(started.api.Progress().complete)
for _,change in ipairs({'owner','cache','write','emit'})do
    local stale=T.context();stale.prepareDelivery();assert(stale.installDelivery());local publish=stale.api.Boundary.Delivery.writeCache
    if change=='owner'then stale.fixture.state.ClientDeliveryContext={}
    elseif change=='cache'then stale.api.Boundary.Cache={}
    elseif change=='write'then stale.api.Boundary.Delivery.writeCache=function()return true end
    else stale.api.Boundary.EmitLocal=function()return true end end
    assert(not stale.api.IsCurrent()and stale.surface.exports.GetPlayerData()==nil)
    assert(not pcall(publish,'set','cash',1)and not pcall(stale.api.Context.Context.Media.Native.GetSoundId),'old cache/media closures share71 authority')
    assert(not pcall(stale.api.Context.Config.Client.hasKeys,'ABC',42),'old configuration scope shares71 authority')
    assert(not stale.api.Stop()and not stale.api.Progress().complete)
end
local native=T.context();native.prepareDelivery();assert(native.installDelivery());assert(native.active('onResourceStop')==1)
native.emit('onResourceStop','forge-core');assert(native.api.Progress().complete,'one native stop cleans same58')
local staleNative=T.context();staleNative.prepareDelivery();assert(staleNative.installDelivery());staleNative.fixture.state.ClientDeliveryContext={}
assert(pcall(staleNative.emit,'onResourceStop','forge-core')and not staleNative.api.Progress().complete,'stale native Stop stays diagnostic')
local fail=T.context();fail.prepareDelivery();fail.surface.failAt=1;assert(not fail.installDelivery()and fail.api.Progress().boundary.complete)
local interrupt=T.context();interrupt.prepareDelivery();assert(interrupt.installDelivery())
interrupt.readyHook=function()interrupt.emit('onResourceStop','forge-core')end
local ok,value=pcall(interrupt.api.Start);assert(ok and value==false and interrupt.api.Progress().complete)
local registration=T.context();registration.prepareDelivery();registration.onListen=function()registration.api.Stop()end
assert(not registration.installDelivery()and registration.api.Progress().boundary.complete,'Stop during registration never reopens71')
local construction=T.context();construction.configuration.ports.vec4=function()error('virtual construction failure',0)end
assert(not pcall(construction.prepareDelivery)and construction.fixture.state.ClientDeliveryContext.Boundary.Progress().complete,'construction failure closes71')
print('PASS lot71 actual70/69/57/58/49:one producer/cache for player/status/session/job/replay;private domain cleanup,retained PR records,pending drain,stale/failure/native/start-stop guards;virtual only')
