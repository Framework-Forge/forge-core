local R=dofile('tests/kernel_assembly_harness.lua');local H=R.H
local r=R.new();local api=r.mount();local pc,catalog=api.PlayerCore,r.base.JobCatalog
local inventory,weapons,consumption=api.Parts.Inventory,api.Parts.Weapons,api.Parts.Consumption
local cfg,wc=inventory.Config,weapons.Config
r.m.seed(cfg.Storage.items,{burger={name='burger',label='Burger',weight=100,stack=true,active=true,
    interaction={enabled=true,duration=1000,remove=1,hunger=10}}})
r.m.seed(cfg.Storage.weaponInventory,{ammo={},components={},tints={}})
r.m.seed(wc.Storage.file,{weapon_pistol={name='weapon_pistol',label='Pistol',active=true,access={mode='free'},ammotype='AMMO_PISTOL'}})
assert(inventory.Service.Initialize()and weapons.Service.Initialize())
assert(weapons.Service.start());assert(pc.Runtime.Weapons.HasWeapon('weapon_pistol'),'weapon catalog projected into same runtime10')
assert(r.library.inventory.Items('weapon_pistol').weapon,'custom OX definition via PR integration port')
for _,list in ipairs({api.Parts.Transport.Callbacks,inventory.Callbacks,weapons.Callbacks})do
 for _,d in ipairs(list)do api.Security.register(d.name,d.handler,d.options)end
end
assert(next(r.handlers)and api.Security==r.base.Callbacks,'only explicit test registration installs RPC')
for _,name in pairs(wc.Callbacks)do local ok,e=r.handlers[name](1,{});assert(not ok and e=='no_permission','Weapon Security captured before registration')end
pc.Players.CheckPlayerData(1,{citizenid='ASSEMBLY',license='license:test',userId=101,money={cash=10,bank=0}})
assert(inventory.Service.canUseItem(1,'weapon_pistol'))
assert(r.handlers[wc.Callbacks.setActive](2,'pistol',false))
local ok,e=inventory.Service.Exports.CanUseInventoryItem(1,'weapon_pistol')
assert(not ok and e=='disabled'and not pc.Runtime.Weapons.HasWeapon('weapon_pistol')and r.library.inventory.Items('weapon_pistol').disabled,
    'same administrative policy/runtime/custom provider disabled')
assert(r.handlers[wc.Callbacks.setActive](2,'pistol',true));assert(inventory.Service.canUseItem(1,'weapon_pistol'))
local fn=function()return false end;pc.Lifecycle.Functions.CreateUseableItem('test',fn)
assert(pc.Lifecycle.Functions.CanUseItem('test')==fn and pc.State.UsableItems.test==fn,'one usable registry')
r.library.callback.awaitClient=function(...)r.record('use-interaction',...);return true end
consumption.Service.refreshItem('burger')
local use=assert(pc.Lifecycle.Functions.CanUseItem('burger'));local stock=r.items.burger or 0;r.items.burger=2
assert(use(1,{name='burger',slot=4})==false and r.items.burger==1,'local use dispatch -> PR removal once')
assert(catalog.Dependencies.InventoryService==inventory.Service and catalog.Dependencies.WeaponService==weapons.Service)
assert(inventory.Consumption==consumption and catalog.Dependencies.JobPoints==api.Parts.Business.Points and catalog.Dependencies.JobBusiness==api.Parts.Business.Business,'all actual dependencies, no sentinels')
local records=pc.Lookup.GetQBPlayers();local finance=api.Parts.Finance
finance.Vip.Initialize();assert(finance.Vip.grant(2,1,'gold',1));assert(pc.Lookup.GetPlayer(1).PlayerData.metadata.vip.tier=='gold')
assert(finance.Vip.revoke(2,1));assert(pc.State.Players==records,'VIP and inventory share same Player')
-- Inherited R01/R04 policy gaps are not silently fixed or labelled MIG-23 complete by assembly tests.
assert(api.State=='prepared-inactive'and r.base.WorldCore==nil and r.base.PlayerAdminCore==nil,'remaining domain graph intentionally not claimed complete')
print('PASS lot47 central service composition: real Job/Points/Business/Finance/Inventory/Consumption/Weapon/Security on same Player/runtime/usable maps; PR/custom OX in memory, MIG-23/boot not complete')
