local L=dofile('tests/kernel_late_binding_harness.lua');local N=dofile('tests/kernel_forge_normalization_harness.lua');local H=L.H;local T={L=L,N=N,H=H}
function T.aliases(t)
    local names,seen,out={},{},{};for n,v in pairs(t)do if type(v)=='function'then names[#names+1]=n end end;table.sort(names)
    for _,n in ipairs(names)do local fn=t[n];seen[fn]=seen[fn]or n;out[n]=seen[fn]end;return out
end
function T.new()
    local r=L.new();r.normalFixture=N.new(true,'server');r.pr={};r.public={};r.localResource='consumer116';r.localServer=true;r.readiness=true;r.allocationCurrent=true
    r.allocationPorts={side='server',resource='consumer116',prCore=r.pr,public=r.public,inventory=true,
        native={GetCurrentResourceName=function()return r.localResource end,IsDuplicityVersion=function()return r.localServer end},
        normalizedMethods=T.aliases(r.normalFixture.framework),isCurrent=function()return r.allocationCurrent and r.api.IsCurrent()end,isReady=function()return r.readiness end,
        createLate=function()return r.late end,
        createRouting=function()return H.load('../pr_bridge/bridge/compat/forge/routing_factory.lua',H.environment())({active={frameworks='forge'},config={compatFramework='forge'},resourceName='forge-core',contracts={qb=true,qbx=true},
            readDeclarations=function()return{'forge','qbx','qb'}end,isCurrent=function()return r.allocationCurrent end})end,
        createNormalization=function(base)
            local p={};for k,v in pairs(r.normalFixture.ports)do p[k]=v end;p.framework=base;p.resourceName='forge-core'
            p.isCurrent=function()return r.allocationCurrent end;p.core={}
            for name in pairs(r.normalFixture.ports.core)do local fn=r.catalog.Resolve(name);p.core[name]=function(...)
                assert(r.allocation.IsAttached(),'normalization core port not attached');return fn(...)
            end end
            if r.normalHook then r.normalHook()end
            return H.load(N.path,H.environment())(p)
        end}
    r.allocationFactory=H.load('../pr_bridge/bridge/runtime/forge/consumer_allocation_factory.lua',H.environment())
    function r.allocate()r.allocation=r.allocationFactory(r.allocationPorts);return r.allocation end
    local finish=r.finish
    function r.finish()if r.allocation then r.allocation.Close()end;return finish()end
    return r
end
return T
