local I=dofile('tests/kernel_inventory_harness.lua')
local n=0
local function case(label,fn,options)n=n+1;I.case(label,fn,options)end
local accessCases={
    {'free',{},true}, {'job',{jobs={{name='police',grade=4}}},true}, {'job-low',{jobs={{name='police',grade=5}}},false},
    {'wrong-job',{jobs={{name='taxi',grade=0}}},false}, {'gang',{gangs={{name='ballas',grade=2}}},true},
    {'job-or-gang',{jobs={{name='taxi',grade=9}},gangs={{name='ballas',grade=0}}},true},
    {'vip-required',{vips={'gold'}},false}, {'vip-and-job',{vips={'gold'},jobs={{name='police',grade=4}}},true},
    {'vip-fails-job',{vips={'gold'},jobs={{name='taxi',grade=0}}},false}}
for _,entry in ipairs(accessCases)do
    case(entry[1],function(r)r.api.items.burger.access=entry[2];if entry[1]~='vip-required'then r.vip[1]={tier='gold'}end;local ok=r.api.canUseItem(1,'BURGER');assert(ok==entry[3])end)
end
for _,grade in ipairs({4,'4',{level=4},{grade=4},{id=4}})do case('grade forms',function(r)r.players[1].job.grade=grade;r.api.items.burger.access={jobs={{name='POLICE',grade=4}}};assert(r.api.canUseItem(1,'burger'))end)end
for _,role in ipairs({'admin','mod','staff','support'})do
    case('role alias '..role,function(r)r.aces[1]={};r.aces[1][role]=true;r.api.items.burger.access={jobs={{name=role=='support'and'staff'or role,grade=99}}};assert(r.api.canUseItem(1,'burger'))end)
end
case('delegated WeaponService false overrides fallback ACE',function(r)assert(not r.api.canManage(1))end,function(r)r.services.WeaponService={canManage=function()r.record('weapon-manage');return false end}end)
case('console authority',function(r)assert(r.api.canManage(0))end)
case('disabled item',function(r)r.api.items.burger.active=false;local ok,err=r.api.canUseItem(1,'burger');assert(not ok and err=='disabled')end)
case('unrecognized item allowed inherited',function(r)assert(r.api.canUseItem(1,'not-managed'))end)
case('missing PD cannot satisfy group',function(r)r.players[1]=nil;r.api.items.burger.access={jobs={{name='police'}}};assert(not r.api.canUseItem(1,'burger'))end)
case('ammo case-sensitive gate retained',function(r)r.api.weaponInventory.ammo['AMMO_CASE']={active=false};assert(not r.api.canUseItem(1,'AMMO_CASE'));assert(r.api.canUseItem(1,'ammo_case'))end)
case('component blocked',function(r)r.api.weaponInventory.components.comp={active=false};local ok,err=r.api.canUseItem(1,'comp');assert(not ok and err=='disabled')end)
case('weapon policy comes from administrative registry',function(r)r.weapons.weapon_pistol.active=false;local ok,err=r.api.canUseItem(1,'WEAPON_PISTOL');assert(not ok and err=='disabled')end)
for _,kind in ipairs({'item','weapon','ammo','component'})do
    case('give '..kind,function(r)
        if kind=='ammo'then assert(r.api.upsertAmmo(1,{name='ammo',label='Ammo'}))elseif kind=='component'then assert(r.api.upsertComponent(1,{name='comp',label='Comp'}))end
        local name=({item='burger',weapon='weapon_pistol',ammo='ammo',component='comp'})[kind]
        local ok,result=r.api.give(1,'1',kind,name,2);assert(ok and result.target==1 and result.count==2)
    end)
end
for _,count in ipairs({-1,0,1,100000,100001,1.9})do case('item amount '..count,function(r)local ok=r.api.give(1,1,'item','burger',count);assert(ok==(count>=1 and count<100001))end)end
for _,count in ipairs({25,26})do case('weapon cap '..count,function(r)local ok=r.api.give(1,1,'weapon','weapon_pistol',count);assert(ok==(count==25))end)end
for _,target in ipairs({0,99,'bad'})do case('invalid target',function(r)local ok,err=r.api.give(1,target,'item','burger',1);assert(not ok and err=='invalid_player')end)end
case('inactive entry cannot be granted',function(r)r.api.items.burger.active=false;local ok,err=r.api.give(1,1,'item','burger',1);assert(not ok and err=='entry_inactive')end)
case('grant bypasses target access by design',function(r)r.api.items.burger.access={vips={'gold'}};assert(not r.api.canUseItem(1,'burger'));assert(r.api.give(1,1,'item','burger',1))end)
for _,variant in ipairs({'carry-false','carry-throw','carry-nil','add-false','add-nil','add-throw','no-inventory','no-add'})do
    case('give failure '..variant,function(r)
        if variant=='carry-false'then r.results.CanCarryItem=table.pack(false)elseif variant=='carry-throw'then r.results.CanCarryItem='throw'
        elseif variant=='carry-nil'then r.results.CanCarryItem=table.pack(nil)elseif variant=='add-false'then r.results.AddItem=table.pack(false,'denied')
        elseif variant=='add-nil'then r.results.AddItem=table.pack(nil)elseif variant=='add-throw'then r.results.AddItem='throw'
        elseif variant=='no-inventory'then r.library.inventory=nil elseif variant=='no-add'then r.library.inventory.AddItem=nil end
        local ok=r.api.give(1,1,'item','burger',1);assert(ok==(variant=='carry-nil'))
    end)
end
case('catalog only active entries',function(r)
    r.services.WeaponService={canManage=function()return true end,getPayload=function()return{weapons={r.weapons.weapon_pistol}}end}
    assert(r.api.upsertAmmo(1,{name='ammo'}));assert(r.api.upsertComponent(1,{name='comp',active=false}))
    local ok,list=r.api.getGiveCatalog(1);assert(ok and #list==3)
end)
case('permission denies admin APIs',function(r)r.aces[1]={};local ok,err=r.api.getGiveCatalog(1);assert(not ok and err=='no_permission');assert(not r.api.give(1,1,'item','burger',1))end)
print('PASS '..n..' inventory policy/grant differential cases; active/VIP/group/roles/local PD, all grant kinds/limits/provider failures and retained name/fail-open behavior')
