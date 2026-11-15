-- Explicit locale preparation before72 constructs Player/Lifecycle/Commands/Character. Inactive until bound.
local createDelivery=require 'kernel.server.delivery_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
local function branch(root,path)local out=root;for _,key in ipairs(path)do out[key]=copy(out[key]);out=out[key]end;return out end
return function(base,ports)
    assert(base.ServerRuntimeImportContext==nil and base.ServerDeliveryContext==nil,'fresh server runtime imports required')
    local api={OperationalReady=false};base.ServerRuntimeImportContext=api
    local phase,context,graph,worker,lifecycle,token='allocated';local refs={};local removalFailed=false
    local binding=assert(ports.localeBinding);local listen,remove=assert(binding.listen),assert(binding.remove)
    local function canonical()
        if base.ServerRuntimeImportContext~=api then return false end
        for _,r in ipairs(refs)do if r.owner[r.key]~=r.value then return false end end;return true
    end
    local function current()
        if phase=='closed'or phase=='failed'or not canonical()then return false end
        if not context or phase=='stopping'then return true end;return context.IsCurrent()
    end
    local l=copy(ports.locale);l.resource,l.path,l.isCurrent='forge-core','kernel/locales',current
    local locale=assert(ports.createLocale)(l);api.Locale=locale
    local input=copy(ports.imports);input.locale,input.isCurrent=locale.Translate,current
    local imports=assert(ports.createImports)(input);api.Imports=imports
    local function ref(owner,key)refs[#refs+1]={owner=owner,key=key,value=owner[key]}end
    ref(api,'Locale');ref(api,'Imports')
    for _,name in ipairs({'Translate','Initialize','GetLocale','GetLocales'})do ref(locale,name)end
    ref(imports,'NativeCache');ref(imports,'Translate')
    local function retire()
        if not token then return end
        local ok,result=pcall(remove,token)
        if ok and result~=false then token=nil;removalFailed=false else removalFailed=true end
    end
    local function close()imports.Close();locale.Close()end
    local function finish(...)
        if not canonical()then close();phase='failed';return ...end
        local status=lifecycle.Progress()
        if status.phase=='cleaned'or status.phase=='cleanup-failed'then close();phase='closed'end;return ...
    end
    local function cleanup(fn,...)
        phase='stopping';retire();imports.CloseIngress();locale.CloseIngress()
        return finish(locale.DuringCleanup(function(...)return imports.DuringCleanup(fn,...)end,...))
    end
    local function guard(fn)return function(...)if phase=='stopping'or not current()then return end;return fn(...)end end
    local function properties(value,seen)
        if type(value)=='function'then return guard(value)end;if type(value)~='table'then return value end
        seen=seen or{};if seen[value]then return seen[value]end;local out={};seen[value]=out
        for k,v in pairs(value)do out[k]=properties(v,seen)end;return out
    end
    local function public(value)
        local out=copy(value);local publish=out.publishExport
        out.publishExport=function(name,fn)return publish(name,guard(fn))end
        for _,kind in ipairs({'prCommand','oxCommand'})do local bind=out[kind]
            out[kind]=function(name,options,fn)return bind(name,properties(options),guard(fn))end
        end
        local command=out.nativeCommand;out.nativeCommand=function(name,fn,restricted)return command(name,guard(fn),restricted)end
        out.rpc=copy(out.rpc);local bind=out.rpc.Bind;out.rpc.Bind=function(lease,fn)return bind(lease,guard(fn))end;return out
    end
    local function compose()
        local p=copy(ports.deliveryContext);p.mediaContext=copy(p.mediaContext);local media=p.mediaContext
        local support=branch(media,{'supportContext'});local config=branch(support,{'configurationContext'})
        local vehicles=branch(config,{'vehicleContext'});local bank=branch(vehicles,{'bankingContext'})
        local ops=branch(bank,{'operationsContext'});local inventory=branch(ops,{'inventoryContext'})
        local startup=branch(inventory,{'startup'});local life=branch(startup,{'lifecycle'})
        life.worker=copy(life.worker);local w=life.worker;w.graph=copy(w.graph);local domain=w.graph
        domain.central=copy(domain.central);local central=domain.central
        central.session=copy(central.session);central.session.player=copy(central.session.player)
        central.session.player.platform=copy(central.session.player.platform);central.session.player.platform.locale=imports.Translate
        central.lifecycle=copy(central.lifecycle);central.lifecycle.native=copy(central.lifecycle.native);central.lifecycle.native.locale=imports.Translate
        for _,name in ipairs({'runtime','character'})do central[name]=copy(central[name]);central[name].locale=imports.Translate end
        domain.helpers=copy(domain.helpers);domain.helpers.cache=imports.NativeCache
        local function own(holder,key,pending)
            local factory=assert(holder[key]);holder[key]=function(bindings)
                local b=copy(bindings);local prior=assert(b.isCurrent);b.isCurrent=function()return current()and prior()end
                local scope=factory(b)
                if pending then local snapshot=scope.Snapshot;scope.Snapshot=function()
                    local out=snapshot();if imports.Progress().pending+locale.Progress().pending>0 then out.quiescent=false end;return out
                end end;return scope
            end
        end
        own(p,'createDelivery');own(media,'createMedia');own(support,'createDelivery');own(support,'createTasks')
        own(config,'createConfiguration');own(vehicles,'createVehicles');own(bank,'createBanking');own(ops,'createOperations')
        own(inventory,'createInventoryProvider');own(w,'createTasks',true)
        support.public=public(support.public);life.public=public(life.public)
        life.callbacks=copy(life.callbacks)
        for _,kind in ipairs({'native','ox'})do local v=copy(life.callbacks[kind]);local bind=v.Bind
            v.Bind=function(lease,fn)return bind(lease,guard(fn))end;life.callbacks[kind]=v
        end
        life.events=copy(life.events);local bind=life.events.listen
        life.events.listen=function(name,fn)return bind(name,function(resource,...)
            if name=='onResourceStop'and resource=='forge-core'then
                if not current()then return api.Stop()end;return cleanup(fn,resource,...)
            end;return guard(fn)(resource,...)
        end)end
        local report=w.onError;w.onError=function(...)
            if context and canonical()then cleanup(context.Stop)else close();phase='failed'end;return report(...)
        end
        return createDelivery(base,p)
    end
    function api.Prepare(key)
        if phase~='allocated'or not current()then return false,'runtime_imports_not_allocated'end
        phase='preparing';local ok,problem=pcall(locale.Initialize,key)
        if not ok then close();phase='failed';error(problem,0)end
        if phase~='preparing'or not current()then close();return false,'preparation_cancelled'end
        ok,problem=pcall(compose)
        if not ok then close();phase='failed';error(problem,0)end
        if phase~='preparing'or not current()then
            close();if base.ServerWorkerContext then base.ServerWorkerContext.Close()end
            phase='failed';return false,'composition_cancelled'
        end
        context=problem;graph=context.Graph;worker=base.ServerWorkerContext;lifecycle=base.ServerLifecycleContext
        api.Context,api.Graph=context,graph;phase='prepared'
        for _,name in ipairs({'ServerDeliveryContext','ServerMediaContext','ServerConfigurationContext','ServerWorkerContext','ServerLifecycleContext',
            'DomainAssembly','ServerAssembly','PlayerCore','Shared','Groups','Helpers'})do ref(base,name)end
        for _,name in ipairs({'Players','Status','Session','BridgeCache'})do ref(graph.PlayerCore.State,name)end
        for _,name in ipairs(graph.Order)do ref(graph.Parts,name)end;return true
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'runtime_imports_not_prepared'end
        if not binding.available('export','getLocale')then close();phase='failed';return false,'locale_export_collision'end
        assert(locale.Open()and imports.Open(),'runtime import scopes unavailable');phase='installing'
        local ok,result,err=pcall(function()
            local installed,reason=context.Install();if not installed then return false,reason end
            local received=listen('ox_lib:setLocale',guard(locale.Initialize))
            if phase~='installing'or not current()then remove(received);return false,'installation_cancelled'end;token=received
            binding.publishExport('getLocale',guard(locale.GetLocale))
            return phase=='installing'and current()
        end)
        if ok and result then phase='installed';return true end
        if phase~='closed'and canonical()then cleanup(context.Stop)else close()end
        if not ok then error(result,0)end;return false,err
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'runtime_imports_not_installed'end
        phase='starting';local result=table.pack(pcall(context.Start))
        if result[1]and result[2]and current()and phase~='stopping'then phase='running';return table.unpack(result,2,result.n)end
        if phase~='closed'and canonical()then cleanup(context.Stop)else close()end
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Stop()
        if not context then close();phase='closed';return true end
        if phase=='closed'then retire();return context.Stop()end
        if not current()then close();worker.Close();retire();phase='failed';return false,'stale_context'end
        return cleanup(context.Stop)
    end
    function api.Poll()
        if not context then return phase=='closed'end
        if phase=='closed'then retire();return context.Poll()end
        if phase~='stopping'then return false,'not_stopping'end
        if not current()then close();worker.Close();retire();phase='failed';return false,'stale_context'end
        return cleanup(context.Poll)
    end
    function api.IsCurrent()return current()end
    function api.Progress()
        local c=context and context.Progress()or nil;local i,l=imports.Progress(),locale.Progress()
        return{phase=phase,context=c,imports=i,locale=l,localeListenerRemaining=token~=nil,removalFailed=removalFailed,
            complete=phase=='closed'and(not c or c.complete)and i.complete and l.complete and token==nil}
    end
    return api
end
