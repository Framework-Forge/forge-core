-- Fresh local config06 before all65 captures; Helpers07 remains the sole persistence implementation.
local createShared=require 'kernel.config.shared'
local createServer=require 'kernel.config.server'
local createVehicles=require 'kernel.server.vehicle_integration_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
local function branch(root,path)
    local out=root
    for _,key in ipairs(path)do out[key]=copy(out[key]);out=out[key]end
    return out
end
return function(base,ports)
    assert(base.ServerConfigurationContext==nil and base.ServerVehicleContext==nil,'fresh server configuration context required')
    local api={OperationalReady=false};base.ServerConfigurationContext=api
    local phase,context,graph,keys='constructing'
    local config,server,shared,refs
    local function current()
        if phase=='closed'or phase=='failed'or base.ServerConfigurationContext~=api then return false end
        if config then
            if api.Config~=config or config.Server~=server or config.Shared~=shared then return false end
            for _,d in ipairs(refs)do if d.owner[d.key]~=d.value then return false end end
        end
        if not context then return true end
        local inner=context.Progress()
        return inner.phase~='closed'and inner.phase~='failed'and base.ServerVehicleContext==context
            and base.DomainAssembly==graph and base.PlayerCore==graph.PlayerCore and base.ServerAssembly==graph.Central
            and base.Callbacks==graph.Security and base.Shared==graph.PlayerCore.Shared and base.Groups==graph.PlayerCore.Groups
            and base.Helpers==graph.Parts.Helpers
    end
    local external=copy(ports.configuration);external.isCurrent=current;external.pr={}
    for _,name in ipairs({'buyOriginalKey','createTempKeyItem','giveTempKey','setLockState'})do
        external.pr[name]=function(...)return assert(keys,'local PR65 scope not constructed').Pr[name](...)end
    end
    local boundary=assert(ports.createConfiguration,'explicit PR configuration factory required')(external);api.Boundary=boundary
    shared=createShared(assert(ports.shared));server=createServer(boundary.Ports)
    config={Shared=shared,Server=server};api.Config=config;refs={}
    local function ref(owner,key)refs[#refs+1]={owner=owner,key=key,value=owner[key]}end
    for _,name in ipairs({'money','player','server','logging','characters','characterDataTables','persistence','giveVehicleKeys','setVehicleLock'})do ref(server,name)end
    for _,name in ipairs({'status','identifierTypes','bloodTypes'})do ref(server.player,name)end
    for _,name in ipairs({'defaultSpawn','starterItems','notifyPosition','serverName'})do ref(shared,name)end
    local p=copy(ports.vehicleContext)
    local life=branch(p,{'bankingContext','operationsContext','inventoryContext','startup','lifecycle'})
    life.worker=copy(life.worker);local worker=life.worker;worker.graph=copy(worker.graph);worker.graph.central=copy(worker.graph.central)
    local central=worker.graph.central
    central.session=copy(central.session);central.session.player=copy(central.session.player);central.session.status=copy(central.session.status)
    central.session.player.config,central.session.player.defaultSpawn=server,shared.defaultSpawn
    central.session.status.config=server.player.status
    central.runtime=copy(central.runtime);central.runtime.config=server
    central.runtime.removeKeyItem=function(...)return assert(keys,'local PR65 scope not constructed').VehicleKey.RemoveKeyItem(...)end
    central.character=copy(central.character);central.character.config,central.character.starterItems=server,shared.starterItems
    central.slots=copy(central.slots);central.slots.config,central.slots.starterItems=server,shared.starterItems
    central.lifecycle=copy(central.lifecycle);central.lifecycle.config=server
    central.lifecycle.notifyPosition,central.lifecycle.serverName=shared.notifyPosition,shared.serverName
    central.lifecycle.disablePersistence=function(...)
        if not current()then return nil,'configuration_context_closed'end
        return assert(graph,'local Helpers not constructed').Parts.Helpers.Persistence.DisablePersistence(...)
    end
    local createKeyScope=assert(p.createVehicles)
    p.createVehicles=function(bindings)
        local b=copy(bindings);local prior=assert(b.isCurrent)
        b.isCurrent=function()return current()and prior()end
        keys=createKeyScope(b);return keys
    end
    local function guard(fn)return function(...)
        if not current()then return end
        return fn(...)
    end end
    life.callbacks=copy(life.callbacks)
    for _,kind in ipairs({'native','ox'})do
        local owner=copy(life.callbacks[kind]);local bind=owner.Bind
        owner.Bind=function(lease,fn)return bind(lease,guard(fn))end;life.callbacks[kind]=owner
    end
    local function properties(value,seen)
        if type(value)=='function'then return guard(value)end
        if type(value)~='table'then return value end
        seen=seen or{};if seen[value]then return seen[value]end
        local out={};seen[value]=out;for key,item in pairs(value)do out[key]=properties(item,seen)end;return out
    end
    life.public=copy(life.public);local pub=life.public;local publish=pub.publishExport
    pub.publishExport=function(name,fn)return publish(name,guard(fn))end
    for _,kind in ipairs({'prCommand','oxCommand'})do local register=pub[kind]
        pub[kind]=function(name,options,fn)return register(name,properties(options),guard(fn))end
    end
    local command=pub.nativeCommand;pub.nativeCommand=function(name,fn,restricted)return command(name,guard(fn),restricted)end
    pub.rpc=copy(pub.rpc);local bind=pub.rpc.Bind;pub.rpc.Bind=function(lease,fn)return bind(lease,guard(fn))end
    life.events=copy(life.events);local listen=life.events.listen
    life.events.listen=function(name,fn)return listen(name,function(resource,...)
        if name=='onResourceStop'and resource=='forge-core'then
            phase='closed';boundary.Close();return fn(resource,...)
        end
        if not current()then return end
        return fn(resource,...)
    end)end
    local onError=worker.onError;worker.onError=function(...)phase='failed';boundary.Close();return onError(...)end
    local constructed,value=pcall(createVehicles,base,p)
    if not constructed then phase='failed';boundary.Close();error(value,0)end
    context=value;graph=context.Graph;api.Context,api.Graph=context,graph;phase='prepared'
    local function run(method,target)
        local result=table.pack(pcall(method))
        if result[1]and result[2]and current()then phase=target;return table.unpack(result,2,result.n)end
        if phase~='closed'then phase='failed'end;boundary.Close();context.Stop()
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'configuration_context_not_prepared'end
        local ok,why=boundary.Open();if not ok then return false,why end
        return run(context.Install,'installed')
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'configuration_context_not_installed'end
        phase='starting';return run(context.Start,'running')
    end
    function api.Stop()phase='closed';boundary.Close();return context.Stop()end
    function api.Poll()if phase=='closed'or phase=='failed'then boundary.Close()end;return context.Poll()end
    function api.IsCurrent()return current()end
    function api.Progress()
        local inner=context.Progress();local scope=boundary.Progress()
        return{phase=phase,context=inner,configuration=scope,complete=inner.complete==true and scope.complete}
    end
    return api
end
