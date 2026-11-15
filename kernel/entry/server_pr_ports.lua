local bindIngress=require 'kernel.entry.bootstrap_ingress_ports'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(input,services,rpc,registration,barrier)
    assert(rpc.Side=='server'and services.Inventory and services.Operations and services.Banking and services.Keys,'prepared server PR services required')
    local n,callbacks=bindIngress(barrier,registration,rpc.Owners)
    local root=copy(input);local out=root
    local branches={};for _,key in ipairs({'deliveryContext','mediaContext','supportContext','configurationContext','vehicleContext','bankingContext','operationsContext','inventoryContext','startup','lifecycle'})do
        out[key]=copy(out[key]);out=out[key];branches[key]=out
    end
    local function adopt(scope)
        local view=copy(scope)
        view.Open=function()if scope.Progress().phase=='open'then return true end;return scope.Open()end
        return view
    end
    local inventory,operations,banking,keys=adopt(services.Inventory),adopt(services.Operations),adopt(services.Banking),adopt(services.Keys)
    branches.inventoryContext.createInventoryProvider=function()return inventory end
    branches.operationsContext.createOperations=function()return operations end
    branches.bankingContext.createBanking=function()return banking end
    branches.vehicleContext.createVehicles=function()return keys end
    local life=branches.lifecycle;local prior=assert(life.callbacks.securityLibrary)
    local library=copy(prior);library.callback=copy(prior.callback);library.callback.register=rpc.Owners.native.CaptureRegister
    life.callbacks={native=callbacks.native,ox=callbacks.ox,securityLibrary=library}
    life.worker=copy(life.worker);life.worker.graph=copy(life.worker.graph)
    for _,group in ipairs({'central','domains'})do local source=life.worker.graph[group];local replacement=copy(source)
        for key,part in pairs(source)do
            if part==prior then replacement[key]=library
            elseif type(part)=='table'and part.library==prior then replacement[key]=copy(part);replacement[key].library=library end
        end
        life.worker.graph[group]=replacement
    end
    for _,key in ipairs({'helpers'})do local part=life.worker.graph[key]
        if type(part)=='table'and part.library==prior then life.worker.graph[key]=copy(part);life.worker.graph[key].library=library end
    end
    life.worker.bootstrap=copy(life.worker.bootstrap)
    if life.worker.bootstrap.library==prior then life.worker.bootstrap.library=library end
    for _,scope in ipairs({life,branches.supportContext})do scope.public=copy(scope.public);scope.public.rpc=callbacks.ox end
    return root,n,{Inventory=inventory,Operations=operations,Banking=banking,Keys=keys,SecurityLibrary=library,Callbacks=callbacks}
end
