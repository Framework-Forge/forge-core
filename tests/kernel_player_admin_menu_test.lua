local R=dofile('tests/kernel_player_admin_harness.lua');local n=0
local function case(name,fn)R.menuCase(name,fn);n=n+1 end
case('personal info',function(r)assert(r.menu.openPlayerMenu());assert(r.last.id=='forge_core_player_menu'and #r.last.options==6)end)
case('personal failure still opens',function(r)r.rpcHook=function()return false,'invalid_player'end;assert(r.menu.openPlayerMenu())end)
case('personal malformed',function(r)r.personalInfo=false;r.menu.openPlayerMenu()end)
for _,value in ipairs({false,123,'','table: 0xabc',{},'Admin'})do case('displayScalar '..type(value),function(r)r.personalInfo.extra=value;r.menu.openPlayerMenu()end)end
case('personal prison insertion and locked jobs',function(r)r.personalInfo.prison={enabled=true,jailed=true,sentence={amount=30,unit='minutes'},remainingMinutes=25};r.menu.openPlayerMenu();assert(#r.last.options==7 and r.last.options[6].disabled)end)
for _,i in ipairs({1,5,6})do case('personal route '..i,function(r)r.menu.openPlayerMenu();r.select(i)end)end
case('management parent/list',function(r)r.menu.openPlayersManagement();assert(r.last.menu=='forge_core_main'and #r.last.options==3);r.select(3)end)
for _,i in ipairs({1,2})do case('management settings '..i,function(r)r.menu.openPlayersManagement();r.select(i)end)end
case('empty player list',function(r)r.list={};r.menu.openPlayersManagement();assert(r.last.options[3].disabled)end)
case('list denied',function(r)r.rpcHook=function()return false,'no_permission'end;r.menu.openPlayersManagement()end)
case('managed parent',function(r)r.detail.prison={enabled=false};r.menu.openManagedPlayer(1);assert(r.last.menu=='forge_core_players_management'and #r.last.options==8)end)
for _,i in ipairs({2,3,4,5,6,7,8,9,10})do case('managed route '..i,function(r)r.menu.openManagedPlayer(1);r.select(i)end)end
case('managed missing target returns list',function(r)
 r.rpcHook=function(name)if name==r.config.PlayerManagement.Callbacks.list then return true,{}end;return false,'invalid_player'end;r.menu.openManagedPlayer(99)
end)
case('whitelist answers',function(r)r.menu.openPlayerWhitelistAdmin(1);assert(r.last.menu=='forge_core_managed_player'and #r.last.options==2);r.select(1);r.runTimers()end)
case('whitelist no answers',function(r)r.detail.whitelist={whitelisted=false,answers={}};r.menu.openPlayerWhitelistAdmin(1);assert(r.last.options[2].disabled)end)
case('whitelist scalar answers',function(r)r.detail.whitelist.answers={a='plain',b={value='x',correct=true}};r.menu.openPlayerWhitelistAdmin(1)end)
case('whitelist save denied',function(r)
 r.rpcHook=function(name)if name==r.config.PlayerManagement.Callbacks.details then return true,R.H.copy(r.detail)end;return false,'no_permission'end
 r.menu.openPlayerWhitelistAdmin(1);r.select(1);r.runTimers()
end)
case('add job two dialogs',function(r)r.inputs={{'police'},{'2'}};r.menu.openPlayerJobsAdmin(1);r.select(1);r.runTimers()end)
case('add job second cancel',function(r)r.inputs={{'police'}};r.menu.openPlayerJobsAdmin(1);r.select(1)end)
for _,answer in ipairs({'confirm','cancel'})do
 case('remove job '..answer,function(r)r.alerts={answer};r.menu.openPlayerJobsAdmin(1);r.select(2);r.runTimers()end)
 case('remove staff '..answer,function(r)r.alerts={answer};r.menu.openPlayerStaffAdmin(1);r.select(2);r.runTimers()end)
 case('admin car '..answer,function(r)r.detail.prison={enabled=false};r.alerts={answer};r.menu.openManagedPlayer(1);r.select(8);r.runTimers()end)
end
case('staff multi-checkbox form',function(r)r.inputs={{true,true}};r.menu.openPlayerStaffAdmin(1);r.select(1);r.runTimers()end)
case('staff deselect all removes',function(r)r.inputs={{false,false}};r.menu.openPlayerStaffAdmin(1);r.select(1);r.runTimers()end)
case('staff no permissions',function(r)r.detail.staffRole=nil;r.detail.staffPermissions={};r.menu.openPlayerStaffAdmin(1);assert(#r.last.options==1)end)
case('staff catalog refusal',function(r)
 r.rpcHook=function(name)if name==r.config.PlayerManagement.Callbacks.details then return true,R.H.copy(r.detail)end;return false,'no_permission'end
 r.menu.openPlayerStaffAdmin(1);r.select(1)
end)
for _,raw in ipairs({'admin',{admin=true},{permissions={'moderator'}}})do case('staff raw selection '..type(raw),function(r)r.detail.staffPermissions=nil;r.detail.staffRole=raw;r.menu.openPlayerStaffAdmin(1)end)end
case('give item',function(r)r.inputs={{'item:burger',2}};r.menu.openPlayerGiveAdmin(1);r.runTimers()end)
case('give weapon',function(r)r.inputs={{'weapon:pistol',2}};r.menu.openPlayerGiveAdmin(1);r.runTimers()end)
case('give weapon too many',function(r)r.inputs={{'weapon:pistol',26}};r.menu.openPlayerGiveAdmin(1)end)
case('give missing token',function(r)r.inputs={{'bad',2}};r.menu.openPlayerGiveAdmin(1)end)
case('give catalog empty',function(r)r.catalog={};r.menu.openPlayerGiveAdmin(1)end)
case('give catalog denied',function(r)
 r.rpcHook=function(name)if name==r.config.PlayerManagement.Callbacks.details then return true,R.H.copy(r.detail)end;return false,'no_permission'end;r.menu.openPlayerGiveAdmin(1)
end)
case('give save refusal',function(r)
 r.inputs={{'item:burger',2}};r.rpcHook=function(name)
  if name==r.config.PlayerManagement.Callbacks.details then return true,R.H.copy(r.detail)end
  if name==r.config.Inventory.Callbacks.getGiveCatalog then return true,R.H.copy(r.catalog)end;return false,'blocked'
 end;r.menu.openPlayerGiveAdmin(1);r.runTimers()
end)
case('old target reused by timer inherited',function(r)r.inputs={{'item:burger',1}};r.menu.openPlayerGiveAdmin(1);r.detail.name='New same source';r.runTimers();assert(r.last.title=='[1] New same source')end)
for _,clock in ipairs({'real','game'})do case('prison sentence '..clock,function(r)r.inputs={{2,'hours',clock}};r.menu.setPlayerPrison(1)end)end
for _,answer in ipairs({'confirm','cancel'})do case('prison release '..answer,function(r)r.alerts={answer};r.menu.releasePlayerPrison(1)end)end
for _,status in ipairs({{jailed=true,remainingMinutes=1501,sentence={amount=2,unit='days'}},{fugitive=true,remainingMinutes=4.1},{status='fugitive'},{jailed=false}})do
 case('prison description '..tostring(status.status or status.jailed or status.fugitive),function(r)return r.shared.prisonDescription(status)end)
end
case('prison 60s wait and strict success',function(r)
 r.inputs={{1,'minutes','real'}};r.rpcHook=function(name)
  if name==r.config.PlayerManagement.Callbacks.details then return true,R.H.copy(r.detail)end;return 1,'provider_result'
 end;r.menu.setPlayerPrison(1)
end)
case('prison exception caught',function(r)
 r.alerts={'confirm'};r.rpcHook=function(name)if name==r.config.PlayerManagement.Callbacks.prisonRelease then error('fixture-prison',0)end;return true,R.H.copy(r.detail)end
 r.menu.releasePlayerPrison(1)
end)
print('PASS player admin menus: '..n..' differential cases')
