local W=dofile('tests/kernel_worker_harness.lua');local H=W.H
local T={W=W,H=H,path='../pr_bridge/bridge/delivery/forge_native_execution.lua'}
function T.new(side)
    local r={clock=W.clock(),current=true,side=side or'server',source=1,name='forge-core',events={},calls={}}
    local n={};for k,v in pairs(r.clock.native)do n[k]=v end
    n.GetCurrentResourceName=function()return r.name end;n.IsDuplicityVersion=function()return r.side=='server'end
    n.GetGameTimer=function()return r.clock.now end;n.GetConvar=function(key,fallback)return key=='inventory:framework'and'forge'or fallback end
    n.GetConvarInt=function(_,fallback)return fallback end
    n.GetResourceState=function(name)r.calls[#r.calls+1]=name;return'started',nil,2 end
    r.native=n;r.ports={native=n,isCurrent=function()return r.current end,side=r.side,events=r.events,running=coroutine.running,getSource=function()return r.source end}
    r.factory=H.load(T.path,H.environment());function r.allocate()r.api=r.factory(r.ports);return r.api end
    function r.manage()
        r.tasks=W.create({running=coroutine.running,isCurrent=function()return r.current end,onError=error})
        r.managed=r.tasks.WrapNative(r.api.Native);assert(r.tasks.Open());return r.managed
    end
    return r
end
return T
