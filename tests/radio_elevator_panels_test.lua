-- Run from forge-core with lua55.exe. No live menu or ACE is changed.
local opened,context,notifications,exported={},{},{},{}
GetCurrentResourceName=function()return 'forge-core'end
local available=true
GetResourceState=function()return available and 'started' or 'stopped'end
local function panel(resource)
    return {OpenAdminMenu=function(_,parent,caller)opened[#opened+1]={resource,parent,caller}end}
end
exports=setmetatable({mm_radio=panel('mm_radio'),pr_elevator=panel('pr_elevator')},
    {__call=function(_,name,fn)exported[name]=fn end})
local shared={t=function(key)return key end,showContext=function(value)context=value end,
    awaitServer=function()return true,{}end,notify=function(value)notifications[#notifications+1]=value end,
    boolDefault=function(value,default)if value==nil then return default end;return value end}
ForgeCore={Client={Menu={},MenuShared=shared},JobService={canManage=function(src)return src==1 end}}
PR={Afk={Callbacks={getSettings='afk'},Defaults={enabled=false,minutes=10}},
    Password={Callbacks={getSettings='password'},Defaults={enabled=false,password='',supportLink='',cardTitle='',cardDescription='',placeholder='',submitText=''}}}
dofile('server/menu.lua');dofile('client/menu/menu_server.lua')
assert(exported.CanManageServerSettings(1))
assert(not exported.CanManageServerSettings(2) and not exported.CanManageServerSettings(0) and not exported.CanManageServerSettings('1'))
local function find(key)for _,option in ipairs(context.options)do if option.title==key then return option end end;error(key)end
ForgeCore.Client.Menu.openServerSettingsMenu()
local radio,elevator=find('panels.radio.title'),find('panels.elevator.title')
assert(not radio.disabled and not elevator.disabled)
radio.onSelect();elevator.onSelect()
assert(opened[1][1]=='mm_radio' and opened[2][1]=='pr_elevator')
assert(opened[1][2]=='forge_core_server_settings' and opened[1][3]=='forge-core')
available=false
ForgeCore.Client.Menu.openServerSettingsMenu()
assert(find('panels.radio.title').disabled and find('panels.elevator.title').disabled)
radio.onSelect();assert(#opened==2 and #notifications==1,'Resource stop must be handled without invoking a missing export')
print('PASS: real Forge server-settings shortcuts, disabled stopped resources, parent menu and shared server authorization')
