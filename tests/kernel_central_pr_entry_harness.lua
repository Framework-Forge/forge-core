local N=dofile('tests/kernel_native_bootstrap_harness.lua');local S=dofile('tests/kernel_core_services_harness.lua')
local P=dofile('tests/kernel_activation_package_harness.lua');local H=N.H;local T={N=N,S=S,P=P,H=H}
function T.new()
    local r=N.server();r.servicesFixture=S.new();local s=r.servicesFixture;s.wire.open();s.allocate();assert(s.api.Prepare())
    r.barrier=P.barrier();local env;env=H.environment({require=function(name)return H.load(name:gsub('%.','/')..'.lua',env)end})
    local binder=H.load('kernel/entry/server_pr_ports.lua',env)
    local original=r.bootstrapPorts.context;r.originalPorts=original
    local context,registration,adopted=binder(original,s.api,s.wire.scopes.server,r.bootstrapPorts.registration,r.barrier)
    r.adopted=adopted;r.bootstrapPorts.context=context;r.bootstrapPorts.registration=registration
    function r.installNewPR()
        r.surface.Open();local ok,reason=r.api.Install();assert(ok,reason)
    end
    return r
end
return T
