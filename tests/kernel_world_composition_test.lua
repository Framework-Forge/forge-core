-- Canonical settings34 + server/world35 + client/world35. No live FXServer, file, SQL or UI effects.
local R=dofile('tests/kernel_world_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_server_settings_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('local inputs,alerts=',1,true))
local g=assert(load(source:sub(1,cut-1)..[[
return {graph=graph,base=base,r=r,wire=wire,settings=settings,menus=menus,config=config}
]],'@canonical-settings34','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
local fixture=R.new(true)
fixture.library.framework=setmetatable({},{__index=function()error('forbidden framework cycle')end})
fixture.native.source=function()return wire.server.source end
-- Installed PR cache used passively. No collector or framework fallback.
fixture.native.TriggerClientEvent=function(name,target,packet)
    assert(name=='forge-core:cache:world'and target==-1);r.fire(name,65535,H.copy(packet))
end
local oldQueue,oldTrace=#fixture.queue,#fixture.trace
local server=H.load('kernel/server/world_core.lua',R.env())(base,{
    config=fixture.config,library=fixture.library,native=fixture.native,translate=fixture.translate})
assert(#fixture.queue==oldQueue and #fixture.trace==oldTrace and not server.Density.Service.started,'inactive server world composition')
assert(server.PlayerCore==base.PlayerCore and server.Security==base.Callbacks and server.Settings==g.settings)
assert(base.JobCatalog.Dependencies.State==server.State and base.JobCatalog.Dependencies.DensityService==server.Density.Service)
assert(base.JobCatalog.Dependencies.WeatherService==server.Weather.Service and server.Services.JobService==base.JobCatalog.Service)
assert(not pcall(H.load('kernel/server/world_core.lua',R.env()),base,{}),'duplicate world server refused')
for _,d in ipairs(server.Callbacks)do assert(d.options.access=='admin');base.Callbacks.register(d.name,d.handler,d.options)end
for _,d in ipairs(server.RawCallbacks)do wire.server.api.register(d.name,d.handler)end
-- The old homonymous producer export must not be overwritten by a public installation.
assert(server.World.Exports.GetCachedState==server.State.getRecord and server.State~=base.PlayerCore.State)
config.Weather,config.Density=server.Config.Weather,server.Config.Density
for _,n in ipairs(R.densityNatives)do r.native[n]=function(...)r.record(n,...)end end
r.native.time=function()return 1792483200 end
r.native.TriggerEvent=r.env.TriggerEvent
r.native.TriggerClientEvent=function()error('client must not send world broadcast')end
r.native.source=function()return r.env.source end
r.native.joaat=function(v)return tostring(v):lower()end
local context=graph.context.api
local fetches=0
local admin={root='renewed_weather:admin',data={},t=function(k)return k end,fetch=function()fetches=fetches+1;return true end}
-- Whole installed external entry. Provider config/permissions/weather engine are not mocked as verified.
local providerExports={}
H.load('../../../[standalone]/Renewed-Weathersync/client/panel/admin_entry.lua',H.environment({
    RenewedWeather={Admin=admin},pr_lib={registerContext=context.RegisterContext,showContext=context.ShowContext},
    RegisterNetEvent=function()end,exports=function(name,fn)providerExports[name]=fn end}))
local integration={resourceState=function(name)assert(name=='Renewed-Weathersync');return'started'end,
    openWeatherAdmin=function(name,parent,owner)assert(name=='Renewed-Weathersync');return providerExports.OpenWeatherAdmin(parent,owner)end}
local ports={client=graph.client,config=config,library=r.library,native=r.native,weatherAdminIntegration=integration}
oldTrace,oldQueue=#r.trace,#r.queue
local client=H.load('kernel/client/world_core.lua',R.env())(graph.state,ports)
assert(#r.trace==oldTrace and #r.queue==oldQueue,'inactive client world composition')
assert(client.Menu==g.menus.Menu and client.Shared==g.menus.Shared and client.Producer==graph.producer)
assert(client.WorldState==graph.client.WorldState and client.WorldState~=graph.state and client.WorldState~=graph.producer.Session)
assert(not pcall(H.load('kernel/client/world_core.lua',R.env()),graph.state,ports),'duplicate world client refused')
graph.register(client.Events)
server.World.Initialize();client.World.Initialize()
server.Density.Service.start();fixture.advance(0)
assert(client.WorldState.get('density').values.peds==0.8,'actual public delta reaches same client world')
-- Actual Security, local JobService and PR callback transport, not a framework adapter.
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
wire.playerSource=1
local ok,err=rpc(config.Density.Callbacks.saveSettings,{enabled=false});assert(not ok and err=='no_permission')
ok,err=rpc(config.Weather.Callbacks.setTime,12,0);assert(not ok and err=='no_permission')
wire.playerSource=2
ok,err=rpc(config.Weather.Callbacks.setTime,25,90);assert(ok and err.hour==23 and err.minute==59)
ok,err=rpc(config.Weather.Callbacks.setFreezeTime,true);assert(ok and fixture.weatherData.freezeTime)
ok,err=rpc(config.Weather.Callbacks.setFreezeTime,false);assert(ok and not fixture.weatherData.freezeTime,'PR snapshot verifies unfreeze false return')
-- Parent34 -> density -> real sliders -> local service/PR JSON -> delta -> frame/periodic.
g.menus.Menu.openServerSettingsMenu()
context.RegisterContext({id='forge_core_main',title='Root',options={}})
context.HandleSelect('forge_core_server_settings',6)
assert(context.GetOpenContextMenu()=='forge_core_density')
r.library.menus.InputDialog=function(_,fields)
    assert(#fields==5 and fields[1].type=='slider');return{0.1,0.2,0.3,0.4,0.5}
end
fixture.now=fixture.now+1
context.HandleSelect('forge_core_density',2);fixture.advance(0);r.advance(1100)
assert(server.State.get('density').values.peds==0.4 and client.WorldState.get('density').values.peds==0.4)
assert(fixture.m.files[config.Density.Storage.file],'density JSON persisted only in memory')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
-- Client frame and long workers are explicitly scheduled only here.
local frame=coroutine.create(client.Density.Threads[1]);assert(coroutine.resume(frame))
local periodic=coroutine.create(client.Density.Threads[2]);local alive,delay=coroutine.resume(periodic);assert(alive and delay==10000)
local found=false
for _,e in ipairs(r.trace)do if e.kind=='SetPedDensityMultiplierThisFrame'and e.args[1]==0.4 then found=true end end
assert(found,'actual density worker reads public state, not PlayerData')
-- Failed JSON must not publish a new public revision.
local revision=server.State.getRecord('density').revision
fixture.m.onWrite=function()return false end
ok,err=rpc(config.Density.Callbacks.saveSettings,{enabled=false});assert(not ok and err=='save_failed')
assert(server.State.getRecord('density').revision==revision)
fixture.m.onWrite=nil
-- Whole external panel entry keeps both parent and resource owner.
context.HandleSelect('forge_core_server_settings',4)
assert(context.GetOpenContextMenu()==admin.root and admin.parentMenu=='forge_core_server_settings'and admin.parentResource=='forge-core'and fetches==1)
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
-- Raw public snapshot: partial world is not globally hydrated; no false all-domains-ready claim.
local snapshot=wire.client.api.request('forge-core:cache:snapshot',nil,nil,10000)
assert(snapshot.states.density and not snapshot.ready)
assert(not client.WorldState.refresh(),'remaining nine producers not ported by this slice')
-- Read copy, spoofed delta, old generation/revision and stop do not mutate player authority.
local copy=client.WorldState.get('density');copy.enabled=false;assert(client.WorldState.get('density').enabled)
local forged={generation=snapshot.generation+1,states={}}
r.fire('forge-core:cache:world',2,forged);assert(client.WorldState.get('density'))
assert(graph.state.PlayerData.citizenid=='PATIENT'and base.PlayerCore.Lookup.GetPlayer(1).PlayerData.citizenid=='PATIENT')
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending world RPC')
r.fire('onResourceStop',nil,'forge-core')
assert(client.WorldState.get('density')==nil,'world stop clears only world namespace')
assert(graph.state.PlayerData.citizenid=='PATIENT','world view never replaces PlayerData')
print('PASS world composition: canonical Player/Job/Security/settings34/Menu/Shared/Producer, actual PR RPC/context/passive cache/JSON/weather adapter and whole Renewed panel entry; admin refusal/edit/save/failure/delta/frame/parent/hydration/stop; provider engine, raw PR panel/public export binder and real natives/IO/network/boot still pending')
