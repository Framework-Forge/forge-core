-- Whole installed Objects sources vs private factories; PR persistence/cache/RPC/context/streaming/blips are installed code.
local V=dofile('tests/kernel_vinewood_harness.lua')
local H,P,W=V.H,V.P,V.W
local R={H=H,P=P,W=W,V=V,env=V.env}
function R.config(ported)
    if ported then return H.load('kernel/config/forge_objects.lua',R.env())()end
    local e=H.environment({PR={}});H.load('shared/objects.lua',e);return e.PR.Objects
end
function R.seed()return{enabled=true,spawnDistance=300,imageServer='fixture://images',
    nextSceneId=3,nextObjectId=2,scenes={{id=1,name='Scene A'},{id=2,name='Empty'}},
    objects={{id=1,sceneId=1,model='prop_box',coords={x=1,y=2,z=3},rotation={x=0,y=0,z=40},heading=60}}}end
function R.new(ported)
    local r=V.new(ported);r.config.Objects=R.config(ported)
    r.m.seed(r.config.Objects.Storage.file,R.seed());r.callbacks={}
    if ported then
        r.service=H.load('kernel/server/objects.lua',R.env())({config=r.config,library=r.library,native=r.native,
            services=r.services,translate=r.translate,world=r.state})
        for _,d in ipairs(H.load('kernel/server/objects_callbacks.lua',R.env())({config=r.config,service=r.service}))do
            assert(d.options.access==(d.name==r.config.Objects.Callbacks.getAll and'player'or'admin'))
            r.callbacks[d.name]=d.handler
        end
    else
        local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore=r.services,
            GetGameTimer=r.native.GetGameTimer,IsPlayerAceAllowed=r.native.IsPlayerAceAllowed})
        r.services.Callbacks={register=function(n,fn)r.callbacks[n]=fn end}
        H.load('server/objects/service.lua',e);H.load('server/objects/callbacks.lua',e);r.service=r.services.ObjectsService
    end
    assert(not r.service.started and #r.trace==0 and #r.m.trace==0 and #r.queue==0,'inactive Objects service')
    function r.stateSnapshot()return P.snapshot({r.service,r.state.getRecord('objects'),r.m.files})end
    return r
end
function R.case(name,fn,withoutStart)
    local a,b=R.new(false),R.new(true)
    local function action(r)if not withoutStart then r.service.start()end;return fn(r)end
    H.same(V.outcome(action,b),V.outcome(action,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(b.m.trace,a.m.trace,name..' persistence')
    H.same(b.stateSnapshot(),a.stateSnapshot(),name..' state')
end
function R.vector(x,y,z)return setmetatable({x=x or 0,y=y or 0,z=z or 0},{
    __sub=function(a,b)return R.vector(a.x-b.x,a.y-b.y,a.z-b.z)end,
    __len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end})end
function R.hash(value)local n=0;for c in tostring(value):gmatch('.')do n=(n*31+c:byte())%100000000 end;return n end
R.natives={'DoesEntityExist','SetEntityAsMissionEntity','DeleteEntity','FreezeEntityPosition','SetEntityDynamic','SetEntityProofs','SetEntityRotation','SetEntityCoordsNoOffset','SetEntityDrawOutline','joaat','vector3','vec2','vec4','SetDrawOrigin','SetTextScale','SetTextFont','SetTextColour','SetTextCentre','SetTextOutline','BeginTextCommandDisplayText','AddTextComponentSubstringPlayerName','EndTextCommandDisplayText','ClearDrawOrigin','PlayerPedId','GetOffsetFromEntityInWorldCoords','GetEntityHeading','SetEntityHeading','SetEntityCollision','GetEntityCoords','GetEntityRotation','SetEntityCoords','SetEntityDrawOutlineColor','DrawMarker','GetCurrentResourceName','Wait'}
function R.platform(r)
    r.entities={};r.positions={[11]=R.vector(0,0,0)};r.rotations={};r.headings={[11]=90};r.nextEntity=100
    r.validModel=true;r.loaded=true;r.collisions={};r.targetDisabled=false;r.gizmoOptions=nil
    r.native.vector3=R.vector;r.native.vec2=function(x,y)return{x=x,y=y}end
    r.native.vec4=function(x,y,z,w)return{x=x,y=y,z=z,w=w}end;r.native.joaat=R.hash
    r.native.PlayerPedId=function()return 11 end
    r.native.GetCurrentResourceName=function()return'forge-core'end
    r.native.DoesEntityExist=function(id)return r.entities[id]==true end
    r.native.GetEntityCoords=function(id)return r.positions[id]or R.vector()end
    r.native.GetEntityRotation=function(id)return r.rotations[id]or R.vector()end
    r.native.GetEntityHeading=function(id)return r.headings[id]or 0 end
    r.native.GetOffsetFromEntityInWorldCoords=function(id,x,y,z)local p=r.native.GetEntityCoords(id);return R.vector(p.x+x,p.y+y,p.z+z)end
    r.native.IsModelInCdimage=function()return r.validModel end
    r.native.HasModelLoaded=function()if r.modelHook then r.modelHook()end;return r.loaded end
    r.native.IsEntityAPed=function()return false end
    r.native.DeleteEntity=function(id)r.record('delete',id);r.entities[id]=nil end
    r.native.SetEntityCollision=function(id,enabled,keep)r.record('collision',id,enabled,keep);r.collisions[id]=enabled end
    r.native.SetEntityRotation=function(id,x,y,z,...)r.record('rotate',id,x,y,z,...);r.rotations[id]=R.vector(x,y,z)end
    r.native.SetEntityCoordsNoOffset=function(id,x,y,z,...)r.record('move',id,x,y,z,...);r.positions[id]=R.vector(x,y,z)end
    r.native.SetEntityCoords=r.native.SetEntityCoordsNoOffset
    r.native.SetEntityHeading=function(id,v)r.record('heading',id,v);r.headings[id]=v end
    r.native.SetEntityDrawOutlineShader=function(...)r.record('outline-shader',...)end
    for _,name in ipairs(R.natives)do
        if not r.native[name]then r.native[name]=function(...)r.record(name,...)end end
    end
    r.native.SetEntityAlpha=function(...)r.record('alpha',...)end
    r.native.RequestModel=function(...)r.record('request-model',...)end
    r.native.SetModelAsNoLongerNeeded=function(...)r.record('release-model',...)end
    r.native.CreateObjectNoOffset=function(model,x,y,z,...)
        r.record('create-object',model,x,y,z,...)
        if r.createError then error('fixture-create',0)end
        if r.createZero then return 0 end
        r.nextEntity=r.nextEntity+1;local id=r.nextEntity;r.entities[id]=true;r.positions[id]=R.vector(x,y,z)
        return id
    end
    r.native.CreateObject=r.native.CreateObjectNoOffset
    local e=H.environment({Bridge={debug={warn=function(...)r.record('stream-warning',...)end}}})
    for name,fn in pairs(r.native)do e[name]=fn end
    e.IsModelValid=function()return false end -- Explicit optional boundary for the invalid-model path.
    local streaming=H.load('../pr_bridge/bridge/fivem/streaming/client.lua',e)
    r.library.fivem={streaming=streaming,blips=H.load('../pr_bridge/bridge/fivem/blips/shared.lua',H.environment({GetHashKey=R.hash})),gizmo={
        start=function(entity,cb,offset,opts)
            r.record('gizmo-start',entity,offset,opts);r.gizmoEntity=entity;r.gizmoOptions=opts
            if r.gizmoError then error('fixture-gizmo',0)end
            if r.gizmoFailed then return false end
            assert(cb()==true);return{active=true,entity=entity}
        end,
        stop=function()r.record('gizmo-stop');r.gizmoStopped=true end}}
    r.library.target={disableTargeting=function(value)r.record('target-disable',value);r.targetDisabled=value end}
    r.library.Notify=function(...)r.record('notice',...)end
    r.library.callback.await=function(name,timeout,...)
        assert(timeout==10000);r.record('object-rpc',name,timeout,...)
        if r.rpcHook then return r.rpcHook(name,...)end
        return true,99,{objects={}}
    end
    function r.finish(confirmed,coords,rotation)
        assert(r.gizmoOptions,'No gizmo session');r.gizmoOptions.onFinish({confirmed=confirmed,coords=coords or R.vector(8.12345,9.23456,10.34567),rotation=rotation or R.vector(1,2,3)})
    end
end
function R.bindRuntime(r,ported)
    r.value=nil;r.initial={};r.subscriptions={};r.events={}
    r.world={peek=function(key)assert(key=='objects');return r.value end}
    if ported then
        r.runtime=H.load('kernel/client/objects.lua',R.env())({config=r.config,library=r.library,native=r.native,world=r.world,translate=r.translate})
        r.objects=r.runtime.Objects;r.initial=r.runtime.Threads;r.subscriptions=r.runtime.Subscriptions;r.events=r.runtime.Events
    else
        local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore={Client={},State=r.world,t=r.translate}})
        for name,fn in pairs(r.native)do e[name]=fn end
        e.CreateThread=function(fn)r.initial[#r.initial+1]=fn end
        e.AddEventHandler=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=false}end
        r.world.onChange=function(key,fn)r.subscriptions[#r.subscriptions+1]={key=key,handler=fn}end
        H.load('client/objects/main.lua',e);r.objects=e.ForgeCore.Client.Objects
    end
    assert(#r.initial==2 and #r.subscriptions==1 and #r.events==1 and next(r.objects.entries)==nil,'two inert workers/subscription/stop')
    function r.apply(value)r.value=value;r.subscriptions[1].handler(value)end
    function r.run(fn,...)local args=table.pack(...);local co=coroutine.create(function()fn(table.unpack(args,1,args.n))end)
        local ok,ms=coroutine.resume(co);assert(ok,ms);return co,ms end
    function r.resume(co)local ok,ms=coroutine.resume(co);assert(ok,ms);return ms end
    function r.tick(index)r.worker=r.worker or{};local co=r.worker[index or 1]
        if not co then co=coroutine.create(r.initial[index or 1]);r.worker[index or 1]=co end
        local ok,ms=coroutine.resume(co);assert(ok,ms);return ms end
    function r.stop(name)r.events[1].handler(name or'forge-core')end
end
function R.client(ported)
    local r=W.world(ported,false);r.config={Objects=R.config(ported),NotifyPos='top-right'}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    r.native.Wait=function(ms)r.record('wait',ms);r.now=r.now+math.max(ms,1000);return coroutine.yield(ms)end
    R.platform(r);R.bindRuntime(r,ported)
    assert(#r.trace==0 and #r.queue==0,'inactive renderer no entity/IO/timer')
    return r
end
function R.clientCase(name,fn)
    local a,b=R.client(false),R.client(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(P.snapshot(b.objects),P.snapshot(a.objects),name..' object state')
    H.same(P.snapshot({b.entities,b.positions,b.rotations,b.collisions}),P.snapshot({a.entities,a.positions,a.rotations,a.collisions}),name..' platform')
end
function R.menu(ported,nativeCommand)
    local r=W.menu(ported);r.config.Objects=R.config(ported)
    local parentAwait=r.library.callback.await
    r.translate=function(k,p)r.record('translate',k,p);return k end
    R.platform(r);R.bindRuntime(r,ported)
    r.payload=R.seed();r.value=r.payload;r.apply(r.payload);r.commands={}
    r.library.command=function(name,a,b)r.commands[#r.commands+1]={transport='pr',name=name,properties=a,handler=b}end
    if nativeCommand then r.library.command=nil end
    r.env.RegisterCommand=function(name,fn,restricted)r.commands[#r.commands+1]={transport='native',name=name,handler=fn,restricted=restricted}end
    local await=r.library.callback.await
    r.library.callback.await=function(name,timeout,...)
        if not name:find(':objects:',1,true)then return parentAwait(name,timeout,...)end
        assert(timeout==10000);r.record('menu-object-rpc',name,timeout,...)
        if r.rpcHook then return r.rpcHook(name,...)end
        if name==r.config.Objects.Callbacks.getAll then return true,H.copy(r.payload)end
        return true,99,H.copy(r.payload)
    end
    if ported then
        r.menuApi=H.load('kernel/client/menu/objects.lua',R.env())({config=r.config,library=r.library,native=r.native,menu=r.menu,shared=r.shared,objects=r.objects})
        r.commands=r.menuApi.Commands
    else
        r.env.ForgeCore.Client.Objects=r.objects
        r.env.joaat=r.native.joaat;r.env.IsModelInCdimage=r.native.IsModelInCdimage
        H.load('client/menu/menu_objects.lua',r.env)
    end
    r.trace={};return r
end
function R.menuCase(name,fn,nativeCommand)
    local a,b=R.menu(false,nativeCommand),R.menu(true,nativeCommand)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' return');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts')
    H.same(P.snapshot(b.objects),P.snapshot(a.objects),name..' objects')
    H.same(P.snapshot(b.commands),P.snapshot(a.commands),name..' command contract')
end
return R
