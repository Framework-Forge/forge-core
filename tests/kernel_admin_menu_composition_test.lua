local I=dofile('tests/kernel_inventory_harness.lua')
local S=dofile('tests/kernel_job_service_harness.lua')
local F=dofile('tests/kernel_finance_harness.lua')
local T=dofile('tests/kernel_transport_harness.lua')
local L=dofile('tests/kernel_lifecycle_harness.lua')
local H,P,J=I.H,I.P,I.J
local R=dofile('tests/kernel_server_runtime_harness.lua')
local W=dofile('tests/kernel_weapon_harness.lua')
local runtimeFixture=R.new(true,'commands')
local p=P.new(true);p.core.Shared=runtimeFixture.core.Shared;p.core.Player_Buckets,p.core.Entity_Buckets,p.core.UsableItems={},{},{}
local groups=H.load('kernel/server/groups.lua',H.environment())({jobs=p.groupData.jobs,gangs=p.groupData.gangs,
    emitServer=p.platform.emitServer,emitClient=p.platform.emitClient,saveGroups=function()error('No legacy writes')end,logError=function()end})
local l=L.new(true);l.bindings.core,l.bindings.lookup,l.bindings.players,l.bindings.groups=p.core,p.lookup,p.api,groups
l.bindings.native.isAceAllowed=function(src)return tonumber(src)==2 end
local functions=H.load('kernel/server/functions.lua',H.environment())(l.bindings)
local base={Groups=groups,PlayerCore={Groups=groups,State=p.core,Lookup=p.lookup,Players=p.api,Lifecycle={Functions=functions}}}
local function moduleEnvironment()
    local env=H.environment()
    env.require=function(name)assert(name:match('^kernel%.'));return H.load(name:gsub('%.','/')..'.lua',env)end
    return env
end
local rb={};for key,value in pairs(runtimeFixture.bindings)do rb[key]=value end
p.config.server=l.serverConfig;p.config.giveVehicleKeys=runtimeFixture.config.giveVehicleKeys
rb.config,rb.globalState,rb.logger=p.config,p.counters,p.bindings.logger
local runtime=H.load('kernel/server/runtime_core.lua',moduleEnvironment())(base,base.PlayerCore,rb)
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
m.seed(cfg.Storage.items,{})
m.seed(cfg.Storage.weaponInventory,{ammo={},components={},tints={}})
local inventory=I.compose(base,{library=library,native=native,integrations=integrations,translate=function(key)return key end,
    compile=I.compile,resource='forge-core',config=cfg})
local client=W.oxClient()
local function publishClient()
    local pending=ox.events;ox.events={}
    for _,event in ipairs(pending)do
        if event.name=='ox_inventory:forge:setWeaponItem'or event.name=='ox_inventory:forge:removeWeaponItem'then
            -- Captured wire payload is already a copy; drop target=-1 for the client handler.
            local args=event.args;assert(args[1]==-1);client.emit(event.name,table.unpack(args,2,args.n))
        end
    end
end
-- Explicit provider stand-ins for PR contracts absent in the installed public inventory API.
local weaponCalls=0
integrations.inventoryState=function()return'started'end
for _,method in ipairs({'SetWeaponItem','DisableWeaponItem','RemoveWeaponItem','HasWeaponItem'})do
    integrations[method]=function(...)weaponCalls=weaponCalls+1;return ox.exports[method](...)end
end
local wc=W.config(true)
m.seed(wc.Storage.file,{weapon_pistol={name='weapon_pistol',label='Pistol',active=true,ammotype='AMMO_PISTOL',access={mode='job',name='taxi',grade=1}}})
local before={files=#m.trace,trace=#p.trace,runtime=#runtimeFixture.trace,ox=#ox.events,providers=weaponCalls,timers=#timers}
local admin=W.compose(base,{config=wc,library=library,native=native,integrations=integrations,translate=function(key)return key end,resource='forge-core'})
assert(#m.trace==before.files and #p.trace==before.trace and #runtimeFixture.trace==before.runtime and #ox.events==before.ox and weaponCalls==before.providers and #timers==before.timers)
assert(admin.State==p.core and catalog.Dependencies.WeaponRegistry==admin.Registry and base.WeaponCore==admin)
assert(not pcall(W.compose,base,{}),'duplicate administrative attachment refused')
local foreign={PlayerCore={Groups=groups,State=p.core,Runtime={State={}}},Groups=groups,JobCatalog=catalog,InventoryCore=inventory}
assert(not pcall(W.compose,foreign,{}),'foreign runtime refused')
-- Complete canonical dependencies are required, but Business/Points are not exercised by these weapon routes.
local businessSentinel={Points={},Business={}}
catalog.BusinessCore=businessSentinel;catalog.Dependencies.JobPoints,catalog.Dependencies.JobBusiness=businessSentinel.Points,businessSentinel.Business
local transport=T.compose(base,{library=library,native=native,json=m.codec,config={Inventory=cfg,Weapons=wc},translate=function(key)return key end,time=function()return 1000 end})
for _,cb in ipairs(admin.Callbacks)do
    transport.Security.register(cb.name,cb.handler)
    assert(transport.Security.registrations[cb.name].access=='admin')
end
local late={PlayerCore=base.PlayerCore,Groups=groups,InventoryCore=inventory,JobCatalog={
    Groups=groups,Service=catalog.Service,Dependencies={InventoryService=inventory.Service},Transport={}}}
assert(not pcall(W.compose,late,{}),'configuration may not be attached after transport classification')
local M=dofile('tests/kernel_admin_menu_harness.lua')
local U=dofile('tests/kernel_session_harness.lua')
local V=dofile('tests/kernel_legacy_harness.lua')
for _,cb in ipairs(inventory.Callbacks)do
    transport.Security.register(cb.name,cb.handler)
    assert(transport.Security.registrations[cb.name].access=='admin')
end
-- Execute the installed VIP callback file only against the simulated transport/actual private VIP service.
H.load('server/vip/callbacks.lua',H.environment({PR={Vip=finance.VipConfig},
    ForgeCore={Callbacks=transport.Security,VipService=finance.Vip},os={date=function()return'fixture'end}}))
assert(inventory.Service.Initialize());assert(admin.Service.Initialize());assert(admin.Service.start());finance.Vip.Initialize()
p.api.CheckPlayerData(1,{citizenid='DENIED',license='license:test',userId=101})
p.api.CheckPlayerData(2,{citizenid='ADMIN',license='license:test2',userId=102})
local ui=M.new(true)
ui.config={Inventory=cfg,Weapons=wc,Vip=finance.VipConfig}
ui.json=m.codec;ui.codec=m.codec
ui.library.table=H.load('../pr_bridge/bridge/utils/tables.lua',H.environment())
local sr=U.new(true,'client')
local producer=H.load('kernel/client/session_core.lua',moduleEnvironment())(sr.core,
    {native=sr.native,delivery=sr.delivery,statusConfig=sr.clientConfig})
local lf=V.new(true,'client')
local queries=V.client(true)
local lb={};for key,value in pairs(lf.bindings)do lb[key]=value end
lb.membership=queries.membership;lb.notify=queries.bindings.notify
lb.jobs=groups.GetJobs();lb.gangs=groups.GetGangs()
local pulls=0
lb.awaitGroups=function(name)pulls=pulls+1;assert(name=='qbx_core:server:getGroups');return{jobs=groups.GetJobs(),gangs=groups.GetGangs()}end
local legacy=H.load('kernel/client/legacy_core.lua',moduleEnvironment())(sr.core,lb)
assert(pulls==0)
-- Group bootstrap is explicit. No constructor pulls from a stopped/active legacy QBX process.
assert(legacy.Groups.Initialize()and pulls==1)
local context=M.context()
ui.registerHook=context.api.RegisterContext;ui.showHook=context.api.ShowContext
local menu={}
menu.openServerSettingsMenu=function()
    ui.library.menus.RegisterContext({id='forge_core_server_settings',title='Parent',options={{title='Inventory',onSelect=function()menu.openInventoryMenu()end}}})
    ui.library.menus.ShowContext('forge_core_server_settings')
end
local packets=0
ui.library.callback.await=function(name,timeout,...)
    assert(timeout==10000);packets=packets+1
    return assert(handlers[name],'unmapped request '..name)(ui.source,...)
end
oxProxy.AddItem=function(_,target,name,count)
    assert(target==2);counts.add=counts.add+1;acquired[name]=(acquired[name]or 0)+count;return true
end
local before={ui=#ui.trace,files=#m.trace,events=#ox.events,pulls=pulls,packets=packets}
local composeMenus=H.load('kernel/client/menu/administration_core.lua',moduleEnvironment())
local clientMenus=composeMenus(sr.core,{menu=menu,library=ui.library,translate=ui.translate,native=ui.native,
    config=ui.config,json=ui.json,notifyPosition='top-right'})
assert(clientMenus.State==sr.core and clientMenus.Groups==legacy.Groups and clientMenus.Menu==menu and sr.core.AdministrationMenus==clientMenus)
assert(#ui.trace==before.ui and #m.trace==before.files and #ox.events==before.events and pulls==before.pulls and packets==0)
assert(not pcall(composeMenus,sr.core,{}),'duplicate client menu attachment refused')
assert(not pcall(composeMenus,{LegacyCore=legacy,ProducerCore=producer},{}),'foreign client state refused')
local conflicting={PlayerData={}}
conflicting.LegacyCore={State=conflicting,Groups=legacy.Groups};conflicting.ProducerCore={State=conflicting}
assert(not pcall(composeMenus,conflicting,{menu={openServerSettingsMenu=function()end,openInventoryMenu=function()end}}),'existing controller methods not overwritten')
-- Actual PR context selection/back/disabled/serialization with a simulated renderer.
menu.openServerSettingsMenu();context.api.HandleSelect('forge_core_server_settings',1)
assert(context.api.GetOpenContextMenu()=='forge_core_inventory')
context.api.HandleSelect('forge_core_inventory',2)
assert(context.api.GetOpenContextMenu()=='forge_core_weapons')
context.api.HandleBack();assert(context.api.GetOpenContextMenu()=='forge_core_inventory')
context.api.HandleBack();assert(context.api.GetOpenContextMenu()=='forge_core_server_settings')
menu.openInventoryEntries('item')
-- Create a real item via the UI form, actual protected callback and private InventoryService/save/sync.
ui.inputs={{'burger','Burger','100','true','',0,'',0,'true','true','Food','','','','',{}}}
context.api.HandleSelect('forge_core_inventory_item',1);ui.runTimers(400)
assert(inventory.Service.getItem('burger')and m.codec.decode(m.files[cfg.Storage.items]).burger.name=='burger')
assert(library.inventory.Items('burger').name=='burger')
context.api.HandleSelect('forge_core_inventory_item',3)
assert(context.api.GetOpenContextMenu()=='forge_core_inventory_item_burger')
ui.runTimers(650);ui.inputs={{2}};context.api.HandleSelect('forge_core_inventory_item_burger',3);ui.runTimers(400)
assert(counts.add==1 and acquired.burger==4)
-- Interaction editor -> same item service. JSON/Lua source is transported, not executed in the client.
ui.runTimers(650);menu.openInventoryEntryDetails('item',inventory.Service.getItem('burger'))
ui.inputs={{'true','interact','food','Eat',0,'true',0,'full',ui.codec.encode({dict='dict',clip='clip',props={{model='prop'}}}),
    0,0,0,0,5,5,2,2,0,0,0,0,0,'',12000,1.15}}
context.api.HandleSelect('forge_core_inventory_item_burger',5);ui.runTimers(400)
local item=inventory.Service.getItem('burger');assert(item.interaction.enabled and item.interaction.duration==0 and item.interaction.remove==0)
assert(item.interaction.animation.anim=='clip'and item.interaction.effects.hunger.min==5)
-- Block and verify disabled controls cannot bypass the actual context dispatcher.
ui.runTimers(650);menu.openInventoryEntryDetails('item',item)
context.api.HandleSelect('forge_core_inventory_item_burger',2);ui.runTimers(400)
assert(not inventory.Service.canUseItem(2,'burger')and library.inventory.Items('burger').disabled)
context.api.HandleSelect('forge_core_inventory_item',3)
local beforePackets=packets
context.api.HandleSelect('forge_core_inventory_item_burger',3)
assert(packets==beforePackets and counts.add==1,'disabled give button makes no request')
-- Local client group update is visible without another framework request.
for _,event in ipairs(legacy.Groups.Events)do if event.name=='qbx_core:client:onJobUpdate'then event.handler('local_job',{label='Local Job'})end end
ui.inputs={};menu.openInventoryEntryEditor('ammo')
local form
for i=#ui.trace,1,-1 do if ui.trace[i].kind=='input'then form=ui.trace[i].args[2];break end end
local found=false;for _,option in ipairs(form[5].options)do if option.value=='local_job'then found=true end end
assert(found and pulls==1)
-- Weapon editor -> real Registry/save/internal catalog/custom OX publication.
ui.runTimers(1000);menu.openWeaponsMenu()
ui.inputs={{'new','New Weapon','Throwable','none','Damage','','200','0.1','free','',0}}
context.api.HandleSelect('forge_core_weapons',1);ui.runTimers(500)
assert(admin.Registry.getWeapons().weapon_new.throwable and runtime.Weapons.HasWeapon('weapon_new'))
assert(library.inventory.Items('weapon_new').weapon)
local created=admin.Registry.getWeapons().weapon_new
menu.openWeaponDetails(created);ui.runTimers(1000)
context.api.HandleSelect('forge_core_weapon_weapon_new',4);ui.runTimers(500)
assert(not runtime.Weapons.HasWeapon('weapon_new')and library.inventory.Items('weapon_new').disabled)
-- Rebuilt item form omits interaction; actual service replaces the record, so this inherited loss reaches persistence.
ui.runTimers(650)
ui.inputs={{'ignored','Burger edited','100','true','',0,'',0,'true','true','Food','','','','',{}}}
menu.openInventoryEntryEditor('item',inventory.Service.getItem('burger'));ui.runTimers(400)
assert(inventory.Service.getItem('burger').interaction==nil and m.codec.decode(m.files[cfg.Storage.items]).burger.interaction==nil)
ui.source=1;menu.openInventoryMenu()
assert(context.api.GetOpenContextMenu()=='forge_core_server_settings','non-admin request returns to explicit parent after refusal')
assert(sr.core.PlayerData==clientMenus.State.PlayerData and base.PlayerCore.State.Players[2]==p.lookup.GetPlayer(2))
assert(#queued==0 and #ox.workers==1,'no live workers/native inventory engine executed')
print('PASS administrative menu composition: canonical producer/groups/controller + actual protected Inventory/Weapons/VIP handlers/services and PR context/persistence/OX definitions; forms/navigation/back/disabled/grants/block/status in simulated wire/JSON/items, not real NUI/consumption/startup')
