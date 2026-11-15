local R=dofile('tests/kernel_starterpack_harness.lua');local n=0
local function case(name,fn)R.menuCase(name,fn);n=n+1 end
local function stop(r)return r.starterPayload.prologue.stops[1]end
case('root parent',function(r)r.menu.openStarterpackMenu();assert(r.last.menu=='forge_core_server_settings'and #r.last.options==4)end)
case('settings parent34 route',function(r)r.menu.openServerSettingsMenu();r.select(25);assert(r.last.id=='forge_core_starterpack')end)
case('read failure',function(r)r.starterRpcHook=function()return false,'no_permission'end;r.menu.openStarterpackMenu()end)
case('malformed payload',function(r)r.starterRpcHook=function()return true,false end;r.menu.openStarterpackMenu();assert(#r.last.options==4)end)
for _,i in ipairs({1,2,3,4})do case('root route '..i,function(r)r.menu.openStarterpackMenu();r.select(i)end)end
case('items parent',function(r)r.menu.openStarterpackItems();assert(r.last.menu=='forge_core_starterpack'and #r.last.options==3);r.select(2)end)
case('item remove',function(r)r.menu.openStarterpackItem(r.starterPayload.items[1]);r.select(2)end)
case('item edit route',function(r)r.menu.openStarterpackItem(r.starterPayload.items[1]);r.select(1)end)
case('prologue parent',function(r)r.menu.openStarterpackPrologue();assert(r.last.menu=='forge_core_starterpack'and #r.last.options==5);r.select(5)end)
for _,i in ipairs({1,2,3,4,5,6})do case('stop action '..i,function(r)r.menu.openStarterpackStop(stop(r));r.select(i)end)end
case('rewards parent',function(r)r.menu.openStarterpackStopRewards(stop(r));assert(r.last.menu=='forge_core_starterpack_stop_one');r.select(2)end)
case('reward remove',function(r)r.menu.openStarterpackReward(stop(r),1);r.select(2);assert(#stop(r).rewards==0)end)
case('reward missing',function(r)r.menu.openStarterpackReward(stop(r),999)end)
case('dialogs parent',function(r)r.menu.openStarterpackStopDialogs(stop(r));assert(r.last.menu=='forge_core_starterpack_stop_one');r.select(2)end)
case('dialog remove',function(r)r.menu.openStarterpackDialog(stop(r),1);r.select(2);assert(#stop(r).routeDialogs==0)end)
case('dialog missing',function(r)r.menu.openStarterpackDialog(stop(r),999)end)
local forms={
 {'settings','openStarterpackSettings',function(r)return{r.starterPayload.settings}end,{'false','true','true'}},
 {'new item','openStarterpackItemEditor',function()return{}end,{'water','Water',2,'true','{}'}},
 {'edit item','openStarterpackItemEditor',function(r)return{r.starterPayload.items[1]}end,{'burger','Food',3,'true','{}'}},
 {'prologue','openStarterpackPrologueSettings',function(r)return{r.starterPayload.prologue}end,{'true','model','car',45,'remove'}},
 {'new stop','openStarterpackStopEditor',function()return{}end,{'New','true','Route','Arrive','Next',1,5}},
 {'edit stop','openStarterpackStopEditor',function(r)return{stop(r)}end,{'Updated','false','Route','Arrive','Next',3,8}},
 {'new reward','openStarterpackRewardEditor',function(r)return{stop(r)}end,{'water',3,33,'Dialogue',5000,'true'}},
 {'edit reward','openStarterpackRewardEditor',function(r)return{stop(r),1}end,{'token',4,100,'Dialogue',3000,'false'}},
 {'new dialog','openStarterpackDialogEditor',function(r)return{stop(r)}end,{40,'Text',6000}},
 {'edit dialog','openStarterpackDialogEditor',function(r)return{stop(r),1}end,{70,'Changed',3000}},
}
for _,f in ipairs(forms)do
 case(f[1]..' cancel',function(r)r.menu[f[2]](table.unpack(f[3](r)))end)
 case(f[1]..' save',function(r)r.inputs={f[4]};r.menu[f[2]](table.unpack(f[3](r)))end)
 case(f[1]..' save refusal',function(r)
  r.inputs={f[4]};r.starterRpcHook=function(name)if name==r.config.Starterpack.Callbacks.getAll then return true,R.seed()end;return false,'save_failed'end
  r.menu[f[2]](table.unpack(f[3](r)))
 end)
end
for _,key in ipairs({'Vehicle','Lamar'})do
 local method='placeStarterpack'..key
 case(key..' placement',function(r)r.invokePlacement=true;r.placement={coords={x=2.12345,y=3,z=4},heading=98.888};r.menu[method](r.starterPayload.prologue)end)
 case(key..' cancel',function(r)r.invokePlacement=true;r.menu[method](r.starterPayload.prologue)end)
 case(key..' unavailable',function(r)r.library.devtools=nil;r.menu[method](r.starterPayload.prologue)end)
 case(key..' start false',function(r)r.placementResult=false;r.menu[method](r.starterPayload.prologue)end)
 case(key..' delayed callback',function(r)r.menu[method](r.starterPayload.prologue);r.placementCallback({1,2,3})end)
end
for _,i in ipairs({1,2,3})do
 case('actions cancel '..i,function(r)r.menu.openStarterpackActions();r.select(i)end)
 case('actions perform '..i,function(r)r.inputs={i==2 and{2}or{'CID1'}};r.menu.openStarterpackActions();r.select(i)end)
end
case('metadata invalid ignored',function(r)r.decodeError=true;r.inputs={{'water','Water',1,'true','not json'}};r.menu.openStarterpackItemEditor()end)
case('metadata value preserved',function(r)r.decoded={quality=88,serial='test'};r.inputs={{'water','Water',1,'true','metadata'}};r.menu.openStarterpackItemEditor()end)
case('snapshot mutated before refusal inherited',function(r)
 r.starterRpcHook=function(name)if name==r.config.Starterpack.Callbacks.getAll then return true,R.seed()end;return false,'save_failed'end
 r.inputs={{'token',2,50,'Hello',1000,'true'}};r.menu.openStarterpackRewardEditor(stop(r),1);assert(stop(r).rewards[1].count==2)
end)
print('PASS starterpack menus: '..n..' differential cases; parents, forms, CRUD, metadata, placement, callbacks and failure snapshots')
