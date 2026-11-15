-- Test-only full installed client bodies and actual PR cache/inventory adapter.
local A=dofile('tests/kernel_automedic_harness.lua')
local Cache=dofile('tests/cache_harness.lua')
local H,P=A.H,A.P
local R={A=A,H=H,P=P}
local NATIVE_NAMES={'AddBlipForEntity','AddTextComponentString','BeginTextCommandSetBlipName','ClearFacialIdleAnimOverride','ClearPedBloodDamage','ClearPedTasks','ClearPedTasksImmediately','CreateCam','CreatePed','CreateThread','DeleteEntity','DestroyCam','DoScreenFadeIn','DoScreenFadeOut','DoesBlipExist','DoesEntityExist','EndTextCommandSetBlipName','FreezeEntityPosition','GetCloudTimeAsInt','GetCurrentResourceName','GetEntityCoords','GetEntityHeading','GetEntityHealth','GetEntityMaxHealth','GetGameTimer','GetGroundZFor_3dCoord','GetHeadingFromVector_2d','GetOffsetFromEntityInWorldCoords','GetPedCauseOfDeath','GetWeapontypeGroup','HasAnimDictLoaded','HasCollisionLoadedAroundEntity','HasModelLoaded','IsControlJustPressed','IsDisabledControlJustPressed','IsEntityDead','IsPedDeadOrDying','IsPedFatallyInjured','IsPedMale','IsScreenFadedIn','IsScreenFadedOut','IsScreenFadingOut','NetworkAddPedToSynchronisedScene','NetworkCreateSynchronisedScene','NetworkResurrectLocalPlayer','NetworkStartSynchronisedScene','NetworkStopSynchronisedScene','PlayCamAnim','PlayerPedId','RemoveAnimDict','RemoveBlip','RenderScriptCams','RequestAnimDict','RequestCollisionAtCoord','RequestModel','ResetPedVisibleDamage','SetBlipColour','SetBlipSprite','SetBlockingOfNonTemporaryEvents','SetEntityAsMissionEntity','SetEntityCanBeDamaged','SetEntityCoords','SetEntityCoordsNoOffset','SetEntityHeading','SetEntityHealth','SetEntityInvincible','SetEntityNoCollisionEntity','SetEntityRotation','SetEntityVisible','SetFacialIdleAnimOverride','SetModelAsNoLongerNeeded','SetPedCanRagdoll','SetTimeout','TaskGoStraightToCoord','TaskGoToEntity','TaskPlayAnim','TaskTurnPedToFaceEntity','TriggerServerEvent','Wait'}
function R.env()
    local e=H.environment()
    e.debug={traceback=function(err)return tostring(err):gsub('kernel/client/automedic/hospital.lua:%d+: ',''):gsub('client/automedic/hospital.lua:%d+: ','')end}
    e.math.random=function(a,b)return b and a or 0.25 end
    e.require=function(name)assert(name:match('^kernel%.'));return H.load(name:gsub('%.','/')..'.lua',e)end
    return e
end
local function vector(x,y,z)
    return setmetatable({x=x,y=y,z=z},{__sub=function(a,b)return vector(a.x-b.x,a.y-b.y,a.z-b.z)end,
        __len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end})
end
R.vector=vector
function R.new(ported)
    local r=Cache.new(false);local e=r.env
    e.debug={traceback=function(err)return tostring(err):gsub('kernel/client/automedic/hospital.lua:%d+: ',''):gsub('client/automedic/hospital.lua:%d+: ','')end}
    e.math=H.copy(math);e.math.random=function(a,b)return b and a or 0.25 end
    r.trace={};r.ped=11;r.health=100;r.maxHealth=200;r.dead=true;r.fatal=false;r.model=true;r.animation=true
    r.positions={[11]=vector(0,0,30)};r.heading=0;r.faded=false;r.blips={};r.exists={};r.inventoryCallback=nil
    r.native={};r.eventsList={};r.initialThreads={};r.binds={};r.status={health=0,hunger=100,thirst=100}
    r.data={citizenid='C1',metadata={isdead=true},job={name='police',grade={level=1}},gang={name='none'}}
    function r.record(k,...)r.trace[#r.trace+1]={kind=k,args=P.snapshot(table.pack(...))}end
    local function effect(name)return function(...)r.record(name,...)end end
    for _,name in ipairs(NATIVE_NAMES)do r.native[name]=effect(name)end
    r.native.joaat=function(name)return name end;r.native.vector3=vector
    r.native.print=function(...)r.record('print',...)end
    r.native.PlayerPedId=function()return r.ped end
    r.native.GetCurrentResourceName=function()return'forge-core'end
    r.native.source=function()return e.source end
    r.native.GetGameTimer=function()return r.now end
    r.native.GetCloudTimeAsInt=function()return math.floor(r.now/1000)end
    local platformWait=e.Wait
    r.native.Wait=function(ms)return platformWait(math.max(10,ms))end
    r.native.CreateThread=e.CreateThread;r.native.SetTimeout=e.SetTimeout
    r.native.DoesEntityExist=function(ped)return ped~=nil and ped~=0 and r.exists[ped]~=false end
    r.native.IsEntityDead=function(ped)return ped==r.ped and r.dead end
    r.native.IsPedFatallyInjured=function(ped)return ped==r.ped and r.fatal end
    r.native.IsPedDeadOrDying=function(ped)return ped==r.ped and(r.dead or r.health<=100)or r.medicDead==true end
    r.native.GetEntityHealth=function(ped)return r.health end
    r.native.GetEntityMaxHealth=function()return r.maxHealth end
    r.native.GetEntityCoords=function(ped)return r.positions[ped]or vector(1,1,30)end
    r.native.GetEntityHeading=function()return r.heading end
    r.native.GetOffsetFromEntityInWorldCoords=function(ped,x,y,z)local p=r.native.GetEntityCoords(ped);return vector(p.x+x,p.y+y,p.z+z)end
    r.native.GetHeadingFromVector_2d=function()return 90 end
    r.native.GetGroundZFor_3dCoord=function(_,_,z)return not r.noGround,z-25 end
    r.native.GetPedCauseOfDeath=function()return r.cause or 0 end
    r.native.GetWeapontypeGroup=function(cause)return cause end
    r.native.HasModelLoaded=function()return r.model end
    r.native.HasAnimDictLoaded=function()return r.animation end
    r.native.IsPedMale=function()return not r.female end
    r.native.IsScreenFadedIn=function()return not r.faded end
    r.native.IsScreenFadedOut=function()return r.faded end
    r.native.IsScreenFadingOut=function()return false end
    r.native.DoScreenFadeOut=function(ms)r.record('fade-out',ms);r.faded=true end
    r.native.DoScreenFadeIn=function(ms)r.record('fade-in',ms);r.faded=false end
    r.native.SetEntityHealth=function(ped,v)r.record('health',ped,v);r.health=v end
    r.native.SetEntityCoordsNoOffset=function(ped,x,y,z,...)r.record('coords-no',ped,x,y,z,...);r.positions[ped]=vector(x,y,z)end
    r.native.SetEntityCoords=function(ped,x,y,z,...)r.record('coords',ped,x,y,z,...);r.positions[ped]=vector(x,y,z+1)end
    r.native.SetEntityHeading=function(_,v)r.heading=v;r.record('heading',v)end
    r.native.TaskGoStraightToCoord=function(ped,x,y,z,...)r.record('go-straight',ped,x,y,z,...);r.positions[ped]=vector(x,y,z)end
    r.native.NetworkResurrectLocalPlayer=function(...)r.record('resurrect',...);r.dead=false end
    r.native.CreatePed=function(...)r.record('create-ped',...);if r.spawnFail then return 0 end;r.positions[22]=vector(1,1,30);return 22 end
    r.native.DeleteEntity=function(ped)r.record('delete',ped);r.exists[ped]=false end
    r.native.AddBlipForEntity=function(ped)r.record('blip',ped);r.blips[33]=true;return 33 end
    r.native.DoesBlipExist=function(id)return r.blips[id]==true end
    r.native.RemoveBlip=function(id)r.record('remove-blip',id);r.blips[id]=false end
    r.native.IsControlJustPressed=function()return r.press==true end
    r.native.IsDisabledControlJustPressed=function()return false end
    r.native.HasCollisionLoadedAroundEntity=function()return r.collision~=false end
    r.native.NetworkCreateSynchronisedScene=function(...)r.record('scene',...);return 44 end
    r.native.CreateCam=function(...)r.record('camera',...);return 55 end
    r.native.TriggerEvent=function(name,...)r.record('emit',name,...);r.fire(name,e.source,...)end
    r.native.TriggerServerEvent=function(name,...)
        r.record('server',name,...)
        if r.send then return r.send(name,...)end
    end
    for name,fn in pairs(r.native)do e[name]=fn end
    e.print=r.native.print
    -- The constructor API describes only initial workers; dynamic workers use the simulated platform.
    local originalCreate=e.CreateThread
    e.CreateThread=function(fn)r.initialThreads[#r.initialThreads+1]=fn;return originalCreate(fn)end
    r.library=e.pr_lib;r.library.framework=nil
    r.library.Notify=function(...)r.record('notify',...)end
    r.library.ShowTextUI=function(...)r.record('show-text',...)end
    r.library.HideTextUI=function(...)r.record('hide-text',...)end
    r.library.progressBar=function(props)r.record('progress',props);if r.progressHook then return r.progressHook(props)end
        r.native.Wait(props.duration);return r.progressResult~=false end
    r.library.addKeybind=function(data)r.binds[#r.binds+1]=data end
    r.library.callback.await=function(name,timeout,...)
        assert(timeout==10000);r.record('await',name,...)
        if r.awaitHook then return r.awaitHook(name,...)end
        local cb=r.config.AutoMedic.Callbacks
        if name==cb.getStatus then return true,{enabled=true,cooldown=0,treatmentPrice=100,reviveHealthPercent=10}end
        if name==cb.requestTreatment then return true,{token='T1'}end
        return true,{}
    end
    local ox={useItem=function(_,data,cb)r.record('use-item',data);r.inventoryCallback=cb;if r.useError then error('fixture-use',0)end end}
    local invEnv=H.environment({ActiveBridges={inventory='ox'},exports={ox_inventory=ox}})
    r.library.inventory=H.load('../pr_bridge/bridge/inventories/ox/client.lua',invEnv)
    r.kernel={GetPlayerData=function()return r.data end,GetStatus=function()return r.status end,
        GetAuthenticatedPlayerData=function()
            local record=r.library.cache.GetResourceState('qbx_core','session')
            if record and record.authenticated==false then return {}end
            return r.data or {}
        end,
        RefreshNativeStatus=function()r.native.TriggerEvent('qbx_core:client:refreshNativeStatus')end,
        SetDeathPoseOverride=function(v)r.native.TriggerEvent('qbx_core:client:setDeathPoseOverride',v)end}
    r.kernel.IsAuthenticated=function()local d=r.kernel.GetAuthenticatedPlayerData();return type(d)=='table'and(d.citizenid~=nil or d.identifier~=nil)end
    -- Compile the exact installed normalizer function, not an invented Session.isDead surrogate.
    local file=assert(io.open('../pr_bridge/bridge/framework_normalizer.lua','r'));local text=file:read('*a');file:close()
    local fn=assert(text:match('if not framework.IsPlayerDead then (function framework.IsPlayerDead%(%) .- end) end'))
    local fe=setmetatable({framework={},playerData=r.kernel.GetAuthenticatedPlayerData,IsEntityDead=r.native.IsEntityDead,PlayerPedId=r.native.PlayerPedId},{__index=_G})
    assert(load(fn,'@normalizer-IsPlayerDead','t',fe))()
    r.kernel.IsPlayerDead=fe.framework.IsPlayerDead
    local originalEvents=r.events
    local function register(d)r.eventsList[#r.eventsList+1]=d;e.AddEventHandler(d.name,d.handler)end
    local add=e.AddEventHandler
    register=function(d)r.eventsList[#r.eventsList+1]=d;add(d.name,d.handler)end
    e.AddEventHandler=function(name,fn)register({name=name,handler=fn,network=false})end
    e.RegisterNetEvent=function(name,fn)register({name=name,handler=fn,network=true})end
    r.config={AutoMedic=A.config(true),NotifyPos='top-right'}
    e.PR=r.config
    r.translate=function(key,params)r.record('translate',key,params);return key end
    e.ForgeCore={t=r.translate,State={copy=Cache.copy}}
    if ported then
        r.session=H.load('kernel/client/forge_session.lua',R.env())({kernel=r.kernel,cache=r.library.cache,native=r.native})
        r.hospitalModule=H.load('kernel/client/automedic/hospital.lua',R.env())({config=r.config,library=r.library,native=r.native,translate=r.translate})
        r.hospital=r.hospitalModule.Hospital
        r.runtime=H.load('kernel/client/automedic/runtime.lua',R.env())({config=r.config,library=r.library,native=r.native,
            translate=r.translate,kernel=r.kernel,hospital=r.hospital})
        assert(#r.trace==0 and #r.queue==0,'inactive constructors must not create effects')
        for _,d in ipairs(r.session.Events)do register(d)end
        r.session.Initialize()
        for _,d in ipairs(r.hospitalModule.Events)do register(d)end
        r.hospitalModule.Initialize()
        for _,d in ipairs(r.runtime.Events)do register(d)end
        r.binds=r.hospitalModule.Keybinds
        r.exports=r.runtime.Exports;r.worker=r.runtime.Threads[1];r.state=r.runtime.State
    else
        r.library.framework={GetPlayerData=r.kernel.GetAuthenticatedPlayerData,IsPlayerLoaded=r.kernel.IsAuthenticated,IsPlayerDead=r.kernel.IsPlayerDead}
        e.exports.qbx_core={GetPlayerData=function()return r.data end,GetStatus=function()return r.status end}
        e.exports.ox_inventory=ox
        r.load('shared/session.lua');r.session={Session=e.ForgeCore.Session}
        r.load('client/automedic/hospital.lua');r.hospital=e.ForgeCore.Hospital
        -- Capture, don't start the initial worker. Dynamic workers still execute through the platform.
        e.CreateThread=function(fn)r.worker=fn end
        r.load('client/automedic/main.lua');e.CreateThread=r.native.CreateThread
        r.exports=r.exported
    end
    function r.fn(name)
        local seen={}
        local function walk(fn)
            if type(fn)~='function'or seen[fn]then return end;seen[fn]=true
            for i=1,100 do local key,v=debug.getupvalue(fn,i);if not key then break end
                if key==name then return v end
                if key~='_ENV'and type(v)=='function'then local found=walk(v);if found~=nil then return found end end
            end
        end
        local found=walk(r.worker)
        if found==nil then for _,fn in pairs(r.exports)do found=walk(fn);if found~=nil then break end end end
        if found==nil then for _,d in ipairs(r.eventsList)do found=walk(d.handler);if found~=nil then break end end end
        assert(found~=nil,'test upvalue unavailable: '..name);return found
    end
    if not ported then r.state=r.fn('state')end
    function r.start(name,...)local args=table.pack(...);r.native.CreateThread(function()r.fn(name)(table.unpack(args,1,args.n))end)end
    function r.use(value)if r.inventoryCallback then return r.inventoryCallback(value)end end
    r.trace={}
    return r
end
function R.outcome(fn,r)
    local result=table.pack(pcall(fn,r))
    if not result[1]then
        local msg=tostring(result[2]);assert(not msg:find('assertion failed',1,true)and not msg:find('test upvalue',1,true)
            and not msg:find('Unbound test boundary',1,true)and not msg:find('test failure:',1,true),msg)
        result[2]=msg:gsub('[^\n]-:%d+: ',''):gsub('stack traceback:[%s%S]*','')
        assert(msg:find('fixture-',1,true),'Unexpected test error: '..msg)
    end
    return P.snapshot(result)
end
function R.case(name,fn)
    local a,b=R.new(false),R.new(true)
    local rb,ra=R.outcome(fn,b),R.outcome(fn,a)
    if rb[1]~=ra[1]then print(name,tostring(rb[2]),tostring(ra[2]))end
    H.same(rb,ra,name..': return')
    H.same(b.trace,a.trace,name..': effects');H.same(b.state,a.state,name..': state')
    H.same(P.snapshot(b.hospital),P.snapshot(a.hospital),name..': hospital')
    H.same(b.library.cache.get('forge-core:session:self'),a.library.cache.get('forge-core:session:self'),name..': session')
    H.same({b.health,b.ped,b.faded,b.positions,b.status,b.data},{a.health,a.ped,a.faded,a.positions,a.status,a.data},name..': entities/data')
end
-- Menus use the installed Shared helpers; UI/placement/time and RPC replies are test boundaries.
function R.menu(ported)
    local M=dofile('tests/kernel_admin_menu_harness.lua')
    local r=M.new(ported);r.config.AutoMedic=A.config(true)
    r.settings=H.copy(r.config.AutoMedic.Defaults);r.settings.beds={A.bed('bed',10)};r.saved={}
    r.native.PlayerPedId=function()return 11 end;r.native.GetEntityCoords=function()return vector(1,2,3)end
    r.native.GetEntityHeading=function()return 90 end;r.native.GetGameTimer=function()return 12345 end
    r.native.SetTimeout=r.native.setTimeout
    r.library.callback.await=function(name,timeout,data)
        assert(timeout==10000);r.record('await',name,timeout,data)
        if r.awaitHook then return r.awaitHook(name,data)end
        local c=r.config.AutoMedic.Callbacks
        if name==c.getSettings then return true,H.copy(r.settings)end
        r.saved[#r.saved+1]={name=name,data=H.copy(data)}
        if name==c.saveSettings then r.settings=H.copy(data)
        elseif name==c.saveBed then r.settings.beds={H.copy(data)}
        elseif name==c.deleteBed then r.settings.beds={}end
        return true,H.copy(r.settings)
    end
    r.library.fivem={blips={getPropImageUrl=function(model)r.record('image',model);return model..'.jpg'end},
        devtools={placeAnimatedPed=function(model,count,anims,fn,opts)
            r.record('placement',model,count,anims,opts);r.place=fn
            if r.placeError then error('fixture-placement',0)end
            return r.placeStart~=false
        end}}
    if ported then
        r.boundary=H.load('kernel/client/menu/automedic.lua',R.env())({menu=r.menu,shared=r.shared,config=r.config,
            library=r.library,native=r.native,translate=r.translate})
    else
        local e=r.env
        for name,fn in pairs(r.native)do e[name]=fn end
        e.math.random=function(a,b)return b and a or 0.25 end
        H.load('client/menu/menu_automedic.lua',e)
    end
    r.trace={}
    return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..': return')
    H.same(b.trace,a.trace,name..': effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..': contexts')
    H.same({b.settings,b.saved},{a.settings,a.saved},name..': settings')
end
return R
