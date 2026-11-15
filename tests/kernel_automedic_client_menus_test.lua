local R=dofile('tests/kernel_automedic_client_harness.lua')
local n=0
local function case(name,fn)R.menuCase(name,fn);n=n+1 end
case('main',function(r)assert(r.menu.openAutoMedicMenu());assert(r.last.menu=='forge_core_main'and #r.last.options==10)end)
case('beds',function(r)r.menu.openAutoMedicBeds();assert(r.last.menu=='forge_core_automedic'and r.last.options[2].image=='v_med_bed1.jpg')end)
case('bed-details',function(r)r.menu.openAutoMedicBeds();r.select(2);assert(r.last.menu=='forge_core_automedic_beds')end)
for _,index in ipairs({2,3,8,9,10})do
    case('toggle-'..index,function(r)r.menu.openAutoMedicMenu();r.select(index);r.runTimers(500);assert(#r.saved==1)end)
end
for _,entry in ipairs({{4,3},{5,50},{6,12345},{7,55}})do
    case('number-'..entry[1],function(r)r.menu.openAutoMedicMenu();r.inputs={{entry[2]}};r.select(entry[1]);r.runTimers(500);assert(#r.saved==1)end)
    case('cancel-'..entry[1],function(r)r.menu.openAutoMedicMenu();r.select(entry[1]);assert(#r.saved==0)end)
end
case('settings-load-denied',function(r)r.awaitHook=function()return false,'no_permission'end;assert(r.menu.openAutoMedicMenu()==false)end)
case('settings-save-denied',function(r)r.menu.openAutoMedicMenu();r.awaitHook=function()return false,'no_permission'end;r.select(3);r.runTimers()end)
case('stale-full-save',function(r)r.menu.openAutoMedicMenu();r.settings.treatmentPrice=999;r.select(3);assert(r.saved[1].data.treatmentPrice~=999)end)
case('lock-stuck-error',function(r)r.menu.openAutoMedicMenu();r.awaitHook=function()error('fixture-await',0)end
    local ok=pcall(r.select,3);assert(not ok);r.awaitHook=nil;r.select(2);assert(#r.saved==0)end)
case('timer-reopen',function(r)r.menu.openAutoMedicMenu();r.select(3);r.menu.openAutoMedicBeds();r.runTimers();assert(r.last.id=='forge_core_automedic')end)
case('add-bed',function(r)r.menu.openAutoMedicBeds();r.inputs={{'New','v_med_bed2'}};r.select(1)
    assert(r.place);r.place({coords={x=2,y=3,z=4},heading=180});assert(r.saved[1].data.exit.x==1)end)
case('add-bed-cancel-form',function(r)r.menu.openAutoMedicBeds();r.select(1);assert(not r.place)end)
case('add-bed-cancel-editor',function(r)r.menu.openAutoMedicBeds();r.inputs={{'New','v_med_bed2'}};r.select(1);r.place(nil);assert(#r.saved==0)end)
case('editor-unavailable',function(r)r.library.fivem.devtools=nil;r.menu.openAutoMedicBeds();r.select(1);assert(#r.saved==0)end)
case('editor-refused',function(r)r.placeStart=false;r.menu.openAutoMedicBeds();r.inputs={{'New','v_med_bed2'}};r.select(1)end)
case('editor-error',function(r)r.placeError=true;r.menu.openAutoMedicBeds();r.inputs={{'New','v_med_bed2'}};r.select(1)end)
case('reposition',function(r)r.menu.openAutoMedicBeds();r.select(2);r.inputs={{'Old','v_med_bed1'}};r.select(1)
    r.place({x=7,y=8,z=9,heading=70});assert(r.saved[1].data.exit.x==10 and r.saved[1].data.id=='bed')end)
case('set-exit',function(r)r.menu.openAutoMedicBeds();r.select(2);r.select(2);assert(r.saved[1].data.exit.x==1)end)
case('prison-flag',function(r)r.menu.openAutoMedicBeds();r.select(2);r.select(3);assert(r.saved[1].data.prison==true)end)
case('delete-confirm',function(r)r.menu.openAutoMedicBeds();r.select(2);r.alerts={'confirm'};r.select(4);assert(#r.settings.beds==0)end)
case('delete-cancel',function(r)r.menu.openAutoMedicBeds();r.select(2);r.select(4);assert(#r.settings.beds==1)end)
case('image-unavailable',function(r)r.library.fivem.blips=nil;r.menu.openAutoMedicBeds();assert(r.last.options[2].image==nil)end)
print('PASS AutoMedic client menu differentials '..n)
