local P=dofile('tests/kernel_domain_profile_harness.lua');local T={P=P,H=P.H}
function T.new(side)
    local r=P.new(side);r.schema149=T.H.load('kernel/entry/'..side..'_engine_schema.lua',T.H.environment())()
    local context=r.profilePorts.bootstrap.context;local g
    if side=='client'then g=context.runtimeContext.deliveryContext.configurationContext.mediaContext.worker
    else g=context.deliveryContext.mediaContext.supportContext.configurationContext.vehicleContext.bankingContext.operationsContext.inventoryContext.startup.lifecycle.worker.graph end
    local n=side=='server'and r.seedPorts.native or r.seedUnit.seedPorts.native
    local function collect(source)
        for key,value in pairs(source or{})do local target=r.schema149[key]
            if target and target:sub(1,1)~='$'and type(value)=='function'and n[target]==nil then n[target]=value end
        end
    end
    local function parts(source)for _,p in pairs(source)do if type(p)=='table'and p.native then collect(p.native)end end end
    if side=='server'then parts(g.central);parts(g.domains);collect(g.helpers.native)
        local w=context.deliveryContext.mediaContext.supportContext.configurationContext.vehicleContext.bankingContext.operationsContext.inventoryContext.startup.lifecycle.worker
        collect(w.bootstrap.native)
    else collect(g.central.native);parts(g.central);parts(g.domains.domains)end
    local skills=side=='server'and g.domains.Skills.native or{}
    r.profilePorts.nativeAdjuncts={time=function()return math.floor(r.clock.now/1000)end,date=os.date,
        locale=side=='server'and g.central.lifecycle.native.locale or function(...)return ...end,
        newPromise=skills.promise,awaitPromise=skills.await}
    r.factory149=T.H.load('kernel/entry/engine_native_profile.lua',T.H.environment())
    function r.allocate149()
        r.profile=r.factory149(side=='server'and r.fixture.base or r.fixture.state,r.profilePorts)
        r.api=side=='server'and r.profile or r.profile.Bootstrap;return r.profile
    end
    return r
end
return T
