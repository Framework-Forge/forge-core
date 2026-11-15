-- Derived158:installed cleanup before native/manual domain Stop;retain seed until accepted calls drain.
return function(base,ports)
    local seed=assert(ports.seed);assert(seed.IsCurrent(),'prepared native seed required')
    if ports.side=='server'then return seed.Registry.Require('kernel.entry.engine_native_profile')(base,ports)end
    assert(ports.side=='client','client/server progress profile side required')
    local phase='allocating';local delegate,progress;local stopBoundary;local api={OperationalReady=false,Seed=seed}
    local function current()return phase~='closed'and seed.IsCurrent()end
    local function finish()
        local done=not delegate or delegate.Progress().complete
        if progress then done=progress.Close()and done end
        if done then phase='closed';return true end;return false
    end
    function api.Stop()
        if phase=='closed'then return true end;phase='closing'
        if progress then progress.CloseIngress()end
        if delegate then delegate.Stop()end;return finish()
    end
    function api.Poll()
        if phase=='closed'then return true end;if phase~='closing'then return false,'progress_profile_not_stopping'end
        return api.Stop()
    end
    local ok,problem=pcall(function()
        local p={};for k,v in pairs(ports)do p[k]=v end;p.bootstrap={};for k,v in pairs(assert(ports.bootstrap))do p.bootstrap[k]=v end
        local loadPR=assert(ports.loadPR);local opts=assert(ports.progress,'explicit player/settings progress ports required')
        local built=loadPR('@pr_bridge/bridge/delivery/forge_progress_environment').Build({execution=seed.Execution,environment=ports.environment,
            localPlayer=opts.localPlayer,settings=opts.settings,getUI=function()return delegate and delegate.Delegate.Delegate.UI end})
        local events={listen=function(...)return assert(delegate,'profile not allocated').Bootstrap.Transport.Events.listen(...)end,
            remove=function(...)return assert(delegate,'profile not allocated').Bootstrap.Transport.Events.remove(...)end}
        progress=loadPR('@pr_bridge/bridge/delivery/forge_client_progress_shutdown')({prCore=ports.prCore,environment=built.Environment,
            streaming=built.Streaming,settings=built.Settings,events=events,isCurrent=current,load=loadPR});api.ProgressScope=progress
        p.bootstrap.context=seed.Registry.Require('kernel.entry.progress_context_ports')(p.bootstrap.context,progress)
        stopBoundary=seed.Registry.Require('kernel.entry.resource_stop_ports')(p.bootstrap,'client',function()
            phase='closing';return progress.CloseIngress()
        end);p.bootstrap=stopBoundary.Bootstrap;api.StopBoundary=stopBoundary
        delegate=seed.Registry.Require('kernel.entry.engine_native_profile')(base,p)
        api.Delegate,api.Bootstrap,api.DomainConfiguration,api.PortAudit,api.Engine=delegate,delegate.Bootstrap,delegate.DomainConfiguration,delegate.PortAudit,delegate.Engine
    end)
    if not ok then api.Stop();error(problem,0)end;phase='allocated'
    local function run(name,expected,nextPhase,...)
        if phase~=expected or not current()then return false,'progress_profile_unavailable'end
        phase=name:lower()..'ing';local active=phase;local out=table.pack(pcall(delegate[name],...))
        if not out[1]then api.Stop();error(out[2],0)end
        if out[2]~=true or phase~=active or not current()then api.Stop();return false,'progress_profile_cancelled'end
        if name=='Install'then local done,reason=progress.Open();if not done then api.Stop();return false,reason end end
        phase=nextPhase;return table.unpack(out,2,out.n)
    end
    function api.Prepare(...)return run('Prepare','allocated','prepared',...)end
    function api.Install()return run('Install','prepared','installed')end
    function api.Start()return run('Start','installed','running')end
    function api.IsCurrent()return current()and delegate.IsCurrent()end
    function api.Progress()return{phase=phase,profile=delegate and delegate.Progress(),progress=progress and progress.Progress(),stopBoundary=stopBoundary and stopBoundary.Progress(),complete=phase=='closed',operationalReady=false}end
    return api
end
