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
assert(inventory.Service.Initialize())
assert(admin.Service.Initialize()and not admin.Service.Initialize())
assert(admin.Service.start())
publishClient()
local exists,weapon,managed,hash=runtime.Weapons.HasWeapon('weapon_pistol')
assert(exists and managed and weapon.label=='Pistol'and p.core.Shared.Weapons[hash]==runtime.Main.GetWeapons(hash))
local item=library.inventory.Items('weapon_pistol')
assert(item.weapon and item.ammoname=='ammo-9'and not item.disabled and client.items.WEAPON_PISTOL.weapon)
p.api.CheckPlayerData(1,{citizenid='WEAPONS',license='license:test',userId=101})
assert(p.api.SetJob(1,'mechanic',0));assert(not inventory.Service.canUseItem(1,'weapon_pistol'))
assert(p.api.SetJob(1,'taxi',1));assert(inventory.Service.canUseItem(1,'WEAPON_PISTOL'))
local ok,reason=handlers[wc.Callbacks.setActive](1,'pistol',false);assert(not ok and reason=='no_permission')
client.equip({name='WEAPON_PISTOL',slot=3})
assert(handlers[wc.Callbacks.setActive](2,'pistol',false))
publishClient()
ok,reason=inventory.Service.Exports.CanUseInventoryItem(1,'weapon_pistol')
assert(not ok and reason=='disabled'and not runtime.Weapons.HasWeapon('weapon_pistol'))
item=library.inventory.Items('weapon_pistol')
assert(item.disabled and not item.weapon and not client.items.WEAPON_PISTOL.weapon and client.currentWeapon()==nil and client.disarms==1)
assert(m.codec.decode(m.files[wc.Storage.file]).weapon_pistol.active==false)
assert(handlers[wc.Callbacks.setActive](2,'pistol',true));publishClient()
assert(inventory.Service.canUseItem(1,'weapon_pistol')and runtime.Weapons.HasWeapon('weapon_pistol')and client.items.WEAPON_PISTOL.weapon)
-- Admin-mode restriction shares the real WeaponService->JobService/ACE authority with InventoryService.
assert(handlers[wc.Callbacks.save](2,{name='pistol',label='Admin',access={mode='admin'},ammotype='none'}))
assert(not inventory.Service.canUseItem(1,'weapon_pistol')and inventory.Service.canUseItem(2,'weapon_pistol'))
assert(library.inventory.Items('weapon_pistol').access==nil,'installed projection omits access; policy remains Forge-owned')
local allowed,payload=handlers[wc.Callbacks.getAll](2);assert(allowed and #payload.weapons==1)
local old=m.files[wc.Storage.file]
m.onWrite=function(path,bytes)if path==wc.Storage.file and bytes~=old then return false end;return true end
local calls=weaponCalls
assert(not handlers[wc.Callbacks.save](2,{name='failed'}));assert(admin.Registry.getWeapons().weapon_failed==nil and weaponCalls==calls)
m.onWrite=nil
assert(handlers[wc.Callbacks.setActive](2,'pistol',false));publishClient()
assert(not runtime.Weapons.HasWeapon('weapon_pistol')and not inventory.Service.canUseItem(1,'weapon_pistol'))
-- Persistence reload rebuilds the disabled definition; no actual resource restart is performed.
assert(admin.Service.reload());publishClient()
assert(not library.inventory.Items('weapon_pistol').weapon and admin.Registry.getWeapons().weapon_pistol.active==false)
client.equip({name='WEAPON_PISTOL',slot=3})
assert(handlers[wc.Callbacks.delete](2,'pistol'));publishClient()
assert(library.inventory.Items('weapon_pistol')==nil and client.items.WEAPON_PISTOL==nil and client.currentWeapon()==nil)
assert(inventory.Service.canUseItem(1,'weapon_pistol'),'deleted/unknown policy is allow, not a block; inherited')
-- Failed external publication leaves persisted/local catalog committed; explicit retry repairs it.
local set=integrations.SetWeaponItem;integrations.SetWeaponItem=function()return false end
assert(handlers[wc.Callbacks.save](2,{name='desync',label='Desync'}))
assert(admin.Registry.getWeapons().weapon_desync and runtime.Weapons.HasWeapon('weapon_desync')and not library.inventory.Items('weapon_desync'))
integrations.SetWeaponItem=set;assert(admin.OxSync.syncAll());assert(library.inventory.Items('weapon_desync').weapon)
-- Runtime readiness is identity-based; it does not depend on the old QBX process.
local previous=base.PlayerCore.Runtime;base.PlayerCore.Runtime={}
local count=#runtimeFixture.trace
assert(admin.Projection.syncAll()and #runtimeFixture.trace==count,'inherited ignored publication still tracks when identity is no longer ready')
base.PlayerCore.Runtime=previous
assert(admin.Projection.syncAll())
for _,event in ipairs(admin.Service.Events)do
    event.handler('qbx_core');assert(#timers==0,'old QBX start no longer schedules internal publication')
    event.handler('forge-core');event.handler('ox_inventory')
end
assert(#timers==2 and timers[1].ms==1500 and timers[2].ms==1500)
assert(base.PlayerCore.State.Players[1]==p.lookup.GetPlayer(1)and #queued==0 and #ox.workers==1)
print('PASS weapon composition: same runtime Shared/Player/Inventory/JobService, real protected callbacks and PR persistence, installed OX item module/client update/disarm helpers under simulated wire/natives; disable/reenable/delete/reload/policy/failed publication preserved, not full equip/use/shooting or live restart')
