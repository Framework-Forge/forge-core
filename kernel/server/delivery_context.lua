-- One existing Producer03/cache projection, over68. No new authority or live bootstrap.
local createMedia=require 'kernel.server.media_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
local function branch(root,path)local out=root;for _,key in ipairs(path)do out[key]=copy(out[key]);out=out[key]end;return out end
return function(base,ports)
    assert(base.ServerDeliveryContext==nil and base.ServerMediaContext==nil,'fresh server delivery context required')
    local api={OperationalReady=false};base.ServerDeliveryContext=api
    local phase,context,graph,worker='constructing';local refs={}
    local function canonical()
        if base.ServerDeliveryContext~=api then return false end
        for _,r in ipairs(refs)do if r.owner[r.key]~=r.value then return false end end
        return true
    end
    local function current()
        if phase=='closed'or phase=='failed'or not canonical()then return false end
        if not context then return true end
        -- Child scopes close before60 runs its cleanup. Only this owned cleanup window remains callable.
        if phase=='stopping'then return true end
        local p=context.Progress()
        return p.phase~='closed'and p.phase~='failed'and base.ServerConfigurationContext.IsCurrent()
    end
    local b=copy(ports.delivery);b.isCurrent=current
    local boundary=assert(ports.createDelivery,'explicit PR cache delivery factory required')(b);api.Boundary=boundary
    local p=copy(ports.mediaContext)
    local support=branch(p,{'supportContext'})
    local config=branch(support,{'configurationContext'})
    local vehicles=branch(config,{'vehicleContext'})
    local bank=branch(vehicles,{'bankingContext'})
    local ops=branch(bank,{'operationsContext'})
    local inventory=branch(ops,{'inventoryContext'})
    local startup=branch(inventory,{'startup'})
    local life=branch(startup,{'lifecycle'});life.worker=copy(life.worker);local w=life.worker
    w.graph=copy(w.graph);local domain=w.graph;domain.central=copy(domain.central);domain.domains=copy(domain.domains)
    local function ref(owner,key)refs[#refs+1]={owner=owner,key=key,value=owner[key]}end
    for _,key in ipairs({'getResourceState','writeCache','emit'})do ref(boundary.Delivery,key)end
    for _,key in ipairs({'get','set','patch','clear','clearPrefix','GetPlayer','GetMetadata','GetResourceState','SetResourceState'})do ref(boundary.Cache,key)end
    for _,key in ipairs({'Delivery','Cache','EmitLocal'})do ref(boundary,key)end;ref(api,'Boundary')
    local libraries={}
    local function library(lib)
        if libraries[lib]then return libraries[lib]end
        local out=copy(lib);libraries[lib]=out;out.cache=boundary.Cache;return out
    end
    local function native(n)
        local out=copy(n)
        for _,key in ipairs({'emit','TriggerEvent'})do if n[key]then out[key]=boundary.EmitLocal end end
        return out
    end
    for _,group in ipairs({'central','domains'})do for name,v in pairs(domain[group])do
        local out=copy(v);if v.library then out.library=library(v.library)end;if v.native then out.native=native(v.native)end;domain[group][name]=out
    end end
    domain.helpers=copy(domain.helpers);domain.helpers.library=library(domain.helpers.library);domain.helpers.native=native(domain.helpers.native)
    domain.central.session=copy(domain.central.session);local session=domain.central.session
    session.delivery=boundary.Delivery;session.player=copy(session.player);session.player.platform=copy(session.player.platform)
    session.player.library=library(session.player.library)
    session.player.platform.emitServer=boundary.EmitLocal
    w.bootstrap=copy(w.bootstrap);w.bootstrap.library=library(w.bootstrap.library);w.bootstrap.native=native(w.bootstrap.native)
    life.callbacks=copy(life.callbacks);life.callbacks.securityLibrary=library(life.callbacks.securityLibrary)
    local function ownFactory(holder,key,pending)
        local factory=assert(holder[key],'explicit existing factory required: '..key)
        holder[key]=function(bindings)
            local b=copy(bindings);local prior=assert(b.isCurrent);b.isCurrent=function()return current()and prior()end
            local scope=factory(b)
            if pending then local snapshot=scope.Snapshot
                scope.Snapshot=function()local out=snapshot();if boundary.Progress().pending>0 then out.quiescent=false end;return out end
            end
            return scope
        end
    end
    ownFactory(p,'createMedia');ownFactory(support,'createDelivery');ownFactory(support,'createTasks')
    ownFactory(config,'createConfiguration');ownFactory(vehicles,'createVehicles');ownFactory(bank,'createBanking')
    ownFactory(ops,'createOperations');ownFactory(inventory,'createInventoryProvider');ownFactory(w,'createTasks',true)
    local function finish(...)
        local status=base.ServerLifecycleContext.Progress()
        if status.phase=='cleaned'or status.phase=='cleanup-failed'then boundary.Close();phase='closed'end
        return ...
    end
    local function cleanup(fn,...)
        if boundary.Progress().phase=='closed'then return fn(...)end
        phase='stopping';boundary.CloseIngress();return finish(boundary.DuringCleanup(fn,...))
    end
    local function guard(fn)return function(...)if phase=='stopping'or not current()then return end;return fn(...)end end
    local function properties(value,seen)
        if type(value)=='function'then return guard(value)end;if type(value)~='table'then return value end
        seen=seen or{};if seen[value]then return seen[value]end;local out={};seen[value]=out
        for key,v in pairs(value)do out[key]=properties(v,seen)end;return out
    end
    local function public(value)
        local out=copy(value);local publish=out.publishExport;out.publishExport=function(name,fn)return publish(name,guard(fn))end
        for _,kind in ipairs({'prCommand','oxCommand'})do local bind=out[kind];out[kind]=function(name,options,fn)return bind(name,properties(options),guard(fn))end end
        local command=out.nativeCommand;out.nativeCommand=function(name,fn,restricted)return command(name,guard(fn),restricted)end
        out.rpc=copy(out.rpc);local bind=out.rpc.Bind;out.rpc.Bind=function(lease,fn)return bind(lease,guard(fn))end;return out
    end
    support.public=public(support.public);life.public=public(life.public)
    for _,kind in ipairs({'native','ox'})do local v=copy(life.callbacks[kind]);local bind=v.Bind
        v.Bind=function(lease,fn)return bind(lease,guard(fn))end;life.callbacks[kind]=v
    end
    life.events=copy(life.events);local listen=life.events.listen
    life.events.listen=function(name,fn)return listen(name,function(resource,...)
        if name=='onResourceStop'and resource=='forge-core'then
            if not current()then return api.Stop()end;return cleanup(fn,resource,...)
        end
        return guard(fn)(resource,...)
    end)end
    local report=w.onError;w.onError=function(...)
        if context and canonical()then cleanup(context.Stop)else phase='failed';boundary.Close()end
        return report(...)
    end
    local ok,value=pcall(createMedia,base,p)
    if not ok then phase='failed';boundary.Close();error(value,0)end
    context=value;graph=context.Graph;worker=assert(base.ServerWorkerContext);api.Context,api.Graph=context,graph;phase='prepared'
    for _,key in ipairs({'ServerMediaContext','ServerSupportContext','ServerConfigurationContext','ServerVehicleContext','ServerBankingContext',
        'ServerInventoryOperationsContext','ServerInventoryContext','ServerStartupContext','ServerLifecycleContext','ServerWorkerContext',
        'ShutdownSequence','DomainAssembly','ServerAssembly','PlayerCore','Callbacks','Shared','Groups','Helpers'})do ref(base,key)end
    for _,key in ipairs({'Players','Status','Session','BridgeCache'})do ref(graph.PlayerCore.State,key)end
    for _,name in ipairs(graph.Order)do ref(graph.Parts,name)end
    local function run(fn,target)
        local result=table.pack(pcall(fn))
        if result[1]and result[2]and current()and phase~='stopping'then phase=target;return table.unpack(result,2,result.n)end
        if phase~='closed'and canonical()then cleanup(context.Stop)else boundary.Close()end
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'server_delivery_not_prepared'end
        if not boundary.Open()then return false,'server_delivery_scope_unavailable'end;return run(context.Install,'installed')
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'server_delivery_not_installed'end
        phase='starting';return run(context.Start,'running')
    end
    function api.Stop()
        if phase=='closed'then return context.Stop()end
        if not current()then boundary.Close();worker.Close();phase='failed';return false,'stale_context'end
        return cleanup(context.Stop)
    end
    function api.Poll()
        if phase=='closed'then return context.Poll()end
        if phase~='stopping'then return false,'not_stopping'end
        if not current()then boundary.Close();worker.Close();phase='failed';return false,'stale_context'end
        return cleanup(context.Poll)
    end
    function api.IsCurrent()return current()end
    function api.Progress()local c,b=context.Progress(),boundary.Progress()
        return{phase=phase,context=c,boundary=b,complete=phase=='closed'and c.complete and b.complete}
    end
    return api
end
