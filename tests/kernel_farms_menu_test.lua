local R=dofile('tests/kernel_farms_harness.lua')
local n=0
local function case(name,fn)R.menuCase(name,fn);n=n+1 end
case('root parent',function(r)r.menu.openFarmsMenu();assert(r.last.menu=='forge_core_server_settings'and #r.last.options==3)end)
case('settings parent routes',function(r)r.menu.openServerSettingsMenu();r.select(24);assert(r.last.id=='forge_core_farms_admin')end)
case('public read refusal',function(r)r.farmRpcHook=function()return false,'no_permission'end;r.menu.openFarmsMenu()end)
case('malformed payload',function(r)r.farmRpcHook=function()return true,false end;r.menu.openFarmsMenu();assert(#r.last.options==2)end)
case('missing farm returns root',function(r)r.menu.openFarmAdmin(999);assert(r.last.id=='forge_core_farms_admin')end)
case('missing item returns items',function(r)r.menu.openFarmItemMenu(1,'missing');assert(r.last.id=='forge_core_farm_items_1')end)
case('root create route',function(r)r.menu.openFarmsMenu();r.select(2)end)
case('admin parent and actions',function(r)r.menu.openFarmAdmin(1);assert(r.last.menu=='forge_core_farms_admin'and #r.last.options==5)end)
case('access public save',function(r)r.menu.openFarmAccessMenu(1);r.select(1);r.runTimers();assert(#r.farmRefreshes==1)end)
case('job group route',function(r)r.menu.openFarmAccessMenu(1);r.select(2);assert(r.last.id=='forge_core_farm_group_list_1_job')end)
case('gang group route',function(r)r.menu.openFarmAccessMenu(1);r.select(3);assert(r.last.id=='forge_core_farm_group_list_1_gang')end)
case('empty groups',function(r)r.farmRpcHook=function(name)if name==r.config.Farms.Callbacks.getGroups then return true,{}end;return true,R.seed()end;r.menu.openFarmGroupList(1,'job');assert(r.last.options[1].disabled)end)
case('group read denied',function(r)r.farmRpcHook=function(name)if name==r.config.Farms.Callbacks.getGroups then return false,'no_permission'end;return true,R.seed()end;r.menu.openFarmGroupList(1,'gang')end)
case('entrance parent',function(r)r.menu.openFarmEntranceMenu(1);assert(r.last.menu=='forge_core_farm_admin_1'and #r.last.options==4)end)
case('mark current entrance',function(r)r.menu.markFarmStart(1);r.runTimers();assert(#r.farmRefreshes==1)end)
case('teleport entrance',function(r)r.menu.openFarmEntranceMenu(1);r.select(4)end)
case('items menu parent',function(r)r.menu.openFarmItems(1);assert(r.last.menu=='forge_core_farm_admin_1'and #r.last.options==2)end)
case('catalog item select',function(r)r.menu.openFarmItemCreateSelect(1);assert(#r.last.options==3 and r.last.menu=='forge_core_farm_items_1')end)
case('empty item catalog',function(r)r.farmRpcHook=function(name)if name==r.config.Farms.Callbacks.getItems then return true,{}end;return true,R.seed()end;r.menu.openFarmItemCreateSelect(1);assert(r.last.options[1].disabled)end)
case('item actions',function(r)r.menu.openFarmItemMenu(1,'crop');assert(#r.last.options==7 and r.last.menu=='forge_core_farm_items_1')end)
case('point list parent',function(r)r.menu.openFarmItemPoints(1,'crop');assert(#r.last.options==3 and r.last.menu=='forge_core_farm_item_1_crop')end)
case('point capture current',function(r)r.menu.openFarmPointCaptureMenu(1,'crop');r.select(1);r.runTimers()end)
case('point actions teleport',function(r)r.menu.openFarmPointMenu(1,'crop',1);r.select(1)end)
case('point actions delete',function(r)r.menu.openFarmPointMenu(1,'crop',2);r.select(3);r.runTimers()end)
case('missing point returns list',function(r)r.menu.openFarmPointMenu(1,'crop',999);assert(r.last.id=='forge_core_farm_points_1_crop')end)
case('replace point current',function(r)r.menu.openFarmPointReplaceMenu(1,'crop',1);r.select(1);r.runTimers()end)
case('extras parent',function(r)r.menu.openFarmItemExtras(1,'crop');assert(r.last.menu=='forge_core_farm_item_1_crop'and #r.last.options==2)end)
local forms={
 {'settings','openFarmSettings',function()return{{enabled=true}}end,{'false'}},
 {'create','openFarmCreate',function()return{}end,{'New','true','true'}},
 {'edit','openFarmEdit',function()return{1}end,{'Edited','true'}},
 {'grade','openFarmGroupGrade',function()return{1,'job',{name='police',label='Police'}}end,{2}},
 {'target label','openFarmTargetEdit',function()return{1}end,{'New Label'}},
 {'new item details','openFarmItemCreateDetails',function()return{1,'burger','Burger'}end,{'New','true',1,3,4000}},
 {'item edit','openFarmItemEdit',function()return{1,'crop'}end,{'Crop','true',2,6,7000,'true','true'}},
 {'item required','openFarmItemRequired',function()return{1,'crop'}end,{'token',5,'adder'}},
 {'item limits','openFarmItemLimits',function()return{1,'crop'}end,{'true','farm',6,20,'true'}},
 {'item animation','openFarmItemAnimation',function()return{1,'crop'}end,{'manual','','custom_dict','custom_anim'}},
 {'extra new','openFarmExtraEdit',function()return{1,'crop'}end,{'water',2,4}},
 {'extra edit','openFarmExtraEdit',function()return{1,'crop',1}end,{'water',1,3}},
}
for _,f in ipairs(forms)do
 case(f[1]..' cancel',function(r)r.menu[f[2]](table.unpack(f[3]()))end)
 case(f[1]..' save',function(r)r.inputs={f[4]};r.menu[f[2]](table.unpack(f[3]()));r.runTimers();assert(#r.farmRefreshes>0)end)
end
case('animation scenario inference',function(r)r.inputs={{'weld','WORLD_HUMAN_WELDING','',''}};r.menu.openFarmItemAnimation(1,'crop');r.runTimers()end)
case('settings save refusal',function(r)r.inputs={{'false'}};r.farmRpcHook=function(name)if name==r.config.Farms.Callbacks.getAll then return true,R.seed()end;return false,'save_failed'end;r.menu.openFarmSettings({enabled=true});r.runTimers();assert(#r.farmRefreshes==0)end)
case('farm save refusal',function(r)r.inputs={{'Changed','true'}};r.farmRpcHook=function(name)if name==r.config.Farms.Callbacks.getAll then return true,R.seed()end;return false,'save_failed'end;r.menu.openFarmEdit(1);assert(#r.farmRefreshes==0)end)
case('required vehicles catalog refusal',function(r)r.farmRpcHook=function(name)if name==r.config.Farms.Callbacks.getVehicles then return false,'no_permission'end;if name==r.config.Farms.Callbacks.getItems then return true,{}end;return true,R.seed()end;r.menu.openFarmItemRequired(1,'crop')end)
case('extra items unavailable',function(r)r.farmRpcHook=function(name)if name==r.config.Farms.Callbacks.getItems then return true,{}end;return true,R.seed()end;r.menu.openFarmExtraEdit(1,'crop')end)
for _,answer in ipairs({'confirm','cancel'})do
 case('farm delete '..answer,function(r)r.alerts={answer};r.menu.deleteFarm(1);r.runTimers()end)
 case('item delete '..answer,function(r)r.alerts={answer};r.menu.deleteFarmItem(1,'crop');r.runTimers()end)
end
local function capture(r,key)
 local co=coroutine.create(assert(r.dynamicThreads[1]));assert(coroutine.resume(co));r.just={[key]=true};local ok,e=coroutine.resume(co);assert(ok,e);r.runTimers();assert(not r.textActive)
end
case('entrance devlaser confirm',function(r)r.menu.markFarmStartWithDevLaser(1);capture(r,201);assert(#r.farmRefreshes==1)end)
case('entrance devlaser cancel',function(r)r.menu.markFarmStartWithDevLaser(1);capture(r,177);assert(#r.farmRefreshes==0)end)
case('add point devlaser',function(r)r.menu.openFarmPointCaptureMenu(1,'crop');r.select(2);capture(r,201)end)
case('replace point devlaser',function(r)r.menu.openFarmPointReplaceMenu(1,'crop',1);r.select(2);capture(r,201)end)
case('laser missing',function(r)r.library.devlaser=nil;r.menu.markFarmStartWithDevLaser(1);assert(#r.dynamicThreads==0)end)
case('laser reentry',function(r)r.menu.markFarmStartWithDevLaser(1);r.menu.markFarmStartWithDevLaser(1);assert(#r.dynamicThreads==1)end)
case('laser external stop',function(r)r.menu.markFarmStartWithDevLaser(1);r.laserActive=false;r.laserOptions.onStop();assert(not r.textActive)end)
case('laser becomes inactive cleanup',function(r)r.menu.markFarmStartWithDevLaser(1);r.laserActive=false;local co=coroutine.create(r.dynamicThreads[1]);assert(coroutine.resume(co));assert(not r.textActive)end)
case('laser invalid target remains until cancel',function(r)
 r.menu.markFarmStartWithDevLaser(1);r.library.devlaser.getTarget=function()return{}end;local co=coroutine.create(r.dynamicThreads[1]);assert(coroutine.resume(co))
 r.just={[201]=true};assert(coroutine.resume(co));assert(r.textActive);r.just={[177]=true};assert(coroutine.resume(co));assert(not r.textActive)
end)
print('PASS farms menu differentials '..n)
