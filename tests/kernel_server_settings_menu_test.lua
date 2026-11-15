local R=dofile('tests/kernel_server_settings_harness.lua')
local count=0
local function case(n,fn)R.menuCase(n,fn);count=count+1 end
case('parent fetch AFK/password',function(r)r.menu.openServerSettingsMenu();assert(r.last.id=='forge_core_server_settings'and r.last.menu=='forge_core_main')end)
case('failed fetch fallback',function(r)r.awaitHook=function()return false,'no_permission'end;r.menu.openServerSettingsMenu()end)
case('malformed fetch fallback',function(r)r.awaitHook=function()return true,'bad'end;r.menu.openServerSettingsMenu()end)
case('password editor cancel',function(r)r.menu.openPasswordSettingsEditor({})end)
case('password editor save',function(r)r.inputs={{'true','********','Help','Title','Body','Input','Go'}};r.menu.openPasswordSettingsEditor({});assert(r.savedPassword.password=='********');r.runTimers()end)
case('password denied',function(r)r.inputs={{'true','fixture'}};r.awaitHook=function()return false,'no_permission'end;r.menu.openPasswordSettingsEditor({});r.runTimers()end)
case('password lock',function(r)r.inputs={{'true','A'},{'false','B'}};r.menu.openPasswordSettingsEditor({});r.menu.openPasswordSettingsEditor({});assert(r.count('await')==1);r.runTimers(1000)end)
case('AFK uses old editor',function(r)r.inputs={{'true',30}};r.menu.openAfkSettingsEditor({});r.runTimers()end)
case('backup history empty',function(r)r.menu.openDatabaseBackupMenu();assert(#r.last.options==3 and r.last.menu=='forge_core_server_settings')end)
case('backup running disabled',function(r)r.history.running=true;r.menu.openDatabaseBackupMenu();assert(r.last.options[1].disabled)end)
case('backup history rows',function(r)r.history.entries={{success=true,mode='both',tables=1,rows=2,path='X'},{success=false,error='failed',mode='data'}};r.menu.openDatabaseBackupMenu();assert(#r.last.options==5 and r.last.options[4].disabled)end)
case('backup history failure',function(r)local n=0;r.awaitHook=function()n=n+1;if n==1 then return false,'no_permission'end;return true,{}end;r.menu.openDatabaseBackupMenu()end)
for index,mode in ipairs({'schema','data','both'})do
    case('backup confirm '..mode,function(r)r.menu.openDatabaseBackupMenu();r.alerts={'confirm'};r.select(index);assert(r.backups[1]==mode);r.runTimers()end)
end
case('backup cancel',function(r)r.menu.openDatabaseBackupMenu();r.alerts={'cancel'};r.select(1);assert(#r.backups==0)end)
case('backup failure',function(r)
    r.menu.openDatabaseBackupMenu();r.alerts={'confirm'}
    r.awaitHook=function(name)if name==r.config.DatabaseBackup.Callbacks.create then return false,'save_failed'end;return true,{}end
    r.select(1);r.runTimers()
end)
case('backup lock',function(r)r.menu.openDatabaseBackupMenu();local ctx=r.last;r.alerts={'confirm','confirm'};r.select(1,ctx);r.select(2,ctx);assert(#r.backups==1)end)
local panels={{14,'forge-chat'},{15,'forge-smallresources'},{16,'xt-prison'},{17,'mm_radio'},{18,'pr_elevator'},
    {19,'forge-hud'},{20,'forge-gym'},{21,'forge-backpack'},{22,'illenium-appearance'}}
for _,p in ipairs(panels)do
    for _,status in ipairs({'started','stopped','error','false-return'})do
        case('panel '..p[2]..' '..status,function(r)
            r.resources[p[2]]=status=='stopped'and'stopped'or'started';r.panelError=status=='error';r.panelResult=status~='false-return'
            r.menu.openServerSettingsMenu();r.select(p[1])
        end)
    end
end
case('panel failed resource lookup escapes pcall',function(r)r.panelIntegration.resourceState=function()error('fixture-resource',0)end;r.env.GetResourceState=r.panelIntegration.resourceState;r.menu.openServerSettingsMenu()end)
print('PASS server settings menu differentials '..count)
