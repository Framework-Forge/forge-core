local R=dofile('tests/kernel_event_registration_harness.lua');local r=R.new();local before=r.server.snapshot();local a,c=r.prepare()
R.H.same(r.server.snapshot(),before,'server event preparation inert')
assert(a.Count==73 and c.Count==91 and #r.serverBus.trace==0 and #r.clientBus.trace==0)
assert(R.coverage(r.serverGraph,r.serverEntries)==73,'all reachable server event descriptors covered once')
local first,network,seen=0,0,{}
for _,d in ipairs(a.Describe())do
 first=first+(d.sourceFirst and 1 or 0);network=network+(d.network and 1 or 0)
 if d.owner=='Parts.Skills.Boundary'then seen[d.name]=d.network end
end
assert(first==33 and network==18,'explicit old/source-first versus new/payload policies')
assert(seen['forge-core:server:skills:initialize']==true and seen['qbx_core:server:progressionCheckpoint']==false,'Skills separate lists collected')
local pos={};for i,d in ipairs(a.Describe())do pos[d.owner]=pos[d.owner]or i end
assert(pos['PlayerCore.Runtime.Main']<pos['PlayerCore.Producers.Cache']and pos['PlayerCore.Producers.Cache']<pos['PlayerCore.Producers.Session']
 and pos['PlayerCore.Producers.Session']<pos['PlayerCore.Producers.Status']and pos['PlayerCore.Producers.Status']<pos['PlayerCore.Lifecycle.Events'],'QBX relative manifest order')
assert(pos['Parts.World.World']<pos['Parts.AutoMedic.Session']and pos['Parts.AutoMedic.Session']<pos['Central.Parts.Transport.Security']
 and pos['Central.Parts.Finance.Vip']<pos['Central.Parts.Weapons.Service']and pos['Central.Parts.Weapons.Service']<pos['Central.Parts.Inventory.Service']
 and pos['Parts.Farms']<pos['Parts.AutoMedic.Boundary']and pos['Parts.AutoMedic.Boundary']<pos['Parts.PlayerAdmin'],'Forge relative manifest order')
assert(a.Install()and r.serverBus.active()==73 and not a.Install())
local pc=r.serverGraph.PlayerCore;local src=31
pc.Players.CheckPlayerData(src,{citizenid='EVENT51',license='license:event51',userId=101,charinfo={firstname='Event',lastname='Test'}})
local session=pc.Producers.Session.Session
assert(not session.isLoaded(src))
r.serverBus.emit('QBCore:Server:OnPlayerLoaded',src)
assert(session.isLoaded(src),'injected network origin updates actual same session')
local auto=r.serverGraph.Parts.AutoMedic
auto.Service.deaths[src]={at=123};auto.Service.deaths[99]={at=321}
r.serverBus.emit('pr_bridge:server:OnPlayerUnloaded',99,src)
assert(auto.Service.deaths[src]==nil and auto.Service.deaths[99],'payload-only listener does not consume event source')
assert(auto.Session.Session.isLoaded(src)==false,'actual PR session view consumes payload origin')
r.serverBus.emit('qbx_core:server:onSetMetaData',0,'isdead',false,true,src)
assert(auto.Service.deaths[src],'same metadata event reaches different old/new argument conventions')
-- Exact removal source flag46, not payload spoofed as a different player.
local admin=r.serverGraph.Parts.CharacterAdmin.Service;admin.busy[src]=true;admin.busy[99]=true
-- Exercise only the actual bound46 wrapper; full playerDropped fans out into saving/SQL and is not a boot test.
local wrapper
for token,v in pairs(r.serverBus.records)do if v.name=='playerDropped'then
 local desc=a.Describe()[token.id];if desc.owner=='Parts.CharacterAdmin'then wrapper=v.handler end
end end
assert(wrapper);r.serverBus.origin=src;wrapper(99)
assert(admin.busy[src]==nil and admin.busy[99],'playerDropped46 receives true origin not payload')
local status=pc.State.Status;pc.State.Status={}
auto.Service.deaths[src]=nil;r.serverBus.emit('qbx_core:server:onSetMetaData',0,'isdead',false,true,src)
assert(auto.Service.deaths[src]==nil,'replaced producer authority blocks registration');pc.State.Status=status
local old=r.serverGraph.Parts.Access;r.serverGraph.Parts.Access={}
auto.Service.deaths[src]=nil;r.serverBus.emit('qbx_core:server:onSetMetaData',0,'isdead',false,true,src)
assert(auto.Service.deaths[src]==nil,'replaced domain blocks installed wrappers');r.serverGraph.Parts.Access=old
assert(a.Dispose()and r.serverBus.active()==0 and not a.Install())
assert(r.serverGraph.Unbound and not a.StartedServices and c.State=='prepared-inactive','event install is not service/RPC/framework activation')
local enabled=R.T.new();enabled.server.central.ports.lifecycle.queue.enabled=true
local graph=enabled.server.mount();local bus=R.bus();local queue=R.H.load('kernel/server/event_registration.lua',R.env())(graph,bus.ports)
assert(queue.Count==74 and #bus.trace==0,'enabled queue descriptor collected without Bootstrap/hardcap action')
local found=false;for _,d in ipairs(queue.Describe())do if d.owner=='PlayerCore.Lifecycle.Queue'then found=d.name=='onResourceStarting'and d.sourceFirst end end
assert(found,'real queue event preserves origin signature')
print('PASS lot51 server: 73 actual event descriptors/18 network/33 source-first (74 with queue), reachable coverage, Skills lists/Weapon hook, same session/metadata/PR view/drop origin, identity and disposal; event bus/IO/natives virtual')
