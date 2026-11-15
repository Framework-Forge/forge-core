-- Engine delegates remain open through graph cleanup,then close before the borrowed seed/raw.
return function(base,ports)
    local seed=assert(ports.seed);assert(seed.IsCurrent(),'prepared native seed required')
    local side=assert(ports.side);assert(side=='server'or side=='client','engine profile side required')
    local phase='allocating';local engine,delegate;local api={OperationalReady=false,Seed=seed}
    local function current()return phase~='closed'and seed.IsCurrent()end
    local function finish()
        if delegate and not delegate.Progress().complete then return false end
        if engine and not engine.Close()then return false end;phase='closed';return true
    end
    function api.Stop()
        if phase=='closed'then return true end;phase='closing'
        if delegate and not delegate.Stop()then return false end;return finish()
    end
    function api.Poll()
        if phase=='closed'then return true end;if phase~='closing'then return false,'engine_profile_not_stopping'end
        if delegate and not delegate.Poll()then return false end;return finish()
    end
    local ok,problem=pcall(function()
        local p={};for k,v in pairs(ports)do p[k]=v end;p.bootstrap={};for k,v in pairs(assert(ports.bootstrap))do p.bootstrap[k]=v end
        local ep={};for k,v in pairs(assert(ports.nativeAdjuncts))do ep[k]=v end
        ep.execution,ep.side,ep.isCurrent=seed.Execution,side,current
        engine=assert(ports.loadPR)('@pr_bridge/bridge/delivery/forge_native_ports')(ep);api.Engine=engine
        local schema=seed.Registry.Require('kernel.entry.'..side..'_engine_schema')()
        local bind=seed.Registry.Require('kernel.entry.engine_context_ports')
        p.bootstrap.context,api.PortAudit=bind[side=='server'and'Server'or'Client'](p.bootstrap.context,engine,schema)
        delegate=seed.Registry.Require('kernel.entry.domain_native_profile')(base,p)
        api.Delegate,api.Bootstrap,api.DomainConfiguration=delegate,delegate.Bootstrap,delegate.DomainConfiguration
    end)
    if not ok then api.Stop();error(problem,0)end;phase='allocated'
    local function run(name,expected,nextPhase,...)
        if phase~=expected or not current()then return false,'engine_profile_unavailable'end
        phase=name:lower()..'ing';local active=phase;local out=table.pack(pcall(delegate[name],...))
        if not out[1]then api.Stop();error(out[2],0)end
        if out[2]~=true or phase~=active or not current()then
            api.Stop()
            if out[2]~=true and out[3]~=nil then return table.unpack(out,2,out.n)end
            return false,'engine_profile_cancelled'
        end
        phase=nextPhase;return table.unpack(out,2,out.n)
    end
    function api.Prepare(...)return run('Prepare','allocated','prepared',...)end
    function api.Install()return run('Install','prepared','installed')end
    function api.Start()return run('Start','installed','running')end
    function api.IsCurrent()return current()and delegate.IsCurrent()end
    function api.Progress()return{phase=phase,profile=delegate and delegate.Progress(),engine=engine and engine.Progress(),complete=phase=='closed',operationalReady=false}end
    return api
end
