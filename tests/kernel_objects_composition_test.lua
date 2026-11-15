-- Canonical graph through world35 + Vinewood37, followed by Objects38; virtual effects only.
local R=dofile('tests/kernel_objects_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_vinewood_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('graph.register(g.client.Events)',1,true))
local g=assert(load(source:sub(1,cut-1)..[[
return {graph=graph,base=base,r=r,wire=wire,config=config,worldServer=g.server,worldClient=g.client,
    worldFixture=g.fixture,settings=g.settings,menus=g.menus,vinewoodServer=server,vinewoodClient=client}
]],'@canonical-world35-vinewood37','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
local fixture=R.new(true)
fixture.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
fixture.native.GetGameTimer=g.worldFixture.native.GetGameTimer
local trace,ioSize=#fixture.trace,#fixture.m.trace
local server=H.load('kernel/server/objects_core.lua',R.env())(base,{
    config=fixture.config,library=fixture.library,native=fixture.native,translate=fixture.translate})
assert(#fixture.trace==trace and #fixture.m.trace==ioSize and not server.Service.started,'inactive Objects server')
assert(server.Security==base.Callbacks and server.PlayerCore==base.PlayerCore and server.State==g.worldServer.State)
assert(base.JobCatalog.Dependencies.ObjectsService==server.Service and base.JobCatalog.Dependencies.VinewoodService==g.vinewoodServer.Service,'one holder per domain')
assert(not pcall(H.load('kernel/server/objects_core.lua',R.env()),base,{}),'duplicate server refused')
for _,d in ipairs(server.Callbacks)do
    assert(d.options.access==(d.name==server.Config.Objects.Callbacks.getAll and'player'or'admin'))
    base.Callbacks.register(d.name,d.handler,d.options)
end
for _,d in ipairs(g.worldServer.RawCallbacks)do wire.server.api.register(d.name,d.handler)end
config.Objects=server.Config.Objects
local actualAwait=r.library.callback.await
R.platform(r);r.library.callback.await=actualAwait
r.library.command=function()error('no command installation')end
trace=#r.trace
local client=H.load('kernel/client/objects_core.lua',R.env())(graph.state,{
    client=graph.client,config=config,library=r.library,native=r.native,translate=fixture.translate})
assert(#r.trace==trace+1 and r.trace[#r.trace].kind=='translate'and next(r.entities)==nil,'only local command-help translation, no entity/worker/registration IO')
assert(client.Objects==graph.client.Objects and client.WorldState==g.worldClient.WorldState and client.Menu==g.menus.Menu)
assert(client.Shared==g.vinewoodClient.Shared and client.Menu==g.vinewoodClient.Menu,'same settings34 controller')
assert(not pcall(H.load('kernel/client/objects_core.lua',R.env()),graph.state,{}),'duplicate client refused')
graph.register(g.worldClient.Events);graph.register(client.Events)
for _,d in ipairs(client.Subscriptions)do client.WorldState.onChange(d.key,d.handler)end
g.worldServer.World.Initialize();g.worldClient.World.Initialize()
server.Service.start();g.worldFixture.advance(0);r.advance(0)
assert(client.Objects.get(1).model=='prop_box'and next(r.entities)==nil,'delta only updates entries, not a second spawn controller')
local worker=coroutine.create(client.Threads[1]);assert(coroutine.resume(worker));assert(r.entities[101],'actual PR streaming spawns virtual object')
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
wire.playerSource=1
local ok,p=rpc(config.Objects.Callbacks.getAll);assert(ok and #p.scenes==2,'getAll remains public for a valid player')
ok,p=rpc(config.Objects.Callbacks.createScene,'DENIED');assert(not ok and p=='no_permission')
ok,p=rpc(config.Objects.Callbacks.deleteObject,1);assert(not ok and p=='no_permission')
wire.playerSource=2
local context=graph.context.api
context.RegisterContext({id='forge_core_main',title='Root',options={}})
g.menus.Menu.openServerSettingsMenu();context.HandleSelect('forge_core_server_settings',10)
assert(context.GetOpenContextMenu()=='forge_core_objects','parent34 to objects38')
context.HandleSelect('forge_core_objects',5)
assert(context.GetOpenContextMenu()=='forge_core_objects_scene','scene menu with canonical data')
r.library.menus.InputDialog=function(_,fields)assert(#fields==1);return{'prop_new'}end
context.HandleSelect('forge_core_objects_scene',1)
assert(client.Objects.editorActive and r.targetDisabled and r.entities[102])
g.worldFixture.now=g.worldFixture.now+1
r.finish(true,R.vector(4.12345,5.23456,6.34567),R.vector(1,2,3))
g.worldFixture.advance(0);r.advance(700)
assert(not client.Objects.editorActive and not r.targetDisabled and not r.entities[102],'confirmed preview cleanup')
assert(client.Objects.get(2).coords.x==4.123 and server.Service.getAll().objects[2].coords.y==5.235,'menu -> PR RPC -> service -> PR JSON -> World35 -> client')
assert(fixture.m.files[config.Objects.Storage.file],'objects persistence is memory only')
assert(coroutine.resume(worker));assert(client.Objects.get(2).handle and r.entities[103])
context.HandleSelect('forge_core_objects_scene',5)
assert(context.GetOpenContextMenu()=='forge_core_object_actions')
context.HandleSelect('forge_core_object_actions',1)
g.worldFixture.now=g.worldFixture.now+1
r.finish(true,R.vector(10,11,12),R.vector(5,6,7));g.worldFixture.advance(0);r.advance(0)
assert(server.Service.getAll().objects[2].coords.x==10 and client.Objects.get(2).rotation.z==7)
client.Menu.openObjectActions(2) -- PR selection closes the previous context; edit has no automatic reopening.
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_objects_scene')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_objects')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
local before=g.worldServer.State.getRecord('objects')
fixture.m.onWrite=function()return false end
ok,p=rpc(config.Objects.Callbacks.deleteObject,2);assert(not ok and p=='save_failed')
H.same(g.worldServer.State.getRecord('objects'),before,'failed persistence no new publication')
fixture.m.onWrite=nil
ok,p=rpc(config.Objects.Callbacks.deleteScene,1);assert(not ok and p=='scene_not_empty')
g.worldFixture.now=g.worldFixture.now+1
assert(rpc(config.Objects.Callbacks.deleteObject,2));g.worldFixture.advance(0);r.advance(0)
assert(not client.Objects.get(2)and not r.entities[103],'deletion delta removes same local entity')
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending Objects RPC')
local snapshot=wire.client.api.request('forge-core:cache:snapshot',nil,nil,10000)
assert(snapshot.states.objects and not snapshot.ready,'remaining domains not falsely declared ready')
r.fire('onResourceStop',nil,'forge-core');assert(next(r.entities)==nil,'resource stop clears known object handles')
assert(graph.state.PlayerData.citizenid=='PATIENT'and base.PlayerCore.Lookup.GetPlayer(1).PlayerData.citizenid=='PATIENT','world is not a second player authority')
print('PASS objects composition: canonical World35/Job/Security/Menu34 beside Vinewood37, actual PR RPC/context/recovery/cache/streaming/blips; public read/admin denial/create/gizmo protocol/save/update/delete/failure/parent/stop; gizmo UI/provider, assets, native vectors, JSON durability and real boot not verified')
