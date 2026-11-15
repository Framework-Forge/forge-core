local D=dofile('tests/kernel_domains_harness.lua');local r=D.new();local api=r.mount();r.register()
local pc=api.PlayerCore;local counts={admin=0,player=0}
for _,d in ipairs(api.Callbacks)do
 local access=api.Security.registrations[d.name].access;counts[access]=counts[access]+1
 if access=='admin'then local ok,e=r.central.handlers[d.name](1);assert(not ok and e=='no_permission','server denial '..d.name)end
end
assert(counts.admin==131 and counts.player==65,'complete shared classification before domains')
pc.Players.CheckPlayerData(1,{citizenid='CANONICAL',license='license:test',userId=101,charinfo={firstname='Canonical',lastname='Player',birthdate='2000-10-22'}})
local player=pc.Lookup.GetPlayer(1);local records=pc.Lookup.GetQBPlayers()
local ok,p=r.rpc('PlayerManagement','details',2,1);assert(ok and p.citizenid=='CANONICAL','profile sees canonical Player')
ok,p=r.rpc('Player','getInfo',1);assert(ok and p.firstname=='Canonical','personal info same Player')
api.Central.Parts.Finance.Vip.Initialize()
assert(r.rpc('Vip','grant',2,1,'gold',2));assert(player.PlayerData.metadata.vip.tier=='gold')
ok,p=r.rpc('Vip','get',2,1);assert(ok and p.tier=='gold');assert(r.rpc('Vip','revoke',2,1))
local inventory,weapons=api.Central.Parts.Inventory,api.Central.Parts.Weapons
local wc=r.config.Weapons;local m=r.central.m
m.seed(r.config.Inventory.Storage.items,{})
m.seed(r.config.Inventory.Storage.weaponInventory,{ammo={},components={},tints={}})
m.seed(wc.Storage.file,{weapon_pistol={name='weapon_pistol',label='Pistol',active=true,access={mode='free'}}})
assert(inventory.Service.Initialize());assert(weapons.Service.Initialize());assert(weapons.Service.start())
local load=r.central.handlers['forge-core:server:plugin:load'];local action=r.central.handlers['forge-core:server:plugin:action']
ok,p=load(2,'weapon');assert(ok and #p.weapons==1,'actual Weapon plugin previously missing in historical full graph')
ok,p=action(2,'weapon','setActive',{name='weapon_pistol',active=false});assert(ok,'plugin routes to same Weapon service')
ok,p=inventory.Service.canUseItem(1,'weapon_pistol');assert(not ok and p=='disabled'and not pc.Runtime.Weapons.HasWeapon('weapon_pistol'))
ok,p=action(2,'weapon','setActive',{name='weapon_pistol',active=true});assert(ok and inventory.Service.canUseItem(1,'weapon_pistol'))
ok,p=action(2,'weapon','save',{weapon={name='weapon_test48',label='Test48',active=true}});assert(ok,'plugin save reaches actual Weapon service')
ok,p=load(2,'weapon');assert(ok and #p.weapons==2,'saved weapon visible through same plugin payload')
ok,p=action(2,'weapon','delete',{name='weapon_test48'});assert(ok,'plugin delete reaches actual Weapon service')
ok,p=load(2,'weapon');assert(ok and #p.weapons==1,'deleted weapon absent from same catalog')
ok,p=action(2,'density','save',{settings={enabled=false}});assert(ok and not r.base.WorldCore.Density.Service.getSettings().enabled,'plugin changes same Density')
ok,p=action(2,'afk','save',{settings={enabled=false,minutes=12}});assert(ok and r.base.AccessCore.Afk.Service.getSettings().minutes==12,'plugin changes same AFK')
assert(pc.Players.AddMoney(1,'cash',12.6));assert(player.PlayerData.money.cash==13,'Player round delegated to same local helper07')
-- Plugin registration remains explicit and external. Construction did not register anything.
local fixture=r.fixtures.PlayerAdmin;assert(#fixture.registrations==0)
for _,e in ipairs(api.Parts.PlayerAdmin.Events)do if e.name=='forge-management:server:pluginsReady'then e.handler()end end
assert(#fixture.registrations==9,'nine explicit external plugin registration descriptors')
assert(pc.State.Players==records and r.base.PlayerCore==pc and r.base.Callbacks==api.Security,'no swapped authority')
assert(api.Unbound and api.State=='prepared-inactive','tests do not mark operationally installed')
print('PASS lot48 routing: 131 administrative denials/65 player classifications, canonical profiles/VIP/all weapon plugin paths/Density/AFK/money and explicit registration; actual services with virtual PR/provider/IO')
