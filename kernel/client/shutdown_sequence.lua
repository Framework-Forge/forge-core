local createSequence=require 'kernel.shared.shutdown_sequence'
local createEvents=require 'kernel.client.event_registration'
local createCallbacks=require 'kernel.client.callback_registration'
local createPublic=require 'kernel.client.public_registration'
local createInput=require 'kernel.client.state_input_registration'
local createSubscriptions=require 'kernel.client.subscription_registration'
local function copy(t)local o={};for k,v in pairs(t)do o[k]=v end;return o end
return function(worker,ports)
    local graph=assert(worker.Graph);local state=assert(graph.Core)
    assert(state.ClientWorkerContext==worker and graph.IsCanonical(),'canonical worker57 required')
    for _,name in ipairs({'ShutdownSequence','EventRegistration','CallbackRegistration','PublicRegistration','StateInputRegistration','WorldSubscriptionRegistration'})do
        assert(state[name]==nil,'shutdown context cannot adopt existing registry: '..name)
    end
    local resource=ports.resource
    assert(resource=='forge-core','preserve current resource identifier')
    local live,sequence,canonical,holders,inFlight=false,nil,nil,{},0
    local function gate(fn)return function(...)
        if not live then return end
        local ok,allowed=pcall(canonical);if not ok or not allowed then return end
        inFlight=inFlight+1
        local result=table.pack(pcall(fn,...));inFlight=inFlight-1
        if not result[1]then error(result[2],0)end
        return table.unpack(result,2,result.n)
    end end
    local refs,stops={},{}
    local function resolve(path)local v=graph;for key in path:gmatch('[^.]+')do v=assert(v[tonumber(key)or key],path)end;return v end
    -- Same relative order as Events51; Zones includes Points and Business, without alias replay.
    for _,path in ipairs({'Central.Parts.Producers.Status','Central.Parts.Character.Flow','Parts.World.World','Parts.AutoMedic.Session',
        'Parts.Zones','Parts.Objects','Parts.Npcs','Parts.Billboards','Parts.Stores','Parts.Farms','Parts.Starterpack',
        'Parts.AutoMedic.Hospital','Parts.AutoMedic.Runtime','Central.Parts.Consumption','Parts.Vinewood'})do
        local module=resolve(path);refs[#refs+1]={path=path,value=module}
        local events=assert(module.Events);refs[#refs+1]={path=path..'.Events',value=events,count=#events}
        for i,d in ipairs(events)do if d.name=='onResourceStop'then
            assert(not d.network,'stop event cannot be networked')
            local name=path..'.Events.'..i
            refs[#refs+1]={path=name..'.handler',value=d.handler}
            stops[#stops+1]={name=name,handler=function()return d.handler(resource)end,original=d.handler}
        end end
    end
    local seen={};for _,d in ipairs(stops)do assert(not seen[d.original],'duplicate stop alias');seen[d.original]=true end
    assert(#stops==16,'client stop coverage changed')
    canonical=function()
        if state.ClientWorkerContext~=worker or not graph.IsCanonical()then return false end
        if sequence and state.ShutdownSequence~=sequence then return false end
        for key,value in pairs(holders)do if state[key]~=value then return false end end
        for _,d in ipairs(refs)do
            local ok,value=pcall(resolve,d.path)
            if not ok or value~=d.value or(d.count and #value~=d.count)then return false end
        end
        return true
    end
    local e=assert(ports.events);local listen,remove=assert(e.listen),assert(e.remove)
    local virtual,virtualOrder={},{}
    local eventPorts=copy(e)
    eventPorts.listen=function(name,fn)
        if name=='onResourceStop'then local t={handler=fn};virtual[t]=true;virtualOrder[#virtualOrder+1]=t;return t end
        return listen(name,gate(fn))
    end
    eventPorts.remove=function(token)
        if virtual[token]then virtual[token]=nil;token.handler=nil;return true end
        return remove(token)
    end
    local providers={}
    for _,name in ipairs({'native','ox'})do
        local p=copy(assert(ports.callbacks[name]));local bind=p.Bind
        p.Bind=function(lease,fn)return bind(lease,gate(fn))end;providers[name]=p
    end
    local public=copy(ports.public)
    local function properties(value,seen)
        if type(value)=='function'then return gate(value)end
        if type(value)~='table'then return value end
        seen=seen or{};if seen[value]then return seen[value]end
        local out={};seen[value]=out;for k,v in pairs(value)do out[k]=properties(v,seen)end;return out
    end
    local publish=public.publishExport
    public.publishExport=function(name,fn)return publish(name,gate(fn))end
    for _,key in ipairs({'prCommand','oxCommand'})do local fn=public[key]
        public[key]=function(name,options,handler)return fn(name,properties(options),gate(handler))end
    end
    local native=public.nativeCommand
    public.nativeCommand=function(name,fn,restricted)return native(name,gate(fn),restricted)end
    local input=copy(ports.input);local add=input.addBag
    input.addBag=function(key,filter,fn)return add(key,filter,gate(fn))end
    local provider=input.keybind;local call=assert(getmetatable(provider).__call)
    local proxy=copy(provider)
    setmetatable(proxy,{__call=function(_,data)
        for k,v in pairs(data)do if type(v)=='function'then data[k]=gate(v)end end
        return call(provider,data)
    end});input.keybind=proxy
    local bindings={
        {name='events51',api=createEvents(graph,eventPorts)},
        {name='callbacks52',api=createCallbacks(graph,providers)},
        {name='public53',api=createPublic(graph,public)},
        {name='input54',api=createInput(graph,input)},
        {name='subscriptions55',api=createSubscriptions(graph)}}
    for _,key in ipairs({'EventRegistration','CallbackRegistration','PublicRegistration','StateInputRegistration','WorldSubscriptionRegistration'})do holders[key]=state[key]end
    sequence=createSequence({owner=state,worker=worker,binders=bindings,entries=stops,isCurrent=canonical},{
        setActive=function(value)live=value end,detach=remove,pending=function()return inFlight end,
        attach=function(onOwnStop)
            return listen('onResourceStop',function(stoppedResource,...)
                if stoppedResource==resource then return onOwnStop()end
                if live and canonical()then
                    for _,token in ipairs(virtualOrder)do if token.handler then token.handler(stoppedResource,...)end end
                end
            end)
        end})
    return sequence
end
