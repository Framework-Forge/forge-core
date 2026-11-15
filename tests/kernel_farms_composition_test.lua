-- One graph through Stores42. Actual local services and PR RPC/context/cache/recovery/OX adapter; native/provider effects virtual.
local R=dofile('tests/kernel_farms_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_stores_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('\ngraph.register(g.worldClient.Events)',1,true))
local g=assert(load(source:sub(1,cut-1)..[[
return {graph=graph,base=base,r=r,wire=wire,config=config,worldServer=g.worldServer,worldClient=g.worldClient,
 worldFixture=g.worldFixture,storesServer=server,storesClient=client}
]],'@canonical-world35-stores42','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
-- The world/stores graph predates runtime10/vehicle36 attachment. Apply the installed private
-- vehicle composition setup to THIS base, rather than borrowing services from a second graph.
local vehicleFile=assert(io.open('tests/kernel_vehicles_composition_test.lua','r'))
local vehicleSource=vehicleFile:read('*a'):gsub('\r\n','\n');vehicleFile:close()
local vehicleStart=assert(vehicleSource:find('local state=base.PlayerCore.State',1,true))
local vehicleEnd=assert(vehicleSource:find('\nconfig.Vehicles=server.Config.Vehicles',vehicleStart,true))
local vehicleEnv=setmetatable({base=base,graph=graph,r=r,wire=wire,config=config,H=H,
 R=dofile('tests/kernel_vehicles_harness.lua')},{__index=_ENV})
local vehicle=assert(load(vehicleSource:sub(vehicleStart,vehicleEnd-1)..'\nreturn {server=server,runtime=runtime,shared=shared}\n',
 '@same-base-vehicle36-setup','t',vehicleEnv))()
config.Vehicles=vehicle.server.Config.Vehicles
local fixture=R.new(true)
fixture.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
fixture.native.GetGameTimer=g.worldFixture.native.GetGameTimer
local trace,size=#fixture.trace,#fixture.m.trace
local server=H.load('kernel/server/farms_core.lua',R.env())(base,{
 config=fixture.config,library=fixture.library,native=fixture.native,clock=fixture.clock,math=fixture.math,
 translate=fixture.translate,inventoryIntegration=fixture.inventoryIntegration,coreState=function()return'started'end})
assert(#fixture.trace==trace and #fixture.m.trace==size and not server.Service.started,'inert farm server')
assert(server.Security==base.Callbacks and server.State==g.worldServer.State and server.PlayerCore==base.PlayerCore)
assert(server.Runtime==base.VehicleCore.Runtime and server.Kernel.getVehiclesByName==base.PlayerCore.Runtime.Main.GetVehiclesByName)
assert(base.JobCatalog.Dependencies.FarmsService==server.Service and base.JobCatalog.Dependencies.StoresService==g.storesServer.Service)
assert(not pcall(H.load('kernel/server/farms_core.lua',R.env()),base,{}),'duplicate farm server refused')
for _,d in ipairs(server.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
config.Farms=server.Config.Farms
local actualMenus,actualInventory,actualAwait,actualMath=r.library.menus,r.library.inventory,r.library.callback.await,r.library.math
R.platform(r);r.library.menus,r.library.inventory,r.library.callback.await,r.library.math=actualMenus,actualInventory,actualAwait,actualMath
r.library.framework=setmetatable({},{__index=function()error('forbidden client framework cycle')end})
local playerData,session,stores=graph.state.PlayerData,graph.client.ForgeSession,graph.client.Stores
trace=#r.trace
local client=H.load('kernel/client/farms_core.lua',R.environment())(graph.state,{
 client=graph.client,config=config,library=r.library,native=r.native,math=r.math,translate=fixture.translate})
assert(#r.trace==trace and not client.Farms.active and #client.Threads==1 and #client.Events==3,'inert farm client')
assert(client.Menu==g.storesClient.Menu and client.Shared==g.storesClient.Shared and client.WorldState==g.worldClient.WorldState)
assert(client.Player.GetPlayerData()==graph.state.PlayerData,'canonical snapshot reference')
assert(not pcall(H.load('kernel/client/farms_core.lua',R.env()),graph.state,{}),'duplicate farm client refused')
graph.register(g.worldClient.Events);graph.register(g.storesClient.Events);graph.register(client.Events)
for _,api in ipairs({g.storesClient,client})do for _,d in ipairs(api.Subscriptions)do api.WorldState.onChange(d.key,d.handler)end end
g.worldServer.World.Initialize();g.worldClient.World.Initialize()
g.storesServer.Service.start();server.Service.start();g.worldFixture.advance(0);r.advance(0)
assert(g.storesClient.Stores.ready and #g.storesClient.Stores.zones==2 and #client.Farms.zones==1,
 'independent stores/farms targets '..tostring(g.storesClient.Stores.ready)..'/'..#g.storesClient.Stores.zones..'/'..#client.Farms.zones)
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
local function flush(ms)g.worldFixture.advance(0);r.advance(ms or 0)end
local function nextTick()g.worldFixture.now=g.worldFixture.now+1 end
wire.playerSource=1
local ok,p=rpc(config.Farms.Callbacks.getAll);assert(ok and #p.farms==1,'public farm read')
for _,method in ipairs({'saveSettings','createFarm','updateFarm','deleteFarm'})do
 ok,p=rpc(config.Farms.Callbacks[method],1,{});assert(not ok and p=='no_permission','admin policy '..method)
end
ok,p=rpc(config.Farms.Callbacks.getGroups,'job');assert(not ok and p=='no_permission','service catalog permission')
local player=assert(base.PlayerCore.Lookup.GetPlayer(1));assert(server.Kernel.GetPlayerData(1)==player.PlayerData)
wire.playerSource=2
assert(vehicle.shared.Vehicles.sultan and vehicle.runtime==base.PlayerCore.Runtime)
ok,p=rpc(config.Farms.Callbacks.getVehicles);assert(ok and #p>0 and p[1].model=='sultan','local vehicle catalog')
ok,p=rpc(config.Farms.Callbacks.getGroups,'job');assert(ok and type(p)=='table','same local job registry')
local context=graph.context.api
context.RegisterContext({id='forge_core_main',title='Root',options={}})
client.Menu.openServerSettingsMenu();context.HandleSelect('forge_core_server_settings',24)
assert(context.GetOpenContextMenu()=='forge_core_farms_admin','parent34 to farms43')
context.HandleSelect('forge_core_farms_admin',3);assert(context.GetOpenContextMenu()=='forge_core_farm_admin_1')
context.HandleSelect('forge_core_farm_admin_1',4);assert(context.GetOpenContextMenu()=='forge_core_farm_items_1')
context.HandleSelect('forge_core_farm_items_1',2);assert(context.GetOpenContextMenu()=='forge_core_farm_item_1_crop')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_farm_items_1')
context.HandleBack();context.HandleBack();context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
r.library.menus.InputDialog=function(_,fields)assert(#fields==2);return{'Edited Farm','true'}end
nextTick();client.Menu.openFarmEdit(1);flush(300)
assert(server.Service.state.farms[1].name=='Edited Farm'and client.Farms.payload.farms[1].name=='Edited Farm','menu RPC/JSON/world update')
local before=g.worldServer.State.getRecord('farms')
fixture.m.onWrite=function()return false end
nextTick();ok,p=rpc(config.Farms.Callbacks.saveSettings,{enabled=false});assert(not ok and p=='save_failed')
H.same(g.worldServer.State.getRecord('farms'),before,'failed farm save no publication');fixture.m.onWrite=nil
wire.playerSource=1
-- The route/collection flow calls the real server handler through the installed PR transport.
local limited=server.Service.getAll().farms[1];limited.items[1].limits={enabled=true,maxPerRoute=1,scope='item'}
wire.playerSource=2;nextTick();assert(rpc(config.Farms.Callbacks.updateFarm,1,limited));flush();wire.playerSource=1
nextTick();r.targets[client.Farms.zones[1]].options[1].onSelect()
context.HandleSelect('forge_core_farm_player_1',1)
assert(client.Farms.active and #client.Farms.routeZones==2 and server.Service.activeRoutes['1:1:crop'])
assert(server.Service.state.usage[player.PlayerData.citizenid..':1:crop'],'usage uses canonical character id')
local progressCount=0
r.progressHook=function(data)progressCount=progressCount+1;assert(data.duration==1000 and data.canCancel);return true end
local cash=player.PlayerData.money.cash
nextTick();r.targets[client.Farms.routeZones[1]].options[1].onSelect()
assert(progressCount==1 and not client.Farms.active and not server.Service.activeRoutes['1:1:crop'],'client max route finishes server route')
assert(fixture.items[1][3].metadata.durability==90 and player.PlayerData.money.cash==cash,'inventory durability separate from core money')
local rewards={};for _,i in pairs(fixture.items[1])do rewards[i.name]=(rewards[i.name]or 0)+i.count end
assert(rewards.burger==12 and rewards.water==1,'virtual primary and extra delivery through actual PR adapter')
-- Preserve the inherited failure semantics rather than claiming an atomic transaction.
server.Service.state.farms[1].items[1].limits={enabled=false}
nextTick();assert(rpc(config.Farms.Callbacks.startRoute,1,'crop'));fixture.addResult=false
nextTick();ok,p=rpc(config.Farms.Callbacks.collect,1,'crop');assert(not ok and p=='add_item_failed'and fixture.items[1][3].metadata.durability==80)
fixture.addResult=nil;assert(server.Service.finishRoute(1,1,'crop'))
server.Service.state.farms[1].items[1].limits={enabled=true,onceDaily=true}
fixture.date='2026-10-22';nextTick();assert(rpc(config.Farms.Callbacks.startRoute,1,'crop'));server.Service.finishRoute(1,1,'crop')
nextTick();ok,p=rpc(config.Farms.Callbacks.startRoute,1,'crop');assert(not ok and p=='daily_limit')
server.Service.state.farms[1].items[1].limits={enabled=false};nextTick();assert(rpc(config.Farms.Callbacks.startRoute,1,'crop'))
assert(server.Events[1].sourceFirst);server.Events[1].handler(1);assert(not server.Service.activeRoutes['1:1:crop'],'explicit source drop cleanup')
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending farms RPC')
local snap=wire.client.api.request('forge-core:cache:snapshot',nil,nil,10000);assert(snap.states.farms and snap.states.stores and not snap.ready,'partial world not ready')
r.fire('onResourceStop',nil,'forge-core');assert(#client.Farms.zones==0 and #client.Farms.blips==0)
assert(graph.state.PlayerData==playerData and graph.client.ForgeSession==session and graph.client.Stores==stores)
print('PASS farms composition: canonical Player/Lookup/JobRegistry/vehicle runtime/Security/World35/Menu34 beside Stores42; installed PR RPC/context/cache/recovery/OX adapter, public read/admin refusal/catalogs/edit/save failure/start/progress/collect/tool/extras/local max route/finish/daily/source drop/back/stop. Provider/native progress/UI/JSON durability/MIG-23/FiveM boot unverified; inherited non-atomic durability and server validation gaps retained')
