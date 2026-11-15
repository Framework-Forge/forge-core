-- Actual startup61/lifecycle60/graph48 and PR dependency shim; SQL/catalog/platform virtual.
local T=dofile('tests/kernel_server_lifecycle_harness.lua')
local R={T=T,H=T.H}
function R.new()
    local r=T.new();local f=r.fixture;local db=f.central.db
    r.states={pr_bridge='started',oxmysql='started',ox_inventory='started',ox_lib='stopped'}
    r.versions={ox_inventory='2.47.8'};r.contractVersion='3.30.6';r.sqlTrace={};r.catalog={};r.ping=true;r.dbReady=true
    local rawQuery=db.query.await
    local function execute(sql,...)
        if sql:find('CREATE TABLE IF NOT EXISTS `users`',1,true)or sql:find('ADD COLUMN IF NOT EXISTS `userId`',1,true)then
            r.sqlTrace[#r.sqlTrace+1]=sql
            if r.sqlHook then r.sqlHook(sql)end
            if r.sqlError then error('virtual SQL failure')end
            if r.sqlFalse then return false end
            if sql:find('CREATE TABLE',1,true)then r.catalog.users=true else r.catalog.userId=true end
            return {affected=0},nil,8
        end
        return rawQuery(sql,...)
    end
    db.query.await=execute
    local rawSingle=db.single.await
    db.single.await=function(sql,...)
        if sql=='SELECT 1 AS forge_ready'then if r.pingHook then r.pingHook()end;return{forge_ready=r.ping and 1 or 0}end
        if sql:find('AS present',1,true)then
            if r.inspectHook then r.inspectHook(sql)end
            local key=sql:find('information_schema.COLUMNS',1,true)and'userId'or'users'
            return{present=not r.badInspection and r.catalog[key]and 1 or 0}
        end
        return rawSingle(sql,...)
    end
    local env=T.H.environment({pr_lib={},GetResourceMetadata=function(name)return r.versions[name]end,
        GetInvokingResource=function()return'forge-core'end,GetCurrentResourceName=function()return'forge-core'end,print=function()end})
    local github=T.H.load('../pr_bridge/bridge/github/server.lua',env)
    local shim=T.H.load('../pr_bridge/bridge/compat/ox_lib/ox_native.lua',T.H.environment())
    local function noop()end
    local adapter=shim({github=github,fivem={vehicleProperties={},ace={addAce=noop,removeAce=noop,addPrincipal=noop,removePrincipal=noop}}},
        'server',r.contractVersion,function(name)return r.states[name]=='started'end)
    f.ports.central.runtime.library.checkDependency=function(...)
        if r.dependencyHook then r.dependencyHook(...)end;return adapter.checkDependency(...)
    end
    r.startPorts={lifecycle=r.lifePorts,resourceState=function(name)return r.states[name]end,databaseReady=function()return r.dbReady end}
    local environment=T.W.D.R.env();environment.print=function(...)f.central.record('print',...)end
    r.startFactory=T.H.load('kernel/server/startup_context.lua',environment)
    function r.prepareStartup()r.api=r.startFactory(f.base,r.startPorts);r.graph=r.api.Graph;return r.api end
    function r.startupInstall()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return R
