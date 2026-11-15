-- One internal hooks/logger06 instance captured before66. No framework/inventory routing.
local createContext=require 'kernel.server.configuration_context'
local createHooks=require 'kernel.modules.owned_hooks'
local createLogger=require 'kernel.modules.logger'
local createPublic=require 'kernel.shared.public_registration'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
local function branch(root,path)local out=root;for _,k in ipairs(path)do out[k]=copy(out[k]);out=out[k]end;return out end
return function(base,ports)
    assert(base.ServerSupportContext==nil and base.ServerConfigurationContext==nil,'fresh support context required')
    local api={OperationalReady=false};base.ServerSupportContext=api
    local phase,context,graph,surface='constructing'
    local function current()
        if phase=='closed'or phase=='failed'or base.ServerSupportContext~=api then return false end
        if not context then return true end
        return base.ServerConfigurationContext==context and context.IsCurrent()and base.DomainAssembly==graph
            and base.PlayerCore==graph.PlayerCore and base.Helpers==graph.Parts.Helpers
    end
    local deliveryPorts=copy(ports.delivery);deliveryPorts.isCurrent=current
    local delivery=assert(ports.createDelivery,'explicit PR logging factory required')(deliveryPorts);api.Delivery=delivery
    local hooks=createHooks({hooks=assert(ports.hooks),isCurrent=current});api.Hooks=hooks
    local tasks=assert(ports.createTasks,'explicit PR task factory required')({isCurrent=current,running=assert(ports.running),
        onError=function(...)
            phase='failed';hooks.Close();delivery.Close();if surface then surface.Dispose()end
            if context then context.Stop()end;return assert(ports.onError)(...)
        end})
    local log=copy(ports.logger);assert(log.isServer==true,'server logger required')
    local scheduler=tasks.WrapNative({CreateThread=log.thread,Wait=log.wait})
    log.thread,log.wait=scheduler.CreateThread,scheduler.Wait
    log.libraryLogger,log.httpRequest=delivery.LibraryLogger,delivery.HttpRequest
    local logger=createLogger(log);api.Logger={log=function(...)
        if(phase~='installed'and phase~='starting'and phase~='running')or not current()then return nil,'support_context_closed'end
        return logger.log(...)
    end}
    local p=copy(ports.configurationContext)
    local life=branch(p,{'vehicleContext','bankingContext','operationsContext','inventoryContext','startup','lifecycle'})
    life.worker=copy(life.worker);local worker=life.worker;worker.graph=copy(worker.graph);worker.graph.central=copy(worker.graph.central)
    local central=worker.graph.central;central.session=copy(central.session);central.session.player=copy(central.session.player)
    central.session.player.triggerHook,central.session.player.logger=hooks.Hooks.trigger,api.Logger
    for _,name in ipairs({'lifecycle','runtime','character'})do central[name]=copy(central[name]);central[name].logger=api.Logger end
    local function revoke()
        hooks.Close();delivery.Close();tasks.Close();if surface then surface.Dispose()end
    end
    local function guard(fn)return function(...)if not current()then return end;return fn(...)end end
    life.callbacks=copy(life.callbacks)
    for _,kind in ipairs({'native','ox'})do local owner=copy(life.callbacks[kind]);local bind=owner.Bind
        owner.Bind=function(lease,fn)return bind(lease,guard(fn))end;life.callbacks[kind]=owner
    end
    local function properties(value,seen)
        if type(value)=='function'then return guard(value)end;if type(value)~='table'then return value end
        seen=seen or{};if seen[value]then return seen[value]end;local out={};seen[value]=out
        for k,v in pairs(value)do out[k]=properties(v,seen)end;return out
    end
    life.public=copy(life.public);local pub=life.public;local publish=pub.publishExport
    pub.publishExport=function(name,fn)return publish(name,guard(fn))end
    for _,kind in ipairs({'prCommand','oxCommand'})do local fn=pub[kind]
        pub[kind]=function(name,options,handler)return fn(name,properties(options),guard(handler))end
    end
    local command=pub.nativeCommand;pub.nativeCommand=function(name,fn,restricted)return command(name,guard(fn),restricted)end
    pub.rpc=copy(pub.rpc);local bind=pub.rpc.Bind;pub.rpc.Bind=function(lease,fn)return bind(lease,guard(fn))end
    life.events=copy(life.events);local listen=life.events.listen
    life.events.listen=function(name,fn)return listen(name,function(resource,...)
        if name=='onResourceStop'then
            if resource=='forge-core'then phase='closed';revoke();return fn(resource,...)
            else hooks.ResourceStopped(resource)end
        end
        if not current()then return end
        return fn(resource,...)
    end)end
    local report=worker.onError;worker.onError=function(...)phase='failed';revoke();return report(...)end
    local ok,value=pcall(createContext,base,p)
    if not ok then phase='failed';revoke();error(value,0)end
    context=value;graph=context.Graph;api.Context,api.Graph=context,graph
    local owner={};local entries={}
    for _,name in ipairs({'registerHook','removeHooks'})do entries[#entries+1]={kind='export',owner='InternalHooks06',name=name,
        handler=function(...)if phase~='running'or not current()then return end;return hooks.Hooks[name](...)end}end
    surface=createPublic({owner=owner,side='server',isCurrent=current,entries=entries},assert(ports.public));api.Public=surface
    phase='prepared'
    local function fail()if phase~='closed'then phase='failed'end;revoke();context.Stop()end
    local function run(method,target)
        local result=table.pack(pcall(method))
        if result[1]and result[2]and current()then phase=target;return table.unpack(result,2,result.n)end
        fail();if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'support_not_prepared'end
        local result=table.pack(pcall(function()
            for _,d in ipairs(entries)do assert(ports.public.available('export',d.name),'foreign hook export: '..d.name)end
            assert(hooks.CheckDependencies()and current(),'internal hook dependency refused')
            assert(delivery.Open()and hooks.Open()and tasks.Open(),'support scopes unavailable')
            local ok,err=context.Install();assert(ok,err)
            local bound,why=surface.Install();assert(bound,why)
            return true
        end))
        if result[1]and result[2]and current()then phase='installed';return true end
        fail();return false,result[2]
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'support_not_installed'end
        phase='starting';return run(context.Start,'running')
    end
    function api.Stop()phase='closed';revoke();return context.Stop()end
    function api.Poll()if not current()then revoke()end;return context.Poll()end
    function api.Progress()
        local inner,h,t,d=context.Progress(),hooks.Progress(),tasks.Snapshot(),delivery.Progress()
        return{phase=phase,context=inner,hooks=h,tasks=t,delivery=d,public=surface.State,
            complete=inner.complete==true and h.complete and t.quiescent and d.complete}
    end
    return api
end
