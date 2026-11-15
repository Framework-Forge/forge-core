-- One passive PR projection before70/69/57/49-50. No alternate PlayerData or producer.
local createConfiguration=require 'kernel.client.configuration_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(state,ports)
    assert(state.ClientDeliveryContext==nil and state.ClientConfigurationContext==nil,'fresh client delivery context required')
    local api={OperationalReady=false};state.ClientDeliveryContext=api
    local phase,context,graph='constructing';local refs={}
    local function current()
        if phase=='closed'or phase=='failed'or state.ClientDeliveryContext~=api then return false end
        for _,r in ipairs(refs)do if r.owner[r.key]~=r.value then return false end end
        if not context then return true end
        local childPhase=context.GetPhase()
        return childPhase~='closed'and childPhase~='failed'and state.ClientConfigurationContext==context and context.IsCurrent()and graph.IsCanonical()
    end
    local b=copy(ports.delivery);b.isCurrent=current
    local boundary=assert(ports.createDelivery,'explicit PR cache delivery factory required')(b);api.Boundary=boundary
    local p=copy(ports.configurationContext);p.mediaContext=copy(p.mediaContext)
    local m=p.mediaContext;m.worker=copy(m.worker);local w=m.worker;w.central=copy(w.central);local central=w.central
    central.producers=copy(central.producers);central.producers.delivery=boundary.Delivery
    central.native=copy(central.native);central.native.TriggerEvent=boundary.EmitLocal
    central.library=copy(central.library);central.library.cache=boundary.Cache
    w.domains=copy(w.domains);w.domains.domains=copy(w.domains.domains)
    local function ref(owner,key)refs[#refs+1]={owner=owner,key=key,value=owner[key]}end
    for _,name in ipairs({'getResourceState','writeCache','emit'})do ref(boundary.Delivery,name)end
    for _,name in ipairs({'get','set','patch','clear','clearPrefix','GetPlayer','GetMetadata','GetResourceState','SetResourceState'})do ref(boundary.Cache,name)end
    ref(boundary,'Cache');ref(boundary,'Delivery');ref(boundary,'EmitLocal');ref(api,'Boundary')
    for name,d in pairs(w.domains.domains)do
        local v=copy(d);v.library=copy(v.library);v.library.cache=boundary.Cache;w.domains.domains[name]=v
    end
    local mediaFactory=assert(m.createMedia)
    m.createMedia=function(bindings)local b=copy(bindings);local prior=assert(b.isCurrent)
        b.isCurrent=function()return current()and prior()end;return mediaFactory(b)
    end
    --70 creates this scope before69/58 capture pending; never replace worker.Progress afterwards.
    local factory=assert(p.createConfiguration)
    p.createConfiguration=function(bindings)
        local b=copy(bindings);local prior=assert(b.isCurrent);b.isCurrent=function()return current()and prior()end
        local scope=factory(b);local progress=scope.Progress
        scope.Progress=function()local out=progress();local pending=boundary.Progress().pending
            out.pending=out.pending+pending;out.complete=out.complete and pending==0;return out
        end
        return scope
    end
    local function finish(...)
        if context.Progress().phase=='closed'then boundary.Close();phase='closed'end;return ...
    end
    local function cleanup(fn,...)
        if boundary.Progress().phase=='closed'then return fn(...)end
        phase='stopping';boundary.CloseIngress();return finish(boundary.DuringCleanup(fn,...))
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
    for _,kind in ipairs({'prCommand','oxCommand'})do local bind=pub[kind];pub[kind]=function(name,options,fn)return bind(name,properties(options),guard(fn))end end
    local bind=pub.nativeCommand;pub.nativeCommand=function(name,fn,restricted)return bind(name,guard(fn),restricted)end
    s.input=copy(s.input);local bag=s.input.addBag;s.input.addBag=function(key,filter,fn)return bag(key,filter,guard(fn))end
    local provider=s.input.keybind;local call=assert(getmetatable(provider).__call);local proxy=copy(provider)
    setmetatable(proxy,{__call=function(_,data)for k,v in pairs(data)do if type(v)=='function'then data[k]=guard(v)end end;return call(provider,data)end});s.input.keybind=proxy
    local report=w.onError;w.onError=function(...)phase='failed';boundary.Close();return report(...)end
    local ok,value=pcall(createConfiguration,state,p)
    if not ok then phase='failed';boundary.Close();error(value,0)end
    context=value;graph=context.Graph;api.Context,api.Graph=context,graph;phase='prepared'
    local function run(fn,target)
        local result=table.pack(pcall(fn))
        if result[1]and result[2]and current()and phase~='stopping'then phase=target;return table.unpack(result,2,result.n)end
        if phase~='closed'and current()then cleanup(context.Stop)else boundary.Close()end
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'client_delivery_not_prepared'end
        if not boundary.Open()then return false,'client_delivery_scope_unavailable'end;return run(context.Install,'installed')
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'client_delivery_not_installed'end
        phase='starting';return run(context.Start,'running')
    end
    function api.Stop()
        if phase=='closed'then return context.Stop()end
        if not current()then boundary.Close();context.Context.Worker.Close();phase='failed';return false,'stale_context'end
        return cleanup(context.Stop)
    end
    function api.Poll()
        if phase=='closed'then return context.Poll()end
        if phase~='stopping'then return false,'not_stopping'end
        if not current()then boundary.Close();context.Context.Worker.Close();phase='failed';return false,'stale_context'end
        return cleanup(context.Poll)
    end
    function api.IsCurrent()return current()end
    function api.Progress()local c,b=context.Progress(),boundary.Progress()
        return{phase=phase,context=c,boundary=b,complete=phase=='closed'and c.complete and b.complete}
    end
    return api
end
