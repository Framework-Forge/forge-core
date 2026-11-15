local M=dofile('tests/kernel_native_profile_harness.lua');local H=M.H;local r=M.server()
local root='../../../../.planning/migration/staging/'
local function read(path)local f=assert(io.open(root..path,'rb'));local text=f:read('*a');f:close();return text end
r.seed.Close();r.servicesFixture.api.Close();r.servicesFixture.wire.close()
local env=H.environment();for k,v in pairs(r.seedPorts.environment)do env[k]=v end
for k,v in pairs(r.servicesFixture.ports.native)do env[k]=v end;for k,v in pairs(r.seedPorts.native)do env[k]=v end
env.GetResourceState=r.servicesFixture.ports.native.GetResourceState
env.PRCore=r.servicesFixture.wire.prs.server;env.exports=r.servicesFixture.external;env.json=r.ioFixture.codec;env.source=0
env.promise=r.servicesFixture.ports.environment.promise;env.Citizen=r.servicesFixture.ports.environment.Citizen
env.Debug=function()end;env.Lang={t=function(_,key)return key end};env.load=load;env.coroutine=coroutine;env._ENV=env
env.joaat=function(value)return value end -- Explicit unused server hash native;client hashing is covered by131.
local entry;local rawFactory=assert(load(read('125/pr_bridge/bridge/forge_raw_core.lua'),'@@raw125','t',env))()
local raw=rawFactory({isCurrent=function()return r.nativeCurrent end,namespaceAvailable=r.servicesFixture.wire.ports.server.available,
    beforeClose=function()return not entry or entry.Stop()end})
assert(raw.Prepare());local runtime=r.profilePorts.bootstrap.context.deliveryContext.mediaContext.supportContext.configurationContext.vehicleContext.bankingContext.operationsContext.inventoryContext.startup.lifecycle.worker.graph.central.runtime
runtime.native.GetConvar,runtime.native.GetConvarInt=env.GetConvar,env.GetConvarInt
r.profilePorts.bootstrap.context.locale.readFile=env.LoadResourceFile;r.profilePorts.bootstrap.context.locale.decode=env.json.decode
entry=assert(load(read('135/pr_bridge/bridge/forge_native_profile.lua'),'@@profile135','t',env))()(raw,{isCurrent=function()return r.nativeCurrent end,
    base=r.fixture.base,bootstrap=r.profilePorts.bootstrap,barrier=r.barrier,public={},nativeCache={resource='forge-core',game='fxserver'},
    events=r.events,inventoryBridgeProbe=function()return r.descriptor end,onError=error})
assert(entry.Progress().phase=='allocated'and not entry.Start());local ok,reason=entry.Prepare('pt-br');assert(ok,reason)
r.surface.Open();assert(entry.Install());r.api=entry;r.emit('onResourceStart','forge-core');r.begin();if coroutine.status(r.co)~='dead'then r.resume()end
assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[3]or r.outcome[2]));assert(entry.Progress().phase=='running')
assert(raw.RPC==env.PRCore.forgeOwnedCallbacks and raw.Services==env.PRCore.forgeCoreServices)
entry.Stop();r.clock.advance(1200000);assert(entry.Poll()and entry.Progress().complete and env.PRCore.forgeNativeProfileEntry==nil)
assert(raw.RPC.Owners.native.IsReady());assert(raw.Close()and raw.Progress().complete and #r.ioFixture.writes==0)
print('PASS lot135 physical server entry after actual raw125,local PRCore/seed/profile,Prepare/Install/Start/Stop,borrowed raw drained last;native SQL/platform virtual')
