local I=dofile('tests/kernel_inventory_harness.lua')
local S=dofile('tests/kernel_job_service_harness.lua')
local F=dofile('tests/kernel_finance_harness.lua')
local T=dofile('tests/kernel_transport_harness.lua')
local L=dofile('tests/kernel_lifecycle_harness.lua')
local H,P,J=I.H,I.P,I.J
local p=P.new(true);p.core.Player_Buckets,p.core.Entity_Buckets,p.core.UsableItems={},{},{}
local groups=H.load('kernel/server/groups.lua',H.environment())({jobs=p.groupData.jobs,gangs=p.groupData.gangs,
    emitServer=p.platform.emitServer,emitClient=p.platform.emitClient,saveGroups=function()error('No legacy writes')end,logError=function()end})
local l=L.new(true);l.bindings.core,l.bindings.lookup,l.bindings.players,l.bindings.groups=p.core,p.lookup,p.api,groups
l.bindings.native.isAceAllowed=function(src)return tonumber(src)==2 end
local functions=H.load('kernel/server/functions.lua',H.environment())(l.bindings)
local base={Groups=groups,PlayerCore={Groups=groups,State=p.core,Lookup=p.lookup,Players=p.api,Lifecycle={Functions=functions}}}
local m=J.persistence();local library={};for k,v in pairs(m.api)do library[k]=v end
local ox=I.oxItems();local acquired={burger=2};local counts={add=0,carry=0,mutation=0}
local oxProxy={}
for name,fn in pairs(ox.exports)do oxProxy[name]=function(_,...)return fn(...)end end
oxProxy.CanCarryItem=function()counts.carry=counts.carry+1;return true end
oxProxy.AddItem=function(_,target,name,count)assert(target==1);counts.add=counts.add+1;acquired[name]=(acquired[name]or 0)+count;return true end
local removalCount=0
oxProxy.RemoveItem=function(_,target,name,count,metadata,slot)
    assert(target==1 and metadata==nil and slot==3);removalCount=removalCount+1
    if (acquired[name]or 0)<count then return false end
    acquired[name]=acquired[name]-count;return true
end
local hookExports,hookTimers={},{}
local hooks=H.load('../../../[ox]/ox_inventory/modules/hooks/server.lua',H.environment({
    pr_lib={},os={microtime=function()return 1 end},shared={info=function()end},server={loghookrejection=false},
    warn=function()end,exports=function(name,fn)hookExports[name]=fn end,GetInvokingResource=function()return'pr_bridge'end,
    AddEventHandler=function()end,TriggerEvent=function()end,SetTimeout=function(ms,fn)assert(ms==50);hookTimers[#hookTimers+1]=fn end}))
oxProxy.registerHook=function(_,name,cb,opts)
    -- Simulate Cfx callable references only; actual hook filtering/dispatch executes unchanged.
    local ref=setmetatable({},{__call=function(_,payload)return cb(payload)end})
    return hookExports.registerHook(name,ref,opts)
end
-- Exact installed PR inventory adapter for public Items/CanCarry/Add contracts, providers are simulated.
library.inventory=H.load('../pr_bridge/bridge/inventories/ox/server.lua',H.environment({
    ActiveBridges={inventory='ox'},exports={ox_inventory=oxProxy},Debug=function()end,Lang={t=function(_,key)return key end}}))
local queued,timers,aceCommands={},{},{}
local caller='pr_bridge'
local native={isAceAllowed=function(src)return tonumber(src)==2 end,isPlayerAceAllowed=function(src)return tonumber(src)==2 end,
    getInvokingResource=function()return caller end,isPrincipalAceAllowed=function()return false end,
    getPlayerName=function(src)return p.lookup.GetPlayer(src)and'Player'end,getPlayers=function()return {'1'}end,
    emitClient=p.platform.emitClient,emit=function()end,getSource=function()return 1 end,getGameTimer=function()return 1000 end,getPlayerPing=function()return 50 end,
    print=function()end,setTimeout=function(ms,fn)timers[#timers+1]={ms=ms,fn=fn}end,
    spawn=function(fn)queued[#queued+1]=fn end,wait=function()error('No workers run')end,getIdentifier=function()return'license:test'end,
    execute=function(cmd)aceCommands[#aceCommands+1]=cmd end}
library.notify={NotifyPlayer=function()end};library.database={query=function()return {}end,transaction=function()return true end}
library.banking={EnsureJobAccount=function()return true end};library.command=function()error('No command installation')end
local handlers={};library.callback={register=function(name,fn)handlers[name]=fn end}
local helpers=T.helpers();library.load=function(path)assert(path=='@pr_bridge/bridge/frameworks/compat_helpers');return helpers end
local jobConfig=J.config(true).config
local catalog=J.composition(base,{config=jobConfig,library=library,translate=function(key)return key end})
S.compose(base,{library=library,translate=function(key)return key end,dependencies={},native=native,time=function()return 1000 end})
local integrations={inventoryReady=function()return true end,applyPlayerInventoryBonus=function()return true end}
local finance=F.compose(base,{library=library,translate=function(key)return key end,native=native,integrations=integrations,time=function()return 1000 end,resource='forge-core'})
-- Mutators are explicit stand-ins for the missing future PR custom-definition API, not direct production exports.
for method,name in pairs({setItemDefinition='SetItemDefinition',disableItemDefinition='DisableItemDefinition',removeItemDefinition='RemoveItemDefinition'})do
    integrations[method]=function(...)counts.mutation=counts.mutation+1;return ox.exports[name](...)end
end
local C=dofile('tests/kernel_consumables_harness.lua')
local U=dofile('tests/kernel_session_harness.lua')
local cr=C.new('client',true)
local sr=U.new(true,'client')
local function moduleEnvironment()
    local env=H.environment()
    env.require=function(name)
        assert(name:match('^kernel%.'))
        return H.load(name:gsub('%.','/')..'.lua',env)
    end
    return env
end
local client=H.load('kernel/client/session_core.lua',moduleEnvironment())(sr.core,
    {native=sr.native,delivery=sr.delivery,statusConfig=sr.clientConfig})
local clientCount=#sr.trace
local clientConsumption=H.load('kernel/client/inventory/consumption_core.lua',moduleEnvironment())(sr.core,
    {config=I.config(true),native=cr.native,library=cr.library,integrations=cr.integrations})
assert(#sr.trace==clientCount and #cr.trace==0 and sr.core.Consumption==clientConsumption)
assert(not pcall(H.load('kernel/client/inventory/consumption_core.lua',moduleEnvironment()),sr.core,{}))
local cfg=I.config(true)
m.seed(cfg.Storage.items,{burger={name='burger',label='Burger',weight=150,active=true,interaction={
    enabled=true,duration=1000,remove=1,effects={hunger={min=10,max=10},thirst={min=2,max=2}}}}})
m.seed(cfg.Storage.weaponInventory,{ammo={},components={},tints={}})
local inventory=I.compose(base,{library=library,native=native,integrations=integrations,translate=function(key)return key end,
    compile=I.compile,resource='forge-core',config=cfg})
local wireCount=0
local registeredClient=clientConsumption.Callbacks['forge-core:client:inventory:useInteraction']
library.callback.awaitClient=function(src,name,timeout,item,interaction)
    assert(src==1 and name=='forge-core:client:inventory:useInteraction'and timeout==6000)
    wireCount=wireCount+1
    local result=registeredClient(item,interaction)
    if library.afterProgress then library.afterProgress()end
    return result
end
native.emitClient=function(name,src,...)
    assert(src==1)
    if name=='forge-core:client:inventory:applyInteractionEffects'then
        for _,e in ipairs(clientConsumption.Events)do if e.name==name then e.handler(...)end end
    else
        local delivered=false
        for _,e in ipairs(client.Status.Events)do if e.name==name then e.handler(...);delivered=true end end
        assert(delivered,'unexpected client protocol '..name)
    end
end
local countBefore={files=#m.trace,ox=#ox.events,timers=#timers,player=#p.trace}
local compose=H.load('kernel/server/inventory/consumption_core.lua',moduleEnvironment())
local consumption=compose(base,{library=library,native=native,integrations={useLockpick=function()error('No specials exercised')end}})
assert(#m.trace==countBefore.files and #ox.events==countBefore.ox and #timers==countBefore.timers and #p.trace==countBefore.player)
assert(catalog.Dependencies.ConsumableService==consumption.Service and inventory.Consumption==consumption)
assert(not pcall(compose,base,{}))
native.emit=function(name,...)
    for _,e in ipairs(consumption.Service.Events)do if e.name==name then e.handler(...)end end
end
assert(inventory.Service.Initialize())
assert(consumption.Service.Initialize()and not consumption.Service.Initialize())
local queuedTimers=timers;timers={};for _,v in ipairs(queuedTimers)do assert(v.ms==0);v.fn()end
local callable=functions.CanUseItem('burger')
assert(type(callable)=='function'and p.core.UsableItems.burger==callable)
assert(#queued==0,'no payroll/VIP workers started')
p.api.CheckPlayerData(1,{citizenid='CONSUME',license='license:test',userId=101})
assert(client.Status.Exports.SetStatus('hunger',20))
assert(client.Status.Exports.SetStatus('thirst',30))
local function expireDedup()
    local list=timers;timers={};for _,v in ipairs(list)do assert(v.ms==750);v.fn()end
end
-- This seam calls actual local policy before a fixture slot callback. It is NOT the full OX useItem engine.
local function attempt()
    local allowed,reason=inventory.Service.canUseItem(1,'burger')
    if not allowed then return false,reason end
    return callable(1,{name='burger',slot=3})
end
assert(inventory.Service.setItemActive(0,'burger',false))
local allowed,reason=attempt();assert(allowed==false and reason=='disabled')
assert(wireCount==0 and acquired.burger==2 and removalCount==0 and sr.core.Status.hunger==20)
assert(inventory.Service.setItemActive(0,'burger',true))
assert(attempt()==false,'success still vetoes vanilla consumption')
assert(wireCount==1 and acquired.burger==1 and removalCount==1)
assert(sr.core.Status.hunger==30 and sr.core.PlayerData.metadata.hunger==30 and sr.core.Status.thirst==32)
-- Actual OX hook module and local fallback share the same duplicate suppression.
do local result <close> = hooks('usingItem',{source=1,item={name='burger',slot=3}})
    assert(not result.success and acquired.burger==1 and wireCount==1)
end
expireDedup()
cr.progress=false
assert(attempt()==false and acquired.burger==1 and sr.core.Status.hunger==30,'cancel changes neither slot nor status')
expireDedup();cr.progress=true;acquired.burger=0
assert(attempt()==false and sr.core.Status.hunger==30,'failed PR RemoveItem must not apply status')
expireDedup();acquired.burger=3
library.afterProgress=function()assert(inventory.Service.setItemActive(0,'burger',false))end
assert(attempt()==false and acquired.burger==2 and sr.core.Status.hunger==40,'inherited mid-await block is still ineffective')
library.afterProgress=nil
assert(not inventory.Service.canUseItem(1,'burger'))
consumption.Service.Exports.SetHunger(1,50);assert(sr.core.Status.hunger==50)
consumption.Service.Exports.AddThirst(1,5);assert(sr.core.Status.thirst==39)
assert(base.PlayerCore.State.Players[1]==p.lookup.GetPlayer(1))
assert(#ox.workers==1 and #clientConsumption.Threads==2 and #clientConsumption.Keybinds==1)
print('PASS consumption composition: actual local usable registry/InventoryService/Player/status + installed PR inventory and OX items/hooks; blocked-before-use/unblock/cancel/removal/effects and inherited mid-await block under simulated wire/slots; not full OX consumption or real MIG-23')
