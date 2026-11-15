-- Actual canonical Player/Job/Security/Shared/runtime/helpers and PR transport/context/cache/database.
-- All SQL/files/entities/items/time/network remain virtual. Missing PR binder is an explicit test boundary.
local R=dofile('tests/kernel_vehicles_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_world_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('graph.register(client.Events)',1,true))
local g=assert(load(source:sub(1,cut-1)..[[
return {graph=graph,base=base,r=r,wire=wire,config=config,worldServer=server,worldClient=client}
]],'@canonical-world35-settings34','t',_ENV))()
local base,graph,r,wire,config=g.base,g.graph,g.r,g.wire,g.config
local state=base.PlayerCore.State
local runtimeFixture=dofile('tests/kernel_server_runtime_harness.lua').new(true,'commands')
-- Seed the canonical Shared once, before attaching its runtime. No service state is cloned.
local shared=H.load('kernel/shared/main.lua',R.env())({weapons=state.Shared.Weapons or{},locations=state.Shared.Locations or{}})
state.Shared=shared
local clientShared=H.load('kernel/shared/main.lua',R.env())({weapons={},locations={}})
graph.state.Shared=clientShared
local clientRuntimeFixture=dofile('tests/kernel_client_runtime_harness.lua')
-- The existing client main09 setter operates over the same client state/Shared.
local mainNative={}
for k,v in pairs(r.native)do mainNative[k]=v end
mainNative.GetDisplayNameFromVehicleModel=function()return'SULTAN'end
mainNative.AddTextEntryByHash=function(...)r.record('vehicle-label',...)end
mainNative.joaat=R.hash
local clientMain=H.load('kernel/client/main.lua',R.env())({core=graph.state,native=mainNative,cache={ped=11},config={},helpers={table={mapBySubfield=runtimeFixture.helpers.table.mapBySubfield}}})
graph.register(clientMain.Events)
local vf=R.new(true)
vf.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
vf.native.source=function()return wire.server.source end
vf.native.TriggerClientEvent=function(name,target,...)
    assert(name=='qbx_core:client:setVehicleCatalog');assert(target==-1 or target==1);r.fire(name,65535,H.copy(...))
end
local helperFixture=dofile('tests/kernel_helpers_harness.lua').new(true,'server')
local helperPorts={}
for k,v in pairs(helperFixture.ports)do helperPorts[k]=v end
helperPorts.shared,helperPorts.functions=shared,base.PlayerCore.Lifecycle.Functions
helperPorts.native.DoesEntityExist=vf.native.DoesEntityExist
helperPorts.native.Entity=function(v)return{state={set=function(_,key,value,replicated)r.record('persisted-state',v,key,value,replicated);vf.persisted=value end}}end
base.Helpers=H.load('kernel/helpers.lua',R.env())(helperPorts)
local runtimePorts={}
for k,v in pairs(runtimeFixture.bindings)do runtimePorts[k]=v end
runtimePorts.helpers=base.Helpers.Lib
runtimePorts.native.TriggerClientEvent=vf.native.TriggerClientEvent
local runtime=H.load('kernel/server/runtime_core.lua',R.env())(base,base.PlayerCore,runtimePorts)
assert(runtime.State==state and base.PlayerCore.Runtime==runtime)
local names,hashes=shared.Vehicles,shared.VehicleHashes
-- Runtime public export keeps rejecting foreign callers; internal Forge projection must not inherit that caller.
runtimeFixture.caller='external-catalog-consumer'
assert(not runtime.Main.SetVehicleCatalog({}),'public setter caller guard retained')
local keyExports,keyRows,keyItems={}, {},{}
local keyCache={}
local keyDelivery=true
H.load('../../../[vehicle_system]/pr_carkeys/server/sv_shop.lua',H.environment({
    exports=function(name,fn)keyExports[name]=fn end,
    PRCarkeys={GenerateBarcode=function()return'ORIGINAL1'end,SanitizePlate=function(p)return p end,
        ResolveKeyItem=function()return'carkey_permanent'end,
        Cache={GetKey=function(k)return keyCache[k]end,SetKey=function(k,v)keyCache[k]=v end}},
    Config={Sound={soundDefault=1},Default={UseKeyAnim={DefaultDistance=10}}},
    ExecuteSQLInsert=function(sql,params)keyRows[#keyRows+1]={sql=sql,params=H.copy(params)};return 88 end,
    Bridge={framework={GetIdentifier=function(src)local p=base.PlayerCore.Lookup.GetPlayer(src);return p and p.PlayerData.citizenid end},
        inventory={AddItem=function(...)keyItems[#keyItems+1]=H.copy({...});return keyDelivery end},notify={Notify=function()end}},
    Debug=function()end,os={time=function()return 1792483200 end}}))
-- Whole installed garage entry handler, not the rest of its persistent-controller lifecycle.
local garageFile=assert(io.open('../forge-garage/client/persist.lua','r'));local garageSource=garageFile:read('*a'):gsub('\r\n','\n');garageFile:close()
local entry=assert(garageSource:match("(RegisterNetEvent%('forge_garage:client:registerExistingPersistentVehicle', function%(plate, netId%)\n.-\nend%))"))
local garage,spawnedVehs,spawnedPlates=nil,{},{}
assert(load(entry,'@installed-garage-entry','t',H.environment({
    RegisterNetEvent=function(_,fn)garage=fn end,NetworkGetEntityFromNetworkId=function(id)return id==501 and 101 or 0 end,
    DoesEntityExist=vf.native.DoesEntityExist,Entity=function(v)return{state={set=function(_,...)r.record('garage-state',v,...)end}}end,
    spawnedVehs=spawnedVehs,spawnedPlates=spawnedPlates,pr_lib={cache=r.library.cache}})))()
local integration={resourceState=vf.integration.resourceState,buyOriginalKey=keyExports.BuyOriginalKey,
    registerExistingPersistentVehicle=function(target,plate,netId)assert(target==-1);garage(plate,netId)end}
vf.library.callback.awaitClient=function(target,name,timeout,...)
    local oldPlayer,oldSource=wire.playerSource,wire.server.source;wire.playerSource=target
    local result=table.pack(pcall(wire.server.api.request,name,target,nil,timeout,...))
    wire.playerSource,wire.server.source=oldPlayer,oldSource
    assert(result[1],result[2]);return table.unpack(result,2,result.n)
end
local oldTrace,oldTimers=#vf.trace,#vf.timers
local server=H.load('kernel/server/vehicle_core.lua',R.env())(base,{
    config=vf.config,library=vf.library,native=vf.native,translate=vf.translate,catalogFile=vf.catalogFile,
    json=vf.json,compile=load,coreState=function()return'started'end,vehicleIntegration=integration})
assert(#vf.trace==oldTrace and #vf.timers==oldTimers,'inactive vehicle server composition')
assert(server.PlayerCore==base.PlayerCore and server.Runtime==runtime and server.Helpers==base.Helpers and server.Security==base.Callbacks)
assert(server.Projection.Shared==shared and server.Projection.State==state and base.JobCatalog.Dependencies.VehicleService==server.Service)
assert(not pcall(H.load('kernel/server/vehicle_core.lua',R.env()),base,{}),'duplicate server attachment refused')
for _,d in ipairs(server.Callbacks)do assert(d.options.access=='admin');base.Callbacks.register(d.name,d.handler,d.options)end
assert(server.Initialize()and not server.Initialize());vf.runTimers(0)
assert(shared.Vehicles==names and shared.VehicleHashes==hashes and names.sultan and not names.disabled,'catalog indices updated in place')
assert(clientShared.Vehicles.sultan and clientShared.VehicleHashes[R.hash('sultan')],'actual main09 receives main10 contract')
assert(runtime.Main.GetVehiclesByCategory().sports[1].model=='sultan','runtime category query shares catalog')
config.Vehicles=server.Config.Vehicles
-- Actual PR streaming creates only the virtual vehicle; properties remain a declared native fixture.
local clientFixture=R.menu(true)
for n,fn in pairs(clientFixture.native)do if n~='SetTimeout'and n~='CreateThread'and n~='Wait'then r.native[n]=fn end end
r.native.GetGameTimer=function()return r.now end
r.native.joaat=R.hash
local streamingEnv=H.environment({Bridge={debug={warn=function(...)r.record('stream-warning',...)end}},vector3=R.vector,
    joaat=R.hash,GetGameTimer=r.native.GetGameTimer,Wait=r.native.Wait,
    IsModelInCdimage=function()return true end,HasModelLoaded=function()return true end,
    DoesEntityExist=vf.native.DoesEntityExist,CreateVehicle=function()vf.entities[101]=true;return 101 end,
    SetModelAsNoLongerNeeded=function()end,SetEntityAsMissionEntity=function()end,SetEntityCollision=function()end,
    FreezeEntityPosition=function()end,IsEntityAPed=function()return false end,SetVehicleOnGroundProperly=function()return true end})
local streaming=H.load('../pr_bridge/bridge/fivem/streaming/client.lua',streamingEnv)
r.native.DoesEntityExist=vf.native.DoesEntityExist
r.native.GetVehiclePedIsIn=function()return 101 end
r.native.NetworkGetNetworkIdFromEntity=function()return 501 end
r.native.NetworkGetEntityIsNetworked=function()return true end
r.native.SetVehicleNumberPlateText=function(_,plate)vf.plate=plate end
r.library.fivem={streaming=streaming,blips=clientFixture.library.fivem.blips,
    getVehicleProperties=function()return{model=R.hash('sultan'),plate=vf.plate}end}
local oldSnapshot=r.native.GetOffsetFromEntityInWorldCoords
local client=H.load('kernel/client/menu/vehicles_core.lua',R.env())(graph.state,{
    client=graph.client,config=config,library=r.library,native=r.native,random=function()return 42 end})
assert(client.Menu==g.worldClient.Menu and client.Shared==g.worldClient.Shared and client.Producer==graph.producer)
assert(not pcall(H.load('kernel/client/menu/vehicles_core.lua',R.env()),graph.state,{}),'duplicate client attachment refused')
for name,fn in pairs(client.Callbacks)do wire.client.api.register(name,fn)end
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
wire.playerSource=1
local ok,err=rpc(config.Vehicles.Callbacks.save,{model='denied'});assert(not ok and err=='no_permission')
wire.playerSource=2
ok,err=rpc(config.Vehicles.Callbacks.save,{model='new',name='New',class='A',category='sports',hash='new'});assert(ok and names.new,'same local projection even under external export caller')
g.worldClient.Menu.openServerSettingsMenu()
local ctx=graph.context.api
ctx.RegisterContext({id='forge_core_main',title='Root',options={}})
ctx.HandleSelect('forge_core_server_settings',8);assert(ctx.GetOpenContextMenu()=='forge_core_vehicles')
ctx.HandleSelect('forge_core_vehicles',5);assert(ctx.GetOpenContextMenu()=='forge_core_vehicles_category_sports')
ctx.HandleBack();ctx.HandleBack();assert(ctx.GetOpenContextMenu()=='forge_core_server_settings','same settings parent restored')
-- Real snapshot callback -> PR RPC -> local lookup -> actual PR DB adapter (virtual driver) -> installed key provider -> garage entry.
ok,err=rpc(config.Vehicles.Callbacks.adminCarCurrent,1);assert(ok and err.target==1 and err.id==77)
assert(keyRows[1]and keyItems[1]and keyItems[1][1]==1 and vf.persisted==true)
assert(spawnedVehs[501]==101 and spawnedPlates.TEST01==101 and r.library.cache.get('persistent:veh:TEST01')==101)
assert(base.PlayerCore.Lookup.GetPlayer(1).PlayerData.citizenid=='PATIENT'and graph.state.PlayerData.citizenid=='PATIENT')
-- Inherited provider acknowledgement: AddItem false does not make BuyOriginalKey fail.
keyDelivery=false;vf.plate='OTHER';ok,err=rpc(config.Vehicles.Callbacks.adminCarCurrent,1)
assert(ok and #keyItems==2,'provider ignores AddItem acknowledgement, preserved not fixed')
-- Failure before key creation rolls back the virtual owned row; no catalog rollback.
integration.buyOriginalKey=function()return{success=false,reason='full'}end
vf.plate='THIRD';ok,err=rpc(config.Vehicles.Callbacks.adminCarCurrent,1);assert(not ok and err=='full')
local deleted=false;for _,e in ipairs(vf.trace)do if e.kind=='db-execute'and e.args[1]:find('DELETE FROM player_vehicles',1,true)then deleted=true end end
assert(deleted,'owned row rollback via actual PR DB adapter')
-- Use whole installed PR streaming from the actual details action and temporary-key RPC.
integration.buyOriginalKey=keyExports.BuyOriginalKey
client.Menu.openVehicleDetails(server.Service.getEntry('sultan'),'sports')
ctx.HandleSelect('forge_core_vehicle_sultan',2)
assert(vf.plate:sub(1,2)=='FG','client temporary spawn used virtual PR streaming')
ok=rpc(config.Vehicles.Callbacks.setActive,'sultan',false);assert(ok and not names.sultan and not clientShared.Vehicles.sultan)
assert(names==shared.Vehicles and hashes==shared.VehicleHashes,'no replacement catalog tables')
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending vehicle RPC')
print('PASS vehicle composition: canonical Player/Job/Security/runtime10/Shared/main09/helpers07/Menu/settings34, installed PR RPC/context/DB/key adapter/streaming, whole key shop and garage handler in memory; catalog/back/owner/key/rollback/disable, no real SQL/vehicles/items/boot or public PR binder')
