local I=dofile('tests/kernel_native_io_harness.lua');local H=I.H;local T={I=I,H=H}
function T.new()
    local r=I.new('server');r.allocate();r.domainCurrent=true
    r.persistenceFactory=H.load('../pr_bridge/bridge/delivery/forge_domain_persistence.lua',H.environment())
    r.persistencePorts={io=r.api,isCurrent=function()return r.domainCurrent end}
    function r.mount()r.persistence=r.persistenceFactory(r.persistencePorts);return r.persistence end
    return r
end
return T
