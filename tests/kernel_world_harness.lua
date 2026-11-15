-- Whole installed world/weather/density counterparts, actual PR adapters/cache/JSON, virtual effects only.
local S=dofile('tests/kernel_server_settings_harness.lua')
local Cache=dofile('tests/cache_harness.lua')
local H,P=S.H,S.P
local R={H=H,P=P,env=S.env,Cache=Cache}
R.domains={'stores','objects','npcs','density','vinewood','starterpack','farms','billboards','characterPreviews','spotlights'}
R.densityNatives={'EnableDispatchService','SetPedPopulationBudget','SetVehiclePopulationBudget','RemoveVehiclesFromGeneratorsInArea',
    'SetScenarioTypeEnabled','SetVehicleModelIsSuppressed','SetScenarioGroupEnabled','SetParkedVehicleDensityMultiplierThisFrame',
    'SetVehicleDensityMultiplierThisFrame','SetRandomVehicleDensityMultiplierThisFrame','SetPedDensityMultiplierThisFrame','SetScenarioPedDensityMultiplierThisFrame'}
function R.config(ported)
    if ported then return{Weather=H.load('kernel/config/forge_weather.lua',R.env())(),
        Density=H.load('kernel/config/forge_density.lua',R.env())(),AdminAce='forge-core.admin',NotifyPos='top-right'}end
    local e=H.environment({PR={}})
    H.load('shared/weather.lua',e);H.load('shared/density.lua',e)
    e.PR.AdminAce='forge-core.admin';e.PR.NotifyPos='top-right';return e.PR
end
function R.world(ported,server,library)
    local r=Cache.new(server);local e=r.env
    e.os={time=function()return 1792483200 end}
    local function record(k,...)r.trace[#r.trace+1]={kind=k,args=P.snapshot(table.pack(...))}end
    r.record=record;r.trace={}
    local trigger=e.TriggerEvent
    e.TriggerEvent=function(n,...)record('local-event',n,...);return trigger(n,...)end
    local native={time=e.os.time,source=function()return e.source end}
    for _,n in ipairs({'GetGameTimer','CreateThread','Wait','SetTimeout','TriggerEvent','TriggerClientEvent'})do native[n]=e[n]end
    r.native=native
    if library then library.cache=e.pr_lib.cache;library.callback=e.pr_lib.callback;e.pr_lib=library end
    r.library=e.pr_lib
    if ported then
        r.library.cache.set('forge-core:world:density',{data={retained=true}})
        r.api=H.load('kernel/shared/world_state.lua',R.env())({library=r.library,native=native,server=server})
        assert(#r.queue==0 and #r.trace==0 and next(r.events)==nil and next(r.callbacks)==nil and next(r.exported)==nil,'inactive world constructor')
        assert(r.library.cache.get('forge-core:world:density').data.retained,'constructor must not clear a preexisting cache')
        assert(r.api.Initialize() and not r.api.Initialize(),'explicit idempotent world initialization')
        assert(r.library.cache.get('forge-core:world:density')==nil,'only explicit Initialize clears world namespace')
        r.state=r.api.State
        for _,d in ipairs(r.api.Events)do e.AddEventHandler(d.name,d.handler)end
        for _,d in ipairs(r.api.Callbacks)do r.callbacks[d.name]=d.handler end
        for n,fn in pairs(r.api.Exports)do r.exported[n]=fn end
        r.initial=r.api.Threads
    else
        local thread=e.CreateThread;r.initial={}
        e.CreateThread=function(fn)r.initial[#r.initial+1]=fn end
        H.load('shared/cache.lua',e);e.CreateThread=thread;r.state=e.ForgeCore.State
    end
    r.trace={}
    return r
end
function R.adapter(r)
    r.weatherData={weather={weather='CLEAR'},currentTime={hour=12,minute=0},timeScale=2000,freezeTime=false,blackOut=false}
    r.weatherList={{weather='CLEAR',time=10},{weather='RAIN',time=20}}
    r.exportOverrides={};r.resource='started'
    local exports={}
    setmetatable(exports,{__index=function(_,resource)
        assert(resource=='Renewed-Weathersync')
        return setmetatable({},{__index=function(_,name)return function(...)
            r.record('weather-export',name,...)
            local fn=r.exportOverrides[name];if fn then return fn(...)end
            if name=='GetWeatherList'then return H.copy(r.weatherList)end
            if name=='GetSnapshot'then return H.copy(r.weatherData)end
            if name=='SetWeatherType'then r.weatherData.weather.weather=select(2,...);return true end
            if name=='SetTime'then r.weatherData.currentTime={hour=(...),minute=select(2,...)};return H.copy(r.weatherData.currentTime)end
            if name=='SetTimeScale'then r.weatherData.timeScale=(...);return(...)end
            if name=='SetFreezeTime'then r.weatherData.freezeTime=(...);return(...)end
            return true
        end end})
    end})
    local e=H.environment({exports=exports,ActiveBridges={weather='default'},GetResourceState=function(name)
        r.record('weather-resource',name);return r.resource end,AddEventHandler=function()error('Unexpected weather subscription')end})
    return H.load('../pr_bridge/bridge/weather/renewed/server.lua',e)
end
function R.new(ported)
    local m=S.J.persistence()
    local r=R.world(ported,true,m.api)
    r.m=m;r.config=R.config(ported);r.jobResult=true;r.ace=true;r.callbacks={}
    r.native.GetCurrentResourceName=function()return'forge-core'end
    r.native.IsPlayerAceAllowed=function(src,ace)r.record('ace',src,ace);return r.ace end
    r.native.joaat=function(s)return 'hash:'..tostring(s):lower()end
    r.native.GetEntityModel=function(handle)return r.models and r.models[handle]end
    r.native.CancelEvent=function()r.record('cancel-entity')end
    r.services={JobService={canManage=function(src)r.record('job-access',src);if r.jobError then error('fixture-job',0)end;return r.jobResult end}}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    r.library.debug={};for _,level in ipairs({'success','error','warn'})do r.library.debug[level]=function(...)r.record('log-'..level,...)end end
    r.library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    r.library.weather=R.adapter(r)
    r.m.seed(r.config.Density.Storage.file,H.copy(r.config.Density.Defaults))
    local e=H.environment({PR=r.config,ForgeCore=r.services,pr_lib=r.library})
    for n,fn in pairs(r.native)do e[n]=fn end
    e.ForgeCore.State=r.state;e.ForgeCore.t=r.translate
    e.ForgeCore.Callbacks={register=function(n,fn)r.callbacks[n]=fn end}
    local function listen(n,fn)r.env.AddEventHandler(n,fn)end
    e.AddEventHandler=listen
    if ported then
        local ports={config=r.config,library=r.library,native=r.native,services=r.services,translate=r.translate,world=r.state}
        r.weather=H.load('kernel/server/weather.lua',R.env())(ports)
        r.density=H.load('kernel/server/density.lua',R.env())(ports)
        r.w,r.d=r.weather.Service,r.density.Service
        for _,d in ipairs(r.weather.Callbacks)do assert(d.options.access=='admin');r.callbacks[d.name]=d.handler end
        for _,d in ipairs(H.load('kernel/server/density_callbacks.lua',R.env())({config=r.config,service=r.d}))do
            assert(d.options.access=='admin');r.callbacks[d.name]=d.handler end
        for _,d in ipairs(r.density.Events)do listen(d.name,d.handler)end
    else
        H.load('server/weather/callbacks.lua',e);H.load('server/density/service.lua',e);H.load('server/density/callbacks.lua',e)
        r.w,r.d=e.ForgeCore.WeatherService,e.ForgeCore.DensityService
    end
    assert(#r.trace==0 and #r.m.trace==0 and not r.d.started,'no automatic weather/density IO/start')
    r.trace={};r.m.trace={};return r
end
function R.outcome(fn,r)return S.outcome(fn,r)end
function R.case(name,fn)
    local a,b=R.new(false),R.new(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(b.m.trace,a.m.trace,name..' IO')
    H.same(P.snapshot({b.d,b.state.getRecord('density'),b.m.files}),P.snapshot({a.d,a.state.getRecord('density'),a.m.files}),name..' state')
end
function R.client(ported)
    local r=R.world(ported,false);r.config=R.config(ported);r.value=nil;r.threads={}
    local world={peek=function(key)assert(key=='density');return r.value end}
    for _,n in ipairs(R.densityNatives)do r.native[n]=function(...)r.record(n,...)end end
    r.native.joaat=function(s)return 'hash:'..tostring(s):lower()end
    if ported then
        r.density=H.load('kernel/client/density.lua',R.env())({config=r.config,native=r.native,world=world})
        r.threads=r.density.Threads
    else
        local e=H.environment({PR=r.config,ForgeCore={State=world,Client={}},CreateThread=function(fn)r.threads[#r.threads+1]=fn end})
        for n,fn in pairs(r.native)do if n~='CreateThread'then e[n]=fn end end
        H.load('client/density/main.lua',e)
    end
    assert(#r.threads==2 and #r.trace==0 and #r.queue==0,'unstarted frame/long workers')
    r.cos={coroutine.create(r.threads[1]),coroutine.create(r.threads[2])}
    function r.tick(index)local ok,ms=coroutine.resume(r.cos[index or 1]);assert(ok,ms);return ms end
    return r
end
function R.clientCase(name,fn)
    local a,b=R.client(false),R.client(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return');H.same(b.trace,a.trace,name..' effects')
end
function R.menu(ported)
    local r=S.menu(ported);local config=R.config(ported)
    r.config.Weather,r.config.Density=config.Weather,config.Density
    r.densitySettings=H.copy(config.Density.Defaults)
    local await=r.library.callback.await
    r.library.callback.await=function(name,timeout,...)
        if name~=r.config.Density.Callbacks.getSettings and name~=r.config.Density.Callbacks.saveSettings then return await(name,timeout,...)end
        assert(timeout==10000);r.record('await-density',name,timeout,...)
        if r.densityHook then return r.densityHook(name,...)end
        if name==r.config.Density.Callbacks.getSettings then return true,H.copy(r.densitySettings)end
        r.densitySettings=H.copy((...));return true,H.copy(r.densitySettings)
    end
    r.weatherIntegration={resourceState=r.panelIntegration.resourceState,openWeatherAdmin=r.panelIntegration.openAdminMenu}
    if ported then
        local ports={config=r.config,menu=r.menu,shared=r.shared,native=r.native,weatherAdminIntegration=r.weatherIntegration}
        H.load('kernel/client/menu/weather.lua',R.env())(ports);H.load('kernel/client/menu/density.lua',R.env())(ports)
    else
        r.env.exports=setmetatable({},{__index=function(_,resource)return{
            OpenAdminMenu=function(_,...)return r.panelIntegration.openAdminMenu(resource,...)end,
            OpenWeatherAdmin=function(_,...)return r.weatherIntegration.openWeatherAdmin(resource,...)end}end})
        H.load('client/menu/menu_weather.lua',r.env);H.load('client/menu/menu_density.lua',r.env)
    end
    r.trace={};return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts');H.same(b.densitySettings,a.densitySettings,name..' settings')
end
return R
