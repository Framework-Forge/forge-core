local createWorker=require 'kernel.server.worker_context'
local createSequence=require 'kernel.shared.shutdown_sequence'
local createIngress=require 'kernel.shared.owned_ingress'
local createEvents=require 'kernel.server.event_registration'
local createSupplement=require 'kernel.shared.event_registration'
local createCallbacks=require 'kernel.server.callback_registration'
local createPublic=require 'kernel.server.public_registration'
local function copy(t)local o={};for k,v in pairs(assert(t))do o[k]=v end;return o end
return function(base,ports)
    assert(base.ServerLifecycleContext==nil and base.ServerWorkerContext==nil,'fresh server lifecycle required')
    for _,key in ipairs({'ShutdownSequence','EventRegistration','CallbackRegistration','PublicRegistration'})do assert(base[key]==nil,'fresh registry required: '..key)end
    assert(ports.resource=='forge-core','preserve current resource identifier')
    local api={OperationalReady=false,PhysicalRemoval=false};base.ServerLifecycleContext=api
    local graph,worker,sequence,scope,canonical
    local live,closing,inFlight,started,pendingStart,ownStarted=false,false,0,false,false,false
    local holders,refs,stops,starts={},{},{},{}
    local function resolve(path)local v=graph;for k in path:gmatch('[^.]+')do v=assert(v[tonumber(k)or k],path)end;return v end
    canonical=function()
        if not graph or graph.State~='prepared-inactive'or graph.Central.State~='prepared-inactive'
            or base.ServerLifecycleContext~=api or base.ServerWorkerContext~=worker or base.DomainAssembly~=graph
            or base.ServerAssembly~=graph.Central or base.PlayerCore~=graph.PlayerCore or base.Callbacks~=graph.Security then return false end
        if graph.PlayerCore.Shared~=base.Shared or graph.PlayerCore.Groups~=base.Groups then return false end
        if sequence and base.ShutdownSequence~=sequence then return false end
        for k,v in pairs(holders)do if base[k]~=v then return false end end
        for _,d in ipairs(refs)do local ok,v=pcall(resolve,d.path);if not ok or v~=d.value or(d.count and #v~=d.count)then return false end end
        return true
    end
    local function gate(fn)return function(...)
        if not live or not canonical()then return end
        inFlight=inFlight+1;local result=table.pack(pcall(fn,...));inFlight=inFlight-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end end
    scope=createIngress({isCurrent=function()return not closing and canonical()end})
    local eventPorts=copy(ports.events);local listen,remove=assert(eventPorts.listen),assert(eventPorts.remove)
    local p=copy(ports.worker);p.graph=copy(p.graph);p.graph.central=copy(p.graph.central);p.graph.domains=copy(p.graph.domains)
    local libraries,natives={},{}
    local function library(lib)
        if libraries[lib]then return libraries[lib]end
        local out=copy(lib);libraries[lib]=out
        if lib.inventory then
            out.inventory=copy(lib.inventory)
            if lib.inventory.RegisterHook then out.inventory.RegisterHook=scope.Wrap(lib.inventory.RegisterHook,nil)end
        end
        return out
    end
    local function native(n)
        if natives[n]then return natives[n]end
        local out=copy(n);natives[n]=out
        if n.listen then out.listen=scope.Wrap(listen,remove)end
        return out
    end
    for k,v in pairs(p.graph.central)do
        local out=copy(v);if v.library then out.library=library(v.library)end;if v.native then out.native=native(v.native)end;p.graph.central[k]=out
    end
    for k,v in pairs(p.graph.domains)do
        local out=copy(v);if v.library then out.library=library(v.library)end;if v.native then out.native=native(v.native)end
        if v.inventoryIntegration and v.inventoryIntegration.onPurchaseResult then
            out.inventoryIntegration=copy(v.inventoryIntegration)
            out.inventoryIntegration.onPurchaseResult,out.inventoryIntegration.removePurchaseResult=scope.Wrap(
                v.inventoryIntegration.onPurchaseResult,assert(v.inventoryIntegration.removePurchaseResult))
        end
        p.graph.domains[k]=out
    end
    p.bootstrap=copy(p.bootstrap);p.bootstrap.library=library(p.bootstrap.library)
    local report=assert(p.onError)
    p.onError=function(...)
        local result=table.pack(pcall(report,...));if sequence then sequence.Stop()end
        if not result[1]then error(result[2],0)end
        return table.unpack(result,2,result.n)
    end
    worker=createWorker(base,p);graph=worker.Graph;api.Worker,api.Graph,api.Ingress=worker,graph,scope
    for _,name in ipairs(graph.Order)do refs[#refs+1]={path='Parts.'..name,value=graph.Parts[name]}end
    for _,path in ipairs({'PlayerCore.State','PlayerCore.State.Players','PlayerCore.State.Status','PlayerCore.State.Session',
        'PlayerCore.State.BridgeCache','PlayerCore.Shared','PlayerCore.Groups'})do refs[#refs+1]={path=path,value=resolve(path)}end
    -- Same relative order as51, source-first only on the two QBX owners.
    for _,item in ipairs({{'PlayerCore.Producers.Cache',true},{'PlayerCore.Lifecycle.Events',true},
        {'Parts.World.World',false},{'Parts.AutoMedic.Session',false},{'Central.Parts.Finance.Vip',false},
        {'Central.Parts.Weapons.Service',false},{'Central.Parts.Inventory.Service',false},{'Parts.Vehicles',false},
        {'Parts.Stores',false},{'Parts.PlayerAdmin',false}})do
        local path,first=item[1],item[2];local m=resolve(path);refs[#refs+1]={path=path,value=m}
        refs[#refs+1]={path=path..'.Events',value=m.Events,count=#m.Events}
        for i,d in ipairs(m.Events)do if d.name=='onResourceStart'or d.name=='onResourceStop'then
            assert(not d.network,'resource lifecycle cannot be networked')
            refs[#refs+1]={path=path..'.Events.'..i..'.handler',value=d.handler}
            local fn=d.handler;local call=function(resource)if first then return fn(nil,resource)end;return fn(resource)end
            local entry={name=path..'.Events.'..i,handler=call,original=fn,sourceFirst=first}
            if d.name=='onResourceStop'then stops[#stops+1]=entry else starts[#starts+1]=entry end
        end end
    end
    assert(#stops==5 and #starts==8,'server lifecycle coverage changed')
    local seen={};for _,list in ipairs({stops,starts})do for _,d in ipairs(list)do assert(not seen[d.original],'duplicate lifecycle alias');seen[d.original]=true end end
    local virtual={};local e=copy(eventPorts)
    e.listen=function(name,fn)
        if name=='onResourceStop'or name=='onResourceStart'then local t={name=name,handler=fn};virtual[t]=true;return t end
        return listen(name,gate(fn))
    end
    e.remove=function(t)if virtual[t]then virtual[t]=nil;t.handler=nil;return true end;return remove(t)end
    local cb={securityLibrary=library(assert(ports.callbacks.securityLibrary))}
    for _,name in ipairs({'native','ox'})do
        local v=copy(ports.callbacks[name]);local bind=v.Bind;v.Bind=function(lease,fn)return bind(lease,gate(fn))end;cb[name]=v
    end
    local pub=copy(ports.public)
    local function properties(v,seen)
        if type(v)=='function'then return gate(v)end;if type(v)~='table'then return v end
        seen=seen or{};if seen[v]then return seen[v]end;local out={};seen[v]=out;for k,item in pairs(v)do out[k]=properties(item,seen)end;return out
    end
    local publish=pub.publishExport;pub.publishExport=function(name,fn)return publish(name,gate(fn))end
    for _,k in ipairs({'prCommand','oxCommand'})do local fn=pub[k];pub[k]=function(name,opts,handler)return fn(name,properties(opts),gate(handler))end end
    local command=pub.nativeCommand;pub.nativeCommand=function(name,fn,restricted)return command(name,gate(fn),restricted)end
    local supplementOwner={};local supplemental={}
    for _,d in ipairs(worker.Bootstrap.Events)do supplemental[#supplemental+1]={owner='Bootstrap59',name=d.name,handler=d.handler,network=d.network,sourceFirst=d.sourceFirst}end
    local binders={{name='ingress60',api=scope},{name='events51',api=createEvents(graph,e)},
        {name='bootstrap59',api=createSupplement({owner=supplementOwner,side='server',entries=supplemental,isCurrent=canonical},e)},
        {name='callbacks52',api=createCallbacks(graph,cb)},{name='public53',api=createPublic(graph,pub)}}
    for _,k in ipairs({'EventRegistration','CallbackRegistration','PublicRegistration'})do holders[k]=base[k]end
    local function resourceStart(resource)
        if resource=='forge-core'then
            if ownStarted then return end
            if not started then pendingStart=true;return end
            ownStarted=true;pendingStart=false
        end
        return gate(function()for _,d in ipairs(starts)do if not live or not canonical()then return end;d.handler(resource)end end)()
    end
    local startListen=scope.Wrap(listen,remove)
    binders[#binders+1]={name='resourceStart60',api={Install=function()
        local token=startListen('onResourceStart',resourceStart);return token~=nil and token~=false
    end,Dispose=function()return true end}}
    local bodies={};for _,d in ipairs(stops)do bodies[#bodies+1]={name=d.name,handler=function()return d.handler('forge-core')end}end
    local start=worker.Start
    sequence=createSequence({owner=base,isCurrent=canonical,binders=binders,entries=bodies,worker={
        Close=worker.Close,Progress=worker.Progress,Start=function()
            local ok,why=start();if not ok then return false,why end;started=true
            if pendingStart then resourceStart('forge-core')end;return true
        end}},{setActive=function(v)live=v;if not v then closing=true end end,pending=function()return inFlight+scope.Pending()end,
        attach=function(onOwnStop)
            return listen('onResourceStop',function(resource)
                if resource=='forge-core'then return onOwnStop()end
                return gate(function()for _,d in ipairs(stops)do if not live or not canonical()then return end;d.handler(resource)end end)()
            end)
        end,detach=remove})
    api.Install,api.Start,api.Stop,api.Poll=sequence.Install,sequence.Start,sequence.Stop,sequence.Poll
    function api.Progress()local out=sequence.Progress();out.ingress=scope.Progress();out.ownStartDelivered=ownStarted
        out.ownStartPending=pendingStart;return out end
    function api.Describe()local out={stops={},starts={}};for _,k in ipairs({'stops','starts'})do
        for i,d in ipairs(k=='stops'and stops or starts)do out[k][i]={name=d.name,handler=d.original,sourceFirst=d.sourceFirst}end
    end;return out end
    return api
end
