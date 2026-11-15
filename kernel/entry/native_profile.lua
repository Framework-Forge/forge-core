-- Assemble the installed private factories around the supplied domain context and borrowed seed/raw services.
return function(base,ports)
    local seed,services,pr=assert(ports.seed),assert(ports.services),assert(ports.prCore)
    local side=assert(ports.side);assert(side=='server'or side=='client','profile side required')
    local rpc=assert(pr.forgeOwnedCallbacks);assert(rpc.Side==side and seed.IsCurrent(),'prepared matching native seed required')
    local loadPR=assert(ports.loadPR);local binder=seed.Registry.Require('kernel.entry.native_context_ports')
    local input={};for k,v in pairs(assert(ports.bootstrap))do input[k]=v end
    local phase='allocating';local boot,configuration,database,ui;local errors={};local api={OperationalReady=false,Seed=seed}
    local function current()return phase~='closed'and seed.IsCurrent()end
    local function attempt(fn)local out=table.pack(pcall(fn));if not out[1]then errors[#errors+1]=tostring(out[2])end;return out[1]and out[2]==true end
    local function finish()
        if not boot or boot.Progress().complete then
            local done=true
            if ui then done=attempt(ui.Close)and done end
            if database then done=attempt(database.Close)and done end
            if configuration then done=attempt(configuration.Close)and done end
            if done then phase='closed';return true end
        end
        return false
    end
    function api.Stop()
        if phase=='closed'then return true end;phase='closing'
        if boot then attempt(boot.Stop)end
        if ui and ui.Progress().phase=='open'then
            -- Pending input may be holding a domain callback;streaming remains open for58 cleanup.
            pcall(ui.Library.closeInputDialog);pcall(ui.Library.closeAlertDialog)
        end
        return finish()
    end
    function api.Poll()
        if phase=='closed'then return true end
        if phase~='closing'then return false,'profile_not_stopping'end
        if boot then attempt(boot.Poll)end;return finish()
    end
    local ok,problem=pcall(function()
        configuration=loadPR('@pr_bridge/bridge/delivery/forge_native_configuration')({execution=seed.Execution,external=assert(ports.external),
            side=side,keys=services.Keys,random=ports.random,running=ports.running,load=loadPR,isCurrent=current});api.Configuration=configuration
        if side=='server'then
            database=loadPR('@pr_bridge/bridge/database/forge_native_await')({database=assert(services.Public.database),isCurrent=current});api.Database=database
            local bindServices=seed.Registry.Require('kernel.entry.server_pr_ports')
            input.context,input.registration=bindServices(input.context,services,rpc,input.registration,assert(ports.barrier))
            input.context=binder.Server(input.context,configuration,database)
        else
            local events={listen=function(...)return assert(boot,'bootstrap not allocated').Transport.Events.listen(...)end,
                remove=function(...)return assert(boot,'bootstrap not allocated').Transport.Events.remove(...)end}
            local public={};for k,v in pairs(assert(ports.public))do public[k]=v end;public.callback=rpc.Native
            ui=loadPR('@pr_bridge/bridge/delivery/forge_native_client_ui')({prCore=pr,public=public,library=seed.Library.Library,
                events=events,environment=assert(ports.environment),load=loadPR,isCurrent=current,
                createTasks=loadPR('@pr_bridge/bridge/runtime/owned_tasks'),running=assert(ports.running),onError=assert(ports.onError)});api.UI=ui
            input.context=binder.Client(input.context,configuration,ui)
        end
        boot=seed.Registry.Require('kernel.entry.'..side..'_bootstrap')(base,input);api.Bootstrap=boot
    end)
    if not ok then api.Stop();error(problem,0)end;phase='allocated'
    local function operate(name,expected,nextPhase,...)
        if phase~=expected or not current()then return false,'profile_'..name:lower()..'_unavailable'end
        phase=name:lower()..'ing';local working=phase
        local out=table.pack(pcall(boot[name],...))
        if not out[1]then api.Stop();error(out[2],0)end
        if phase~=working or not current()or out[2]~=true then
            api.Stop()
            if out[2]~=true and out[3]~=nil then return table.unpack(out,2,out.n)end
            return false,'profile_operation_cancelled'
        end
        if name=='Install'and ui then
            local done,reason=ui.Open();if not done then api.Stop();return false,reason end
        end
        phase=nextPhase;return table.unpack(out,2,out.n)
    end
    function api.Prepare(...)return operate('Prepare','allocated','prepared',...)end
    function api.Install()return operate('Install','prepared','installed')end
    function api.Start()return operate('Start','installed','running')end
    function api.IsCurrent()return current()and boot.IsCurrent()end
    function api.Progress()return{phase=phase,bootstrap=boot and boot.Progress(),ui=ui and ui.Progress(),database=database and database.Progress(),
        errors=errors,complete=phase=='closed',operationalReady=false}end
    return api
end
