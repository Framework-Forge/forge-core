local S=dofile('tests/kernel_native_bootstrap_harness.lua');local C=dofile('tests/kernel_native_client_bootstrap_harness.lua');local H=S.H
local T={S=S,C=C,H=H}
local function loadModule(name)return H.load('kernel/compat/qbx/'..name..'.lua',H.environment())end
function T.new(side)
    local r=side=='server'and S.server()or C.new();r.caller='consumer103';r.invoker='qbx_core';r.relayCurrent=true;r.gatewayReady=true;r.published={};r.foreign={}
    r.origin=loadModule('call_origin')({running=coroutine.running,getInvokingResource=function()return r.invoker end,isCurrent=function()return r.nativeCurrent end})
    if side=='server'then r.bootstrapPorts.context=loadModule('origin_bindings')(r.importPorts,r.origin)end
    r.prepareBootstrap();r.startBootstrap()
    r.catalog=loadModule('export_catalog')(r.graph,side,{isCurrent=function()return r.api.IsCurrent()end})
    r.gatewayPorts={generation='core103-A',isCurrent=function()return r.api.IsCurrent()end,
        isReady=function()if r.readyHook then r.readyHook()end;return r.gatewayReady end,getInvokingResource=function()return r.invoker end}
    r.gateway=loadModule('export_gateway')(r.catalog,r.origin,r.gatewayPorts);assert(r.gateway.Open())
    r.relayPorts={getCurrentResourceName=function()return r.resource or'qbx_core'end,getInvokingResource=function()return r.caller end,
        isCurrent=function()return r.relayCurrent end,
        describe=function()if r.describeHook then r.describeHook()end;local data=r.gateway.Describe();if r.dataHook then r.dataHook(data)end;return data end,
        call=function(...)
            if r.callHook then r.callHook(...)end
            return r.gateway.Call(...)
        end,
        available=function(name)if r.availableHook then r.availableHook(name)end;return not r.foreign[name]and not r.published[name]end,
        publishExport=function(name,fn)r.published[name]=fn;if r.publishHook then return r.publishHook(name,fn)end end}
    r.relayFactory=loadModule('export_relay');r.relay=r.relayFactory(side,r.relayPorts)
    function r.installRelay()assert(r.relay.Prepare());return r.relay.Install()end
    function r.finish()r.relay.Close();r.gateway.Close();r.catalog.Close();r.origin.Close();return r.drain()end
    return r
end
return T
