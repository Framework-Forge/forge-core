-- Canonical existing graph through Objects38; no resource effects.
local R=dofile('tests/kernel_npcs_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_objects_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('graph.register(g.worldClient.Events)',1,true))
local g=assert(load(source:sub(1,cut-1)..[[
return {graph=graph,base=base,r=r,wire=wire,config=config,worldServer=g.worldServer,worldClient=g.worldClient,
 worldFixture=g.worldFixture,settings=g.settings,menus=g.menus,objectsServer=server,objectsClient=client}
]],'@canonical-world35-objects38','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
local fixture=R.new(true)
fixture.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
fixture.native.GetGameTimer=g.worldFixture.native.GetGameTimer
local trace,size=#fixture.trace,#fixture.m.trace
local server=H.load('kernel/server/npcs_core.lua',R.env())(base,{
 config=fixture.config,library=fixture.library,native=fixture.native,translate=fixture.translate})
assert(#fixture.trace==trace and #fixture.m.trace==size and not server.Service.started,'inert NPC service')
assert(server.Security==base.Callbacks and server.State==g.worldServer.State and server.PlayerCore==base.PlayerCore)
assert(base.JobCatalog.Dependencies.NpcsService==server.Service and base.JobCatalog.Dependencies.ObjectsService==g.objectsServer.Service)
assert(not pcall(H.load('kernel/server/npcs_core.lua',R.env()),base,{}),'duplicate service refused')
for _,d in ipairs(server.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
config.Npcs=server.Config.Npcs
local actualAwait=r.library.callback.await
R.platform(r);r.library.callback.await=actualAwait
r.library.command=function()error('no command installation')end
-- Existing medical/world fixture has no Legacy08 attachment. Attach its actual factory to the same state.
local L=dofile('tests/kernel_legacy_harness.lua')
local lf,queries=L.new(true,'client'),L.client(true)
local lb={};for k,v in pairs(lf.bindings)do lb[k]=v end
lb.membership=queries.membership;lb.notify=queries.bindings.notify
lb.jobs=base.Groups.GetJobs();lb.gangs=base.Groups.GetGangs()
local pulls=0;lb.awaitGroups=function()pulls=pulls+1;return{jobs=base.Groups.GetJobs(),gangs=base.Groups.GetGangs()}end
local legacy=H.load('kernel/client/legacy_core.lua',R.env())(graph.state,lb)
assert(pulls==0);assert(legacy.Groups.Initialize()and pulls==1)
local localSession=graph.client.ForgeSession
trace=#r.trace
local client=H.load('kernel/client/npcs_core.lua',R.env())(graph.state,{
 client=graph.client,config=config,library=r.library,native=r.native,translate=fixture.translate,integration=r.integration})
assert(#r.trace==trace+1 and next(r.entities)==nil,'only local command-help translation')
assert(graph.client.ForgeSession==localSession and client.WorldState==g.worldClient.WorldState and client.Menu==g.objectsClient.Menu)
assert(client.Shared==g.objectsClient.Shared and client.Npcs==graph.client.Npcs)
assert(not pcall(H.load('kernel/client/npcs_core.lua',R.env()),graph.state,{}),'duplicate NPC client refused')
graph.register(g.worldClient.Events);graph.register(client.Events)
for _,d in ipairs(client.Subscriptions)do client.WorldState.onChange(d.key,d.handler)end
g.worldServer.World.Initialize();g.worldClient.World.Initialize()
server.Service.start();g.worldFixture.advance(0);r.advance(0)
assert(client.Npcs.get(1).model=='a_m_m_business_01'and next(r.entities)==nil,'delta updates entries without second controller')
local worker=coroutine.create(client.Threads[1]);assert(coroutine.resume(worker));assert(r.entities[101]and r.targets[101])
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
wire.playerSource=1
local ok,p=rpc(config.Npcs.Callbacks.getAll);assert(ok and #p.groups==2,'public NPC read')
ok,p=rpc(config.Npcs.Callbacks.createGroup,'DENIED');assert(not ok and p=='no_permission')
ok,p=rpc(config.Npcs.Callbacks.deleteNpc,1);assert(not ok and p=='no_permission')
wire.playerSource=2
local context=graph.context.api
context.RegisterContext({id='forge_core_main',title='Root',options={}})
client.Menu.openServerSettingsMenu();context.HandleSelect('forge_core_server_settings',11)
assert(context.GetOpenContextMenu()=='forge_core_npcs','parent34 to NPC39')
context.HandleSelect('forge_core_npcs',4);assert(context.GetOpenContextMenu()=='forge_core_npcs_group')
context.HandleSelect('forge_core_npcs_group',1);assert(context.GetOpenContextMenu()=='forge_core_npcs_models')
r.library.menus.InputDialog=function(_,fields)assert(#fields==2);return{'NPC new','Description'}end
context.HandleSelect('forge_core_npcs_models',2)
assert(client.Npcs.placementActive and r.targetDisabled)
g.worldFixture.now=g.worldFixture.now+1
r.finish({x=4.12345,y=5.23456,z=6.34567,heading=90});g.worldFixture.advance(0);r.advance(700)
assert(not client.Npcs.placementActive and not r.targetDisabled)
assert(server.Service.getAll().npcs[2].coords.x==4.123 and client.Npcs.get(2).coords.y==5.235,'menu RPC service JSON World35 roundtrip')
assert(fixture.m.files[config.Npcs.Storage.file],'only virtual JSON')
assert(coroutine.resume(worker));assert(client.Npcs.get(2).handle==102)
client.Menu.openNpcActions(2);context.HandleSelect('forge_core_npc_actions',1)
g.worldFixture.now=g.worldFixture.now+1
r.finish({x=10,y=11,z=12,heading=180});g.worldFixture.advance(0);r.advance(600)
assert(server.Service.getAll().npcs[2].coords.x==10 and client.Npcs.get(2).heading==180)
-- Verify local catalog/Session bindings, not only equivalent fixture responses.
local groups=graph.state.LegacyCore.Groups
groups.GetJobs().fixture_job={label='Fixture Job'}
r.library.menus.InputDialog=function(_,fields)
 assert(#fields==8);local found=false;for _,o in ipairs(fields[5].options)do if o.value=='fixture_job'then found=true end end
 assert(found,'menu reads canonical local groups');return{'both','Talk','fixture:action',3,'fixture_job',2,'',0}
end
client.Menu.openNpcActions(2);context.HandleSelect('forge_core_npc_actions',3)
g.worldFixture.advance(0);r.advance(600)
assert(server.Service.getAll().npcs[2].interaction.access.job=='fixture_job')
local pd=graph.state.PlayerData;pd.job={name='fixture_job',grade={level=2}};localSession.refresh()
assert(r.targets[102][1].canInteract(),'target reads canonical Forge Session')
pd.job.grade.level=1;localSession.refresh();assert(not r.targets[102][1].canInteract());pd.job.grade.level=2;localSession.refresh()
client.Menu.openNpcActions(2);context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_npcs_group')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_npcs')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
local before=g.worldServer.State.getRecord('npcs')
fixture.m.onWrite=function()return false end
ok,p=rpc(config.Npcs.Callbacks.deleteNpc,2);assert(not ok and p=='save_failed')
H.same(g.worldServer.State.getRecord('npcs'),before,'failed persistence no publication')
fixture.m.onWrite=nil;g.worldFixture.now=g.worldFixture.now+1
assert(rpc(config.Npcs.Callbacks.deleteNpc,2));g.worldFixture.advance(0);r.advance(0)
assert(not client.Npcs.get(2)and not r.entities[102]and not r.targets[102])
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending NPC RPC')
local snapshot=wire.client.api.request('forge-core:cache:snapshot',nil,nil,10000)
assert(snapshot.states.npcs and not snapshot.ready,'partial world not falsely ready')
r.fire('onResourceStop',nil,'forge-core');assert(next(r.entities)==nil)
assert(graph.state.PlayerData.citizenid=='PATIENT'and graph.client.ForgeSession==localSession)
print('PASS NPC composition: canonical World35/Job/Security/Menu34/Session31/Groups08 beside Objects38; actual PR RPC/context/recovery/cache/streaming/blips, public read/admin refusal/create/edit/group catalog/access/delete/save failure/parent/stop; target/devtools/actions, assets, Cfx vectors, JSON durability and live boot not verified')
