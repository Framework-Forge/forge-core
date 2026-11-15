local T=dofile('tests/kernel_engine_profile_harness.lua');local H=T.H;local r=T.new('server')
local root='../../../../.planning/migration/staging/'
local function read(path)local f=assert(io.open(root..path,'rb'));local text=f:read('*a');f:close();return text end
r.seed.Close();r.servicesFixture.api.Close();r.servicesFixture.wire.close()
local env=H.environment();for k,v in pairs(r.seedPorts.environment)do env[k]=v end
for k,v in pairs(r.servicesFixture.ports.native)do env[k]=v end;for k,v in pairs(r.seedPorts.native)do env[k]=v end
env.GetResourceState=r.servicesFixture.ports.native.GetResourceState
env.PRCore=r.servicesFixture.wire.prs.server;env.exports=r.servicesFixture.external;env.json=r.ioFixture.codec;env.source=0
env.promise=r.servicesFixture.ports.environment.promise;env.Citizen=r.servicesFixture.ports.environment.Citizen
env.Debug=function()end;env.Lang={t=function(_,key)return key end};env.load=load;env.coroutine=coroutine;env._ENV=env
env.vec3=r.configFixture144.vec3;env.joaat=function(value)return value end -- Explicit unused server hash native;client hashing is covered by131.
local entry;local rawFactory=assert(load(read('125/pr_bridge/bridge/forge_raw_core.lua'),'@@raw125','t',env))()
local raw=rawFactory({isCurrent=function()return r.nativeCurrent end,namespaceAvailable=r.servicesFixture.wire.ports.server.available,
    beforeClose=function()return not entry or entry.Stop()end})
assert(raw.Prepare());local runtime=r.profilePorts.bootstrap.context.deliveryContext.mediaContext.supportContext.configurationContext.vehicleContext.bankingContext.operationsContext.inventoryContext.startup.lifecycle.worker.graph.central.runtime
runtime.native.GetConvar,runtime.native.GetConvarInt=env.GetConvar,env.GetConvarInt
r.profilePorts.bootstrap.context.locale.readFile=env.LoadResourceFile;r.profilePorts.bootstrap.context.locale.decode=env.json.decode
local player=runtime and r.profilePorts.bootstrap.context.deliveryContext.mediaContext.supportContext.configurationContext.vehicleContext.bankingContext.operationsContext.inventoryContext.startup.lifecycle.worker.graph.central.session.player.platform
for alias,name in pairs({getInvokingResource='GetInvokingResource',getPlayerName='GetPlayerName',getIdentifier='GetPlayerIdentifierByType',getIdentifiers='GetPlayerIdentifiers',dropPlayer='DropPlayer',emitClient='TriggerClientEvent',emitServer='TriggerEvent',getPed='GetPlayerPed',setArmour='SetPedArmour',player='Player',entityExists='DoesEntityExist',getCoords='GetEntityCoords',getHeading='GetEntityHeading'})do if rawget(env,name)==nil then env[name]=player[alias]end end
entry=assert(load(read('150/pr_bridge/bridge/forge_native_profile.lua'),'@@profile150','t',env))()(raw,{isCurrent=function()return r.nativeCurrent end,
    base=r.fixture.base,bootstrap=r.profilePorts.bootstrap,barrier=r.barrier,public={},nativeCache={resource='forge-core',game='fxserver'},
    locale=player.locale,domainLocale=r.configFixture144.locale,events=r.events,inventoryBridgeProbe=function()return r.descriptor end,onError=error})
assert(entry.Progress().phase=='allocated'and not entry.Start());local ok,reason=entry.Prepare('pt-br');assert(ok,reason)
r.surface.Open();assert(entry.Install());r.api=entry;r.emit('onResourceStart','forge-core');r.begin();if coroutine.status(r.co)~='dead'then r.resume()end
assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[3]or r.outcome[2]));assert(entry.Progress().phase=='running')
assert(raw.RPC==env.PRCore.forgeOwnedCallbacks and raw.Services==env.PRCore.forgeCoreServices)
entry.Stop();r.clock.advance(1200000);assert(entry.Poll()and entry.Progress().complete and env.PRCore.forgeNativeProfileEntry==nil)
assert(raw.RPC.Owners.native.IsReady());assert(raw.Close()and raw.Progress().complete);for _,w in ipairs(r.ioFixture.writes)do assert(w[1]=='forge-core')end
print('PASS150 physical server engine profile,installed PRCore recovery,virtual JSON/SQL/native,mapped='..entry.Profile.PortAudit.mapped..' remaining='..#entry.Profile.PortAudit.remaining..';borrowed raw drained last')
