local A=dofile('tests/kernel_consumer_allocation_harness.lua');local I=dofile('tests/kernel_compat_identity_harness.lua');local H=A.H;local T={A=A,I=I,H=H}
local function copy(t)local out={};for k,v in pairs(t or{})do out[k]=v end;return out end
function T.new(side,inventory)
    local r=side=='server'and A.new()or I.new('client');r.side=side;r.boundResource=inventory and'ox_inventory'or'consumer117';r.pr={};r.public={};r.providerReads=0;r.boundReady=true
    if side=='client'then r.normalFixture=A.N.new(true,'client');r.adapterFixture=A.L.A.new('client')end
    local norm,base=r.normalFixture.ports,r.adapterFixture.ports.adapter
    local n=copy(norm.native);for k,v in pairs(base.native or{})do n[k]=n[k]or v end
    n.GetCurrentResourceName=function()return r.boundResource end;n.IsDuplicityVersion=function()return side=='server'end
    n.GetResourceState=r.identityPorts.getResourceState;n.GetResourceMetadata=r.identityPorts.getResourceMetadata;n.GetNumResourceMetadata=r.identityPorts.getNumResourceMetadata
    n.GetConvar=function()return'true'end;n.TriggerEvent=base.triggerLocal or function()end;n.TriggerServerEvent=base.triggerServer or function()end
    r.boundAPI={core={},inventory={}};for name in pairs(norm.core)do if side=='server'or(name~='EnablePersistence'and name~='DisablePersistence')then r.boundAPI.core[name]=r.catalog.Resolve(name)end end
    if side=='server'then r.boundAPI.framework=base.core;r.boundAPI.getCoreObject=r.lookup('GetCoreObject')
        for _,name in ipairs({'GetPlayer','GetPlayersData','CanUseItem','GetGroups','IsGradeBoss'})do r.boundAPI.inventory[name]=r.catalog.Resolve(name)end
    end
    local inv=copy(base.inventory);for k,v in pairs(norm.inventory or{})do inv[k]=v end
    r.services={inventory=inv,banking=norm.banking,notify=norm.notify,textui=norm.textui,db=base.db,decode=base.decode,
        events=r.adapterFixture.ports.events,callbacks=r.adapterFixture.ports.callbacks,cache=base.cache,inventoryBridge=inventory and r.ox.ports or nil}
    local function module(name)if r.moduleHook then local v=r.moduleHook(name);if v then return v end end;return H.load('../pr_bridge/'..name..'.lua',H.environment())end
    r.bindingPorts={native=n,load=module,prCore=r.pr,public=r.public,inventory=inventory,config={compatFramework='forge'},contracts={qb=side=='server',qbx=true},
        api=r.boundAPI,isCurrent=function()return r.api.IsCurrent()end,isReady=function()return r.boundReady end,
        readDeclarations=function()return{'forge','qbx','qb'}end,createEvents=H.load('kernel/shared/event_registration.lua',H.environment()),
        view=side=='client'and{PlayerData=r.catalog.Resolve('GetPlayerData')()}or nil,cacheNamespace='qbx_core',readSessionReady=base.readSessionReady,
        getServices=function()r.providerReads=r.providerReads+1;if r.servicesHook then r.servicesHook()end;return r.services end}
    r.bindingFactory=H.load('../pr_bridge/bridge/runtime/forge/native_bindings_factory.lua',H.environment())
    function r.makeBindings()r.bindings=r.bindingFactory(r.bindingPorts);return r.bindings end
    local finish=r.finish
    function r.finish()if r.bindings then r.bindings.Close()end;return finish()end
    return r
end
return T
