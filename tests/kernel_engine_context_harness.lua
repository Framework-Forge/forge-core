local P=dofile('tests/kernel_domain_profile_harness.lua');local E=dofile('tests/kernel_engine_ports_harness.lua');local T={P=P,E=E,H=P.H}
T.bind=T.H.load('kernel/entry/engine_context_ports.lua',T.H.environment())
function T.new(side)
    local r=P.new(side);r.engineSchema=T.H.load('kernel/entry/'..side..'_engine_schema.lua',T.H.environment())()
    r.engineFixture=E.new(side,r.engineSchema);r.engine146=r.engineFixture.mount146();r.original148=r.profilePorts.bootstrap.context
    r.profilePorts.bootstrap.context,r.audit148=T.bind[side=='server'and'Server'or'Client'](r.original148,r.engine146,r.engineSchema)
    return r
end
function T.graph(r,context)
    if r.profilePorts.side=='client'then return context.runtimeContext.deliveryContext.configurationContext.mediaContext.worker end
    return context.deliveryContext.mediaContext.supportContext.configurationContext.vehicleContext.bankingContext.operationsContext.inventoryContext.startup.lifecycle.worker.graph
end
return T
