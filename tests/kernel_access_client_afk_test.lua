local R=dofile('tests/kernel_access_client_harness.lua')
local count=0
local function case(n,fn)R.menuCase(n,fn);count=count+1 end
case('cancel',function(r)r.menu.openAfkSettingsEditor({enabled=true,minutes=5})end)
case('defaults',function(r)r.inputs={{'true','invalid'}};r.menu.openAfkSettingsEditor();r.runTimers()end)
for _,v in ipairs({'true','false'})do
    case('save '..v,function(r)r.inputs={{v,'1440'}};r.menu.openAfkSettingsEditor({});r.runTimers()end)
end
case('denied',function(r)r.inputs={{'true',12}};r.awaitHook=function()return false,'no_permission'end;r.menu.openAfkSettingsEditor({});r.runTimers()end)
case('locked',function(r)
    r.inputs={{'true',10},{'false',20}};r.menu.openAfkSettingsEditor({});r.menu.openAfkSettingsEditor({})
    assert(r.count('await')==1);r.runTimers(1000);r.inputs={{'true',30}};r.menu.openAfkSettingsEditor({});assert(r.count('await')==2)
end)
case('lock inherited after error',function(r)
    r.inputs={{'true',10}};r.awaitHook=function()error('fixture-rpc',0)end
    local ok=pcall(r.menu.openAfkSettingsEditor,{});assert(not ok)
    r.inputs={{'true',20}};r.awaitHook=nil;r.menu.openAfkSettingsEditor({});assert(r.count('await')==1)
end)
print('PASS AFK client editor differentials '..count)
