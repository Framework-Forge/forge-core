-- One existing graph through NPC39; PR libraries and effects isolated in memory.
local R=dofile('tests/kernel_spotlights_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_npcs_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('\ngraph.register(g.worldClient.Events)',1,true))
local g=assert(load(source:sub(1,cut-1)..[[
return {graph=graph,base=base,r=r,wire=wire,config=config,worldServer=g.worldServer,worldClient=g.worldClient,
 worldFixture=g.worldFixture,settings=g.settings,menus=g.menus,npcsServer=server,npcsClient=client}
]],'@canonical-world35-npcs39','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
local fixture=R.new(true)
fixture.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
fixture.native.GetGameTimer=g.worldFixture.native.GetGameTimer
local trace,size=#fixture.trace,#fixture.m.trace
local server=H.load('kernel/server/spotlights_core.lua',R.env())(base,{
 config=fixture.config,library=fixture.library,native=fixture.native,translate=fixture.translate})
assert(#fixture.trace==trace and #fixture.m.trace==size and not server.Service.started)
assert(server.Security==base.Callbacks and server.State==g.worldServer.State and server.PlayerCore==base.PlayerCore)
assert(base.JobCatalog.Dependencies.SpotlightsService==server.Service and base.JobCatalog.Dependencies.NpcsService==g.npcsServer.Service)
assert(not pcall(H.load('kernel/server/spotlights_core.lua',R.env()),base,{}),'duplicate domain refused')
for _,d in ipairs(server.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
config.Spotlights=server.Config.Spotlights
local actualAwait=r.library.callback.await
R.platform(r);r.library.callback.await=actualAwait
local playerData,session,npcs=graph.state.PlayerData,graph.client.ForgeSession,graph.client.Npcs
trace=#r.trace
local client=H.load('kernel/client/spotlights_core.lua',R.env())(graph.state,{
 client=graph.client,config=config,library=r.library,native=r.native,translate=fixture.translate})
assert(#r.trace==trace and #r.draws==0,'inert renderer/menu constructors')
assert(client.Spotlights==graph.client.Spotlights and client.WorldState==g.worldClient.WorldState)
assert(client.Menu==g.npcsClient.Menu and client.Shared==g.npcsClient.Shared and #client.Threads==1 and #client.Subscriptions==1)
assert(not pcall(H.load('kernel/client/spotlights_core.lua',R.env()),graph.state,{}),'duplicate client refused')
graph.register(g.worldClient.Events)
for _,d in ipairs(client.Subscriptions)do client.WorldState.onChange(d.key,d.handler)end
g.worldServer.World.Initialize();g.worldClient.World.Initialize()
server.Service.start();g.worldFixture.advance(0);r.advance(0)
assert(#client.Spotlights.lights==1 and #r.draws==0,'delta does not spawn another renderer')
local worker=coroutine.create(client.Threads[1]);assert(coroutine.resume(worker));assert(#r.draws==0)
assert(coroutine.resume(worker));assert(#r.draws==1 and math.abs(r.draws[1][4]-0.6)<1e-8)
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
wire.playerSource=1
local ok,p=rpc(config.Spotlights.Callbacks.getAll);assert(ok and #p.groups==2,'public spotlight read')
ok,p=rpc(config.Spotlights.Callbacks.createGroup,'DENIED');assert(not ok and p=='no_permission')
ok,p=rpc(config.Spotlights.Callbacks.deleteLight,1);assert(not ok and p=='no_permission')
wire.playerSource=2
local context=graph.context.api
context.RegisterContext({id='forge_core_main',title='Root',options={}})
client.Menu.openServerSettingsMenu();context.HandleSelect('forge_core_server_settings',12)
assert(context.GetOpenContextMenu()=='forge_core_spotlights','parent34 to spotlight40')
context.HandleSelect('forge_core_spotlights',3);assert(context.GetOpenContextMenu()=='forge_core_spotlights_group_1')
r.library.menus.InputDialog=function(_,fields)assert(#fields==7 and fields[3].type=='color');return{'New','true','#abc',50,1,0,20}end
local co=coroutine.create(function()context.HandleSelect('forge_core_spotlights_group_1',1)end)
assert(coroutine.resume(co));r.just={[38]=true};assert(coroutine.resume(co));assert(coroutine.resume(co));r.just={[201]=true};assert(coroutine.resume(co));r.just={}
assert(coroutine.status(co)=='dead'and not client.Spotlights.editorActive and not r.textui.IsTextUIOpen())
local all=server.Service.getAll();assert(#all.lights==2 and all.lights[2].origin.x==1.123 and all.lights[2].color.r==170)
assert(#client.Spotlights.lights==2,'menu applies successful response before world delta')
g.worldFixture.advance(0);r.advance(600);assert(#client.Spotlights.lights==2)
assert(fixture.m.files[config.Spotlights.Storage.file],'only virtual persistence')
client.Menu.openSpotlightActions(2);context.HandleSelect('forge_core_spotlight_2',3)
g.worldFixture.advance(0);r.advance(500);assert(not server.Service.getAll().lights[2].enabled and not client.Spotlights.lights[2].enabled)
local rev=server.Service.state.revision;assert(rev>r.now-10000,'revision is independent of UI frame clock')
local beforeDraw=#r.draws;assert(coroutine.resume(worker));assert(#r.draws==beforeDraw+1,'disabled light not drawn')
local before=g.worldServer.State.getRecord('spotlights')
fixture.m.onWrite=function()return false end
ok,p=rpc(config.Spotlights.Callbacks.updateLight,1,{name='FAILED'});assert(not ok and p=='save_failed')
H.same(g.worldServer.State.getRecord('spotlights'),before,'failed save no publication')
fixture.m.onWrite=nil
assert(rpc(config.Spotlights.Callbacks.updateLight,1,{groupId=2,name='Moved',color='rgb(1,2,3)'}))
g.worldFixture.advance(0);r.advance(0)
assert(server.Service.state.revision==rev+1 and client.Spotlights.lights[1].groupId==2)
assert(client.Spotlights.lights[1].color.g==2,'same-tick revision increments delivered')
-- Parent context must have been registered; moving a light does not register its new group menu.
client.Menu.openSpotlightsGroup(2,'Empty');client.Menu.openSpotlightActions(1);context.HandleBack()
assert(context.GetOpenContextMenu()=='forge_core_spotlights_group_2','new group parent')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_spotlights')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
assert(rpc(config.Spotlights.Callbacks.deleteLight,2));g.worldFixture.advance(0);r.advance(0)
assert(#client.Spotlights.lights==1 and #server.Service.getAll().lights==1)
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending spotlight RPC')
local snapshot=wire.client.api.request('forge-core:cache:snapshot',nil,nil,10000)
assert(snapshot.states.spotlights and not snapshot.ready,'partial world not falsely ready')
assert(graph.state.PlayerData==playerData and graph.client.ForgeSession==session and graph.client.Npcs==npcs)
print('PASS spotlight composition: canonical World35/Job/Security/Menu34 beside NPC39; actual PR RPC/context/recovery/cache/raycast/TextUI, public read/admin refusal/create/serial/color/toggle/move/revision/save failure/delete/parent; native visuals, Cfx vectors, JSON durability and live boot not verified')
