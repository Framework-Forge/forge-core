-- Whole installed settings services/menus vs inactive ports; only virtual IO/SQL/deferrals/UI.
local H=dofile('tests/kernel_harness.lua')
local J=dofile('tests/kernel_job_catalog_harness.lua')
local R={H=H,J=J,P=J.P}
function R.env()
    local e=H.environment()
    e.require=function(name)assert(name:match('^kernel%.'));return H.load(name:gsub('%.','/')..'.lua',e)end
    return e
end
function R.config(ported)
    if ported then return {Password=H.load('kernel/config/forge_password.lua',R.env())(),
        DatabaseBackup=H.load('kernel/config/forge_database_backup.lua',R.env())(),NotifyPos='top-right',AdminAce='forge-core.admin'}end
    local e=H.environment({PR={}});H.load('shared/password.lua',e);H.load('shared/database_backup.lua',e)
    e.PR.NotifyPos='top-right';e.PR.AdminAce='forge-core.admin';return e.PR
end
function R.new(ported)
    local r={trace={},callbacks={},events={},jobResult=true,ace=true,clock=1792483200,names={[1]='Test', [2]='Admin'},
        sqlFiles={},sqlReady=true,sqlSaved=true,rows={{id=1,label="Quote's\\test\n",enabled=true,amount=12.5},{id=2,label='Other',enabled=false}}}
    r.config=R.config(ported);r.m=J.persistence();r.library=r.m.api
    function r.record(k,...)r.trace[#r.trace+1]={kind=k,args=R.P.snapshot(table.pack(...))}end
    r.library.debug={};for _,level in ipairs({'success','error','warn'})do r.library.debug[level]=function(...)r.record('log-'..level,...)end end
    r.library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    r.services={JobService={canManage=function(src)r.record('job-access',src)
        if r.jobError then error('fixture-job-access',0)end;return r.jobResult end}}
    r.native={GetCurrentResourceName=function()return'forge-core'end,
        IsPlayerAceAllowed=function(src,ace)r.record('ace',src,ace);return r.ace end,
        GetPlayerName=function(src)return r.names[src]end,
        Wait=function(ms)r.record('wait',ms);return coroutine.yield(ms)end,
        time=function()return r.clock end,date=function(fmt,t)assert(t==nil or t==r.clock)
            return fmt=='%Y%m%d_%H%M%S'and '20261020_080000'or '2026-10-20 08:00:00'end}
    r.db={isReady=function()return r.sqlReady end}
    function r.db.query(sql,params)
        r.record('sql-query',sql,params)
        if r.sqlHook then r.sqlHook(sql)end
        if sql:find('SHOW FULL TABLES',1,true)then return{{name='players',kind='BASE TABLE'}}end
        if sql:find('SHOW COLUMNS',1,true)then return{{Field='id'},{Field='label'},{Field='enabled'},{Field='amount'}}end
        if sql:find('SELECT *',1,true)then return H.copy(r.rows)end
        error('Unexpected SQL fixture '..sql,0)
    end
    r.db.single=function(sql)r.record('sql-single',sql);if r.noSchema then return nil end
        return{['Create Table']='CREATE TABLE `players` (id INT, label TEXT, enabled BOOL, amount FLOAT)'}end
    local backupEnv=H.environment({SaveResourceFile=function(resource,path,bytes,len)
        assert(resource=='forge-core'and #bytes==len)
        r.record('sql-write',resource,path,bytes)
        if r.sqlWriteError then error('fixture-sql-write',0)end
        r.sqlFiles[path]=bytes
        return r.sqlSaved
    end})
    r.sqlApi=H.load('../pr_bridge/bridge/database/backup/server.lua',backupEnv)(r.db,'forge-core')
    r.library.database={backup={create=function(opts)
        r.record('backup-create',opts)
        if r.backupHook then return r.backupHook(opts)end
        return r.sqlApi.create(opts)
    end}}
    r.m.seed(r.config.Password.Storage.file,{enabled=true,password='fixture-pass',supportLink='fixture-support'})
    r.m.seed(r.config.DatabaseBackup.Storage.historyFile,{})
    local e=H.environment({PR=r.config,pr_lib=r.library,os={time=r.native.time,date=r.native.date}})
    r.services.t=r.translate;r.services.Callbacks={register=function(name,fn)r.callbacks[name]=fn end};e.ForgeCore=r.services
    for n,fn in pairs(r.native)do if n~='time'and n~='date'then e[n]=fn end end
    e.AddEventHandler=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=false}end
    if ported then
        local ports={config=r.config,library=r.library,native=r.native,services=r.services,translate=r.translate}
        r.password=H.load('kernel/server/password.lua',R.env())(ports)
        r.backup=H.load('kernel/server/database_backup.lua',R.env())(ports)
        r.p,r.b=r.password.Service,r.backup.Service
        r.events=r.password.Events
        for _,x in ipairs({{'password',r.p},{'database_backup',r.b}})do
            for _,d in ipairs(H.load('kernel/server/'..x[1]..'_callbacks.lua',R.env())({config=r.config,service=x[2]}))do
                assert(d.options.access=='admin');r.callbacks[d.name]=d.handler
            end
        end
    else
        H.load('server/password/service.lua',e);H.load('server/database_backup/service.lua',e)
        r.p,r.b=e.ForgeCore.PasswordService,e.ForgeCore.DatabaseBackupService
        H.load('server/password/callbacks.lua',e);H.load('server/database_backup/callbacks.lua',e)
    end
    assert(#r.trace==0 and #r.m.trace==0,'no constructor IO/SQL/registration')
    r.env=e
    function r.connect()
        r.deferrals={}
        r.deferrals.defer=function()r.record('defer')end
        r.deferrals.update=function(...)r.record('update-card',...)end
        r.deferrals.presentCard=function(card,fn)r.record('card',card);r.card=card;r.cardResponse=fn end
        r.deferrals.done=function(...)r.record('done',...)end
        local fn=assert(r.events[1].handler)
        local co=coroutine.create(function()fn('Name',function()error('Unexpected kick')end,r.deferrals)end)
        return co
    end
    function r.step(co)local ok,ms=coroutine.resume(co);assert(ok,ms);return ms end
    function r.state()return R.P.snapshot({password=r.p,backup=r.b,files=r.m.files,sqlFiles=r.sqlFiles})end
    r.trace={};r.m.trace={}
    return r
end
function R.outcome(fn,r)
    local out=table.pack(pcall(fn,r))
    if not out[1]then
        local err=tostring(out[2]);assert(err:find('fixture-',1,true),'Unexpected test error: '..err)
        out[2]=err:gsub('stack traceback:[%s%S]*',''):gsub('[^\n]-:%d+: ','')
    end
    return R.P.snapshot(out)
end
-- The installed backup expression `ok and nil or tostring(result)` stores a table address even on success.
-- Keep the error field and its type; normalize only nondeterministic Lua allocation addresses for comparison.
local function addresses(value)
    if type(value)=='string'then return value:gsub('table: [%x]+','table: <address>')end
    if type(value)~='table'then return value end
    local out={};for k,v in pairs(value)do out[k]=addresses(v)end;return out
end
function R.case(name,fn)
    local a,b=R.new(false),R.new(true)
    H.same(addresses(R.outcome(fn,b)),addresses(R.outcome(fn,a)),name..' return')
    H.same(addresses(b.trace),addresses(a.trace),name..' effects')
    H.same(addresses(b.m.trace),addresses(a.m.trace),name..' persistence effects')
    H.same(addresses(b.state()),addresses(a.state()),name..' state')
end
function R.menu(ported)
    local Access=dofile('tests/kernel_access_client_harness.lua')
    local r=Access.menu(ported);r.config.Password=R.config(true).Password;r.config.DatabaseBackup=R.config(true).DatabaseBackup
    r.resources={};r.panelResult=true
    r.native.GetCurrentResourceName=function()return'forge-core'end
    r.panelIntegration={resourceState=function(name)r.record('resource-state',name);return r.resources[name]or'started'end,
        openAdminMenu=function(resource,parent,owner)
            r.record('panel',resource,parent,owner)
            if r.panelError then error('fixture-panel',0)end;return r.panelResult
        end}
    r.afkSettings={enabled=true,minutes=20};r.passwordSettings={enabled=true,password='********',supportLink='Help'}
    r.history={running=false,entries={}};r.savedPassword=nil;r.backups={}
    r.library.callback.await=function(name,timeout,...)
        local backup=name==r.config.DatabaseBackup.Callbacks.create
        assert(timeout==(backup and 300000 or 10000));r.record('await',name,timeout,...)
        if r.awaitHook then return r.awaitHook(name,...)end
        if name==r.config.Afk.Callbacks.getSettings then return true,H.copy(r.afkSettings)end
        if name==r.config.Password.Callbacks.getSettings then return true,H.copy(r.passwordSettings)end
        if name==r.config.DatabaseBackup.Callbacks.getHistory then return true,H.copy(r.history)end
        if name==r.config.Password.Callbacks.saveSettings then r.savedPassword=H.copy((...));return true,H.copy(r.savedPassword)end
        if backup then r.backups[#r.backups+1]=(...);return true,{path='virtual.sql',tables=1,rows=2}end
        return true,{}
    end
    if ported then
        r.menu.openServerSettingsMenu=nil
        r.boundary=H.load('kernel/client/menu/server_settings.lua',R.env())({menu=r.menu,shared=r.shared,
            config=r.config,library=r.library,native=r.native,panelIntegration=r.panelIntegration})
    else
        r.env.GetResourceState=r.panelIntegration.resourceState;r.env.GetCurrentResourceName=r.native.GetCurrentResourceName
        r.env.exports=setmetatable({},{__index=function(_,resource)return{OpenAdminMenu=function(_,...)return r.panelIntegration.openAdminMenu(resource,...)end}end})
        -- Access.menu loaded this origin already, but resets the parent to a fixture. Reload whole origin once for the comparison.
        H.load('client/menu/menu_server.lua',r.env)
    end
    r.trace={}
    return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return')
    H.same(b.trace,a.trace,name..' effects')
    H.same(R.P.snapshot(b.contexts),R.P.snapshot(a.contexts),name..' contexts')
    H.same({b.savedPassword,b.backups},{a.savedPassword,a.backups},name..' requests')
end
return R
