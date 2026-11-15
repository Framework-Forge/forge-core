-- Installed PR persistence/OX adapter vs exact source/factories. All IO, provider, natives/time are virtual.
local S=dofile('tests/kernel_stores_harness.lua')
local H,V,P=S.H,S.V,S.P
local R={H=H,V=V,P=P,S=S,env=S.env,environment=S.environment}
function R.config(ported)
    if ported then return H.load('kernel/config/forge_starterpack.lua',R.env())()end
    local e=H.environment({PR={}});H.load('shared/starterpack.lua',e);return e.PR.Starterpack
end
function R.seed()
    return{settings={enabled=true,oncePerCharacter=true,autoGiveOnFirstJoin=false},claimed={},rewardClaims={},
        items={{id='food',name='burger',label='Food',count=2,enabled=true,metadata={quality=99}},
            {id='drink',name='water',count=1,enabled=true,metadata={quality=77}}},
        prologue={enabled=true,vehicleModel='asea',lamarModel='ig_lamardavis',vehicleStart={coords={x=101,y=202,z=40.7},heading=137},
            lamarStart={coords={x=99,y=200,z=42.15},heading=73},stops={{id='one',title='One',enabled=true,coords={x=101,y=202,z=40.4},
                routeDialogs={{id='hello',text='Hello',progress=0,duration=2000}},
                rewards={{id='token',item='token',count=1,progress=0,enabled=true,metadata={quality=55}}},cameraFrames={}}}}}
end
function R.new(ported)
    local r=V.new(ported);r.config.Starterpack=R.config(ported);S.ox(r);S.players(r)
    r.clock={time=function()return r.seconds or 1792530000 end};r.callbacks={};r.commands={}
    r.native.GetPlayerName=function(src)if not r.missingName then return'Player '..src end end
    r.native.GetCurrentResourceName=function()return'forge-core'end
    r.print=function(...)r.record('print',...)end
    r.inventoryIntegration.canCarryRaw=function(...)return r.ox:CanCarryItem(...)end
    local add=r.ox.AddItem;r.addCalls=0
    r.ox.AddItem=function(self,...)
        r.addCalls=r.addCalls+1
        if r.failAddAt==r.addCalls then r.record('add-failed',...);if r.throwAdd then error('fixture-add',0)end;return false end
        return add(self,...)
    end
    r.m.seed(r.config.Starterpack.Storage.file,R.seed())
    if ported then
        r.boundary=H.load('kernel/server/starterpack.lua',R.env())({config=r.config,library=r.library,native=r.native,
            clock=r.clock,services=r.services,translate=r.translate,world=r.state,player=r.player,inventoryIntegration=r.inventoryIntegration,print=r.print})
        r.service=r.boundary.Service
        r.callbackDescriptors=H.load('kernel/server/starterpack_callbacks.lua',R.env())({config=r.config,service=r.service})
        for _,d in ipairs(r.callbackDescriptors)do r.callbacks[d.name]=d.handler end
    else
        r.library.framework=r.player
        local e=H.environment({PR=r.config,ForgeCore=r.services,pr_lib=r.library,os=r.clock,print=r.print})
        for n,fn in pairs(r.native)do e[n]=fn end
        e.exports={ox_inventory=r.ox};e.GetResourceState=function(n)assert(n=='ox_inventory');return r.inventoryIntegration.resourceState()end
        r.services.Callbacks={register=function(n,fn)r.callbacks[n]=fn end}
        H.load('server/starterpack/service.lua',e);H.load('server/starterpack/callbacks.lua',e);r.service=r.services.StarterpackService
        r.originalEnv=e
    end
    assert(not r.service.started and #r.trace==0 and #r.m.trace==0,'inert starterpack server')
    function r.bindCommands(usePR)
        r.library.command=usePR and function(n,p,fn)r.commands[#r.commands+1]={name=n,properties=p,handler=fn,provider='pr'};return true end or nil
        if ported then r.commands=H.load('kernel/server/starterpack_commands.lua',R.env())({config=r.config,library=r.library,service=r.service,translate=r.translate,print=r.print})
        else r.originalEnv.RegisterCommand=function(n,fn,restricted)r.commands[#r.commands+1]={name=n,handler=fn,restricted=restricted,provider='native'}end
            H.load('server/starterpack/commands.lua',r.originalEnv)end
        return r.commands[1]
    end
    function r.stateSnapshot()return P.snapshot({r.service,r.state.getRecord('starterpack'),r.m.files,r.items})end
    return r
end
function R.case(name,fn,noStart)
    local a,b=R.new(false),R.new(true)
    local function action(r)if not noStart then r.service.start()end;return fn(r)end
    H.same(V.outcome(action,b),V.outcome(action,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(b.m.trace,a.m.trace,name..' persistence');H.same(b.stateSnapshot(),a.stateSnapshot(),name..' state')
end
-- Reuse the existing installed scene fixture without editing its source or suppressing its assertions.
local file=assert(io.open('tests/starterpack_scene_test.lua','r'));local sceneSource=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(sceneSource:find('\ndo\n',1,true));local scenePrefix=sceneSource:sub(1,cut-1)
local old="    r.load('client/starterpack/main.lua')"
local new=[[
    if options.configure then options.configure(r,e,s)end
    if lot44Ported then
        local api=lot44H.load('kernel/client/starterpack.lua',lot44Env())({config=e.PR,library=e.pr_lib,native=e,
            world=e.ForgeCore.State,session=e.ForgeCore.Session or {isLoaded=function()return true end},translate=e.ForgeCore.t,print=function()end})
        e.ForgeCore.Client={Starterpack=api.Starterpack};r.lot44Runtime=api
        for _,d in ipairs(api.Events)do if d.network then e.RegisterNetEvent(d.name,d.handler)else e.AddEventHandler(d.name,d.handler)end end
        for _,d in ipairs(api.Subscriptions)do e.ForgeCore.State.onChange(d.key,d.handler)end
        for _,fn in ipairs(api.Initializers)do fn()end
    else r.load('client/starterpack/main.lua')end
]]
assert(scenePrefix:find(old,1,true));scenePrefix=scenePrefix:gsub("    r%.load%('client/starterpack/main%.lua'%)",function()return new end)
function R.sceneFixture(ported,options)
    local env=setmetatable({lot44Ported=ported,lot44H=H,lot44Env=R.env},{__index=_ENV})
    return assert(load(scenePrefix..'\nreturn fixture\n','@installed-starterpack-fixture','t',env))()(options)
end
function R.sceneCase(name,fn,options)
    local function action(ported)
        local r,e,s=R.sceneFixture(ported,options);fn(r,e,s)
        return P.snapshot({s=s,out=r.out,time=r.now,queueCount=#r.queue})
    end
    H.same(action(true),action(false),name)
end
function R.runExistingScene(ported)
    local env=setmetatable({lot44Ported=ported,lot44H=H,lot44Env=R.env,print=function()end},{__index=_ENV})
    assert(load(scenePrefix..sceneSource:sub(cut),'@whole-installed-starterpack-scene-tests','t',env))()
end
function R.menu(ported)
    local r=S.menu(ported);r.config.Starterpack=R.config(ported);r.starterPayload=R.seed()
    r.json={encode=function(v)r.record('encode',v);return r.encoded or'{}'end,
        decode=function(v)r.record('decode',v);if r.decodeError then error('fixture-json',0)end;return r.decoded or{}end}
    r.native.TriggerEvent=function(...)r.record('trigger',...)end
    local parent=r.library.callback.await
    r.library.callback.await=function(name,timeout,...)
        if not name:find(':starterpack:',1,true)then return parent(name,timeout,...)end
        assert(timeout==10000);r.record('starterpack-rpc',name,timeout,...)
        if r.starterRpcHook then return r.starterRpcHook(name,...)end
        return true,H.copy(r.starterPayload)
    end
    r.library.devtools={}
    for _,key in ipairs({'placeVehicle','placePed'})do r.library.devtools[key]=function(model,distance,callback,options)
        r.record(key,model,distance,options);r.placementCallback=callback
        if r.invokePlacement then callback(r.placement)end
        return r.placementResult~=false
    end end
    if ported then H.load('kernel/client/menu/starterpack.lua',R.env())({config=r.config,library=r.library,native=r.native,menu=r.menu,shared=r.shared,json=r.json})
    else r.env.json=r.json;for n,fn in pairs(r.native)do r.env[n]=fn end;H.load('client/menu/menu_starterpack.lua',r.env)end
    r.trace={};return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts')
    H.same(P.snapshot(b.starterPayload),P.snapshot(a.starterPayload),name..' local snapshots')
end
return R
