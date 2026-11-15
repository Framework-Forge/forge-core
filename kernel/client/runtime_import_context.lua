-- Existing native cache/positional translator captured before71/70/69/57/49. No public imports or locale bootstrap.
local createDelivery=require 'kernel.client.delivery_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(state,ports)
    assert(state.ClientRuntimeImportContext==nil and state.ClientDeliveryContext==nil,'fresh client runtime imports required')
    local api={OperationalReady=false};state.ClientRuntimeImportContext=api
    local phase,context,graph,worker,sequence='constructing';local refs={}
    local function canonical()
        if state.ClientRuntimeImportContext~=api then return false end
        for _,r in ipairs(refs)do if r.owner[r.key]~=r.value then return false end end
        return not graph or graph.IsCanonical()
    end
    local function current()
        if phase=='closed'or phase=='failed'or not canonical()then return false end
        if not context or phase=='stopping'then return true end
        return context.IsCurrent()
    end
    local input=copy(ports.imports);input.isCurrent=current
    local imports=assert(ports.createImports,'explicit PR runtime imports factory required')(input);api.Imports=imports
    local function ref(owner,key)refs[#refs+1]={owner=owner,key=key,value=owner[key]}end
    ref(api,'Imports');ref(imports,'NativeCache');ref(imports,'Translate')
    local p=copy(ports.deliveryContext);p.configurationContext=copy(p.configurationContext)
    local c=p.configurationContext;c.mediaContext=copy(c.mediaContext);local m=c.mediaContext
    m.worker=copy(m.worker);local w=m.worker;w.central=copy(w.central);local central=w.central
    central.cache=imports.NativeCache;central.runtime=copy(central.runtime);central.character=copy(central.character)
    central.runtime.locale=imports.Translate;central.character.locale=imports.Translate
    local function ownFactory(holder,key,pending)
        local factory=assert(holder[key]);holder[key]=function(bindings)
            local b=copy(bindings);local prior=assert(b.isCurrent);b.isCurrent=function()return current()and prior()end
            local scope=factory(b)
            if pending then local progress=scope.Progress
                scope.Progress=function()local out=progress();local n=imports.Progress().pending
                    out.pending=out.pending+n;out.complete=out.complete and n==0;return out
                end
            end
            return scope
        end
    end
    ownFactory(p,'createDelivery');ownFactory(c,'createConfiguration',true);ownFactory(m,'createMedia');ownFactory(w,'createTasks')
    local function finish(...)
        if not canonical()then imports.Close();phase='failed';return ...end
        local cleanupState=sequence.Progress()
        if context.Progress().phase=='closed'or cleanupState.phase=='cleaned'or cleanupState.phase=='cleanup-failed'then
            imports.Close();phase='closed'
        end;return ...
    end
    local function cleanup(fn,...)
        if imports.Progress().phase=='closed'then return fn(...)end
        phase='stopping';imports.CloseIngress();return finish(imports.DuringCleanup(fn,...))
    end
    local function guard(fn)return function(...)if phase=='stopping'or not current()then return end;return fn(...)end end
    local function properties(value,seen)
        if type(value)=='function'then return guard(value)end;if type(value)~='table'then return value end
        seen=seen or{};if seen[value]then return seen[value]end;local out={};seen[value]=out
        for k,v in pairs(value)do out[k]=properties(v,seen)end;return out
    end
    m.shutdown=copy(m.shutdown);local s=m.shutdown;s.events=copy(s.events);local listen=s.events.listen
    s.events.listen=function(name,fn)return listen(name,function(resource,...)
        if name=='onResourceStop'and resource==s.resource then
            if not current()then return api.Stop()end;return cleanup(fn,resource,...)
        end
        return guard(fn)(resource,...)
    end)end
    s.callbacks=copy(s.callbacks)
    for _,kind in ipairs({'native','ox'})do local v=copy(s.callbacks[kind]);local bind=v.Bind
        v.Bind=function(lease,fn)return bind(lease,guard(fn))end;s.callbacks[kind]=v
    end
    s.public=copy(s.public);local pub=s.public;local publish=pub.publishExport
    pub.publishExport=function(name,fn)return publish(name,guard(fn))end
    for _,kind in ipairs({'prCommand','oxCommand'})do local bind=pub[kind]
        pub[kind]=function(name,options,fn)return bind(name,properties(options),guard(fn))end
    end
    local bind=pub.nativeCommand;pub.nativeCommand=function(name,fn,restricted)return bind(name,guard(fn),restricted)end
    s.input=copy(s.input);local bag=s.input.addBag;s.input.addBag=function(key,filter,fn)return bag(key,filter,guard(fn))end
    local provider=s.input.keybind;local call=assert(getmetatable(provider).__call);local proxy=copy(provider)
    setmetatable(proxy,{__call=function(_,data)for k,v in pairs(data)do if type(v)=='function'then data[k]=guard(v)end end;return call(provider,data)end});s.input.keybind=proxy
    local report=w.onError;w.onError=function(...)
        if context and canonical()then cleanup(context.Stop)else phase='failed';imports.Close()end;return report(...)
    end
    local ok,value=pcall(createDelivery,state,p)
    if not ok then phase='failed';imports.Close();error(value,0)end
    context=value;graph=context.Graph;worker=state.ClientWorkerContext;sequence=state.ClientMediaContext.Sequence
    api.Context,api.Graph=context,graph;phase='prepared';ref(state.ClientMediaContext,'Sequence')
    for _,key in ipairs({'ClientDeliveryContext','ClientConfigurationContext','ClientMediaContext','ClientWorkerContext','ClientAssembly','ClientDomainAssembly','Shared','Status','Session','BridgeCache'})do ref(state,key)end
    local function run(fn,target)
        local result=table.pack(pcall(fn))
        if result[1]and result[2]and current()and phase~='stopping'then phase=target;return table.unpack(result,2,result.n)end
        if phase~='closed'and canonical()then cleanup(context.Stop)else imports.Close()end
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'runtime_imports_not_prepared'end
        if not imports.Open()then return false,'runtime_imports_scope_unavailable'end;return run(context.Install,'installed')
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'runtime_imports_not_installed'end
        phase='starting';return run(context.Start,'running')
    end
    function api.Stop()
        if phase=='closed'then return context.Stop()end
        if not current()then imports.Close();worker.Close();phase='failed';return false,'stale_context'end
        return cleanup(context.Stop)
    end
    function api.Poll()
        if phase=='closed'then return context.Poll()end
        if phase~='stopping'then return false,'not_stopping'end
        if not current()then imports.Close();worker.Close();phase='failed';return false,'stale_context'end
        return cleanup(context.Poll)
    end
    function api.IsCurrent()return current()end
    function api.Progress()local c,i=context.Progress(),imports.Progress()
        return{phase=phase,context=c,imports=i,complete=phase=='closed'and c.complete and i.complete}
    end
    return api
end
