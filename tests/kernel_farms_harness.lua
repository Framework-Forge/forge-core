-- Installed Farms vs private ports. PR persistence/cache/context/OX adapter execute; provider, native and transport effects virtual.
local S=dofile('tests/kernel_stores_harness.lua')
local V,H,P,W=S.V,S.H,S.P,S.W
local R={S=S,V=V,H=H,P=P,W=W,env=S.env,environment=S.environment,vector=S.vector}
function R.config(ported)
    local trace={};local translate=function(k)trace[#trace+1]=k;return k end
    local config
    if ported then config=H.load('kernel/config/forge_farms.lua',R.env())({vec3=R.vector,translate=translate})
    else local e=H.environment({PR={},ForgeCore={t=translate},vec3=R.vector});H.load('shared/farms.lua',e);config=e.PR.Farms end
    return config,trace
end
function R.seed()
    return{settings={enabled=true},nextFarmId=2,usage={},farms={{id=1,name='Farm',enabled=true,public=true,groupType='job',groupName='',minGrade=0,
        start={coords={x=1,y=2,z=3},rotation=90,label='Farm'},items={{id='crop',label='Crop',reward='burger',enabled=true,min=2,max=2,collectTime=1000,
        randomRoute=false,unlimited=false,required={item='token',durability=10,vehicle=''},limits={enabled=false,scope='item',maxPerRoute=0,cooldownMinutes=0,onceDaily=false},
        animation={mode='preset',preset='pickup'},points={{x=10,y=20,z=30},{x=11,y=20,z=30}},extraItems={{item='water',min=1,max=1}}}}}}}
end
function R.random(r)
    r.math=H.copy(math)
    r.math.random=function(lo,hi)r.record('random',lo,hi);return r.randomHigh and hi or lo end
end
function R.inventory(r)
    S.ox(r)
    local search=r.ox.Search
    function r.ox:Search(src,kind,name)
        if kind=='count'then return search(self,src,kind,name)end
        assert(kind=='slots');r.record('search-slots',src,name)
        if r.searchError then error('fixture-search',0)end
        if r.searchResult~=nil then return r.searchResult end
        local out={};for _,item in pairs(r.items[src]or{})do if item.name==name and item.count>0 then out[#out+1]=item end end
        return out
    end
    function r.ox:SetDurability(src,slot,durability)
        r.record('durability',src,slot,durability);if r.durabilityError then error('fixture-durability',0)end
        for _,item in pairs(r.items[src]or{})do if item.slot==slot then item.metadata=item.metadata or{};item.metadata.durability=durability end end
        return r.durabilityResult
    end
    r.inventoryIntegration.searchSlotsRaw=function(src,name)return r.ox:Search(src,'slots',name)end
    r.inventoryIntegration.setDurabilityRaw=function(...)return r.ox:SetDurability(...)end
end
function R.new(ported)
    local r=V.new(ported);r.config.Farms=R.config(ported);r.callbacks={};r.farmEvents={}
    R.inventory(r);S.players(r);R.random(r)
    r.clock={time=function()return r.seconds or 1792530000 end,date=function()return r.date or'2026-10-21'end}
    r.native.vec3=R.vector
    r.native.GetPlayerIdentifierByType=function(src,kind)r.record('identifier-type',src,kind);if not r.noIdentifierType then return'license:'..src end end
    r.native.GetPlayerIdentifier=function(src,index)r.record('identifier',src,index);if not r.noIdentifier then return'license-fallback:'..src end end
    r.vehicles={adder={model='adder',name='Adder',brand='Truffade',category='super'}};r.coreState='started'
    r.kernel={GetPlayerData=r.player.GetPlayerData,resourceState=function()r.record('core-ready');return r.coreState end,
        getVehiclesByName=function()r.record('vehicle-catalog');if r.vehicleError then error('fixture-vehicles',0)end;return r.vehicles end}
    r.services.JobRegistry={list=function(kind)r.record('group-list',kind);return{{name=kind=='gang'and'ballas'or'police',label='Group'}}end}
    r.m.seed(r.config.Farms.Storage.file,R.seed())
    if ported then
        r.boundary=H.load('kernel/server/farms.lua',R.env())({config=r.config,library=r.library,native=r.native,clock=r.clock,math=r.math,
            services=r.services,world=r.state,translate=r.translate,kernel=r.kernel,inventoryIntegration=r.inventoryIntegration})
        r.service=r.boundary.Service;r.farmEvents=r.boundary.Events
        for _,d in ipairs(H.load('kernel/server/farms_callbacks.lua',R.env())({config=r.config,service=r.service}))do r.callbacks[d.name]=d.handler end
    else
        r.library.framework=r.player
        local e=H.environment({PR=r.config,ForgeCore=r.services,pr_lib=r.library,os=r.clock,math=r.math,source=false,print=function()end})
        for n,fn in pairs(r.native)do e[n]=fn end
        e.AddEventHandler=function(n,fn)r.farmEvents[#r.farmEvents+1]={name=n,handler=function(src)e.source=src;fn()end,sourceFirst=true}end
        e.GetResourceState=function(name)if name=='ox_inventory'then return r.inventoryIntegration.resourceState()end;assert(name=='qbx_core');return r.kernel.resourceState()end
        e.exports={ox_inventory=r.ox,qbx_core={GetVehiclesByName=function()return r.kernel.getVehiclesByName()end}}
        r.services.Callbacks={register=function(n,fn)r.callbacks[n]=fn end}
        H.load('server/farms/service.lua',e);H.load('server/farms/callbacks.lua',e);r.service=r.services.FarmsService
    end
    assert(#r.farmEvents==1 and not r.service.started and #r.trace==0 and #r.m.trace==0,'inert farm server')
    function r.drop(src)r.farmEvents[1].handler(src)end
    function r.stateSnapshot()return P.snapshot({r.service,r.state.getRecord('farms'),r.m.files,r.items})end
    return r
end
function R.case(name,fn,noStart)
    local a,b=R.new(false),R.new(true)
    local function action(r)if not noStart then r.service.start()end;return fn(r)end
    H.same(V.outcome(action,b),V.outcome(action,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(b.m.trace,a.m.trace,name..' persistence');H.same(b.stateSnapshot(),a.stateSnapshot(),name..' state')
end
function R.platform(r)
    S.platform(r);R.random(r)
    r.native.vector3=R.vector;r.player.GetPlayerData=function()return r.playerData end
    r.playerData.job={name='police',grade={level=2}};r.playerData.gang={name='ballas',grade={level=1}}
    r.dynamicThreads={};r.contexts={};r.progressResult=true;r.animLoaded=true;r.inVehicle=false;r.lastVehicle=0
    r.native.CreateThread=function(fn)r.dynamicThreads[#r.dynamicThreads+1]=fn end
    r.native.Wait=function(ms)r.record('wait',ms);r.now=r.now+math.max(ms,1000);return coroutine.yield(ms)end
    r.native.SetBlipRoute=function(...)r.record('blip-route',...)end
    r.native.AddTextComponentString=function(...)r.record('blip-name',...)end
    r.native.PlayerPedId=function()return 42 end
    r.native.RequestAnimDict=function(...)r.record('anim-request',...)end
    r.native.HasAnimDictLoaded=function()return r.animLoaded end
    r.native.IsPedUsingScenario=function()return r.usingScenario==true end
    r.native.IsEntityPlayingAnim=function()return r.playingAnim==true end
    for _,n in ipairs({'TaskStartScenarioInPlace','TaskPlayAnim','ClearPedTasks'})do r.native[n]=function(...)r.record(n,...)end end
    r.native.IsPedInAnyVehicle=function()return r.inVehicle end
    r.native.GetVehiclePedIsIn=function()return r.lastVehicle end
    r.native.IsVehicleModel=function(_,model)return model==r.vehicleModel end
    r.native.joaat=function(model)return'hash:'..tostring(model):lower()end
    r.library.inventory={GetItemLabel=function(name)return name..'-label'end}
    r.library.progressBar=function(data)
        r.record('progress',data);if r.progressError then error('fixture-progress',0)end
        if r.progressHook then return r.progressHook(data)end;return r.progressResult
    end
    r.library.menus={RegisterContext=function(data)r.contexts[data.id]=data;r.last=data;r.record('context',data)end,
        ShowContext=function(id)r.record('show',id)end}
end
function R.bindClient(r,ported)
    r.value=nil;r.initial={};r.subscriptions={};r.farmEvents={}
    r.world={get=function(key)assert(key=='farms');return r.value end}
    if ported then
        r.runtime=H.load('kernel/client/farms.lua',R.environment())({config=r.config,library=r.library,native=r.native,math=r.math,
            world=r.world,translate=r.translate,player=r.player})
        r.farms=r.runtime.Farms;r.initial=r.runtime.Threads;r.subscriptions=r.runtime.Subscriptions;r.farmEvents=r.runtime.Events
    else
        r.library.framework=r.player
        local e=R.environment();e.PR=r.config;e.pr_lib=r.library;e.math=r.math;e.ForgeCore={Client={},State=r.world,t=r.translate}
        for n,fn in pairs(r.native)do e[n]=fn end
        e.CreateThread=function(fn)
            -- The installed source creates the hydration worker at top level, animation work only after a user action.
            if not r.boundClient then r.initial[#r.initial+1]=fn else r.native.CreateThread(fn)end
        end
        e.AddEventHandler=function(n,fn)r.farmEvents[#r.farmEvents+1]={name=n,handler=fn,network=false}end
        e.RegisterNetEvent=function(n,fn)r.farmEvents[#r.farmEvents+1]={name=n,handler=fn,network=true}end
        r.world.onChange=function(key,fn)r.subscriptions[#r.subscriptions+1]={key=key,handler=fn}end
        H.load('client/farms/main.lua',e);r.farms=e.ForgeCore.Client.Farms
    end
    r.boundClient=true
    assert(#r.initial==1 and #r.subscriptions==1 and #r.farmEvents==3 and not r.farms.active)
    function r.apply(payload)r.value=payload;r.subscriptions[1].handler(payload)end
    function r.fireFarm(name,...)for _,d in ipairs(r.farmEvents)do if d.name==name then d.handler(...)end end end
end
function R.client(ported)
    local r=W.world(ported,false);r.config={Farms=R.config(ported),NotifyPos='top-right'}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    R.platform(r);r.library.callback.await=function(name,timeout,...)
        assert(timeout==(name==r.config.Farms.Callbacks.finishRoute and 5000 or 10000));r.record('farm-rpc',name,timeout,...)
        if r.rpcHook then return r.rpcHook(name,...)end
        if name==r.config.Farms.Callbacks.collect then return true,{item='burger',count=2,label='Burger'}end
        return true,{active=true}
    end
    R.bindClient(r,ported)
    assert(#r.trace==0 and #r.dynamicThreads==0,'inert farm client')
    function r.start()
        r.apply(R.seed());r.targets[r.farms.zones[1]].options[1].onSelect();r.last.options[1].onSelect()
    end
    function r.collect(index)r.targets[r.farms.routeZones[index or 1]].options[1].onSelect()end
    function r.run(fn)local co=coroutine.create(fn);local ok,v=coroutine.resume(co);assert(ok,v);return co,v end
    function r.resume(co)local ok,v=coroutine.resume(co);assert(ok,v);return v end
    return r
end
function R.clientCase(name,fn)
    local a,b=R.client(false),R.client(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot({b.farms,b.targets,b.blips,b.contexts}),P.snapshot({a.farms,a.targets,a.blips,a.contexts}),name..' client state')
    assert(#a.dynamicThreads==#b.dynamicThreads,'animation worker count')
end
function R.menu(ported)
    local r=S.menu(ported);r.config.Farms=R.config(ported);r.farmPayload=R.seed();r.farmRefreshes={}
    r.farms={refresh=function(p)r.record('farm-refresh',p);r.farmRefreshes[#r.farmRefreshes+1]=H.copy(p)end}
    local parent=r.library.callback.await
    r.library.callback.await=function(name,timeout,...)
        if not name:find(':farms:',1,true)then return parent(name,timeout,...)end
        assert(timeout==10000);r.record('farms-rpc',name,timeout,...)
        if r.farmRpcHook then return r.farmRpcHook(name,...)end
        if name==r.config.Farms.Callbacks.getAll then return true,H.copy(r.farmPayload)end
        if name==r.config.Farms.Callbacks.getGroups then return true,{{name='police',label='Police'}}end
        if name==r.config.Farms.Callbacks.getItems then return true,{{name='burger',label='Burger'},{name='water',label='Water'},{name='token',label='Token'}}end
        if name==r.config.Farms.Callbacks.getVehicles then return true,{{model='adder',label='Adder'}}end
        return true,H.copy(r.farmPayload)
    end
    if ported then r.farmMenu=H.load('kernel/client/menu/farms.lua',R.env())({config=r.config,library=r.library,native=r.native,menu=r.menu,shared=r.shared,farms=r.farms})
    else r.env.ForgeCore.Client.Farms=r.farms;H.load('client/menu/menu_farms.lua',r.env)end
    r.trace={};return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts');H.same(b.farmRefreshes,a.farmRefreshes,name..' refresh')
    assert(#a.dynamicThreads==#b.dynamicThreads,'capture worker count')
end
return R
