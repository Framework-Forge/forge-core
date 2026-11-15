local T=dofile('tests/kernel_public_registration_harness.lua');local H=T.H
local r=T.new();local w=r.transport;local old=r.snapshot();local a,c=r.preparePublic()
H.same(r.snapshot(),old,'public graph constructors have no business/IO/RPC effects')
assert(#r.surfaces.server.trace==0 and #r.surfaces.client.trace==0,'no public constructor registration')
assert(not a.Install(),'supplemental callbacks require explicit owned transport opening')
r.prepare();r.install();r.installPublic()
local e=r.surfaces.server;local exports=e.exports;local graph=r.serverGraph;local pc=graph.PlayerCore
assert(exports.CheckPlayerData==nil and exports.PrepareSchema==nil,'internal methods not published')
assert(exports.GetJobs()==pc.Groups.GetJobs(),'same canonical group catalog')
assert(exports.GetQBPlayers()==pc.Lookup.GetQBPlayers(),'same authoritative Player registry')
pc.Players.CheckPlayerData(1,{citizenid='CANONICAL',license='license:test',userId=101,charinfo={firstname='Canonical',lastname='Player',birthdate='2000-10-22'}})
local player=exports.GetPlayer(1);assert(player==pc.Lookup.GetPlayer(1),'public lookup uses actual Player')
assert(exports.SetMoney(1,'cash',321));assert(exports.GetMoney(1,'cash')==321,'money export uses same Player')
exports.SetMetadata(1,'fixture',7);assert(exports.GetMetadata(1,'fixture')==7,'metadata export uses same Player')
assert(exports.SetVehicles and exports.SetVehicleCatalog,'vehicle catalog aliases preserved')
pc.Producers.Session.Session.setLoaded(1,true)
local session=exports.GetCachedState('session:1');assert(type(session)=='table','server session dispatch preserved')
local world=graph.Parts.World.State;world.publish('stores',{value=19})
local record=exports.GetCachedState('stores');assert(record.data.value==19,'server World dispatch preserved')
record.data.value=99;assert(exports.GetCachedState('stores').data.value==19,'World copies not merged into session')
assert(exports.GetCachedState('unknown')==nil,'unknown domain remains nil')
local groups=w.client.api.ox.await('qbx_core:server:getGroups',false)
assert(groups.jobs==pc.Groups.GetJobs()and groups.gangs==pc.Groups.GetGangs(),'supplemental groups callback uses same catalogs')
r.server.central.characterRow('FOREIGN',1).license='license:other'
assert(w.client.api.ox.await('qbx_core:server:deleteCharacter',false,'FOREIGN')==false,'actual raw deletion callback rejects foreign license')
r.server.central.characterRow('OWNED',1)
assert(w.client.api.ox.await('qbx_core:server:deleteCharacter',false,'OWNED')==true,'actual raw deletion callback uses same slot/storage policy on virtual DB')
-- Coverage is derived independently from every reachable callback descriptor, not the binder counts.
local reachable=T.callbacks(graph);local selected={}
for _,d in ipairs(r.serverRegistration.Describe())do selected[d.name]=true end
for _,d in ipairs(a.Describe())do if d.kind=='callback'then assert(not selected[d.name]);selected[d.name]=true end end
local count=0;for name in pairs(reachable)do assert(selected[name],'unbound reachable callback '..name);count=count+1 end
for name in pairs(selected)do assert(reachable[name],'foreign selected callback '..name)end
assert(count==203,'all203 reachable server callbacks covered without changing lot52')
assert(e.commands.cleanplayergroups.restricted==true,'storage maintenance command remains restricted')
local before=#r.server.central.trace;e.run('cleanplayergroups',1,{},'cleanplayergroups')
assert(#r.server.central.trace==before,'native ACE denial prevents storage maintenance')
local oldPart=graph.Parts.Vehicles;graph.Parts.Vehicles={}
assert(exports.GetPlayer(1)==nil,'canonical replacement revokes stale public export');graph.Parts.Vehicles=oldPart
local foreign=function()return'foreign'end;e.exports.Foreign=foreign
assert(a.Dispose(),'server public surface revoked')
assert(exports.GetPlayer(1)==nil and e.exports.Foreign()== 'foreign','revocation preserves foreign export')
assert(not w.server.find('__ox_cb_qbx_core:server:getGroups')and not w.server.find('__ox_cb_qbx_core:server:deleteCharacter'),'only supplemental RPC leases removed')
assert(w.server.find('__ox_cb_qbx_core:server:getCharacters'),'lot52 registration is not removed by lot53')
assert(r.serverRegistration.Dispose());assert(r.clientRegistration.Dispose())
print('PASS public server: '..a.Counts.exports..' exports/'..a.Counts.commands..' commands/two supplemental ox callbacks; same Player/groups/money/session/World,203 reachable callbacks; virtual registry only')
