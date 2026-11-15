local createContext=require 'kernel.server.lifecycle_context'
local createPreflight=require 'kernel.server.startup_preflight_forge'
local createSchema=require 'kernel.server.startup_schema'
local function copy(t)local o={};for k,v in pairs(assert(t))do o[k]=v end;return o end
return function(base,ports)
    assert(base.ServerStartupContext==nil and base.ServerLifecycleContext==nil,'fresh server startup required')
    local api={OperationalReady=false};base.ServerStartupContext=api
    local phase,context,graph,report='constructing'
    local refs={}
    local function current()
        if phase=='closed'or phase=='failed'or base.ServerStartupContext~=api then return false end
        if not context then return phase=='constructing'end
        if base.ServerLifecycleContext~=context or base.DomainAssembly~=graph or base.PlayerCore~=graph.PlayerCore
            or base.Callbacks~=graph.Security or base.ServerWorkerContext~=context.Worker then return false end
        local workerPhase=context.Worker.Progress().context
        if workerPhase=='closed'or workerPhase=='failed'then return false end
        for _,d in ipairs(refs)do if d.owner[d.key]~=d.value then return false end end
        return true
    end
    local function guard(fn)return function(...)
        if phase~='running'or not current()then return end
        return fn(...)
    end end
    local p=copy(ports.lifecycle);p.events=copy(p.events);p.callbacks=copy(p.callbacks);p.public=copy(p.public)
    p.worker=copy(p.worker);p.worker.graph=copy(p.worker.graph);p.worker.graph.central=copy(p.worker.graph.central)
    p.worker.graph.domains=copy(p.worker.graph.domains)
    local player=copy(p.worker.graph.central.session.player);local db=assert(player.db)
    assert(type(db.query.await)=='function'and type(db.single.await)=='function','explicit awaited canonical DB required')
    local function inspect()
        local users=db.single.await("SELECT COUNT(*) AS present FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'")
        if not current()then return false end
        local column=db.single.await("SELECT COUNT(*) AS present FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'players' AND COLUMN_NAME = 'userId'")
        return current()and type(users)=='table'and tonumber(users.present)==1 and type(column)=='table'and tonumber(column.present)==1
    end
    local schema=createSchema({isCurrent=current,execute=db.query.await,inspect=inspect})
    local preflight=createPreflight({isCurrent=current,resourceState=assert(ports.resourceState),inventoryBridgeProbe=assert(ports.inventoryBridgeProbe),
        checkDependency=assert(p.worker.graph.central.runtime.library.checkDependency),
        getConvar=assert(p.worker.graph.central.runtime.native.GetConvar),getConvarInt=assert(p.worker.graph.central.runtime.native.GetConvarInt),
        databaseReady=assert(ports.databaseReady),ping=function()
            local row=db.single.await('SELECT 1 AS forge_ready');return type(row)=='table'and tonumber(row.forge_ready)==1
        end})
    local query=copy(db.query);local dbProxy=copy(db)
    setmetatable(query,{__call=function(_,sql,...)
        if schema.Matches('users',sql)then return schema.Execute('users',sql,...)end
        return db.query(sql,...)
    end});dbProxy.query=query;player.db=dbProxy
    p.worker.graph.central.session=copy(p.worker.graph.central.session);p.worker.graph.central.session.player=player
    p.worker.graph.central.lifecycle=copy(p.worker.graph.central.lifecycle)
    local rawSchema=p.worker.graph.central.lifecycle.querySchema
    p.worker.graph.central.lifecycle.querySchema=function(sql,...)
        if schema.Matches('playerUserId',sql)then return schema.Execute('playerUserId',sql,...)end
        return rawSchema(sql,...)
    end
    local function check()
        local ok,value=preflight.Check();report=value;return ok
    end
    local originalReady=assert(p.worker.isReady);local prepared=false;local handler
    p.worker.isReady=function()
        if not current()or not check()then return false end
        local ready=originalReady();if not current()or ready~=true then return false end
        -- Refuse a late World reset before accepting even the first schema write.
        local world=graph.Parts.World.State
        for _,key in ipairs({'stores','objects','npcs','density','vinewood','starterpack','farms','billboards','characterPreviews','spotlights'})do
            if world.getRecord(key)~=nil then return false end
        end
        if not prepared then
            local ok,err=schema.Prepare(function()return handler(nil,'forge-core')end)
            assert(ok,err);prepared=true
        end
        return current()and prepared
    end
    local listen=p.events.listen
    p.events.listen=function(name,fn)
        if name=='onResourceStop'then return listen(name,function(resource,...)
            if resource=='forge-core'then phase='closed';schema.Close()end
            return fn(resource,...)
        end)end
        return listen(name,(name=='onResourceStart'or name=='onResourceStop')and fn or guard(fn))
    end
    for _,kind in ipairs({'native','ox'})do
        local owner=copy(p.callbacks[kind]);local bind=owner.Bind;owner.Bind=function(lease,fn)return bind(lease,guard(fn))end;p.callbacks[kind]=owner
    end
    local function properties(v,seen)
        if type(v)=='function'then return guard(v)end;if type(v)~='table'then return v end
        seen=seen or{};if seen[v]then return seen[v]end;local out={};seen[v]=out;for k,item in pairs(v)do out[k]=properties(item,seen)end;return out
    end
    local publish=p.public.publishExport;p.public.publishExport=function(name,fn)return publish(name,guard(fn))end
    for _,kind in ipairs({'prCommand','oxCommand'})do local fn=p.public[kind];p.public[kind]=function(name,options,handler)return fn(name,properties(options),guard(handler))end end
    local command=p.public.nativeCommand;p.public.nativeCommand=function(name,fn,restricted)return command(name,guard(fn),restricted)end
    local rpc=copy(p.public.rpc);local bind=rpc.Bind;rpc.Bind=function(lease,fn)return bind(lease,guard(fn))end;p.public.rpc=rpc
    local libraries={}
    local function library(lib)
        if libraries[lib]then return libraries[lib]end
        local out=copy(lib);libraries[lib]=out
        if lib.inventory and lib.inventory.RegisterHook then
            out.inventory=copy(lib.inventory);out.inventory.RegisterHook=function(name,fn,...)return lib.inventory.RegisterHook(name,guard(fn),...)end
        end
        return out
    end
    for _,group in ipairs({'central','domains'})do for name,value in pairs(p.worker.graph[group])do
        local out=copy(value);if value.library then out.library=library(value.library)end
        if value.inventoryIntegration and value.inventoryIntegration.onPurchaseResult then
            out.inventoryIntegration=copy(value.inventoryIntegration);local register=value.inventoryIntegration.onPurchaseResult
            out.inventoryIntegration.onPurchaseResult=function(id,fn)return register(id,guard(fn))end
        end
        p.worker.graph[group][name]=out
    end end
    p.callbacks.securityLibrary=library(p.callbacks.securityLibrary)
    local onError=p.worker.onError;p.worker.onError=function(...)phase='failed';schema.Close();return onError(...)end
    context=createContext(base,p);graph=context.Graph;api.Context,api.Graph,api.Schema= context,graph,schema
    for _,d in ipairs(graph.PlayerCore.Lifecycle.Events.Events)do if d.name=='onResourceStart'then assert(not handler,'unique core schema handler required');handler=d.handler end end
    assert(handler,'installed core schema handler required')
    for _,d in ipairs({{graph,'PlayerCore'},{graph,'Central'},{graph.PlayerCore,'Storage'},
        {graph.PlayerCore.Storage,'createUsersTable'},{base,'Groups'},{base,'Shared'},
        {db,'query'},{db.query,'await'},{db,'single'},{db.single,'await'},
        {graph.Parts.World,'State'},{graph.Parts.World.State,'getRecord'}})do refs[#refs+1]={owner=d[1],key=d[2],value=d[1][d[2]]}end
    for _,name in ipairs(graph.Order)do refs[#refs+1]={owner=graph.Parts,key=name,value=graph.Parts[name]}end
    phase='prepared'
    function api.Check()return check(),report end
    function api.Install()
        if phase~='prepared'then return false,'startup_not_prepared'end
        if not check()then return false,'startup_dependencies_not_ready'end
        local ok,err=context.Install();if ok then phase='installed'else if phase~='closed'then phase='failed'end;schema.Close()end;return ok,err
    end
    function api.Start()
        if phase~='installed'then return false,'startup_not_installed'end
        phase='starting';local ok,err=context.Start()
        if ok and current()then phase='running';return true end
        if phase~='closed'then phase='failed'end;schema.Close();return false,err
    end
    function api.Stop()phase='closed';schema.Close();return context.Stop()end
    function api.Poll()return context.Poll()end
    function api.Progress()return{phase=phase,dependencies=report,schema=schema.Progress(),lifecycle=context.Progress()}end
    function api.Describe()return preflight.Describe()end
    return api
end
