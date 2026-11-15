local R=dofile('tests/kernel_vinewood_harness.lua')
local n=0
local function case(name,fn,native)R.menuCase(name,fn,native);n=n+1 end
case('parent path',function(r)r.menu.openVinewoodMenu();assert(r.last.id=='forge_core_vinewood'and r.last.menu=='forge_core_server_settings')end)
case('parent routes Vinewood',function(r)r.menu.openServerSettingsMenu();r.select(9);assert(r.last.id=='forge_core_vinewood')end)
case('denied fetch',function(r)r.vinewoodHook=function()return false,'no_permission'end;r.menu.openVinewoodMenu()end)
case('malformed fetch fallback',function(r)r.vinewoodHook=function()return true,false end;r.menu.openVinewoodMenu()end)
case('strict client boolean',function(r)r.vinewoodSettings.enabled='true';r.menu.openVinewoodMenu()end)
case('cancel',function(r)r.menu.openVinewoodMenu();r.select(1)end)
case('form color and limit',function(r)r.inputHook=function(_,fields)assert(#fields==3 and fields[3].type=='color'and fields[2].max==8);return nil end;r.menu.openVinewoodEditor({})end)
for _,answers in ipairs({{'true','NEW','#123456'},{'false','STOP','#FFFFFF'},{'true'}, {false,123,false}})do
    case('editor '..n,function(r)r.inputs={answers};r.menu.openVinewoodEditor({});r.runTimers()end)
end
case('failed save notice',function(r)r.inputs={{'true','FAIL','#fff'}};r.vinewoodHook=function()return false,'save_failed'end
    r.menu.openVinewoodEditor({});r.runTimers()end)
case('double click blocked',function(r)r.inputs={{'true','FIRST','#fff'},{'true','SECOND','#000'}}
    r.menu.openVinewoodEditor({});r.menu.openVinewoodEditor({});assert(r.vinewoodSettings.text=='FIRST');r.runTimers()end)
case('unlock after 1000',function(r)r.inputs={{'true','FIRST','#fff'},{'true','SECOND','#000'}}
    r.menu.openVinewoodEditor({});r.runTimers(1000);r.menu.openVinewoodEditor({});assert(r.vinewoodSettings.text=='SECOND')end)
case('save exception retains lock',function(r)r.inputs={{'true','FIRST','#fff'},{'true','SECOND','#000'}}
    r.vinewoodHook=function()error('fixture-rpc',0)end;local ok=pcall(r.menu.openVinewoodEditor,{});assert(not ok)
    r.vinewoodHook=nil;r.menu.openVinewoodEditor({});assert(r.vinewoodSettings.text=='FORGE')end)
case('PR command opens menu',function(r)assert(r.commands[1].transport=='pr');r.commands[1].handler()end)
case('native fallback command contract',function(r)assert(r.commands[1].transport=='native'and r.commands[1].restricted==false);r.commands[1].handler()end,true)
case('custom command',function(r)assert(r.commands[1].name=='vinewood');r.commands[1].handler()end)
print('PASS Vinewood menu differentials '..n)
