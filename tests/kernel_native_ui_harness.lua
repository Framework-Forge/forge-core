local N=dofile('tests/kernel_native_registration_harness.lua');local M=dofile('tests/kernel_client_media_harness.lua');local H=N.H
local T={N=N,M=M,H=H,path='../pr_bridge/bridge/delivery/forge_native_client_ui.lua'}
function T.new()
    local r={scope=N.new('client'),media=M.provider(),current=true,sends={},public={settings={get=function(_,fallback)return fallback end}}}
    r.scope.allocate();assert(r.scope.api.Open());local env=H.environment(r.media.native)
    local W=dofile('tests/kernel_worker_harness.lua');r.clock=W.clock()
    env.Wait,env.CreateThread,env.SetTimeout=r.clock.native.Wait,r.clock.native.CreateThread,r.clock.native.SetTimeout
    env.GetCurrentResourceName=function()return'forge-core'end;env.IsDuplicityVersion=function()return false end
    env.TriggerEvent=function(...)r.sends[#r.sends+1]=table.pack(...)end
    env.promise={new=function()return{resolve=function(self,value)self.value=value;self.done=true end}end}
    env.Citizen={Await=function(p)if not p.done then coroutine.yield('ui133')end;return p.value end}
    env.json={encode=function()return'virtual' end};env.print=function()end
    r.pr={context='client',resource='forge-core'};r.public.callback={};r.library={callback=r.public.callback,table={}}
    r.ports={prCore=r.pr,public=r.public,library=r.library,events=r.scope.api.Events,environment=env,isCurrent=function()return r.current end,
        createTasks=W.create,running=coroutine.running,onError=error,
        load=function(path,target)if r.loadHook then r.loadHook(path)end;return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end}
    r.factory=H.load(T.path,H.environment());function r.allocate()r.api=r.factory(r.ports);return r.api end
    function r.finish()if r.api then r.api.Close()end;r.scope.api.Close()end
    return r
end
return T
