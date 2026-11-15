local S=dofile('tests/kernel_native_seed_harness.lua');local C=dofile('tests/kernel_native_client_bootstrap_harness.lua')
local F=dofile('tests/kernel_native_configuration_harness.lua');local D=dofile('tests/kernel_native_database_harness.lua');local U=dofile('tests/kernel_native_ui_harness.lua')
local H=S.H;local T={S=S,C=C,F=F,D=D,U=U,H=H};T.binder=H.load('kernel/entry/native_context_ports.lua',H.environment())
local function configuration(r,side,existing,keys)
    local n=r.seedPorts.native
    n.GetResourceState=existing.getResourceState;n.GetVehicleNumberPlateText=existing.getVehicleNumberPlateText
    n.SetVehicleDoorsLocked=existing.setVehicleDoorsLocked;n.vec4=existing.vec4 or function(...)return F.S.P.vector(...)end;n.joaat=existing.joaat
    local p={execution=r.seed.Execution,external=r.external,side=side,isCurrent=function()return r.nativeCurrent end,keys=keys,random=existing.random,
        running=coroutine.running,load=r.seedPorts.loadPR}
    return H.load(F.path,H.environment())(p)
end
function T.server()
    local promise={new=function()return{resolve=function(self,v)self.value=v;self.done=true end}end}
    local await=function(p)assert(p.done,'synchronous SQL fixture required');return p.value end
    local originalFactory=S.C.S.new
    S.C.S.new=function(...)
        local s=originalFactory(...);s.ports.environment.promise=promise;s.ports.environment.Citizen={Await=await};return s
    end
    local ok,r=pcall(S.server);S.C.S.new=originalFactory;assert(ok,r)
    r.external={qbx_vehiclekeys=r.configuration.qbx};r.configurationFixture=r.configuration
    r.configAssembly=configuration(r,'server',r.configuration.ports,r.servicesFixture.api.Keys)
    local original=r.bootstrapPorts.context;local startup=original.deliveryContext.mediaContext.supportContext.configurationContext.vehicleContext.bankingContext.operationsContext.inventoryContext.startup
    local priorDB=startup.lifecycle.worker.graph.central.session.player.db
    -- Exercise installed123 PR database,keeping the existing virtual SQL interpreter as its only external endpoint.
    local db=r.servicesFixture.api.Public.database;r.databaseCalls={}
    local external=r.servicesFixture.external.oxmysql
    for _,name in ipairs({'query','execute','insert','scalar','transaction','prepare','rawExecute'})do
        external[name]=function(self,sql,params,cb)
            assert(self==external);r.databaseCalls[#r.databaseCalls+1]={name,sql,params}
            local value
            if name=='query'then
                if type(sql)=='string'and(sql:find('information_schema',1,true)or sql:find('forge_ready',1,true))then value={priorDB.single.await(sql,params)}
                else value=priorDB.query.await(sql,params)end
            elseif priorDB[name]and priorDB[name].await then value=priorDB[name].await(sql,params)
            else value=true end
            cb(value)
        end
    end
    r.installedDB=db
    r.databaseAssembly=H.load(D.path,H.environment())({database=r.installedDB,isCurrent=function()return r.nativeCurrent end})
    r.originalContext=original;r.bootstrapPorts.context=T.binder.Server(original,r.configAssembly,r.databaseAssembly)
    return r
end
function T.client()
    local r=C.new();r.nativeCurrent=true;local unit=S.unit('client');r.seed=unit.allocateSeed();assert(r.seed.Prepare());r.seedUnit=unit;r.seedPorts=unit.seedPorts
    local existing=r.configuration.ports;r.external={pr_carkeys=r.configuration.raw,qbx_vehiclekeys=r.configuration.qbx}
    r.configAssembly=configuration(r,'client',existing)
    local uiFixture=U.new();r.uiFixture=uiFixture;local p=uiFixture.ports
    -- This UI borrows the same99 transport that101 will open;there is no extra registration scope.
    uiFixture.scope.api.Close();local events={listen=function(...)return r.api.Transport.Events.listen(...)end,remove=function(...)return r.api.Transport.Events.remove(...)end}
    p.events=events;p.prCore=unit.ioFixture.core;p.library=r.seed.Library.Library;p.public=unit.public
    r.uiAssembly=uiFixture.factory(p);r.originalContext=r.bootstrapPorts.context
    r.bootstrapPorts.context=T.binder.Client(r.originalContext,r.configAssembly,r.uiAssembly)
    local env=H.environment();local modules={};env.print=function()end;env.type=r.fixture.modules.Stores.environment().type
    env.require=function(name)if not modules[name]then modules[name]=H.load(name:gsub('%.','/')..'.lua',env)end;return modules[name]end
    r.bootstrapFactory=H.load('kernel/entry/client_bootstrap.lua',env)
    return r
end
return T
