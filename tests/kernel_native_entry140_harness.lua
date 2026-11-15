local M=dofile('tests/kernel_native_profile_harness.lua');local S=dofile('tests/kernel_core_services_harness.lua');local H=M.H
local T={M=M,S=S,H=H,root='../../../../.planning/migration/staging/'}
function T.read(path)local f=assert(io.open(T.root..path,'rb'));local text=f:read('*a');f:close();return text end
function T.client()
    local r=M.client();r.seed.Close();r.seedUnit.wire.close();local services=S.new('client');services.wire.scopes.client.Close();r.rawFixture=services
    local env=H.environment();for k,v in pairs(r.profilePorts.environment)do env[k]=v end
    for k,v in pairs(services.ports.native)do env[k]=v end;for k,v in pairs(r.seedUnit.seedPorts.native)do env[k]=v end
    local c=r.bootstrapPorts.context.runtimeContext.deliveryContext.configurationContext.mediaContext.worker.central
    for name,fn in pairs(c.native)do if rawget(env,name)==nil then env[name]=fn end end
    local names=H.load('kernel/entry/native_graph_ports.lua',H.environment()).DescribeClientNatives()
    for _,name in ipairs(names)do env[name]=assert(c.native[name],name)end
    env.GetCurrentResourceName=function()return'forge-core'end;env.IsDuplicityVersion=function()return false end
    env.LoadResourceFile=r.seedUnit.seedPorts.native.LoadResourceFile;env.SaveResourceFile=r.seedUnit.seedPorts.native.SaveResourceFile
    env.SetVehicleDoorsLocked=function()error('client key native not requested in140')end;env.vec4=r.configuration.ports.vec4
    env.PRCore=r.seedUnit.ioFixture.core;env.exports=services.external;env.exports.pr_carkeys=r.configuration.raw;env.exports.qbx_vehiclekeys=r.configuration.qbx
    env.GetInvokingResource=services.ports.native.GetInvokingResource;env.DoesPlayerExist=services.ports.native.DoesPlayerExist
    env.TriggerServerEvent=services.ports.native.TriggerServerEvent;env.TriggerClientEvent=services.ports.native.TriggerClientEvent
    env.GetConvarInt=services.ports.native.GetConvarInt;env.GetConvar=r.seedUnit.seedPorts.native.GetConvar
    env.Debug=function()end;env.Lang={t=function(_,key)return key end};env.source=0;env.json=r.seedUnit.ioFixture.codec;env.os=os;env.debug=debug;env.coroutine=coroutine;env.load=load;env._ENV=env
    local entry;local raw=assert(load(T.read('125/pr_bridge/bridge/forge_raw_core.lua'),'@@raw125','t',env))()({isCurrent=function()return r.nativeCurrent end,
        namespaceAvailable=services.wire.ports.client.available,beforeClose=function()return not entry or entry.Stop()end})
    assert(raw.Prepare());services.wire.scopes.client=raw.RPC;assert(services.wire.scopes.server.Open());r.raw=raw;r.env140=env
    r.options140={base=r.fixture.state,bootstrap=r.bootstrapPorts,public={},nativeCache=r.runtimeImports.nativeCache,events=r.events,
        locale=function(...)return ...end,inventoryBridgeProbe=function()return{}end,isCurrent=function()return r.nativeCurrent end,onError=error}
    r.factory140=assert(load(T.read('140/pr_bridge/bridge/forge_native_profile.lua'),'@@entry140','t',env))()
    function r.allocate140()entry=r.factory140(raw,r.options140);r.entry140=entry;return entry end
    function r.finish140()
        if entry then entry.Stop();r.clock.advance(120000);entry.Poll()end;raw.Close();services.close();r.uiFixture.finish()
    end
    return r
end
return T
