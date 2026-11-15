-- Private external keys/garage over64; core persistence stays in the canonical Helpers.
local createBanking=require 'kernel.server.banking_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(base,ports)
    assert(base.ServerVehicleContext==nil and base.ServerBankingContext==nil,'fresh vehicle context required')
    local api={OperationalReady=false};base.ServerVehicleContext=api
    local phase,context,graph='constructing'
    local function current()
        if phase=='closed'or phase=='failed'or base.ServerVehicleContext~=api then return false end
        if not context then return true end
        local inner=context.Progress()
        for _,key in ipairs({'operationsContext','inventoryContext','startup','lifecycle'})do
            if inner.phase=='closed'or inner.phase=='failed'then return false end
            inner=inner[key]
        end
        return inner.phase~='closed'and inner.phase~='failed'and base.ServerBankingContext==context
            and base.DomainAssembly==graph and base.PlayerCore==graph.PlayerCore and base.ServerAssembly==graph.Central
            and base.Callbacks==graph.Security and base.Shared==graph.PlayerCore.Shared and base.Groups==graph.PlayerCore.Groups
            and base.Helpers==graph.Parts.Helpers and base.VehicleCore==graph.Parts.Vehicles
    end
    local boundary=copy(ports.vehicles);boundary.isCurrent=current
    local vehicles=assert(ports.createVehicles,'explicit PR vehicle factory required')(boundary);api.Vehicles=vehicles
    local p=copy(ports.bankingContext);p.operationsContext=copy(p.operationsContext)
    local ops=p.operationsContext;ops.inventoryContext=copy(ops.inventoryContext)
    local inv=ops.inventoryContext;inv.startup=copy(inv.startup);inv.startup.lifecycle=copy(inv.startup.lifecycle)
    local life=inv.startup.lifecycle;life.worker=copy(life.worker);local worker=life.worker
    worker.graph=copy(worker.graph);worker.graph.domains=copy(worker.graph.domains)
    local domain=copy(worker.graph.domains.Vehicles);worker.graph.domains.Vehicles=domain
    domain.library=copy(domain.library);domain.library.vehicle_key=vehicles.VehicleKey
    domain.vehicleIntegration=vehicles.Integration
    life.events=copy(life.events);local listen=life.events.listen
    life.events.listen=function(name,fn)return listen(name,function(resource,...)
        if name=='onResourceStop'and resource=='forge-core'then phase='closed';vehicles.Close()end
        return fn(resource,...)
    end)end
    local report=worker.onError;worker.onError=function(...)phase='failed';vehicles.Close();return report(...)end
    context=createBanking(base,p);graph=context.Graph;api.BankingContext,api.Graph=context,graph;phase='prepared'
    local function run(method,target)
        local result=table.pack(pcall(method))
        if result[1]and result[2]and current()then phase=target;return table.unpack(result,2,result.n)end
        if phase~='closed'then phase='failed'end;vehicles.Close();context.Stop()
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'vehicle_context_not_prepared'end
        local ok,why=vehicles.Open();if not ok then return false,why end
        return run(context.Install,'installed')
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'vehicle_context_not_installed'end
        phase='starting';return run(context.Start,'running')
    end
    function api.Stop()phase='closed';vehicles.Close();return context.Stop()end
    function api.Poll()if phase=='closed'or phase=='failed'then vehicles.Close()end;return context.Poll()end
    function api.Progress()
        local inner=context.Progress();local scope=vehicles.Progress()
        return{phase=phase,bankingContext=inner,vehicles=scope,complete=inner.complete==true and scope.complete}
    end
    return api
end
