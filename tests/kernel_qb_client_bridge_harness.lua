local D=dofile('tests/kernel_qb_client_events_harness.lua');local H,P=D.H,D.P
local T={D=D,H=H,P=P}
function T.environment()
    local env=H.environment();local loaded={}
    env.require=function(name)
        assert(name:sub(1,7)=='kernel.','only private kernel imports')
        if not loaded[name]then loaded[name]=H.load(name:gsub('%.','/')..'.lua',env)end
        return loaded[name]
    end
    env.string.strsplit=D.T.V.strsplit
    return env
end
function T.new(ported,setting)
    local r=D.new(true);r.trace={};r.events={};r.exported={};r.current=true;r.ready=true
    r.native.GetConvar=function(key,fallback)assert(key=='qbx:enablebridge');return setting or fallback end
    r.native.TriggerServerEvent=function(...)r.record('server',...);if r.serverHook then return r.serverHook(...)end end
    r.library.table.merge=function(a,b)local out=H.copy(a);for k,v in pairs(b)do out[k]=H.copy(v)end;return out end
    r.library.string={random=function(pattern)return pattern end}
    r.library.print.debug=function(...)r.record('debug',...)end
    r.state.Shared={Vehicles={},VehicleHashes={},Weapons={},Locations={}}
    r.jobs={taxi={label='Taxi'}};r.gangs={none={label='None'}}
    r.configs={Client=r.config,Shared={starterItems={{name='id',amount=1}},defaultSpawn={x=1,y=2,z=3},notifyPosition='center-left'}}
    r.backend={Core={GetPlayerData=function()return r.state.PlayerData end,Notify=function(...)r.record('notify',...)end,
        GetJobs=function()return r.jobs end,GetGangs=function()return r.gangs end},State=r.state,Shared=r.state.Shared,
        Helpers=r.helpers,NativeCache=r.cache,Config=r.configs,IsCurrent=function()return r.current and not r.backendClosed end,
        Close=function()r.backendClosed=true end,Progress=function()return{phase=r.backendClosed and'closed'or'open',pending=0,complete=r.backendClosed==true}end}
    r.ports={native=r.native,library=r.library,inventory={search=function(...)r.record('search',...);return r.searchResult end},
        scheduler=r.scheduler,isCurrent=function()return r.current end,isReady=function()if r.readyHook then r.readyHook()end;return r.ready end}
    local env=T.environment();r.env=env
    if ported then
        r.api=H.load('kernel/compat/qb/client_main.lua',env)(r.backend,r.ports)
        r.object=r.api.Enabled and r.api.GetCoreObject()or nil;r.exported=r.api.Exports
        for _,d in ipairs(r.api.Events)do r.events[d.name]=d end
    else
        for name,fn in pairs(r.native)do env[name]=fn end
        env.QBX=r.state;env.qbx=r.helpers;env.lib=r.library;env.cache=r.cache
        env.CreateThread=r.scheduler.createThread;env.Wait=r.scheduler.wait
        env.exports={ox_inventory={Search=function(_,...)return r.ports.inventory.search(...)end},
            qbx_core={Notify=function(_,...)return r.backend.Core.Notify(...)end}}
        env.GetJobs=r.backend.Core.GetJobs;env.GetGangs=r.backend.Core.GetGangs
        env.RegisterNetEvent=function(name,fn)assert(not r.events[name]);r.events[name]={name=name,handler=fn,network=true}end
        env.require=function(name)
            if name=='config.client'then return r.configs.Client
            elseif name=='config.shared'then return r.configs.Shared
            elseif name=='shared.main'then return r.state.Shared
            elseif name=='client.functions'then return true
            elseif name=='bridge.qb.shared.export-function'then return function(name,fn)assert(not r.exported[name]);r.exported[name]=fn end
            elseif name=='bridge.qb.client.functions'then return assert(load(D.T.dialect(P.source('bridge/qb/client/functions.lua')),'@qb_client_functions','t',env))()
            elseif name=='bridge.qb.shared.main'or name=='bridge.qb.client.drawtext'or name=='bridge.qb.client.events'then
                return P.loadOrigin(name:gsub('%.','/')..'.lua',env)
            end
            error(name)
        end
        P.loadOrigin('bridge/qb/client/main.lua',env)
        r.object=r.exported.GetCoreObject and r.exported.GetCoreObject()or nil
        r.api={Enabled=r.object~=nil,GetCoreObject=r.exported.GetCoreObject}
    end
    return r
end
function T.runtime()
    local L=dofile('tests/kernel_client_locale_harness.lua');local r=L.new();r.prepareLocale()
    local stub=D.new(true);local state=r.fixture.state
    local sharedConfig=H.load('kernel/config/shared.lua',H.environment())({vec4=stub.native.vec4})
    r.qbCurrent=true;r.qbReady=true
    r.qbBackendPorts={sharedConfig=sharedConfig,isCurrent=function()return r.qbCurrent and r.api.IsCurrent()end,
        isReady=function()if r.backendReadyHook then r.backendReadyHook()end;return r.qbReady end}
    local backend=H.load('kernel/client/qb_compat_backend.lua',H.environment())(r.graph,r.qbBackendPorts)
    stub.library.table.merge=function(a,b)local out=H.copy(a);for k,v in pairs(b)do out[k]=H.copy(v)end;return out end
    stub.library.string={random=function(pattern)return pattern end}
    stub.library.print.debug=function(...)stub.record('debug',...)end
    stub.native.GetConvar=function(_,fallback)return fallback end
    stub.native.TriggerServerEvent=function(...)stub.record('server',...)end
    r.qbPorts={native=stub.native,library=stub.library,inventory={search=function(...)stub.record('search',...);return stub.searchResult end},
        scheduler=stub.scheduler,isCurrent=r.qbBackendPorts.isCurrent,isReady=function()if r.bridgeReadyHook then r.bridgeReadyHook()end;return r.qbReady end}
    r.qbBackend=backend;r.qb=H.load('kernel/compat/qb/client_main.lua',T.environment())(backend,r.qbPorts);r.stub=stub
    function r.closeQb()r.qb.Close();r.api.Stop();r.clock.advance(120000);r.api.Poll()end
    return r
end
return T
