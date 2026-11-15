local T=dofile('tests/kernel_shutdown_harness.lua');local r=T.new();r.prepareShutdown();assert(r.install())
local state=r.fixture.state
local oldExport=assert(r.surface.exports.GetPlayerData)
local callbacks=state.CallbackRegistration.Describe();assert(#callbacks==13)
for _,d in ipairs(callbacks)do assert(r.wire.client.find(r.wire.client.owners[d.protocol].EventName(d.name)),'real RPC lease installed')end
local keyDescriptors=state.StateInputRegistration.Describe().keys;assert(#keyDescriptors==2)
for _,d in ipairs(keyDescriptors)do assert(r.keys.provider.get(d.name),'actual owned PR key installed')end
local foreign=r.events.listen('foreign:event',function()r.foreign=true end)
local foreignStop=r.events.listen('onResourceStop',function()r.foreignStop=true end)
local objects=r.graph.Parts.Objects.Objects;local objectFixture=r.fixture.fixtures.Objects
r.graph.Parts.Objects.Subscriptions[1].handler({objects={{id=58,sceneId=1,model='X',coords={x=1,y=2,z=3}}}})
assert(objects.edit(58),'actual known object spawn/editor')
assert(next(objectFixture.entities)~=nil,'actual known object entity exists')
objectFixture.entities[9999]={foreign=true}
-- Real store consumer creates two owned targets, then actual teardown must remove both.
local store=r.graph.Parts.Stores.Stores
store.refresh({settings={enabled=true},stores={{id='shop58',label='Store58',type='general',enabled=true,
    coords={x=26,y=-1347,z=29},points={{id='p1',coords={x=26,y=-1347,z=29}},
        {id='p2',coords={x=27,y=-1347,z=29}}},inventory={},groups={}}}})
local zoneCount=0;for _ in pairs(store.zones)do zoneCount=zoneCount+1 end;assert(zoneCount==2,'actual store targets created')
local bagCount=0;for _ in pairs(r.keys.bags)do bagCount=bagCount+1 end;assert(bagCount==4)
local oldBag;for _,d in pairs(r.keys.bags)do if d.key=='PVPEnabled'then oldBag=d.handler end end
local snapshot=r.fixture.snapshot()
local reentered=false;r.onRemove=function()
    if not reentered then reentered=true;assert(oldExport()==nil,'public ingress closed before removals')end
end
assert(r.api.Stop(),'all real teardown handlers complete on cold quiescent context')
local progress=r.api.Progress();assert(progress.complete and #progress.errors==0 and #progress.ledger==16)
for _,v in ipairs(progress.ledger)do assert(v=='completed')end
assert(next(store.zones)==nil and next(r.keys.bags)==nil,'actual targets and owned bags removed')
for _,d in ipairs(callbacks)do assert(not r.wire.client.find(r.wire.client.owners[d.protocol].EventName(d.name)),'real RPC lease released')end
local entities=0;for _ in pairs(objectFixture.entities)do entities=entities+1 end
assert(entities==1 and objectFixture.entities[9999].foreign,'owned scene object removed, foreign entity retained')
for _,d in ipairs(keyDescriptors)do assert(r.keys.provider.get(d.name)==nil,'actual owned PR key removed')end
assert(oldExport()==nil);oldBag('global','PVPEnabled',true)
assert(r.active()==2 and not foreign.removed and not foreignStop.removed,'foreign listeners retained')
r.emit('foreign:event');r.emit('onResourceStop','forge-core');assert(r.foreign and r.foreignStop)
local effects=r.fixture.snapshot();r.api.Stop();r.api.Poll();T.H.same(r.fixture.snapshot(),effects,'no duplicate actual cleanup')
assert(state.ClientDomainAssembly==r.graph and state.ClientWorkerContext==r.worker,'same canonical state retained')
print('PASS lot58 real51-57 integration: ingress revoked, actual store targets/bags/keys/13 RPC leases disposed,16 teardown bodies once, foreign listeners retained; platform/IO virtual, no live stop')
