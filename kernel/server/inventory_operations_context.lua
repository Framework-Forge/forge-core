-- Private integration layer; no resource exports, IO or automatic initialization.
local createInventory=require 'kernel.server.inventory_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(base,ports)
    assert(base.ServerInventoryOperationsContext==nil and base.ServerInventoryContext==nil,'fresh inventory operations context required')
    local api={OperationalReady=false};base.ServerInventoryOperationsContext=api
    local phase,context,graph='constructing'
    local function current()
        if phase=='closed'or phase=='failed'or base.ServerInventoryOperationsContext~=api then return false end
        if not context then return true end
        local inner=context.Progress()
        return inner.phase~='closed'and inner.phase~='failed'and inner.startup.phase~='closed'and inner.startup.phase~='failed'
            and base.ServerInventoryContext==context and base.DomainAssembly==graph and base.PlayerCore==graph.PlayerCore
            and base.ServerStartupContext==context.Startup and base.ServerLifecycleContext==context.Startup.Context
            and base.ServerWorkerContext==context.Startup.Context.Worker and base.Callbacks==graph.Security
            and base.ServerAssembly==graph.Central and base.Shared==graph.PlayerCore.Shared and base.Groups==graph.PlayerCore.Groups
    end
    local op=copy(ports.operations);op.isCurrent=current
    local operations=assert(ports.createOperations,'explicit PR operations factory required')(op);api.Operations=operations
    local p=copy(ports.inventoryContext);p.startup=copy(p.startup);p.startup.lifecycle=copy(p.startup.lifecycle)
    local lifecycle=p.startup.lifecycle;lifecycle.worker=copy(lifecycle.worker);local worker=lifecycle.worker
    worker.graph=copy(worker.graph);worker.graph.central=copy(worker.graph.central);worker.graph.domains=copy(worker.graph.domains)
    local libraries={}
    local function library(lib)
        if libraries[lib]then return libraries[lib]end
        local out=copy(lib);libraries[lib]=out
        if lib.inventory then
            out.inventory=copy(lib.inventory)
            for name,fn in pairs(operations.Public)do out.inventory[name]=fn end
        end
        return out
    end
    for _,group in ipairs({'central','domains'})do for key,value in pairs(worker.graph[group])do
        local out=copy(value);if value.library then out.library=library(value.library)end;worker.graph[group][key]=out
    end end
    local central=worker.graph.central;central.session=copy(central.session);central.session.player=copy(central.session.player)
    central.session.player.inventory=copy(central.session.player.inventory)
    for _,name in ipairs({'AddItem','RemoveItem','GetSlot','GetSlotWithItem','GetSlotsWithItem','ClearInventory','SetItem'})do
        central.session.player.inventory[name]=operations.Raw[name]
    end
    central.finance.integrations=copy(central.finance.integrations)
    central.finance.integrations.inventoryReady=operations.IsReady
    central.finance.integrations.applyPlayerInventoryBonus=operations.Raw.ApplyPlayerInventoryBonus
    local maps={AutoMedic={isReady=operations.IsReady,clearInventoryRaw=operations.Raw.ClearInventory},
        Stores={resourceState=operations.ResourceState,readShopFile=operations.ReadShopFile,addItemRaw=operations.Raw.AddItem,
            removeItemRaw=operations.Raw.RemoveItem,searchCountRaw=operations.Raw.searchCountRaw,itemsRaw=operations.Raw.Items},
        Farms={resourceState=operations.ResourceState,addItemRaw=operations.Raw.AddItem,searchSlotsRaw=operations.Raw.searchSlotsRaw,
            setDurabilityRaw=operations.Raw.SetDurability,itemsRaw=operations.Raw.Items},
        Starterpack={resourceState=operations.ResourceState,canCarryRaw=operations.Raw.CanCarryItem,addItemRaw=operations.Raw.AddItem}}
    for name,map in pairs(maps)do
        local domain=worker.graph.domains[name];domain.inventoryIntegration=copy(domain.inventoryIntegration)
        for key,fn in pairs(map)do domain.inventoryIntegration[key]=fn end
    end
    worker.bootstrap=copy(worker.bootstrap);worker.bootstrap.library=library(worker.bootstrap.library)
    lifecycle.callbacks=copy(lifecycle.callbacks);lifecycle.callbacks.securityLibrary=library(lifecycle.callbacks.securityLibrary)
    lifecycle.events=copy(lifecycle.events);local listen=lifecycle.events.listen
    lifecycle.events.listen=function(name,fn)return listen(name,function(resource,...)
        if name=='onResourceStop'and resource=='forge-core'then phase='closed';operations.Close()end
        return fn(resource,...)
    end)end
    local report=worker.onError;worker.onError=function(...)phase='failed';operations.Close();return report(...)end
    context=createInventory(base,p);graph=context.Graph;api.InventoryContext,api.Graph=context,graph;phase='prepared'
    local function run(method,target)
        local result=table.pack(pcall(method))
        if result[1]and result[2]and current()then phase=target;return table.unpack(result,2,result.n)end
        if phase~='closed'then phase='failed'end;operations.Close();context.Stop()
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'operations_context_not_prepared'end
        local ok,why=operations.Open();if not ok then return false,why end
        return run(context.Install,'installed')
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'operations_context_not_installed'end
        phase='starting';return run(context.Start,'running')
    end
    function api.Stop()phase='closed';operations.Close();return context.Stop()end
    function api.Poll()if phase=='closed'or phase=='failed'then operations.Close()end;return context.Poll()end
    function api.Progress()
        local inner=context.Progress();local scope=operations.Progress()
        return{phase=phase,inventoryContext=inner,operations=scope,complete=inner.complete==true and scope.complete}
    end
    return api
end
