-- Private society integration over63. No external resource exports, database or second money authority.
local createOperations=require 'kernel.server.inventory_operations_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(base,ports)
    assert(base.ServerBankingContext==nil and base.ServerInventoryOperationsContext==nil,'fresh banking context required')
    local api={OperationalReady=false};base.ServerBankingContext=api
    local phase,context,graph='constructing'
    local function current()
        if phase=='closed'or phase=='failed'or base.ServerBankingContext~=api then return false end
        if not context then return true end
        local inner=context.Progress();local prior=inner.inventoryContext
        return inner.phase~='closed'and inner.phase~='failed'and prior.phase~='closed'and prior.phase~='failed'
            and prior.startup.phase~='closed'and prior.startup.phase~='failed'
            and base.ServerInventoryOperationsContext==context and base.DomainAssembly==graph
            and base.PlayerCore==graph.PlayerCore and base.ServerAssembly==graph.Central and base.Callbacks==graph.Security
            and base.Shared==graph.PlayerCore.Shared and base.Groups==graph.PlayerCore.Groups
    end
    local bank=copy(ports.banking);bank.isCurrent=current
    local banking=assert(ports.createBanking,'explicit PR society factory required')(bank);api.Banking=banking
    local p=copy(ports.operationsContext);p.inventoryContext=copy(p.inventoryContext)
    local inventory=p.inventoryContext;inventory.startup=copy(inventory.startup);inventory.startup.lifecycle=copy(inventory.startup.lifecycle)
    local lifecycle=inventory.startup.lifecycle;lifecycle.worker=copy(lifecycle.worker);local worker=lifecycle.worker
    worker.graph=copy(worker.graph);worker.graph.central=copy(worker.graph.central);worker.graph.domains=copy(worker.graph.domains)
    local libraries={}
    local function library(lib)
        if libraries[lib]then return libraries[lib]end
        local out=copy(lib);libraries[lib]=out;out.banking=lib.banking and copy(lib.banking)or{}
        for _,name in ipairs({'EnsureJobAccount','JobAccountExists','RecordJobTransaction',
            'GetJobAccountBalance','AddJobAccountBalance','RemoveJobAccountBalance'})do out.banking[name]=banking[name]end
        return out
    end
    for _,group in ipairs({'central','domains'})do for key,value in pairs(worker.graph[group])do
        local out=copy(value);if value.library then out.library=library(value.library)end;worker.graph[group][key]=out
    end end
    worker.bootstrap=copy(worker.bootstrap);worker.bootstrap.library=library(worker.bootstrap.library)
    lifecycle.callbacks=copy(lifecycle.callbacks);lifecycle.callbacks.securityLibrary=library(lifecycle.callbacks.securityLibrary)
    lifecycle.events=copy(lifecycle.events);local listen=lifecycle.events.listen
    lifecycle.events.listen=function(name,fn)return listen(name,function(resource,...)
        if name=='onResourceStop'and resource=='forge-core'then phase='closed';banking.Close()end
        return fn(resource,...)
    end)end
    local report=worker.onError;worker.onError=function(...)phase='failed';banking.Close();return report(...)end
    context=createOperations(base,p);graph=context.Graph;api.OperationsContext,api.Graph=context,graph;phase='prepared'
    local function run(method,target)
        local result=table.pack(pcall(method))
        if result[1]and result[2]and current()then phase=target;return table.unpack(result,2,result.n)end
        if phase~='closed'then phase='failed'end;banking.Close();context.Stop()
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Install()
        if phase~='prepared'or not current()then return false,'banking_context_not_prepared'end
        local ok,why=banking.Open();if not ok then return false,why end
        return run(context.Install,'installed')
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'banking_context_not_installed'end
        phase='starting';return run(context.Start,'running')
    end
    function api.Stop()phase='closed';banking.Close();return context.Stop()end
    function api.Poll()if phase=='closed'or phase=='failed'then banking.Close()end;return context.Poll()end
    function api.Progress()
        local inner=context.Progress();local scope=banking.Progress()
        return{phase=phase,operationsContext=inner,banking=scope,complete=inner.complete==true and scope.complete}
    end
    return api
end
