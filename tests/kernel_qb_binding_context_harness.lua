local C=dofile('tests/kernel_qb_client_bridge_harness.lua');local S=dofile('tests/kernel_qb_bridge_harness.lua')
local U=dofile('tests/kernel_qb_event_binding_harness.lua');local H=C.H;local T={C=C,S=S,U=U,H=H}
local function attach(r,side)
    r.side=side;r.currentBinding=true;r.aliasForeign={};r.nativeCore=r.api
    r.root=side=='client'and r.graph.Core or r.graph.Base
    r.bindingPorts={side=side,events=r.events,public=r.surface.ports,
        isCurrent=function()return r.currentBinding and r.nativeCore.IsCurrent()end,
        isReady=function()if r.bindingReadyHook then r.bindingReadyHook()end;return r.bindingReady~=false end,
        aliasAvailable=function(name)
            if r.aliasHook then r.aliasHook(name)end
            if r.aliasForeign[name]then return false end
            for _,t in ipairs(r.bus)do if not t.removed and t.name==name then return false end end
            return true
        end}
    r.bindingFactory=H.load('kernel/compat/qb/binding_context.lua',C.environment())
    function r.prepareBinding()r.binding=r.bindingFactory(r.graph,r.qb,r.qbBackend,r.bindingPorts);return r.binding end
    function r.lookup(name)
        local fn;r.emit('__cfx_export_qb-core_'..name,function(value)fn=value end);return fn
    end
    function r.shutdownAll()
        r.binding.Close();if side=='client'then
            r.nativeCore.Stop();r.clock.advance(120000);r.nativeCore.Poll()
        else r.close()end
    end
    return r
end
function T.client(preparedOnly)
    local r=C.runtime()
    if not preparedOnly then assert(r.installLocale())end
    return attach(r,'client')
end
function T.server()return attach(S.runtime(),'server')end
function T.unit(preparedOnly)
    local r=U.new('client');if not preparedOnly then r.installCore()end
    local state=r.bridge.state;state.EventRegistration=r.core
    local central={State='prepared-inactive'};state.ClientAssembly=central
    local graph={State='prepared-inactive',Core=state,Central=central,IsCanonical=function()return r.current end}
    state.ClientDomainAssembly=graph
    r.graph=graph;r.qb=r.bridge.api;r.backend=r.bridge.backend
    r.bindingPorts={side='client',events=r.bus.ports,public=r.surface.ports,aliasAvailable=r.ports.aliasAvailable,
        isCurrent=function()return r.current end,isReady=function()if r.readyHook then r.readyHook()end;return r.ready~=false end}
    r.factory=H.load('kernel/compat/qb/binding_context.lua',C.environment())
    function r.prepare()r.binding=r.factory(graph,r.qb,r.backend,r.bindingPorts);return r.binding end
    return r
end
return T
