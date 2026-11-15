-- Same graph through lot41, actual PR RPC/context/cache/recovery/OX adapter, virtual OX provider and native effects.
local R=dofile('tests/kernel_stores_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_billboards_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('\ngraph.register(g.worldClient.Events)',1,true))
local g=assert(load(source:sub(1,cut-1)..[[
return {graph=graph,base=base,r=r,wire=wire,config=config,worldServer=g.worldServer,worldClient=g.worldClient,
 worldFixture=g.worldFixture,settings=g.settings,menus=g.menus,boardsServer=server,boardsClient=client}
]],'@canonical-world35-billboards41','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
local fixture=R.new(true)
fixture.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
fixture.native.GetGameTimer=g.worldFixture.native.GetGameTimer
local trace,size=#fixture.trace,#fixture.m.trace
local server=H.load('kernel/server/stores_core.lua',R.env())(base,{
 config=fixture.config,library=fixture.library,native=fixture.native,clock=fixture.clock,
 translate=fixture.translate,inventoryIntegration=fixture.inventoryIntegration})
assert(#fixture.trace==trace and #fixture.m.trace==size and not server.Service.initialized,'inert server composition')
assert(server.Security==base.Callbacks and server.State==g.worldServer.State and server.PlayerCore==base.PlayerCore)
assert(base.JobCatalog.Dependencies.StoresService==server.Service and base.JobCatalog.Dependencies.BillboardsService==g.boardsServer.Service)
assert(not pcall(H.load('kernel/server/stores_core.lua',R.env()),base,{}),'duplicate server refused')
for _,d in ipairs(server.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
config.Stores=server.Config.Stores
R.platform(r)
-- Native blips/targets are boundary doubles; no Cfx UI or inventory process.
local originalData,session,boards=graph.state.PlayerData,graph.client.ForgeSession,graph.client.Billboards
trace=#r.trace
local client=H.load('kernel/client/stores_core.lua',R.environment())(graph.state,{
 client=graph.client,config=config,library=r.library,native=r.native,translate=fixture.translate})
assert(#r.trace==trace and not client.Stores.ready and #client.Threads==1 and #client.Events==4,'inert target/menu constructor')
assert(client.WorldState==g.worldClient.WorldState and client.Menu==g.boardsClient.Menu and client.Shared==g.boardsClient.Shared)
assert(not pcall(H.load('kernel/client/stores_core.lua',R.env()),graph.state,{}),'duplicate client refused')
assert(client.Player.GetPlayerIdentifier()==(graph.state.PlayerData.citizenid or graph.state.PlayerData.identifier or graph.state.PlayerData.charId))
graph.register(g.worldClient.Events);graph.register(client.Events)
for _,d in ipairs(client.Subscriptions)do client.WorldState.onChange(d.key,d.handler)end
g.worldServer.World.Initialize();g.worldClient.World.Initialize()
server.Service.start();g.worldFixture.advance(0);r.advance(0)
assert(client.Stores.ready and #client.Stores.zones==2 and #client.Stores.blips==1,'actual world delta builds two targets/one blip')
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
local function flush()g.worldFixture.advance(0);r.advance(0)end
local function nextTick()g.worldFixture.now=g.worldFixture.now+1 end
wire.playerSource=1
local ok,p=rpc(config.Stores.Callbacks.getAll);assert(ok and #p.stores==1,'public store read')
for _,method in ipairs({'saveSettings','createStore','updateStore','deleteStore'})do
 ok,p=rpc(config.Stores.Callbacks[method],'market',{});assert(not ok and p=='no_permission','admin policy '..method)
end
local pc=base.PlayerCore
local player=assert(pc.Lookup.GetPlayer(1));assert(server.Player.GetPlayerData(1)==player.PlayerData,'same canonical player reference')
local oldJobs,oldJob=player.PlayerData.jobs,player.PlayerData.job
fixture.players[1]=player
for _,membership in ipairs({{jobs={police=2},job={name='police',grade={level=1}}},{jobs={},job={name='police',grade={grade=3}}},{jobs={},job={name='none',grade=0}}})do
 player.PlayerData.jobs,player.PlayerData.job=membership.jobs,membership.job
 for _,group in ipairs({'police','POLICE','none','missing'})do
  for _,grade in ipairs({false,0,2,4})do
   local required=grade~=false and grade or nil
   assert(server.Player.PlayerHasJob(1,group,required)==fixture.player.PlayerHasJob(1,group,required),'installed PR membership policy parity')
  end
 end
end
player.PlayerData.jobs,player.PlayerData.job=oldJobs,oldJob
assert(server.Player.GetPlayerData(999)==nil and not server.Player.PlayerHasJob(999,'police',0))
pc.Players.SetMoney(1,'cash',1000,'fixture-setup')
local before=pc.Players.GetMoney(1,'cash')
nextTick();ok,p=rpc(config.Stores.Callbacks.buyStore,'market','cash');assert(ok,'purchase ownership')
assert(server.Service.state.stores[1].owner==player.PlayerData.citizenid and pc.Players.GetMoney(1,'cash')==before-100)
flush();local targetCount=r.targetId
nextTick();ok,p=rpc(config.Stores.Callbacks.addStockFromPlayer,'market','burger',8,19);assert(ok and server.Service.state.stores[1].stock.burger==8)
flush();assert(r.targetId==targetCount,'stock delta does not rebuild target')
nextTick();ok,p=rpc(config.Stores.Callbacks.buyItem,'market','burger',2);assert(ok and p.total==38 and p.stock==6)
assert(pc.Players.GetMoney(1,'cash')==before-138 and server.Service.state.stores[1].balance==38)
flush();assert(r.targetId==targetCount,'financial delta does not rebuild target')
nextTick();ok,p=rpc(config.Stores.Callbacks.withdraw,'market');assert(ok and p==38 and pc.Players.GetMoney(1,'cash')==before-100)
local payload=server.Service.getAll();local snapshot=g.worldServer.State.getRecord('stores')
fixture.m.onWrite=function()return false end
nextTick();ok,p=rpc(config.Stores.Callbacks.buyItem,'market','burger',1)
assert(not ok and p=='save_failed'and pc.Players.GetMoney(1,'cash')==before-100,'failed persistence compensates local money')
H.same(g.worldServer.State.getRecord('stores'),snapshot,'failed store save no publication')
fixture.m.onWrite=nil
local balance=pc.Players.GetMoney(1,'cash')
local purchaseHandler=assert(fixture.purchaseListeners[server.Service.purchaseHookId])
nextTick();purchaseHandler(true,{source=1,shopType='forge_core_store_market',itemName='burger',count=1,totalPrice=19,currency='money'})
assert(server.Service.state.stores[1].stock.burger==5 and pc.Players.GetMoney(1,'cash')==balance,'post purchase reconciliation never charges core twice')
wire.playerSource=2
local context=graph.context.api
context.RegisterContext({id='forge_core_main',title='Root',options={}})
client.Menu.openServerSettingsMenu();context.HandleSelect('forge_core_server_settings',23)
assert(context.GetOpenContextMenu()=='forge_core_stores_admin','parent34 to stores42: '..tostring(context.GetOpenContextMenu()))
context.HandleSelect('forge_core_stores_admin',4);assert(context.GetOpenContextMenu()=='forge_core_store_admin_market')
context.HandleSelect('forge_core_store_admin_market',2);assert(context.GetOpenContextMenu()=='forge_core_store_points_market')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_store_admin_market')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_stores_admin')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
nextTick();ok,p=rpc(config.Stores.Callbacks.updateStore,'market',{points={{coords={x=0,y=0,z=0}},{coords={x=51,y=0,z=0}}}})
assert(not ok and p=='store_point_out_of_range')
nextTick();ok,p=rpc(config.Stores.Callbacks.updateStore,'market',{points={{coords={x=0,y=0,z=0}},{coords={x=50,y=0,z=0}}}});assert(ok)
flush();assert(r.targetId>targetCount,'structural update rebuilds target')
nextTick();ok,p=rpc(config.Stores.Callbacks.saveSettings,{enabled=true,salesEnabled=true,blacklist={burger=true}});assert(ok)
wire.playerSource=1
nextTick();ok,p=rpc(config.Stores.Callbacks.buyItem,'market','burger',1);assert(not ok and p=='blacklisted_item')
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending stores RPC')
local snap=wire.client.api.request('forge-core:cache:snapshot',nil,nil,10000);assert(snap.states.stores and not snap.ready,'partial world not ready')
r.fire('onResourceStop',nil,'forge-core');assert(#client.Stores.zones==0 and #client.Stores.blips==0)
assert(graph.state.PlayerData==originalData and graph.client.ForgeSession==session and graph.client.Billboards==boards)
print('PASS stores composition: canonical Player/Lookup/money/Job/Security/World35/Menu34 beside Billboards41; actual PR RPC/context/cache/recovery/OX adapter, public read/admin refusal/ownership/deposit/fixed-price purchase/withdraw/rollback/post-purchase/no duplicate debit/points/blacklist/parents/stop. OX provider/checkout/binders/native UI/JSON durability/FiveM boot remain unverified')
