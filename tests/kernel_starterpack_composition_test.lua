-- One canonical graph through Farms43/Stores42; real PR transport/context/recovery/cache and virtual providers.
local R=dofile('tests/kernel_starterpack_harness.lua');local H=R.H
local file=assert(io.open('tests/kernel_farms_composition_test.lua','r'));local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('\ngraph.register(g.worldClient.Events)',1,true))
local g=assert(load(source:sub(1,cut-1)..[[
return{graph=graph,base=base,r=r,wire=wire,config=config,worldServer=g.worldServer,worldClient=g.worldClient,
 worldFixture=g.worldFixture,storesServer=g.storesServer,storesClient=g.storesClient,farmsServer=server,farmsClient=client}
]],'@canonical-world35-farms43','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
local fixture=R.new(true)
fixture.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
fixture.library.command=function()error('constructor must not install commands')end
fixture.native.GetGameTimer=g.worldFixture.native.GetGameTimer
local before=#fixture.m.trace
local server=H.load('kernel/server/starterpack_core.lua',R.env())(base,{config=fixture.config,library=fixture.library,native=fixture.native,
 clock=fixture.clock,translate=fixture.translate,inventoryIntegration=fixture.inventoryIntegration,print=fixture.print})
assert(#fixture.m.trace==before and not server.Service.started and #server.Commands==1,'inert starterpack service/command')
assert(server.Security==base.Callbacks and server.State==g.worldServer.State and server.PlayerCore==base.PlayerCore)
assert(base.JobCatalog.Dependencies.StarterpackService==server.Service and base.JobCatalog.Dependencies.FarmsService==g.farmsServer.Service)
assert(not pcall(H.load('kernel/server/starterpack_core.lua',R.env()),base,{}),'duplicate server refused')
for _,d in ipairs(server.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
config.Starterpack=server.Config.Starterpack
local scene,e,s=R.sceneFixture(false);scene.queue={}
local library=setmetatable({target=e.pr_lib.target,fivem=e.pr_lib.fivem},{__index=r.library})
library.framework=setmetatable({},{__index=function()error('forbidden client framework cycle')end})
local data,session,farms=graph.state.PlayerData,graph.client.ForgeSession,graph.client.Farms
local client=H.load('kernel/client/starterpack_core.lua',R.env())(graph.state,{client=graph.client,config=config,library=library,
 native=e,translate=fixture.translate,print=fixture.print,json=e.json})
assert(client.Menu==g.farmsClient.Menu and client.Shared==g.farmsClient.Shared and client.WorldState==g.worldClient.WorldState)
assert(client.Session==session and #scene.queue==0 and not client.Starterpack.preparationScheduled,'inert canonical scene')
assert(not pcall(H.load('kernel/client/starterpack_core.lua',R.env()),graph.state,{}),'duplicate client refused')
graph.register(g.worldClient.Events);graph.register(g.storesClient.Events);graph.register(g.farmsClient.Events);graph.register(client.Events)
for _,api in ipairs({g.storesClient,g.farmsClient,client})do for _,d in ipairs(api.Subscriptions)do api.WorldState.onChange(d.key,d.handler)end end
g.worldServer.World.Initialize();g.worldClient.World.Initialize()
g.storesServer.Service.start();g.farmsServer.Service.start();server.Service.start();g.worldFixture.advance(0);r.advance(0)
assert(client.Starterpack.payload and #client.Starterpack.payload.items==2,'world hydration')
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
local function flush()g.worldFixture.advance(0);r.advance(0)end
local function tick()g.worldFixture.now=g.worldFixture.now+1 end
local player=assert(base.PlayerCore.Lookup.GetPlayer(1));local cid=assert(player.PlayerData.citizenid)
assert(server.Player.GetPlayerData(1)==player.PlayerData,'canonical identity')
wire.playerSource=1
local ok,p=rpc(config.Starterpack.Callbacks.getAll);assert(ok and #p.items==2 and not p.claimed)
for _,key in ipairs({'saveSettings','savePrologue','setItem','removeItem','setStop','removeStop','giveToPlayer','resetClaim'})do
 ok,p=rpc(config.Starterpack.Callbacks[key],{});assert(not ok and p=='no_permission','admin denial '..key)
end
assert(not server.Commands[1].properties.canAccess(1)and server.Commands[1].properties.canAccess(2),'same local command security')
wire.playerSource=2
local context=graph.context.api;context.RegisterContext({id='forge_core_main',title='Root',options={}})
client.Menu.openServerSettingsMenu();context.HandleSelect('forge_core_server_settings',25)
assert(context.GetOpenContextMenu()=='forge_core_starterpack','parent34 to starterpack44')
context.HandleSelect('forge_core_starterpack',3);assert(context.GetOpenContextMenu()=='forge_core_starterpack_prologue')
context.HandleSelect('forge_core_starterpack_prologue',5);assert(context.GetOpenContextMenu()=='forge_core_starterpack_stop_one')
context.HandleSelect('forge_core_starterpack_stop_one',5);assert(context.GetOpenContextMenu()=='forge_core_starterpack_stop_rewards_one')
context.HandleBack();context.HandleBack();context.HandleBack();context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
r.library.menus.InputDialog=function(_,fields)assert(#fields==3);return{'true','true','true'}end
tick();client.Menu.openStarterpackSettings(server.Service.getAll().settings);flush()
assert(server.Service.state.settings.autoGiveOnFirstJoin and client.Starterpack.payload.settings.autoGiveOnFirstJoin,'menu save RPC/world')
local snapshot=g.worldServer.State.getRecord('starterpack')
fixture.m.onWrite=function()return false end;tick();ok,p=rpc(config.Starterpack.Callbacks.saveSettings,{enabled=false})
assert(not ok and p=='save_failed');H.same(g.worldServer.State.getRecord('starterpack'),snapshot,'failed save no publication');fixture.m.onWrite=nil
wire.playerSource=1;tick();ok,p=rpc(config.Starterpack.Callbacks.claim);assert(ok and server.Service.state.claimed[cid],'canonical claim')
ok,p=rpc(config.Starterpack.Callbacks.claim);assert(not ok and p=='already_claimed','once per canonical character')
tick();ok,p=rpc(config.Starterpack.Callbacks.grantReward,'one','token');assert(ok and server.Service.state.rewardClaims[cid..':one:token'],'reward from player RPC')
ok,p=rpc(config.Starterpack.Callbacks.grantReward,'one','token');assert(ok and p=='already_granted')
wire.playerSource=2;tick();assert(rpc(config.Starterpack.Callbacks.resetClaim,cid));flush()
assert(not server.Service.state.claimed[cid]and not server.Service.state.rewardClaims[cid..':one:token'])
-- With a failed second grant the first is compensated, then the next clean attempt succeeds.
fixture.failAddAt=fixture.addCalls+2;tick();wire.playerSource=1;ok,p=rpc(config.Starterpack.Callbacks.claim)
assert(not ok and p=='add_failed'and not server.Service.state.claimed[cid],'partial grant rollback through PR')
fixture.failAddAt=nil;tick();assert(rpc(config.Starterpack.Callbacks.claim));flush()
-- Same native scene boundary executes the prepared runtime, without invoking the installed duplicate scene.
for _,fn in ipairs(client.Initializers)do fn()end
scene.advance(3000);assert(client.Starterpack.vehicle and s.entities[client.Starterpack.vehicle].grounded,'prepared scene on canonical world')
assert(s.targets[client.Starterpack.lamar],'PR target creation')
r.fire('forge-core:session:changed',nil,nil);assert(not client.Starterpack.vehicle,'session cancellation')
r.fire('onResourceStop',nil,'forge-core');assert(not client.Starterpack.vehicle)
assert(graph.state.PlayerData==data and graph.client.ForgeSession==session and graph.client.Farms==farms)
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending starterpack RPC')
local snap=wire.client.api.request('forge-core:cache:snapshot',nil,nil,10000)
assert(snap.states.starterpack and snap.states.farms and snap.states.stores and not snap.ready,'partial world remains unready')
print('PASS starterpack composition: canonical Player/Lookup/Job/Security/World35/Menu34/Session31 beside Farms43; installed PR RPC/context/recovery/cache/OX adapter, admin denial, parent/back, configuration, once/claims/rewards/reset, partial rollback, scene target and cancellation. Providers/IO/native/JSON durability/FiveM/MIG-23 unverified')
