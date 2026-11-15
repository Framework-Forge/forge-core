local R=dofile('tests/kernel_event_registration_harness.lua');local r=R.new();local before=r.snapshot();local a,c=r.prepare()
R.H.same(r.snapshot(),before,'client event preparation inert');r.connectClientEmissions()
assert(R.coverage(r.clientGraph,r.clientEntries)==91,'all reachable client event descriptors covered once')
local pos={};for i,d in ipairs(c.Describe())do pos[d.owner]=pos[d.owner]or i end
assert(pos['Central.Parts.Runtime.Main']<pos['Central.Parts.Producers.Cache']and pos['Central.Parts.Producers.Cache']<pos['Central.Parts.Producers.Session']
 and pos['Central.Parts.Producers.Session']<pos['Central.Parts.Producers.Status']and pos['Central.Parts.Producers.Status']<pos['Central.Parts.Runtime.Events'],'client QBX relative manifest order')
assert(pos['Parts.World.World']<pos['Parts.AutoMedic.Session']and pos['Parts.Starterpack']<pos['Parts.AutoMedic.Hospital']
 and pos['Parts.AutoMedic.Runtime']<pos['Central.Parts.Consumption']and pos['Parts.Work']<pos['Parts.Skills']
 and pos['Parts.Access']<pos['Parts.Vinewood'],'client Forge relative manifest order')
assert(c.Install()and r.clientBus.active()==91 and not c.Install())
local network=0;for _,d in ipairs(c.Describe())do if d.network then network=network+1 end;assert(not d.sourceFirst)end
assert(network==51,'client never receives extra server-style origin')
local data={citizenid='EVENT51',metadata={hunger=21,thirst=30},job={name='taxi',grade={level=0}}}
r.clientBus.emit('QBCore:Player:SetPlayerData',65535,data)
assert(r.state.PlayerData==data and r.central.api.Parts.Legacy.Functions.GetPlayerData()==data,'bound handler updates actual canonical PlayerData')
r.central.runtime.caller='foreign';r.clientBus.emit('QBCore:Player:SetPlayerData',65535,{citizenid='SPOOF'})
assert(r.state.PlayerData==data,'foreign invokingResource guard not masked');r.central.runtime.caller=nil
local status=r.central.api.Parts.Producers.Status.Exports
status.SetStatus('hunger',20);status.SetStatus('thirst',30)
r.clientBus.emit('forge-core:client:inventory:applyInteractionEffects',65535,{statuses={hunger=5,thirst=2}})
assert(r.state.Status.hunger==25 and data.metadata.hunger==25,'actual installed consumption uses same status producer')
r.clientBus.emit('QBCore:Notify',65535,'Event message','success',500,'Details')
local notice=r.central.runtime.trace[#r.central.runtime.trace];assert(notice.kind=='notify'and notice.args[1].title=='Event message','same local Notify')
local old=r.clientGraph.Parts.World;r.clientGraph.Parts.World={}
r.clientBus.emit('QBCore:Player:SetPlayerData',65535,{citizenid='REPLACED'})
assert(r.state.PlayerData==data,'replaced world invalidates same client registration');r.clientGraph.Parts.World=old
local stale;for token,v in pairs(r.clientBus.records)do if v.name=='QBCore:Player:SetPlayerData'then stale=v.handler end end
assert(c.Dispose()and r.clientBus.active()==0);stale({citizenid='AFTER_STOP'})
assert(r.state.PlayerData==data and not c.Install(),'disposed captured wrapper cannot update player')
assert(r.clientGraph.IsCanonical()and r.clientGraph.Unbound and not c.StartedServices and a.State=='prepared-inactive','no initializer/world hydration/PR collector/bootstrap')
print('PASS lot51 client: 91 actual descriptors/51 network and no source argument, canonical PlayerData/Notify/consumption/status, invokingResource guard/identity/dispose; no start/keybind/statebag/RPC/export or real FiveM')
