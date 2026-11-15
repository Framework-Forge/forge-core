-- Strict flow reference/port. Cfx, PR, UI, resources and time are doubles.
local P=dofile('tests/kernel_player_harness.lua')
local H=P.H
local F={P=P,H=H}
local hostLoad=load
local methods={'characterDialog','checkStrings','capString','openFirstCharacterAppearance',
    'spawnDefault','spawnLastLocation','createCharacter','chooseCharacter'}
F.methods=methods
function F.split(delimiter,value)
    local out,start={},1
    while true do
        local first,last=value:find(delimiter,start,true)
        if not first then out[#out+1]=value:sub(start);break end
        out[#out+1]=value:sub(start,first-1);start=last+1
    end
    return table.unpack(out)
end
function F.character(cid,id)
    return {citizenid=id or 'A',charinfo={cid=cid,firstname='Hank',lastname='Jordan',
        gender=0,birthdate='1990-01-01',nationality='Brazilian',account='BANK1',phone='555'},
        money={bank=500,cash=50},job={label='Taxi',grade={name='Driver'}},
        gang={label='None',grade={name='None'}}}
end
function F.new(ported,configure)
    local r={trace={},events={},threads={},menus={},dialogs={},dialogIndex=0,now=0,waits=0,
        cache={ped=10,playerId=7},playerPed=10,fadedOut=true,fadedIn=true,tutorial=false,
        networkStarted=true,loadResult=true,deleteResult=true,buildResult=true,
        characters={F.character(2,'A')},amount=3,payload={settings={requireItem=true},unlocked={[1]=true}},
        resources={['forge-loadscreen']='started',['illenium-appearance']='started',
            qbx_spawn='started',qbx_apartments='missing'},alert='confirm',randomIndex=0,
        randomValues={1},previewConfigured=false,spawnResult=true,minimumMs=0}
    r.defaultSpawn={x=1,y=2,z=3,w=45}
    r.config={loadingModelsTimeout=30000,characters={useExternalCharacters=false,
        limitNationalities=true,previewCameraDistance=3.2,enableDeleteButton=true,
        startingApartment=false,dateFormat='YYYY-MM-DD',dateMin='1900-01-01',dateMax='2006-12-31',
        profanityWords={bad=true,['bad word']=true},locations={
            {pedCoords={x=5,y=6,z=7,w=90},camCoords={x=8,y=9,z=10,w=45}},
            {pedCoords={x=15,y=16,z=17,w=180},camCoords={x=18,y=19,z=20,w=135}}}}}
    r.core={PlayerData={citizenid='A',position={x=50,y=60,z=70,w=80},metadata={inside={property_id=42}}},
        BridgeCache={refreshContext=function(reason) r.record('refreshContext',reason) end}}
    r.nationalities={'American','Brazilian','Nigerian','Nigerian'}
    function r.record(kind,...) r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))} end
    local function effect(name) return function(...) r.record(name,...) end end
    local n={}
    n.GetResourceState=function(name)
        r.record('GetResourceState',name)
        if r.resourceHook then local result=r.resourceHook(name);if result then return result end end
        return r.resources[name] or 'missing'
    end
    n.GetInvokingResource=function() r.record('GetInvokingResource');return r.invoking end
    n.GetCurrentResourceName=function() r.record('GetCurrentResourceName');return 'forge-core' end
    n.IsScreenFadedIn=function() r.record('IsScreenFadedIn');return r.fadedIn end
    n.IsScreenFadedOut=function() r.record('IsScreenFadedOut');return r.fadedOut end
    n.PlayerPedId=function() r.record('PlayerPedId');return r.playerPed end
    n.NetworkStartSoloTutorialSession=function()
        r.record('NetworkStartSoloTutorialSession')
        if not r.holdTutorial then r.tutorial=true end
        if r.tutorialYield then coroutine.yield('tutorial pending') end
    end
    n.NetworkIsInTutorialSession=function() r.record('NetworkIsInTutorialSession');return r.tutorial end
    n.NetworkIsSessionStarted=function() r.record('NetworkIsSessionStarted');return r.networkStarted end
    n.Wait=function(ms)
        r.record('Wait',ms);r.waits=r.waits+1
        assert(r.waits<=1000,'Bounded simulated wait limit')
        r.now=r.now+(ms==0 and 100 or ms)
        if r.onWait then r.onWait(ms) end
        if coroutine.isyieldable() then return coroutine.yield(ms) end
    end
    for _,name in ipairs({'DisplayRadar','DoScreenFadeIn','DoScreenFadeOut','FreezeEntityPosition',
        'SetEntityCollision','SetEntityCoords','SetEntityHeading','SetEntityInvincible','SetEntityVisible',
        'SetFollowPedCamViewMode','SetTimecycleModifier','ShutdownLoadingScreen','ShutdownLoadingScreenNui'}) do
        n[name]=effect(name)
    end
    local function emit(name,...)
        r.record('local',name,...)
        if r.dispatchLocal then for _,event in ipairs(r.events) do
            if event.name==name then event.handler(...) end
        end end
    end
    n.TriggerEvent=emit
    n.TriggerServerEvent=function(name,...) r.record('server',name,...) end
    local integrations={
        deferForAppearance=function() return emit('space_spawn:client:deferForAppearance') end,
        openFirstCharacterAppearance=function() return emit('qb-clothes:client:CreateFirstCharacter') end,
        setHouseInside=function(...) return n.TriggerServerEvent('qb-houses:server:SetInsideMeta',...) end,
        setApartmentInside=function(...) return n.TriggerServerEvent('qb-apartments:server:SetInsideMeta',...) end,
        enterProperty=function(...) return n.TriggerServerEvent('ps-housing:server:enterProperty',...) end,
        setupApartmentSpawn=function(...) return emit('apartments:client:setupSpawnUI',...) end,
        setupSpawns=function(...) return emit('qb-spawn:client:setupSpawns',...) end,
        openSpawnUI=function(...) return emit('qb-spawn:client:openUI',...) end,
        enableWeatherSync=function() return emit('qb-weathersync:client:EnableSync') end,
        spawnPlayer=function(data)
            r.record('spawnPlayer',data)
            if r.spawnError then error('spawn failed',0) end
            return r.spawnResult
        end,
        setAutoSpawn=function(value)
            r.record('setAutoSpawn',value)
            if r.autoSpawnError then error('auto spawn failed',0) end
        end,
        finishLoadingScreen=function()
            r.record('FinishLoadingScreen')
            if r.loadingError then error('loading provider failed',0) end
            while r.now<r.minimumMs do n.Wait(math.min(1000,r.minimumMs-r.now)) end
            r.loadingClosedAt=r.now
            return r.loadingResult
        end,
    }
    local ui={}
    ui.inputDialog=function(...)
        r.record('inputDialog',...);r.lastDialog=table.pack(...)
        r.dialogIndex=r.dialogIndex+1
        if r.inputYield then coroutine.yield('input pending') end
        return H.copy(r.dialogs[r.dialogIndex])
    end
    ui.registerContext=function(data) r.record('registerContext',data);r.menus[data.id]=data end
    ui.showContext=function(id) r.record('showContext',id);r.shown=id;r.shownAt=r.now end
    ui.alertDialog=function(...) r.record('alertDialog',...);return r.alert end
    local callbacks={}
    callbacks.await=function(name,...)
        r.record('callback',name,...)
        if r.callbackHook then return r.callbackHook(name,...) end
        if r.callbackYield==name then coroutine.yield('callback pending') end
        if name=='qbx_core:server:getCharacters' then return H.copy(r.characters),r.amount,H.copy(r.payload)
        elseif name=='qbx_core:server:createCharacter' then return H.copy(r.createData),r.createError
        elseif name=='qbx_core:server:loadCharacter' then return r.loadResult
        elseif name=='qbx_core:server:deleteCharacter' then return r.deleteResult
        elseif name=='qbx_core:server:getPreviewPedData' then return nil,nil end
        error('Unexpected callback '..tostring(name))
    end
    local renderer={}
    for _,name in ipairs({'previewPed','destroyPreviewCam','setupPreviewCam','focusConfiguredPreview','showConfiguredOverview'}) do
        renderer[name]=function(...)
            r.record(name,...)
            if name=='destroyPreviewCam' then r.setConfigured(false) end
        end
    end
    renderer.IsConfigured=function() return r.previewConfigured end
    renderer.configuredPreviewLocations=function(payload)
        return type(payload)=='table' and type(payload.previews)=='table' and payload.previews or {}
    end
    renderer.buildConfiguredPreviews=function(...)
        r.record('buildConfiguredPreviews',...)
        r.setConfigured(r.buildResult)
        return r.buildResult
    end
    renderer.configuredOverview=function() r.record('configuredOverview');return r.overview end
    r.overview={x=21,y=22,z=23,heading=24}
    r.native=n;r.ui=ui;r.callbacks=callbacks;r.integrations=integrations;r.renderer=renderer
    r.notify=effect('Notify')
    r.locale=function(key,...) local args={...};return key..(#args>0 and ':'..table.concat(args,',') or '') end
    r.random=function(low,high)
        r.record('random',low,high);r.randomIndex=r.randomIndex+1
        return r.randomValues[(r.randomIndex-1)%#r.randomValues+1]
    end
    r.groupdigits=function(value) r.record('groupdigits',value);return 'G:'..tostring(value) end
    if configure then configure(r) end
    local env=H.environment()
    function r.setConfigured(value)
        r.previewConfigured=value
        if not ported then env.configuredPreviewActive=value end
    end
    r.bindings={core=r.core,native=n,cache=r.cache,config=r.config,defaultSpawn=r.defaultSpawn,
        renderer=renderer,ui=ui,callbacks=callbacks,integrations=integrations,notify=r.notify,locale=r.locale,
        groupdigits=r.groupdigits,strsplit=F.split,random=r.random,nationalities=r.nationalities}
    if ported then
        r.factory=H.load('kernel/client/character.lua',env)
        r.api=r.factory(r.bindings)
        assert(#r.trace==0 and #r.threads==0,'No runtime effects in flow constructor')
        r.api.Initialize()
        r.events=r.api.Events;r.threads=r.api.Threads
    else
        for name,fn in pairs(n) do env[name]=fn end
        for name,fn in pairs(renderer) do env[name]=fn end
        env.configuredPreviewActive=r.previewConfigured
        env.QBX=r.core;env.cache=r.cache;env.Notify=r.notify;env.locale=r.locale
        env.math.random=r.random;env.string.strsplit=F.split
        env.CreateThread=function(fn) r.threads[#r.threads+1]=fn end
        env.RegisterNetEvent=function(name,handler) r.events[#r.events+1]={name=name,handler=handler,network=true} end
        env.AddEventHandler=function(name,handler) r.events[#r.events+1]={name=name,handler=handler,network=false} end
        env.exports={spawnmanager={spawnPlayer=function(_,...) return integrations.spawnPlayer(...) end,
            setAutoSpawn=function(_,...) return integrations.setAutoSpawn(...) end},
            ['forge-loadscreen']={FinishLoadingScreen=function() return integrations.finishLoadingScreen() end}}
        env.lib={inputDialog=ui.inputDialog,registerContext=ui.registerContext,showContext=ui.showContext,
            alertDialog=ui.alertDialog,callback=callbacks,math={groupdigits=r.groupdigits},
            load=function(name) assert(name=='data.nationalities');return r.nationalities end}
        env.require=function(name)
            if name=='config.client' then return r.config elseif name=='config.shared' then return {defaultSpawn=r.defaultSpawn} end
            error('External import '..name)
        end
        local source=P.source('client/character.lua')
        local function section(a,b)
            local first=assert(source:find(a,1,true));local last=assert(source:find(b,first,true))
            return source:sub(first,last-1)
        end
        local prefix=section("local config =","-- This public configuration")
        local location=section('local randomLocation =','local randomPeds =')
        local startup=section('NetworkStartSoloTutorialSession()','local function clearConfiguredPreviews()')
        local restStart=assert(source:find('---@param slotSettings table?',1,true))
        local rest=source:sub(restStart)
        local results={};for _,name in ipairs(methods) do results[#results+1]=name..'='..name end
        local text=prefix..location..startup..rest..'\nreturn {'..table.concat(results,',')..'}'
        r.api=assert(hostLoad(text,'@installed-character-flow','t',env))()
    end
    r.env=env
    function r.handler(name) for _,event in ipairs(r.events) do if event.name==name then return event.handler end end;error('Missing '..name) end
    function r.thread(id)
        r.coroutines=r.coroutines or {}
        if not r.coroutines[id] then r.coroutines[id]=coroutine.create(r.threads[id]) end
        local ok,value=coroutine.resume(r.coroutines[id]);assert(ok,value);return value
    end
    function r.fillNationalities() if r.config.characters.limitNationalities then r.thread(1) end end
    function r.clearTrace() r.trace={} end
    return r
end
function F.compare(label,action,configure)
    local a,b=F.new(false,configure),F.new(true,configure)
    local aa,bb=table.pack(pcall(action,a)),table.pack(pcall(action,b))
    if aa[1]==false and bb[1]==false then
        aa[2]=tostring(aa[2]):gsub('^.-:%d+: ','')
        bb[2]=tostring(bb[2]):gsub('^.-:%d+: ','')
    end
    H.same(P.snapshot(bb),P.snapshot(aa),label..' returns')
    H.same(b.trace,a.trace,label..' effects')
    H.same(P.snapshot(b.menus),P.snapshot(a.menus),label..' menus')
    H.same(P.snapshot(b.core),P.snapshot(a.core),label..' state')
    H.same(b.cache,a.cache,label..' native cache')
    assert(#a.events==#b.events and #a.threads==#b.threads,label..' descriptors')
    for i,event in ipairs(a.events) do
        assert(b.events[i].name==event.name and b.events[i].network==event.network,label..' event contract')
    end
    return b,bb
end
function F.bindLoadingController(r,config)
    local exports,threads,events={},{},{}
    local env=H.environment({
        GetGameTimer=function() return r.now end, Wait=r.native.Wait,
        CreateThread=function(fn) threads[#threads+1]=fn end,
        AddEventHandler=function(name,fn) events[name]=fn end,
        RegisterNetEvent=function(name,fn) events[name]=fn end,
        RegisterNUICallback=function(name,fn) events['nui:'..name]=fn end,
        exports=function(name,fn) exports[name]=fn end,
        json={encode=function(value) return H.copy(value) end},
        SendLoadingScreenMessage=function(value) r.record('loadingMessage',value) end,
        SendNUIMessage=function(value) r.record('loadingNui',value) end,
        ShutdownLoadingScreen=function() r.record('controllerShutdown');r.loadingClosedAt=r.now end,
        ShutdownLoadingScreenNui=function() r.record('controllerShutdownNui') end,
        pr_lib={callback={await=function(name,timeout)
            r.record('loadingConfig',name,timeout)
            assert(name=='forge-loadscreen:server:getConfig' and timeout==5000)
            local data=H.copy(config);data.loadingElapsedMs=r.now;return data
        end},addCommand=function() end},
    })
    H.load('../forge-loadscreen/client.lua',env)
    assert(#threads==1,'Controller startup is described, not executed')
    r.integrations.finishLoadingScreen=function()
        r.record('FinishLoadingScreen');return exports.FinishLoadingScreen()
    end
    return exports,events
end
function F.runCoroutine(co,limit)
    for _=1,limit or 500 do
        if coroutine.status(co)=='dead' then return end
        local ok,value=coroutine.resume(co);assert(ok,value)
    end
    assert(coroutine.status(co)=='dead','Bounded simulated coroutine did not finish')
end
return F
