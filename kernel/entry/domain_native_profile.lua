-- Own configuration/persistence views;existing profiles retain graph lifecycle ownership.
return function(base,ports)
    local seed=assert(ports.seed);assert(seed.IsCurrent(),'prepared native seed required')
    local side=assert(ports.side);assert(side=='server'or side=='client','profile side required')
    local phase='allocating';local delegate,persistence;local api={OperationalReady=false,Seed=seed}
    local function current()return phase~='closed'and seed.IsCurrent()end
    local function finish()
        if delegate and not delegate.Progress().complete then return false end
        if persistence and not persistence.Close()then return false end
        phase='closed';return true
    end
    function api.Stop()
        if phase=='closed'then return true end;phase='closing'
        if delegate and not delegate.Stop()then return false end;return finish()
    end
    function api.Poll()
        if phase=='closed'then return true end;if phase~='closing'then return false,'domain_profile_not_stopping'end
        if delegate and not delegate.Poll()then return false end;return finish()
    end
    local ok,problem=pcall(function()
        local p={};for k,v in pairs(ports)do p[k]=v end;p.bootstrap={};for k,v in pairs(assert(ports.bootstrap))do p.bootstrap[k]=v end
        local cp={};for k,v in pairs(assert(ports.domainConfigurationPorts))do cp[k]=v end
        cp.requireLocal=seed.Registry.Require;cp.isCurrent=current
        local config=seed.Registry.Require('kernel.entry.native_domain_configuration')(cp);api.DomainConfiguration=config
        local bind=seed.Registry.Require('kernel.entry.domain_context_ports')
        if side=='server'then
            persistence=assert(ports.loadPR)('@pr_bridge/bridge/delivery/forge_domain_persistence')({io=seed.IO,isCurrent=current})
            api.Persistence=persistence;p.bootstrap.context=bind.Server(p.bootstrap.context,config,persistence)
        else p.bootstrap.context=bind.Client(p.bootstrap.context,config)end
        local factory=side=='client'and'kernel.entry.native_client_profile'or'kernel.entry.native_profile'
        delegate=seed.Registry.Require(factory)(base,p);api.Delegate=delegate;api.Bootstrap=delegate.Bootstrap
    end)
    if not ok then api.Stop();error(problem,0)end;phase='allocated'
    local function run(name,expected,nextPhase,...)
        if phase~=expected or not current()then return false,'domain_profile_unavailable'end
        phase=name:lower()..'ing';local active=phase;local out=table.pack(pcall(delegate[name],...))
        if not out[1]then api.Stop();error(out[2],0)end
        if out[2]~=true or phase~=active or not current()then
            api.Stop()
            if out[2]~=true and out[3]~=nil then return table.unpack(out,2,out.n)end
            return false,'domain_profile_cancelled'
        end
        phase=nextPhase;return table.unpack(out,2,out.n)
    end
    function api.Prepare(...)return run('Prepare','allocated','prepared',...)end
    function api.Install()return run('Install','prepared','installed')end
    function api.Start()return run('Start','installed','running')end
    function api.IsCurrent()return current()and delegate.IsCurrent()end
    function api.Progress()return{phase=phase,profile=delegate and delegate.Progress(),persistence=persistence and persistence.Progress(),complete=phase=='closed',operationalReady=false}end
    return api
end
