local P=dofile('tests/kernel_progress_profile_harness.lua');local T={P=P,H=P.H}
function T.new(side)
    local r=P.new(side);r.factory158=T.H.load('kernel/entry/progress_shutdown_profile.lua',T.H.environment())
    -- Capture the already existing raw event boundary,not another event bus.
    local add=r.profilePorts.bootstrap.registration.native.AddEventHandler;r.stopListeners={}
    r.profilePorts.bootstrap.registration.native.AddEventHandler=function(name,fn)
        local token=add(name,fn);if name=='onClientResourceStop'then r.stopListeners[#r.stopListeners+1]={fn=fn,token=token}end;return token
    end
    function r.allocate158()
        r.profile=r.factory158(side=='server'and r.fixture.base or r.fixture.state,r.profilePorts)
        r.api=side=='server'and r.profile or r.profile.Bootstrap;return r.profile
    end
    function r.open158(start)
        local p=r.allocate158();assert(p.Prepare('pt-br'));r.surface.Open();assert(p.Install())
        if start then if side=='client'then r.runtimeImports.pollNative()end;assert(p.Start())end;return p
    end
    function r.fireStop158(resource,index)
        return assert(r.stopListeners[index or 1],'existing stop listener required').fn(resource)
    end
    return r
end
return T
