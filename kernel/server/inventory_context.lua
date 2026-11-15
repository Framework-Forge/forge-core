-- Private PR inventory binding over startup61. No ambient exports or active manifest changes.
local createStartup=require 'kernel.server.startup_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(base,ports)
    assert(base.ServerInventoryContext==nil and base.ServerStartupContext==nil,'fresh inventory context required')
    local api={OperationalReady=false};base.ServerInventoryContext=api
    local phase,context,graph='constructing'
    local function current()
        local startupPhase=context and context.Progress().phase
        return phase~='closed'and phase~='failed'and base.ServerInventoryContext==api
            and startupPhase~='closed'and startupPhase~='failed'
            and(not context or(base.ServerStartupContext==context and base.DomainAssembly==graph
                and base.ServerLifecycleContext==context.Context and base.PlayerCore==graph.PlayerCore
                and base.ServerAssembly==graph.Central and base.Callbacks==graph.Security
                and base.Shared==graph.PlayerCore.Shared and base.Groups==graph.PlayerCore.Groups))
    end
    local providerPorts=copy(ports.inventory);providerPorts.isCurrent=current;providerPorts.owner='forge-core'
    local provider=assert(ports.createInventoryProvider,'explicit PR inventory factory required')(providerPorts)
    api.Inventory=provider
    local p=copy(ports.startup);p.lifecycle=copy(p.lifecycle);p.lifecycle.worker=copy(p.lifecycle.worker)
    local worker=p.lifecycle.worker;worker.graph=copy(worker.graph)
    worker.graph.central=copy(worker.graph.central);worker.graph.domains=copy(worker.graph.domains)
    local libraries={}
    local function library(lib)
        if libraries[lib]then return libraries[lib]end
        local out=copy(lib);libraries[lib]=out
        if lib.inventory then out.inventory=copy(lib.inventory);out.inventory.RegisterHook=provider.RegisterHook;out.inventory.Items=provider.Items end
        return out
    end
    for _,group in ipairs({'central','domains'})do for key,v in pairs(worker.graph[group])do
        local out=copy(v);if v.library then out.library=library(v.library)end;worker.graph[group][key]=out
    end end
    for _,key in ipairs({'business','inventory','weapons'})do
        local out=worker.graph.central[key];out.integrations=copy(out.integrations)
        out.integrations.inventoryReady=provider.InventoryReady
        out.integrations.inventoryState=provider.InventoryState
        if key=='business'then out.integrations.removeInventoryHooks=provider.RemoveHooks
        elseif key=='inventory'then
            out.integrations.setItemDefinition=provider.SetItemDefinition
            out.integrations.disableItemDefinition=provider.DisableItemDefinition
            out.integrations.removeItemDefinition=provider.RemoveItemDefinition
        else for _,name in ipairs({'SetWeaponItem','DisableWeaponItem','RemoveWeaponItem','HasWeaponItem'})do out.integrations[name]=provider[name]end end
    end
    worker.bootstrap=copy(worker.bootstrap);worker.bootstrap.library=library(worker.bootstrap.library)
    p.lifecycle.callbacks=copy(p.lifecycle.callbacks);p.lifecycle.callbacks.securityLibrary=library(p.lifecycle.callbacks.securityLibrary)
    p.lifecycle.events=copy(p.lifecycle.events);local listen=p.lifecycle.events.listen
    p.lifecycle.events.listen=function(name,fn)
        return listen(name,function(resource,...)
            if name=='onResourceStop'and resource=='forge-core'then phase='closed';provider.Close()end
            return fn(resource,...)
        end)
    end
    local report=worker.onError;worker.onError=function(...)phase='failed';provider.Close();return report(...)end
    context=createStartup(base,p);graph=context.Graph;api.Startup,api.Graph=context,graph
    phase='prepared'
    function api.Install()
        if phase~='prepared'or not current()then return false,'inventory_context_not_prepared'end
        local ok,why=provider.Open();if not ok then return false,why end
        local values=table.pack(pcall(context.Install))
        if values[1]and values[2]and current()then phase='installed';return table.unpack(values,2,values.n)end
        phase='failed';provider.Close();context.Stop()
        if not values[1]then error(values[2],0)end;return table.unpack(values,2,values.n)
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'inventory_context_not_installed'end
        phase='starting';local values=table.pack(pcall(context.Start))
        if values[1]and values[2]and current()then phase='running';return table.unpack(values,2,values.n)end
        if phase~='closed'then phase='failed'end;provider.Close();context.Stop()
        if not values[1]then error(values[2],0)end;return table.unpack(values,2,values.n)
    end
    function api.Stop()phase='closed';provider.Close();return context.Stop()end
    function api.Poll()if phase=='closed'or phase=='failed'then provider.Close()end;return context.Poll()end
    function api.Progress()
        local startup=context.Progress();local inventory=provider.Progress()
        return{phase=phase,startup=startup,inventory=inventory,complete=startup.lifecycle.complete==true and inventory.complete}
    end
    return api
end
