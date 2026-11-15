-- Installed OX limit/clear bodies and PR adapters; only inventory storage/platform/IO are virtual.
local P=dofile('tests/kernel_inventory_provider_harness.lua');local A=dofile('tests/kernel_automedic_harness.lua')
local H=P.H;local O={P=P,H=H}
function O.limits()
    local stream=assert(io.open('../../../[ox]/ox_inventory/modules/inventory/server.lua','rb'))
    local source=stream:read('*a');stream:close()
    local first=assert(source:find('local function normalizeInventoryLimit',1,true))
    local last=assert(source:find('function Inventory.AddItem',first,true))
    local r={rows={},events={},exported={},defaults={playerslots=4,playerweight=1000}}
    local inventory=setmetatable({},{__call=function(_,id)return type(id)=='table'and id or r.rows[id]end})
    local env=H.environment({Inventory=inventory,shared=r.defaults,server={syncInventory=function(inv)r.events[#r.events+1]={'sync',inv.id}end},
        TriggerClientEvent=function(...)r.events[#r.events+1]=H.copy(table.pack(...))end,
        exports=function(name,fn)r.exported[name]=fn end})
    assert(load(source:sub(first,last-1),'@installed_ox_inventory_limits','t',env))();r.api=inventory
    function r.seed(id,items,kind)
        local inv={id=id,type=kind or'player',player=kind~='stash',slots=4,maxWeight=1000,items=items or{},openedBy={}}
        function inv:syncSlotsWithClients(...)r.events[#r.events+1]={'slots',H.copy(table.pack(...))}end
        r.rows[id]=inv;return inv
    end
    return r
end
function O.enrich(r)
    r.calls,r.results,r.files={},{},{};r.capacity=O.limits();r.clear=A.oxClear()
    r.capacity.seed(1);r.clear.seed(1)
    local defaults={}
    for _,name in ipairs({'AddItem','RemoveItem','Search','SetDurability','CanCarryItem','SetItem','GetSlot','GetSlotWithItem',
        'GetSlotsWithItem','GetInventory','SetMetadata','CanCarryAmount','SetMaxWeight','SetSlotCount','RegisterStash','RegisterShop'})do defaults[name]=true end
    for name in pairs(defaults)do local method=name
        r.proxy[name]=function(self,...)
            assert(self==r.proxy,'raw receiver preserved');local args=table.pack(...);r.calls[#r.calls+1]={name=method,args=args}
            if r.onCall then r.onCall(method,args)end
            if r.results[method]=='throw'then error('virtual '..method..' error')end
            local values=r.results[method];if values then return table.unpack(values,1,values.n)end
            if method=='GetInventory'then return{items={}}end
            if method=='GetSlot'or method=='GetSlotWithItem'then return{name='burger',count=2,slot=3,metadata={}}end
            if method=='GetSlotsWithItem'then return{{name='burger',count=2,slot=3,metadata={}}}end
            if method=='Search'then return args[2]=='slots'and{}or 0 end
            return true,nil,'raw-result',nil
        end
    end
    r.proxy.ApplyPlayerInventoryBonus=function(self,...)
        assert(self==r.proxy);r.calls[#r.calls+1]={name='ApplyPlayerInventoryBonus',args=table.pack(...)}
        return r.capacity.exported.ApplyPlayerInventoryBonus(...)
    end
    r.proxy.ClearInventory=function(self,...)
        assert(self==r.proxy);r.calls[#r.calls+1]={name='ClearInventory',args=table.pack(...)}
        if r.clearFalse then return false,'virtual clear refusal'end
        return r.clear.clear(...)
    end
    r.createOperations=H.load('../pr_bridge/bridge/inventories/ox/forge_operations.lua',H.environment())
    r.operationPorts={inventory=r.library,custom=r.proxy,isCurrent=function()return r.current end,
        resourceState=function(name)assert(name=='ox_inventory');return r.operationState or(r.ready and'started'or'stopped')end,
        executingResource=function()return r.executing end,
        readResourceFile=function(resource,file)assert(resource=='ox_inventory');r.calls[#r.calls+1]={name='file',args={file}};return r.files[file]end}
    function r.mountOperations()r.ops=r.createOperations(r.operationPorts);return r.ops end
    return r
end
function O.new()return O.enrich(P.new())end
function O.context()
    local r=P.context();O.enrich(r.inventory)
    r.operationContextPorts={inventoryContext=r.invPorts,operations=r.inventory.operationPorts,createOperations=r.inventory.createOperations}
    local env=P.T.T.W.D.R.env();env.print=function(...)r.fixture.central.record('print',...)end
    r.operationFactory=H.load('kernel/server/inventory_operations_context.lua',env)
    function r.prepareOperations()r.api=r.operationFactory(r.fixture.base,r.operationContextPorts);r.graph=r.api.Graph;r.inventory.ops=r.api.Operations;return r.api end
    function r.operationsInstall()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return O
