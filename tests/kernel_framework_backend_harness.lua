local L=dofile('tests/kernel_locale_runtime_harness.lua');local A=dofile('tests/kernel_forge_server_adapter_harness.lua')
local H=L.H;local T={L=L,A=A,H=H}
function T.new()
    local r=L.server();r.prepareImports('en');r.current=true;r.backendReady=false
    r.backendPorts={isCurrent=function()return r.current and r.api.IsCurrent()end,isReady=function()
        if r.readyHook then r.readyHook()end;return r.backendReady
    end}
    r.backend=H.load('kernel/server/framework_backend.lua',H.environment())(r.graph,r.backendPorts)
    local stub=A.new(true);local p=stub.ports;p.core=r.backend.Core
    p.isCurrent=function()return r.current and r.backend.IsCurrent()and r.api.IsCurrent()end
    r.adapter=H.load(A.path,H.environment())(p);r.framework=r.adapter.Framework
    function r.start()r.startImports();r.backendReady=true;return r end
    function r.close()
        r.adapter.Close();r.backend.Close();r.api.Stop();r.clock.advance(1200000);r.api.Poll()
    end
    return r
end
return T
