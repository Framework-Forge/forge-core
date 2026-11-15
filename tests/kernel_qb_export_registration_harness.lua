local C=dofile('tests/kernel_qb_client_bridge_harness.lua');local S=dofile('tests/kernel_qb_bridge_harness.lua')
local E=dofile('tests/kernel_event_registration_harness.lua');local P=dofile('tests/kernel_public_registration_harness.lua')
local H=C.H;local T={C=C,S=S,E=E,P=P,H=H}
function T.new(side,original)
    local r={side=side or'client',current=true}
    r.bridge=r.side=='client'and C.new(true)or S.new(true)
    r.bus=E.bus();r.surface=P.surface(r.side);r.aliasForeign={}
    r.ports={side=r.side,isCurrent=function()return r.current end,events=r.bus.ports,public=r.surface.ports,
        aliasAvailable=function(name)
            if r.aliasHook then r.aliasHook(name)end
            if r.aliasForeign[name]then return false end
            for _,d in pairs(r.bus.records)do if d.active and d.name==name then return false end end
            return true
        end}
    local env=C.environment()
    if original then
        local originalEnv=H.environment({AddEventHandler=function(name,fn)return r.bus.ports.listen(name,fn)end})
        local createExport=H.load(H.qbx..'bridge/qb/shared/export-function.lua',originalEnv)
        for name,fn in pairs(r.bridge.api.Exports)do createExport(name,fn)end
    else r.api=H.load('kernel/compat/qb/export_registration.lua',env)(r.bridge.api,r.ports)end
    function r.lookup(name)
        local fn;local result=r.bus.emit('__cfx_export_qb-core_'..name,0,function(value)fn=value end)
        return fn,result
    end
    function r.install()assert(r.api.Install());return r end
    return r
end
return T
