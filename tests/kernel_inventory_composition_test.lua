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
local cfg=I.config(true)
m.seed(cfg.Storage.items,{burger={name='burger',label='Burger',weight=150,active=true,stack=true,client={status={hunger=100000}},interaction={enabled=true}}})
m.seed(cfg.Storage.weaponInventory,{ammo={},components={},tints={}})
local before={trace=#p.trace,files=#m.trace,events=#ox.events,mutation=counts.mutation,workers=#queued}
local inventory=I.compose(base,{library=library,native=native,integrations=integrations,translate=function(key)return key end,
    compile=I.compile,resource='forge-core',config=cfg})
assert(#p.trace==before.trace and #m.trace==before.files and #ox.events==before.events and counts.mutation==before.mutation and #queued==before.workers)
assert(catalog.Dependencies.InventoryService==inventory.Service and base.InventoryCore==inventory and #inventory.Callbacks==13)
assert(not pcall(I.compose,base,{}),'duplicate inventory attachment refused')
-- Config must be available before transport classification; the guard also rejects late installation.
local businessSentinel={Points={},Business={}}
catalog.BusinessCore=businessSentinel;catalog.Dependencies.JobPoints,catalog.Dependencies.JobBusiness=businessSentinel.Points,businessSentinel.Business
local transport=T.compose(base,{library=library,native=native,json=m.codec,config={Inventory=cfg},translate=function(key)return key end,time=function()return 1000 end})
for _,cb in ipairs(inventory.Callbacks)do transport.Security.register(cb.name,cb.handler);assert(transport.Security.registrations[cb.name].access=='admin')end
assert(inventory.Service.Initialize()and not inventory.Service.Initialize())
local actual=library.inventory.Items('burger');assert(actual.name=='burger'and actual.qbxStatus.hunger==100000 and actual.client==nil and actual.consume==1)
assert(ox.events[#ox.events].name=='ox_inventory:forge:setItem')
p.api.CheckPlayerData(1,{citizenid='INV',license='license:test',userId=101})
assert(p.api.SetJob(1,'taxi',1));local online=p.lookup.GetPlayer(1)
local ok,err=handlers[cfg.Callbacks.setItemActive](1,'burger',false);assert(not ok and err=='no_permission')
assert(handlers[cfg.Callbacks.setItemActive](2,'burger',false))
ok,err=inventory.Service.Exports.CanUseInventoryItem(1,'burger');assert(not ok and err=='disabled'and library.inventory.Items('burger').disabled)
assert(acquired.burger==2 and counts.add==0,'policy/definition test does not execute a consumer or remove acquired slots')
assert(handlers[cfg.Callbacks.setItemActive](2,'burger',true));assert(inventory.Service.canUseItem(1,'burger')and not library.inventory.Items('burger').disabled)
assert(m.codec.decode(m.files[cfg.Storage.items]).burger.active==true)
-- Local PD/VIP policy with the actual metadata-backed VIP service from lot 16.
inventory.Service.getItem('burger').access={jobs={{name='taxi',grade=1}},vips={'gold'}}
assert(not inventory.Service.canUseItem(1,'burger'))
finance.Vip.Initialize();assert(finance.Vip.grant(0,1,'gold',1));assert(inventory.Service.canUseItem(1,'burger'))
assert(online.PlayerData.metadata.vip~=nil and #aceCommands==1 and #queued==1,'VIP ACE/worker are simulated, not executed')
assert(p.api.SetJob(1,'mechanic',0));assert(not inventory.Service.canUseItem(1,'burger'))
assert(transport.Compat.CompatAddItems({{name='water',label='Water',weight=50}}));assert(inventory.Service.getItem('water')and library.inventory.Items('water').weight==50)
assert(transport.Compat.CompatRefreshItems()==2,'real inventory service holder replaces lot-18 double')
local old=m.files[cfg.Storage.items]
m.onWrite=function(path,bytes)if path==cfg.Storage.items and bytes~=old then return false end;return true end
local mutations=counts.mutation
ok=handlers[cfg.Callbacks.saveItem](2,{name='failed',label='Failed'});assert(ok==false and not inventory.Service.getItem('failed')and not library.inventory.Items('failed')and counts.mutation==mutations)
m.onWrite=nil
assert(inventory.Service.upsertAmmo(2,{name='ammo',active=true}));assert(library.inventory.Items('ammo').ammo==true)
assert(inventory.Service.setAmmoActive(2,'ammo',false));assert(library.inventory.Items('ammo')==nil)
assert(inventory.Service.upsertComponent(2,{name='comp'}));assert(library.inventory.Items('comp').component and not library.inventory.Items('comp').stack)
-- Failed publication is retained after successful persistence; retry through explicit reload repairs the external view.
local set=integrations.setItemDefinition;integrations.setItemDefinition=function()return false end
assert(inventory.Service.upsertItem(2,{name='desync',label='Desync',weight=5}));assert(inventory.Service.getItem('desync')and not library.inventory.Items('desync'))
integrations.setItemDefinition=set;assert(inventory.Service.reload());assert(library.inventory.Items('desync'))
caller='untrusted';assert(not pcall(transport.Compat.CompatAddItems,{{name='bad'}}));assert(not inventory.Service.getItem('bad'))
assert(base.PlayerCore.State.Players[1]==online and #ox.workers==1,'actual OX startup/metadata/inventory engine not run')
print('PASS inventory composition: canonical local Player/VIP/holder/facade and protected callbacks, installed PR inventory adapter + full custom OX item module with simulated providers/persistence; block/unblock policy and definitions only, not consumption/race or real startup')
