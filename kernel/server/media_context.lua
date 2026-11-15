-- Server-only PR media ports before Helpers07/Commands10 capture, over unchanged67.
local createSupport=require 'kernel.server.support_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
local function branch(root,path)local out=root;for _,k in ipairs(path)do out[k]=copy(out[k]);out=out[k]end;return out end
return function(base,ports)
    assert(base.ServerMediaContext==nil and base.ServerSupportContext==nil,'fresh media context required')
    local api={OperationalReady=false};base.ServerMediaContext=api
    local phase,context,graph='constructing'
    local function current()
        if phase=='closed'or phase=='failed'or base.ServerMediaContext~=api then return false end
        if not context then return true end
        local inner=context.Progress()
        return inner.phase~='closed'and inner.phase~='failed'and base.ServerSupportContext==context and context.Context.IsCurrent()
            and base.DomainAssembly==graph and base.PlayerCore==graph.PlayerCore and base.Helpers==graph.Parts.Helpers
    end
    local m=copy(ports.media);m.isCurrent=current
    local media=assert(ports.createMedia,'explicit PR media factory required')(m);api.Media=media
    local p=copy(ports.supportContext)
    local life=branch(p,{'configurationContext','vehicleContext','bankingContext','operationsContext','inventoryContext','startup','lifecycle'})
    life.worker=copy(life.worker);local worker=life.worker;worker.graph=copy(worker.graph)
    local domain=worker.graph;domain.helpers=copy(domain.helpers);domain.helpers.audio=media.Audio
    domain.helpers.native=copy(domain.helpers.native);domain.helpers.native.GetResourceState=media.ResourceState
    domain.central=copy(domain.central);domain.central.runtime=copy(domain.central.runtime);domain.central.runtime.chatMessage=media.ChatMessage
    local function guard(fn)return function(...)if not current()then return end;return fn(...)end end
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
        out.rpc=copy(out.rpc);local bind=out.rpc.Bind;out.rpc.Bind=function(lease,fn)return bind(lease,guard(fn))end
        return out
    end
    p.public=public(p.public);life.public=public(life.public)
    life.callbacks=copy(life.callbacks)
    for _,kind in ipairs({'native','ox'})do local owner=copy(life.callbacks[kind]);local bind=owner.Bind
        owner.Bind=function(lease,fn)return bind(lease,guard(fn))end;life.callbacks[kind]=owner
    end
    life.events=copy(life.events);local listen=life.events.listen
    life.events.listen=function(name,fn)return listen(name,function(resource,...)
        if name=='onResourceStop'and resource=='forge-core'then phase='closed';media.Close();return fn(resource,...)end
        if not current()then return end;return fn(resource,...)
    end)end
    local onError=worker.onError;worker.onError=function(...)phase='failed';media.Close();return onError(...)end
    local ok,value=pcall(createSupport,base,p)
    if not ok then phase='failed';media.Close();error(value,0)end
    context=value;graph=context.Graph;api.Context,api.Graph=context,graph;phase='prepared'
    local function run(method,target)
        local result=table.pack(pcall(method))
        if result[1]and result[2]and current()then phase=target;return table.unpack(result,2,result.n)end
        if phase~='closed'then phase='failed'end;media.Close();context.Stop()
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'media_not_prepared'end
        if not media.Open()then return false,'media_scope_unavailable'end
        return run(context.Install,'installed')
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'media_not_installed'end
        phase='starting';return run(context.Start,'running')
    end
    function api.Stop()phase='closed';media.Close();return context.Stop()end
    function api.Poll()if not current()then media.Close();context.Stop()end;return context.Poll()end
    function api.Progress()
        local inner,m=context.Progress(),media.Progress()
        return{phase=phase,context=inner,media=m,complete=inner.complete==true and m.complete}
    end
    return api
end
