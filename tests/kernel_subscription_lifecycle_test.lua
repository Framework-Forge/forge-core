local T=dofile('tests/kernel_subscription_harness.lua');local r=T.new();r.prepare();r.api.Install()
local server=r.connect();local world=r.serverWorld.State
-- Actual public producers initialize explicitly only in this virtual integration fixture.
for _,name in ipairs({'Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack'})do
    local service=server.Parts[name].Service;if service.Initialize then service.Initialize()end;service.start()
end
server.Parts.World.Density.Service.start();server.Parts.CharacterAdmin.Exports.GetCharacterPreviews()
r.fixture.wire.playerSource=3
assert(r.world.refresh(),'actual PR snapshot hydrates same client world')
r.drain()
assert(r.graph.Parts.Stores.Stores.ready and r.graph.Parts.Stores.Stores.payload==r.graph.Client.Stores.payload,'snapshot reaches canonical store consumer')
assert(#r.graph.Parts.Stores.Stores.zones==2 and #r.logs>0,'actual first payload builds both store targets and records diagnostic')
local packet={generation=100,states={stores={generation=100,revision=1,data={settings={enabled=false},stores={},marker=1}}},ready=false}
-- Use a new generation newer than the initialized server clock.
packet.generation=world.getRecord('stores').generation+1;packet.states.stores.generation=packet.generation
local view=r.graph.Parts.Stores.Stores
assert(r.world.apply(packet));r.drain();assert(view.payload.marker==1,'generation reset clears then delivers latest payload')
local old=r.world.getRecord('stores')
assert(not r.world.apply({generation=old.generation-1,states={},ready=false}),'old generation still refused')
local stale=T.H.copy(packet);stale.states.stores.data.marker=99
assert(r.world.apply(stale));r.drain();assert(view.payload.marker==1,'same revision never replays subscription')
-- Serialized in-flight callbacks retain only the latest pending update: use a foreign diagnostic listener on real World.
local calls={};r.world.onChange('stores',function(value)
    calls[#calls+1]=value and value.marker or'stop'
    if value and value.marker==2 then r.clock.env.Wait(20)end
end)
local function nextValue(marker,revision)
    r.apply('stores',{settings={enabled=false},stores={},marker=marker},old.generation,revision)
end
nextValue(2,2);r.drain();nextValue(3,3);nextValue(4,4);r.drain(25)
assert(#calls==2 and calls[1]==2 and calls[2]==4 and view.payload.marker==4,'World serialization/latest-pending semantics preserved')
-- Replacing an actual descriptor owner revokes entry even though its World queue still dispatches.
local current=r.graph.Parts.Stores.Runtime.Subscriptions[1];local saved=current.handler
current.handler=function()error('foreign handler')end
nextValue(5,5);r.drain();assert(view.payload.marker==4,'changed descriptor invalidates installed lease')
current.handler=saved
assert(r.api.Dispose());local data=r.fixture.state.PlayerData;local stop
for _,d in ipairs(r.graph.Parts.World.World.Events)do if d.name=='onResourceStop'then stop=d.handler end end
stop('forge-core');r.drain();assert(r.world.getRecord('stores')==nil and r.fixture.state.PlayerData==data,'world stop is not player authority cleanup')
assert(view.payload.marker==4,'disposal revokes nil stop notifications, no extra consumer cleanup promised')
assert(calls[#calls]=='stop','foreign listener retains original nil stop notification')
print('PASS lot55 lifecycle: actual server48 producers/PR RPC/cache -> World50 subscriptions, reset/revision/latest-pending, descriptor replacement and stop; initializers explicit in virtual fixture only, no real SQL/FiveM')
