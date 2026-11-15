-- Explicit client locale preparation before73/71/70/69/57/49. Inactive.
local createRuntime=require 'kernel.client.runtime_import_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(state,ports)
    assert(state.ClientLocaleContext==nil and state.ClientRuntimeImportContext==nil,'fresh client locale context required')
    local api={OperationalReady=false};state.ClientLocaleContext=api
    local phase,context,graph,worker,sequence,token='allocated';local refs={};local removalFailed=false
    local binding=assert(ports.localeBinding);local listen,remove=assert(binding.listen),assert(binding.remove)
    local function canonical()
        if state.ClientLocaleContext~=api then return false end
        for _,r in ipairs(refs)do if r.owner[r.key]~=r.value then return false end end;return not graph or graph.IsCanonical()
    end
    local function current()
        if phase=='closed'or phase=='failed'or not canonical()then return false end
        if not context or phase=='stopping'then return true end;return context.IsCurrent()
    end
    local l=copy(ports.locale);l.resource,l.path,l.isCurrent='forge-core','kernel/locales',current
    local locale=assert(ports.createLocale)(l);api.Locale=locale
    local function ref(owner,key)refs[#refs+1]={owner=owner,key=key,value=owner[key]}end
    ref(api,'Locale')
    for _,name in ipairs({'Translate','Initialize','GetLocale','GetLocales'})do ref(locale,name)end
    local function retire()
        if not token then return end
        local ok,result=pcall(remove,token)
        if ok and result~=false then token=nil;removalFailed=false else removalFailed=true end
    end
    local function close()locale.Close()end
    local function finish(...)
        if not canonical()then close();phase='failed';return ...end
        local status=sequence.Progress()
        if status.phase=='cleaned'or status.phase=='cleanup-failed'then close();phase='closed'end;return ...
    end
    local function cleanup(fn,...)
        phase='stopping';retire();locale.CloseIngress()
        return finish(locale.DuringCleanup(fn,...))
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
        return out
    end
    local function compose()
        local p=copy(ports.runtimeContext);p.imports=copy(p.imports);p.imports.locale=locale.Translate
        p.deliveryContext=copy(p.deliveryContext);local d=p.deliveryContext;d.configurationContext=copy(d.configurationContext);local c=d.configurationContext
        c.mediaContext=copy(c.mediaContext);local m=c.mediaContext;m.worker=copy(m.worker);local w=m.worker
        local function own(holder,key,pending)
            local factory=assert(holder[key]);holder[key]=function(bindings)
                local b=copy(bindings);local prior=assert(b.isCurrent);b.isCurrent=function()return current()and prior()end;local scope=factory(b)
                if pending then local progress=scope.Progress;scope.Progress=function()local out=progress();local n=locale.Progress().pending;out.pending=out.pending+n;out.complete=out.complete and n==0;return out end end;return scope
            end
        end
        own(p,'createImports');own(d,'createDelivery');own(c,'createConfiguration',true);own(m,'createMedia');own(w,'createTasks')
        m.shutdown=copy(m.shutdown);local shutdown=m.shutdown;shutdown.public=public(shutdown.public);shutdown.callbacks=copy(shutdown.callbacks)
        for _,kind in ipairs({'native','ox'})do local v=copy(shutdown.callbacks[kind]);local bind=v.Bind;v.Bind=function(lease,fn)return bind(lease,guard(fn))end;shutdown.callbacks[kind]=v end
        shutdown.events=copy(shutdown.events);local bind=shutdown.events.listen
        shutdown.events.listen=function(name,fn)return bind(name,function(resource,...)
            if name=='onResourceStop'and resource==shutdown.resource then if not current()then return api.Stop()end;return cleanup(fn,resource,...)end
            return guard(fn)(resource,...)
        end)end
        shutdown.input=copy(shutdown.input);local bag=shutdown.input.addBag;shutdown.input.addBag=function(key,filter,fn)return bag(key,filter,guard(fn))end
        local provider=shutdown.input.keybind;local call=assert(getmetatable(provider).__call);local proxy=copy(provider)
        setmetatable(proxy,{__call=function(_,data)for k,v in pairs(data)do if type(v)=='function'then data[k]=guard(v)end end;return call(provider,data)end});shutdown.input.keybind=proxy
        local report=w.onError;w.onError=function(...)if context and canonical()then cleanup(context.Stop)else close();phase='failed'end;return report(...)end
        return createRuntime(state,p)
    end
    function api.Prepare(key)
        if phase~='allocated'or not current()then return false,'runtime_imports_not_allocated'end
        phase='preparing';local ok,problem=pcall(locale.Initialize,key)
        if not ok then close();phase='failed';error(problem,0)end
        if phase~='preparing'or not current()then close();return false,'preparation_cancelled'end
        ok,problem=pcall(compose)
        if not ok then close();phase='failed';error(problem,0)end
        if phase~='preparing'or not current()then
            close();if state.ClientWorkerContext then state.ClientWorkerContext.Close()end
            phase='failed';return false,'composition_cancelled'
        end
        context=problem;graph=context.Graph;worker=state.ClientWorkerContext;sequence=state.ClientMediaContext.Sequence
        api.Context,api.Graph=context,graph;phase='prepared'
        for _,name in ipairs({'ClientRuntimeImportContext','ClientDeliveryContext','ClientConfigurationContext','ClientMediaContext','ClientWorkerContext','ClientAssembly','ClientDomainAssembly','Shared','Status','Session','BridgeCache'})do ref(state,name)end
        ref(state.ClientMediaContext,'Sequence');return true
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'runtime_imports_not_prepared'end
        if not binding.available('export','getLocale')then close();phase='failed';return false,'locale_export_collision'end
        assert(locale.Open(),'runtime import scopes unavailable');phase='installing'
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
        local c=context and context.Progress()or nil;local l=locale.Progress()
        return{phase=phase,context=c,locale=l,localeListenerRemaining=token~=nil,removalFailed=removalFailed,
            complete=phase=='closed'and(not c or c.complete)and l.complete and token==nil}
    end
    return api
end
