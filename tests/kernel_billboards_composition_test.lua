-- One graph through spotlight40; only virtual IO/CEF/natives/network effects.
local R=dofile('tests/kernel_billboards_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_spotlights_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('\ngraph.register(g.worldClient.Events)',1,true))
local g=assert(load(source:sub(1,cut-1)..[[
return {graph=graph,base=base,r=r,wire=wire,config=config,worldServer=g.worldServer,worldClient=g.worldClient,
 worldFixture=g.worldFixture,settings=g.settings,menus=g.menus,lightsServer=server,lightsClient=client}
]],'@canonical-world35-spotlights40','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
local fixture=R.new(true)
fixture.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
fixture.native.GetGameTimer=g.worldFixture.native.GetGameTimer
local trace,size=#fixture.trace,#fixture.m.trace
local server=H.load('kernel/server/billboards_core.lua',R.env())(base,{
 config=fixture.config,library=fixture.library,native=fixture.native,translate=fixture.translate})
assert(#fixture.trace==trace and #fixture.m.trace==size and not server.Service.started)
assert(server.Security==base.Callbacks and server.State==g.worldServer.State and server.PlayerCore==base.PlayerCore)
assert(base.JobCatalog.Dependencies.BillboardsService==server.Service and base.JobCatalog.Dependencies.SpotlightsService==g.lightsServer.Service)
assert(not pcall(H.load('kernel/server/billboards_core.lua',R.env()),base,{}),'duplicate server refused')
for _,d in ipairs(server.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
config.Billboards=server.Config.Billboards
local actualAwait=r.library.callback.await
R.platform(r);r.library.callback.await=actualAwait
local playerData,session,lights=graph.state.PlayerData,graph.client.ForgeSession,graph.client.Spotlights
trace=#r.trace
local client=H.load('kernel/client/billboards_core.lua',R.env())(graph.state,{
 client=graph.client,config=config,library=r.library,native=r.native,translate=fixture.translate})
assert(#r.trace==trace and next(r.duis)==nil,'inert DUI/menu constructors')
assert(client.Billboards==graph.client.Billboards and client.WorldState==g.worldClient.WorldState)
assert(client.Menu==g.lightsClient.Menu and client.Shared==g.lightsClient.Shared and #client.Threads==1 and #client.Events==1)
assert(not pcall(H.load('kernel/client/billboards_core.lua',R.env()),graph.state,{}),'duplicate client refused')
graph.register(g.worldClient.Events);graph.register(client.Events)
for _,d in ipairs(client.Subscriptions)do client.WorldState.onChange(d.key,d.handler)end
g.worldServer.World.Initialize();g.worldClient.World.Initialize()
server.Service.start();g.worldFixture.advance(0);r.advance(0)
assert(#client.Billboards.entries==1 and next(r.duis)==nil,'delta only updates records')
local worker=coroutine.create(client.Threads[1]);assert(coroutine.resume(worker));assert(r.duis[201]and #r.polys==2)
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
local function nextTick()g.worldFixture.now=g.worldFixture.now+1 end
local function flush(ms)g.worldFixture.advance(0);r.advance(ms or 0)end
wire.playerSource=1
local ok,p=rpc(config.Billboards.Callbacks.getAll);assert(ok and #p.groups==2,'public billboard read')
ok,p=rpc(config.Billboards.Callbacks.createGroup,'DENIED');assert(not ok and p=='no_permission')
ok,p=rpc(config.Billboards.Callbacks.deleteBillboard,1);assert(not ok and p=='no_permission')
wire.playerSource=2
local context=graph.context.api
context.RegisterContext({id='forge_core_main',title='Root',options={}})
client.Menu.openServerSettingsMenu();context.HandleSelect('forge_core_server_settings',13)
assert(context.GetOpenContextMenu()=='forge_core_billboards','parent34 to billboard41')
context.HandleSelect('forge_core_billboards',3);assert(context.GetOpenContextMenu()=='forge_core_billboards_group_1')
r.library.menus.InputDialog=function(_,fields)assert(#fields==6);return{'New','true','fixture://new',800,600,0.04}end
nextTick()
local co=coroutine.create(function()context.HandleSelect('forge_core_billboards_group_1',1)end)
assert(coroutine.resume(co));R.completeCapture(r,co)
assert(coroutine.status(co)=='dead'and not client.Billboards.captureActive and not r.textui.IsTextUIOpen())
assert(#client.Billboards.entries==2,'menu applies successful response before delta')
flush(600)
local all=server.Service.getAll();assert(#all.billboards==2 and all.billboards[2].vertices[1].x==1.123 and all.billboards[2].vertices[4].z==1.346)
assert(fixture.m.files[config.Billboards.Storage.file],'only virtual JSON')
assert(coroutine.resume(worker));local dui=client.Billboards.duis[2].dui;assert(r.duis[dui])
client.Menu.openBillboardActions(2)
local before=g.worldServer.State.getRecord('billboards')
fixture.m.onWrite=function()return false end
context.HandleSelect('forge_core_billboard_2',4)
assert(server.Service.getAll().billboards[2].enabled and not r.duis[dui],'failed optimistic toggle does not roll back native immediately')
H.same(g.worldServer.State.getRecord('billboards'),before,'failed save no publication')
fixture.m.onWrite=nil;client.Menu.openBillboardActions(2)
assert(coroutine.resume(worker));assert(r.duis[client.Billboards.duis[2].dui],'fresh query restores server version')
nextTick();context.HandleSelect('forge_core_billboard_2',4);flush(500)
assert(not server.Service.getAll().billboards[2].enabled and #client.Billboards.entries==1 and not client.Billboards.duis[2])
nextTick();client.Menu.openBillboardActions(2);context.HandleSelect('forge_core_billboard_2',4);flush(500)
assert(server.Service.getAll().billboards[2].enabled and #client.Billboards.entries==2)
client.Menu.openBillboardActions(2);nextTick()
co=coroutine.create(function()context.HandleSelect('forge_core_billboard_2',3)end)
assert(coroutine.resume(co));r.controls={[172]=true};R.resume(co);r.controls={};r.just={[201]=true};R.resume(co);r.just={};flush(500)
assert(math.abs(server.Service.getAll().billboards[2].offset-0.0425)<1e-8,'fine tune menu RPC saves offset')
r.rays={R.vector(10,11,12),R.vector(13,11,12),R.vector(10,11,9),R.vector(13,11,9)}
client.Menu.openBillboardActions(2);nextTick()
co=coroutine.create(function()context.HandleSelect('forge_core_billboard_2',2)end)
assert(coroutine.resume(co));R.completeCapture(r,co);flush(500)
assert(server.Service.getAll().billboards[2].vertices[1].x==10,'recapture updates same record')
local moved=server.Service.getAll().billboards[2];moved.groupId=2;moved.url='fixture://moved'
nextTick();assert(rpc(config.Billboards.Callbacks.updateBillboard,2,moved));flush()
local old=client.Billboards.duis[2].dui;assert(coroutine.resume(worker))
assert(client.Billboards.duis[2].dui~=old and not r.duis[old],'URL change recreates native DUI')
-- Group-specific parent must exist before using Back after a move.
client.Menu.openBillboardsGroup(2,'Empty');client.Menu.openBillboardActions(2);context.HandleBack()
assert(context.GetOpenContextMenu()=='forge_core_billboards_group_2')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_billboards')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
nextTick();assert(rpc(config.Billboards.Callbacks.deleteBillboard,2));flush()
assert(#client.Billboards.entries==1 and not client.Billboards.duis[2])
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending billboard RPC')
local snapshot=wire.client.api.request('forge-core:cache:snapshot',nil,nil,10000)
assert(snapshot.states.billboards and not snapshot.ready,'partial world not falsely ready')
r.fire('onResourceStop',nil,'forge-core');assert(next(r.duis)==nil and next(client.Billboards.duis)==nil,'stop clears known DUI')
assert(graph.state.PlayerData==playerData and graph.client.ForgeSession==session and graph.client.Spotlights==lights)
print('PASS billboard composition: canonical World35/Job/Security/Menu34 beside Spotlight40; actual PR RPC/context/recovery/cache/raycast/TextUI, public read/admin refusal/capture/create/toggle failure/requery/tune/recapture/move/URL/delete/parent/stop; DUI/CEF/native visuals/HTTP/Cfx vectors/JSON durability/live boot not verified')
