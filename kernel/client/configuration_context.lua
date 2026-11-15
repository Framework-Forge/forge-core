-- Construct Client06 once before69/57/49;58 continues to own all registration/cleanup.
local createClient=require 'kernel.config.client'
local createMedia=require 'kernel.client.media_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(state,ports)
    assert(state.ClientConfigurationContext==nil and state.ClientMediaContext==nil,'fresh client configuration context required')
    local p=copy(ports.mediaContext);p.worker=copy(p.worker);p.worker.central=copy(p.worker.central)
    local central=p.worker.central;local inputConfig=copy(central.config)
    assert(inputConfig.Client==nil,'client configuration context owns Client construction')
    local api={OperationalReady=false};state.ClientConfigurationContext=api
    local phase,context,graph='constructing';local config,client,refs
    local function current()
        if phase=='closed'or phase=='failed'or state.ClientConfigurationContext~=api then return false end
        if config then
            if api.Config~=config or config.Client~=client then return false end
            for _,r in ipairs(refs)do if r.owner[r.key]~=r.value then return false end end
        end
        if not context then return true end
        local childPhase=context.GetPhase()
        return childPhase~='closed'and childPhase~='failed'and state.ClientMediaContext==context
            and state.ClientWorkerContext==context.Worker and graph.IsCanonical()
    end
    local b=copy(ports.configuration);b.isCurrent=current
    local boundary=assert(ports.createConfiguration,'explicit PR client configuration factory required')(b);api.Boundary=boundary
    local built,value=pcall(createClient,boundary.Ports)
    if not built then phase='failed';boundary.Close();error(value,0)end
    client=value;config=inputConfig;config.Client=client;central.config=config;api.Config=config;refs={}
    local function ref(owner,key)refs[#refs+1]={owner=owner,key=key,value=owner[key]}end
    for _,name in ipairs({'playerStatus','characters','discord','teleport','getVehiclesInRadius','meCommand','setVehicleProperties','initVehicle','hasKeys'})do ref(client,name)end
    ref(client.playerStatus,'stress');ref(client.characters,'locations');ref(config,'Inventory')
    central.library=copy(central.library);central.library.waitFor=boundary.WaitFor;api.Library=central.library
    ref(central.library,'waitFor');ref(api,'Library')
    local factory=assert(p.createMedia)
    p.createMedia=function(bindings)local m=copy(bindings);local prior=assert(m.isCurrent)
        m.isCurrent=function()return current()and prior()end
        local media=factory(m);local progress=media.Progress
        --69 captures this before58 captures worker.Progress; no late replacement can be relied on.
        media.Progress=function()
            local out=progress();local pending=boundary.Progress().pending
            out.pending=out.pending+pending;out.complete=out.complete and pending==0;return out
        end
        return media
    end
    local function finish(...)
        local status=context.Progress()
        if status.phase=='closed'then boundary.Close();phase='closed'end
        return ...
    end
    local function cleanup(fn,...)
        if boundary.Progress().phase=='closed'then return fn(...)end
        phase='stopping';boundary.CloseIngress();return finish(boundary.DuringCleanup(fn,...))
    end
    local function guard(fn)return function(...)
        if phase=='stopping'or not current()then return end;return fn(...)
    end end
    local function properties(value,seen)
        if type(value)=='function'then return guard(value)end;if type(value)~='table'then return value end
        seen=seen or{};if seen[value]then return seen[value]end;local out={};seen[value]=out
        for k,v in pairs(value)do out[k]=properties(v,seen)end;return out
    end
    local s=copy(p.shutdown);p.shutdown=s;s.events=copy(s.events);local listen=s.events.listen
    s.events.listen=function(name,fn)return listen(name,function(resource,...)
        if name=='onResourceStop'and resource==s.resource then
            if not current()then return api.Stop()end
            return cleanup(fn,resource,...)
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
    s.input=copy(s.input);local bag=s.input.addBag
    s.input.addBag=function(key,filter,fn)return bag(key,filter,guard(fn))end
    local provider=s.input.keybind;local call=assert(getmetatable(provider).__call);local proxy=copy(provider)
    setmetatable(proxy,{__call=function(_,data)for k,v in pairs(data)do if type(v)=='function'then data[k]=guard(v)end end;return call(provider,data)end});s.input.keybind=proxy
    local report=p.worker.onError;p.worker.onError=function(...)phase='failed';boundary.Close();return report(...)end
    local ok,value=pcall(createMedia,state,p)
    if not ok then phase='failed';boundary.Close();error(value,0)end
    context=value;graph=context.Graph;api.Context,api.Graph=context,graph;phase='prepared'
    ref(graph.Central,'Config');ref(graph.Central.Config,'Client');ref(graph.Central.Config,'Inventory')
    local function run(fn,target)
        local result=table.pack(pcall(fn))
        if result[1]and result[2]and current()and phase~='stopping'then phase=target;return table.unpack(result,2,result.n)end
        if phase~='closed'and current()then cleanup(context.Stop)else boundary.Close()end
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'client_configuration_not_prepared'end
        if not boundary.Open()then return false,'client_configuration_scope_unavailable'end
        return run(context.Install,'installed')
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'client_configuration_not_installed'end
        phase='starting';return run(context.Start,'running')
    end
    function api.Stop()
        if phase=='closed'then return context.Stop()end
        if not current()then boundary.Close();context.Worker.Close();phase='failed';return false,'stale_context'end
        return cleanup(context.Stop)
    end
    function api.Poll()
        if phase=='closed'then return context.Poll()end
        if phase~='stopping'then return false,'not_stopping'end
        if not current()then boundary.Close();context.Worker.Close();phase='failed';return false,'stale_context'end
        return cleanup(context.Poll)
    end
    function api.IsCurrent()return current()end
    function api.GetPhase()return phase end
    function api.Progress()local c,b=context.Progress(),boundary.Progress()
        return{phase=phase,context=c,boundary=b,complete=phase=='closed'and c.complete and b.complete}
    end
    return api
end
