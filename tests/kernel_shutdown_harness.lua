-- Actual51-57 factories; explicit platform/transport/IO doubles, no live startup.
local W=dofile('tests/kernel_worker_harness.lua')
local C=dofile('tests/kernel_callback_registration_harness.lua')
local P=dofile('tests/kernel_public_registration_harness.lua')
local K=dofile('tests/kernel_state_input_harness.lua')
local T={W=W,H=W.H,C=C,P=P,K=K}
function T.unit()
    local r={trace={},callbacks={},quiescent=true,counts={},installed=0}
    r.spec={owner={},isCurrent=function()return not r.stale end,entries={},binders={}}
    r.spec.worker={Start=function()r.trace[#r.trace+1]='start';if r.startHook then return r.startHook()end;return true end,
        Close=function()r.trace[#r.trace+1]='close';return true end,
        Progress=function()return{quiescent=r.quiescent}end}
    for i=1,5 do local name='binder'..i
        r.spec.binders[i]={name=name,api={Install=function()
            r.installed=r.installed+1;r.trace[#r.trace+1]='install'..i
            if r.installHook then r.installHook(i)end
            if r.failInstall==i then return false,'install failure'end;return true
        end,Dispose=function()
            r.trace[#r.trace+1]='dispose'..i
            if r.disposeHook then r.disposeHook(i)end
            if r.failDispose==i then return false,'dispose failure'end;return true
        end}}
    end
    for i=1,3 do r.spec.entries[i]={name='body'..i,handler=function()
        r.counts[i]=(r.counts[i]or 0)+1;r.trace[#r.trace+1]='body'..i
        if r.bodyHook then r.bodyHook(i)end
        if r.failBody==i then error('body failure',0)end
    end}end
    r.ports={pending=function()return r.pending or 0 end,setActive=function(v)r.live=v;r.trace[#r.trace+1]=v and'active'or'inactive'end,
        attach=function(fn)r.callbacks[#r.callbacks+1]=fn;if r.attachHook then r.attachHook(fn)end;return r.callbacks end,
        detach=function(token)assert(token==r.callbacks);r.detached=true;r.trace[#r.trace+1]='detach';return not r.failDetach end}
    r.factory=T.H.load('kernel/shared/shutdown_sequence.lua',T.H.environment())
    function r.prepare()r.api=r.factory(r.spec,r.ports);return r.api end
    return r
end
function T.new()
    local r=W.new();r.prepare();r.worker=r.api;r.graph=r.worker.Graph
    r.bus={};r.networks={};r.removed={}
    r.events={listen=function(name,fn)
        local t={name=name,handler=fn};r.bus[#r.bus+1]=t;if r.onListen then r.onListen(t)end;return t
    end,remove=function(t)
        assert(not t.removed,'remove only live owned token');t.removed=true;r.removed[#r.removed+1]=t
        if r.onRemove then r.onRemove(t)end
    end,markNetwork=function(name)r.networks[name]=true end,source=function()return'net:server'end}
    r.wire=C.wire();r.surface=P.surface('client');r.keys=K.ports()
    r.keys.ports.resolveEntity=r.graph.Central.Parts.Helpers.Lib.getEntityAndNetIdFromBagName
    r.ports={resource='forge-core',events=r.events,callbacks=r.wire.client.owners,public=r.surface.ports,input=r.keys.ports}
    r.factory=T.H.load('kernel/client/shutdown_sequence.lua',W.D.A.E.env())
    function r.prepareShutdown()r.api=r.factory(r.worker,r.ports);return r.api end
    function r.install()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    function r.emit(name,...)
        local list={};for _,t in ipairs(r.bus)do list[#list+1]=t end
        for _,t in ipairs(list)do if not t.removed and t.name==name then t.handler(...)end end
    end
    function r.active(name)local n=0;for _,t in ipairs(r.bus)do if not t.removed and(not name or t.name==name)then n=n+1 end end;return n end
    return r
end
return T
