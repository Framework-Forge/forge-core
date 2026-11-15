local R=dofile('tests/kernel_qbx_relay_harness.lua');local Q=dofile('tests/kernel_qb_bridge_harness.lua');local H=R.H
local T={R=R,Q=Q,H=H}
function T.new(enabled)
    local r=R.new('server');local stub=Q.S.new(true);local utility=Q.S.T.shared(true,{})
    stub.lib.math,stub.lib.string=utility.lib.math,utility.lib.string
    local p=stub.ports;p.isCurrent=function()return r.api.IsCurrent()end;p.isReady=function()return true end
    p.convertItems=function()end;p.inventoryItems={};p.legacyItems={};local convar=p.native.GetConvar
    p.native.GetConvar=function(name,fallback)if name=='qbx:enablebridge'then return enabled==false and'false'or'true'end;return convar(name,fallback)end
    r.qbBackend=H.load('kernel/server/qb_compat_backend.lua',H.environment())(r.graph,p)
    r.qb=H.load('kernel/compat/qb/server_main.lua',Q.environment())(r.qbBackend,p)
    r.qbBinding=H.load('kernel/compat/qb/binding_context.lua',Q.environment())(r.graph,r.qb,r.qbBackend,{side='server',
        events=r.api.Transport.Events,public=r.api.Transport.Public,isCurrent=function()return r.api.IsCurrent()end,isReady=function()return true end,
        aliasAvailable=function(name)for _,t in ipairs(r.bus)do if not t.removed and t.name==name then return false end end;return true end})
    if enabled~=false then assert(r.qbBinding.Install())end
    r.extensionReady=true
    r.qbGateway=H.load('kernel/compat/qbx/qb_gateway.lua',H.environment())('server',r.qb,r.qbBinding,r.origin,{
        generation='core106',isCurrent=function()return r.api.IsCurrent()end,isReady=function()return r.extensionReady end,getInvokingResource=function()return r.invoker end})
    r.qbRelayPorts={getCurrentResourceName=function()return'qbx_core'end,getInvokingResource=function()return r.caller end,
        isCurrent=function()return r.relayCurrent end,describe=r.qbGateway.Describe,call=r.qbGateway.Call,
        available=function(name)return r.published[name]==nil end,
        publishExport=function(name,fn)r.published[name]=fn;if r.extraPublishHook then r.extraPublishHook(name,fn)end end}
    r.extraRelay=H.load('kernel/compat/qbx/qb_relay.lua',H.environment())('server',r.qbRelayPorts)
    function r.extraStart()assert(r.extraRelay.Prepare());return r.extraRelay.Install()end
    function r.lookup(name)local fn;r.emit('__cfx_export_qb-core_'..name,function(value)fn=value end);return fn end
    local finish=r.finish
    function r.finish()r.extraRelay.Close();r.qbGateway.Close();r.qbBinding.Close();return finish()end
    return r
end
return T
