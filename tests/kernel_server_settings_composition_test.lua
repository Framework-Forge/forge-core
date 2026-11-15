-- Canonical server32/client33 graph plus new settings; no live connection, SQL or file writes.
local R=dofile('tests/kernel_server_settings_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_access_client_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('local oldTrace,oldQueue=',1,true))
local graph=assert(load(source:sub(1,cut-1)..[[
local access=H.load('kernel/client/access_core.lua',R.env())(state,ports)
return {state=state,medical=medical,client=graph.client,shared=graph.shared,context=graph.context,
    r=r,wire=wire,config=config,base=base,p=p,accessServer=accessServer,access=access,
    register=graph.register,producer=graph.producer}
]],'@canonical-access33','t',_ENV))()
local base,r,wire=graph.base,graph.r,graph.wire
local settingsFixture=R.new(true)
settingsFixture.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
local settings=H.load('kernel/server/server_settings_core.lua',R.env())(base,{
    config=settingsFixture.config,library=settingsFixture.library,native=settingsFixture.native,translate=settingsFixture.translate})
assert(settings.Base==base and settings.Security==base.Callbacks and settings.Access==graph.accessServer)
assert(settings.Services.JobService==base.JobCatalog.Service,'same canonical JobService')
assert(base.JobCatalog.Dependencies.PasswordService==settings.Password.Service
    and base.JobCatalog.Dependencies.DatabaseBackupService==settings.Backup.Service)
assert(#settingsFixture.trace==0 and #settingsFixture.m.trace==0 and not settings.Backup.Service.started,'no automatic settings IO/start')
assert(not pcall(H.load('kernel/server/server_settings_core.lua',R.env()),base,{}),'duplicate server attachment refused')
for _,d in ipairs(settings.Callbacks)do assert(d.options.access=='admin');base.Callbacks.register(d.name,d.handler,d.options)end
settings.Password.Service.start()
-- Backup uses the live holder, including Staff attachment after construction.
local deps=base.JobCatalog.Dependencies
deps.StaffService={canManage=function()return false end}
assert(not settings.Backup.Service.canManage(2),'late Staff policy overrides JobService')
deps.StaffService=nil
assert(settings.Backup.Service.canManage(2),'canonical JobService resumes when Staff absent')
local config=graph.config
config.Password,config.DatabaseBackup=settings.Config.Password,settings.Config.DatabaseBackup
-- Remove only the test parent placeholder created in the immutable menu harness.
graph.client.Menu.openServerSettingsMenu=nil
local afkEditor=graph.client.Menu.openAfkSettingsEditor
local ports={client=graph.client,config=config,library=r.library,native=r.native,panelIntegration={
    resourceState=function()return'stopped'end,openAdminMenu=function()error('no real external panels')end}}
local traceSize,queueSize=#r.trace,#r.queue
local menus=H.load('kernel/client/menu/server_settings_core.lua',R.env())(graph.state,ports)
assert(#r.trace==traceSize and #r.queue==queueSize,'no constructor menu/timer/RPC')
assert(menus.Menu==graph.access.Menu and menus.Shared==graph.access.Shared and menus.Access==graph.access)
assert(menus.Menu.openAfkSettingsEditor==afkEditor,'no duplicated AFK editor')
assert(not pcall(H.load('kernel/client/menu/server_settings_core.lua',R.env()),graph.state,ports),'duplicate menu attachment refused')
local inputs,alerts={},{}
r.library.menus.InputDialog=function(...)r.record('settings-input',...);return table.remove(inputs,1)end
r.library.menus.AlertDialog=function(...)r.record('settings-alert',...);return table.remove(alerts,1)end
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
local pw,bk=config.Password.Callbacks,config.DatabaseBackup.Callbacks
wire.playerSource=1
local ok,err=rpc(pw.getSettings)
assert(not ok and err=='no_permission','non-admin password read denied by actual Security')
ok,err=rpc(pw.saveSettings,{password='fixture-forbidden'});assert(not ok and err=='no_permission')
ok,err=rpc(bk.create,'both');assert(not ok and err=='no_permission','non-admin backup denied')
wire.playerSource=2
ok,err=rpc(pw.getSettings);assert(ok and err.password=='********','actual service masks admin read')
menus.Menu.openServerSettingsMenu()
local context=graph.context.api
assert(context.GetOpenContextMenu()=='forge_core_server_settings')
context.RegisterContext({id='forge_core_main',title='Root',options={}})
-- Real parent -> actual whitelist33 -> back -> root.
context.HandleSelect('forge_core_server_settings',5)
assert(context.GetOpenContextMenu()=='forge_core_whitelist')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_main')
menus.Menu.openServerSettingsMenu()
inputs={{'true','********','Help','Title','Body','Password','Enter'}}
context.HandleSelect('forge_core_server_settings',2);r.advance(1100)
assert(settings.Password.Service.getSettings().password=='fixture-pass','masked edit preserves canonical password')
inputs={{'true',45}}
context.HandleSelect('forge_core_server_settings',1);r.advance(1100)
local afk,afkState=rpc(config.Afk.Callbacks.getSettings);assert(afk and afkState.minutes==45,'AFK33 same server32 state')
-- Real backup UI -> actual PR backup generator/JSON history over virtual SHOW/SELECT and SaveResourceFile.
menus.Menu.openDatabaseBackupMenu()
assert(context.GetOpenContextMenu()=='forge_core_database_backups')
alerts={'confirm'}
context.HandleSelect('forge_core_database_backups',3);r.advance(1100)
assert(#settings.Backup.Service.history==1 and settings.Backup.Service.history[1].success)
local path=settings.Backup.Service.history[1].path
local sql=assert(settingsFixture.sqlFiles[path])
assert(sql:find('CREATE TABLE',1,true)and sql:find('INSERT INTO',1,true),'installed PR backup emits SQL only to memory')
assert(settingsFixture.m.files[config.DatabaseBackup.Storage.historyFile],'history stored only in virtual persistence')
-- Real private password event -> virtual deferral/card, accepts old configured password.
local card,done
local event=settings.Events[1]
local co=coroutine.create(function()event.handler('Test',function()error('No kick')end,{
    defer=function()end,update=function()end,presentCard=function(value,fn)card=value;done=fn end,done=function(err)assert(err==nil)end})
end)
assert(coroutine.resume(co));assert(coroutine.resume(co));assert(coroutine.resume(co));assert(card and done)
done({password='fixture-pass'})
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending settings RPC')
assert(graph.state.PlayerData.citizenid=='PATIENT','same player authority remains untouched')
print('PASS server settings composition: canonical Job/Access/Security/Menu/Shared and AFK33, actual PR RPC/context/persistence/SQL-backup generator in memory; admin denials/mask/edit/AFK/history/backup/card/back; external panel binder/bootstrap and real SQL/NUI/backup remain pending')
