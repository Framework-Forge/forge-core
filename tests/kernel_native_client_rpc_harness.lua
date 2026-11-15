local M=dofile('tests/kernel_native_profile_harness.lua');local H=M.H;local T={M=M,H=H}
T.bind=H.load('kernel/entry/client_pr_ports.lua',H.environment())
function T.new()
    local r=M.client();r.profilePorts.bootstrap.context=T.bind(r.profilePorts.bootstrap.context,r.seedUnit.wire.scopes.client)
    function r.allocateClientProfile()
        local factory=r.seed.Registry.Require('kernel.entry.native_client_profile');r.profile=factory(r.fixture.state,r.profilePorts);r.api=r.profile.Bootstrap;return r.profile
    end
    function r.installClientProfile()r.surface.Open();assert(r.profile.Install())end
    return r
end
return T
