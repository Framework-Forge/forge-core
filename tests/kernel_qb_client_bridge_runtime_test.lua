local T=dofile('tests/kernel_qb_client_bridge_harness.lua');local H=T.H
local r=T.runtime();local state=r.fixture.state;local graph=r.graph;local central=graph.Central
local object=r.qb.GetCoreObject();assert(object.PlayerData==state.PlayerData)
assert(r.qbBackend.State==state and r.qbBackend.Helpers==central.Parts.Helpers.Lib)
assert(r.qbBackend.NativeCache==state.ClientRuntimeImportContext.Imports.NativeCache)
assert(r.qbBackend.Config.Client==central.Config.Client and r.qbBackend.Config.Client==state.ClientConfigurationContext.Config.Client)
assert(object.Shared.Vehicles==state.Shared.Vehicles and object.Shared.Weapons==state.Shared.Weapons and state.Shared.Items==nil)
assert(object.Shared.Jobs==central.Parts.Legacy.Groups.GetJobs()and object.Shared.Gangs==central.Parts.Legacy.Groups.GetGangs())
assert(object.Functions.GetPlayerData()==state.PlayerData)
local runtimeTrace=r.fixture.central.runtime.trace
local beforeNotify=#runtimeTrace
object.Functions.Notify('QB92 internal notification','inform',2000)
assert(#runtimeTrace==beforeNotify+1 and runtimeTrace[#runtimeTrace].kind=='notify')
assert(runtimeTrace[#runtimeTrace].args[1].description=='QB92 internal notification')
assert(r.installLocale(),'open the existing virtual provider scopes before key ingress')
r.configuration.states.pr_carkeys='started'
local keyReads=0
r.configuration.keyHook=function()keyReads=keyReads+1 end
for _,d in ipairs(r.qb.Events)do if d.name=='QBCore:Client:VehicleInfo'then
    d.handler({netId=100,seat=-1,event='Entered',name='server-name'})
end end
assert(keyReads==1,'VehicleInfo must use canonical Client config and installed PR key provider')
local initial=object.PlayerData
state.PlayerData={citizenid='QB92',money={cash=25},job={name='police'},charinfo={firstname='Ana',lastname='Forge',birthdate='2000-01-02',gender=1},gang={name='none'},metadata={}}
assert(object.Functions.GetPlayerData()==state.PlayerData and object.PlayerData==initial)
-- Client PR80 shares current data through its existing passive cache, never through a QBX export.
local A=dofile('tests/kernel_forge_adapter_harness.lua');local pr=A.new(true)
pr.ports.readSessionReady=state.Session.isLoaded;pr.api=H.load(A.path,H.environment())(pr.ports)
pr.cached=state.PlayerData;pr.session={authenticated=true};pr.api.Events[1].handler(state.PlayerData)
assert(pr.api.Framework.GetPlayerData()==state.PlayerData)
local routing=H.load('../pr_bridge/bridge/frameworks/forge/routing_factory.lua',H.environment())({active={frameworks='forge'},config={},contracts={qb=true},
    isCurrent=function()return r.qbCurrent end,readDeclarations=function()return{'forge'}end})
local host=H.load('../pr_bridge/bridge/frameworks/forge/native_host_factory.lua',H.environment())({resourceName='forge-core',
    isCurrent=r.qb.IsCurrent,isReady=function()return r.qbReady end,getNativeOwner=function()return'forge-core'end,
    getBridgeSetting=function()return'true'end,contracts={qb=true},routing=routing,getCoreObject=r.qb.GetCoreObject})
assert(host.GetCoreObject()==object and host.GetCoreObject({'Functions'})==object)
assert(host.Exports.getQBCoreObject().Functions.GetPlayerData()==state.PlayerData)
r.qbReady=false;assert(not pcall(host.GetCoreObject));r.qbReady=true
local old=central.Parts.Legacy.Functions.Notify;central.Parts.Legacy.Functions.Notify=function()error('foreign')end
assert(not r.qbBackend.IsCurrent()and not pcall(host.GetCoreObject));central.Parts.Legacy.Functions.Notify=old
host.Close();routing.Close();pr.api.Close();r.qb.Close()
assert(state.PlayerData.citizenid=='QB92'and r.qb.Progress().complete and r.qbBackend.Progress().complete)
r.api.Stop();r.clock.advance(120000);r.api.Poll();assert(r.api.Progress().complete)
local x=T.runtime();x.backendReadyHook=function()coroutine.yield('backend_ready')end
local co=coroutine.create(x.qbBackend.Core.GetPlayerData);assert(coroutine.resume(co));assert(x.qbBackend.Progress().pending==1)
x.qbBackend.Close();assert(not x.qbBackend.Progress().complete);x.backendReadyHook=nil
assert(not coroutine.resume(co)and x.qbBackend.Progress().complete);x.closeQb()
print('PASS lot92 actual75/49/80/86:4 internal services,same PlayerData/Helpers/groups/Client config/native cache,getter+native host,stale/ready/await guards,no QBX receiver or second authority')
