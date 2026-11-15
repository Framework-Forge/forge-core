local G=dofile('tests/kernel_native_graph_harness.lua');local C=dofile('tests/kernel_native_domains_config_harness.lua');local J=dofile('tests/kernel_domain_persistence_harness.lua')
local T={G=G,C=C,J=J,H=G.H};T.bind=T.H.load('kernel/entry/domain_context_ports.lua',T.H.environment())
function T.server()
    local r=G.server();r.domainConfig=C.new().mount();local p=J.new();r.persistenceFixture=p;r.domainPersistence=p.mount()
    r.original143=r.profilePorts.bootstrap.context;r.profilePorts.bootstrap.context=T.bind.Server(r.original143,r.domainConfig,r.domainPersistence)
    return r
end
function T.client()
    local r=G.client();r.domainConfig=C.new().mount();r.original143=r.profilePorts.bootstrap.context
    r.profilePorts.bootstrap.context=T.bind.Client(r.original143,r.domainConfig);return r
end
return T
