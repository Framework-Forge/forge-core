local H=dofile('tests/cache_harness.lua')
local function equal(a,b)
    if a==b then return true end
    if type(a)~='table' or type(b)~='table' then return false end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function runtime()
    local r=H.new(true);local e=r.env
    e.ForgeCore.t=function(k) return k end;e.joaat=function() return 1 end
    e.vector3=function(x,y,z) return {x=x,y=y,z=z} end;e.vec3=e.vector3;e.vec4=e.vector3
    e.pr_lib.database={query=function() return {} end,transaction=function() return true end}
    return r,e
end
for _,spec in ipairs({{'afk','AfkService','save'},{'password','PasswordService','save'},
    {'multijob','MultiJobService','saveSettings'},{'whitelist','WhitelistService','saveConfig'}}) do
    local r,e=runtime();r.load('shared/'..spec[1]..'.lua');r.load('server/'..spec[1]..'/service.lua')
    local service=e.ForgeCore[spec[2]]
    if service.load then service.load() end
    local field=spec[1]=='whitelist' and 'config' or 'settings'
    local before=H.copy(service[field]);local original=service[field]
    e.SaveResourceFile=function() return false end
    assert(not service[spec[3]](0,{enabled=true,password='safe-test-value'}))
    assert(service[field]==original and equal(service[field],before),spec[1]..' leaked draft')
    print('PASS administrative configuration: '..spec[1])
end
do
    local r,e=runtime();r.load('shared/vip.lua');r.load('server/vip/service.lua')
    local service=e.ForgeCore.VipService;service.tiers={basic={id='basic',label='Basic'}}
    local before=H.copy(service.tiers);local original=service.tiers
    e.SaveResourceFile=function() return false end
    assert(not service.upsertTier(0,{id='new',label='New'}));assert(service.tiers==original and equal(service.tiers,before))
    assert(not service.deleteTier(0,'basic'));assert(equal(service.tiers,before))
end
do
    local r,e=runtime();r.load('shared/inventory.lua');r.load('server/inventory/service.lua')
    local s=e.ForgeCore.InventoryService;s.items={water={name='water',label='Water',active=true}}
    s.weaponInventory.ammo={ammo_test={name='ammo_test',active=true}}
    local items,ammo=H.copy(s.items),H.copy(s.weaponInventory)
    local revision=s.revision
    e.SaveResourceFile=function() return false end
    assert(not s.deleteItem(0,'water'));assert(equal(s.items,items))
    assert(not s.setItemActive(0,'water',false));assert(equal(s.items,items) and s.revision==revision)
    assert(not s.deleteAmmo(0,'ammo_test'));assert(equal(s.weaponInventory,ammo))
    assert(not s.setAmmoActive(0,'ammo_test',false));assert(equal(s.weaponInventory,ammo) and s.revision==revision)
end
for _,spec in ipairs({{'weapon','Weapons','Weapon','upsert',{name='weapon_test',label='Test'}},
    {'skill','Skills','Skill','upsertSkill',{name='test',label='Test',maxXp=100}},
    {'job','Job','Job','upsert',{name='test',label='Test',type='job',grades={['0']={name='Test',payment=0}}}}}) do
    local r,e=runtime();local syncs=0
    e.ForgeCore.WeaponQbxSync={syncAll=function() syncs=syncs+1 end}
    e.ForgeCore.WeaponOxSync=e.ForgeCore.WeaponQbxSync;e.ForgeCore.JobQbxSync=e.ForgeCore.WeaponQbxSync
    r.load('shared/'..(spec[1]=='weapon' and 'weapons' or spec[1]=='skill' and 'skills' or 'job')..'.lua')
    if spec[1]=='skill' then r.load('../pr_bridge/shared/progression.lua') end
    r.load('server/'..spec[1]..'/registry.lua');r.load('server/'..spec[1]..'/storage.lua');r.load('server/'..spec[1]..'/service.lua')
    local registry=e.ForgeCore[spec[3]..'Registry'];local service=e.ForgeCore[spec[3]..'Service']
    local before=H.copy(registry);local revision=registry.revision
    e.SaveResourceFile=function() return false end
    assert(not service[spec[4]](0,spec[5]));assert(equal(registry,before))
    assert(registry.revision==revision and syncs==0,'failed catalog must not sync framework/inventory')
    e.SaveResourceFile=function() return true end
    assert(service[spec[4]](0,spec[5]));assert(registry.revision>revision)
    print('PASS staged registry: '..spec[1])
end
do
    local r,e=runtime();r.load('shared/job.lua');r.load('server/job/payments.lua')
    local p=e.ForgeCore.JobPayments;p.settings={enabled=false};p.nextPaymentAt=123
    e.ForgeCore.JobStorage={savePayments=function() return false end}
    assert(not p.save({enabled=true}));assert(p.settings.enabled==false and p.nextPaymentAt==123)
    local cash,government=100,50
    local player={Functions={AddMoney=function(_,amount) cash=cash+amount;return true end}}
    local settings={mei={enabled=true,openingCost=10,paymentAccount='cash',governmentAccount='government'}}
    e.pr_lib.banking={RemoveJobAccountBalance=function(_,amount) government=government-amount;return true end}
    assert(p.refundMeiOpening(player,settings));assert(cash==110 and government==40,'MEI refund must debit government')
    e.pr_lib.banking.RemoveJobAccountBalance=function() return false end
    assert(not p.refundMeiOpening(player,settings));assert(cash==110,'failed reversal must not mint money')
end
print('PASS administrative persistence: settings, VIP, items/ammo, jobs/weapons/skills, payroll, MEI compensation')
