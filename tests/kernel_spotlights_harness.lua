-- Whole installed Spotlights sources vs private factories; PR persistence/cache/RPC/context/streaming/blips are installed code.
local V=dofile('tests/kernel_vinewood_harness.lua')
local H,P,W=V.H,V.P,V.W
local R={H=H,P=P,W=W,V=V,env=V.env}
function R.config(ported)
    if ported then return H.load('kernel/config/forge_spotlights.lua',R.env())()end
    local e=H.environment({PR={}});H.load('shared/spotlights.lua',e);return e.PR.Spotlights
end
function R.seed()return{enabled=true,drawDistance=450,nextGroupId=3,nextLightId=2,
    groups={{id=1,name='Group A'},{id=2,name='Empty'}},
    lights={{id=1,groupId=1,name='Light A',enabled=true,origin={x=1,y=2,z=3},target={x=4,y=6,z=3},
        color={r=10,g=20,b=30},distance=50,brightness=1,hardness=0,radius=20}}}end
function R.new(ported)
    local r=V.new(ported);r.config.Spotlights=R.config(ported)
    r.m.seed(r.config.Spotlights.Storage.file,R.seed());r.callbacks={}
    if ported then
        r.service=H.load('kernel/server/spotlights.lua',R.env())({config=r.config,library=r.library,native=r.native,
            services=r.services,translate=r.translate,world=r.state})
        for _,d in ipairs(H.load('kernel/server/spotlights_callbacks.lua',R.env())({config=r.config,service=r.service}))do
            assert(d.options.access==(d.name==r.config.Spotlights.Callbacks.getAll and'player'or'admin'))
            r.callbacks[d.name]=d.handler
        end
    else
        local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore=r.services,
            GetGameTimer=r.native.GetGameTimer,IsPlayerAceAllowed=r.native.IsPlayerAceAllowed})
        r.services.Callbacks={register=function(n,fn)r.callbacks[n]=fn end}
        H.load('server/spotlights/service.lua',e);H.load('server/spotlights/callbacks.lua',e);r.service=r.services.SpotlightsService
    end
    assert(not r.service.started and #r.trace==0 and #r.m.trace==0 and #r.queue==0,'inactive Spotlights service')
    function r.stateSnapshot()return P.snapshot({r.service,r.state.getRecord('spotlights'),r.m.files})end
    return r
end
function R.case(name,fn,withoutStart)
    local a,b=R.new(false),R.new(true)
    local function action(r)if not withoutStart then r.service.start()end;return fn(r)end
    H.same(V.outcome(action,b),V.outcome(action,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(b.m.trace,a.m.trace,name..' persistence')
    H.same(b.stateSnapshot(),a.stateSnapshot(),name..' state')
end
local vm={}
function R.vector(x,y,z)return setmetatable({x=x or 0,y=y or 0,z=z or 0},vm)end
vm.__sub=function(a,b)return R.vector(a.x-b.x,a.y-b.y,a.z-b.z)end
vm.__add=function(a,b)return R.vector(a.x+b.x,a.y+b.y,a.z+b.z)end
vm.__mul=function(a,b)return R.vector(a.x*b,a.y*b,a.z*b)end
vm.__div=function(a,b)return R.vector(a.x/b,a.y/b,a.z/b)end
vm.__len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end
R.natives={'DrawSpotLight','Wait','DisableControlAction','DisablePlayerFiring','PlayerId','GetPedBoneCoords','PlayerPedId','DrawLine','DrawSphere','IsControlJustPressed','IsDisabledControlJustPressed','GetGameTimer','IsDisabledControlPressed','IsControlPressed','GetEntityCoords'}
function R.platform(r)
    r.positions={[11]=R.vector()};r.controls={};r.just={};r.draws={};r.uiMessages={};r.frame=0
    r.rays={R.vector(1.12345,2.23456,3.34567),R.vector(4,6,3)}
    r.native.vector3=R.vector;r.native.PlayerPedId=function()return 11 end
    r.native.PlayerId=function()return 1 end
    r.native.GetEntityCoords=function(id)return r.positions[id]or R.vector()end
    r.native.GetPedBoneCoords=function()return R.vector(0,0,2)end
    r.native.GetGameTimer=function()return r.now end
    r.native.Wait=function(ms)r.record('wait',ms);r.now=r.now+math.max(ms,16);r.frame=r.frame+1
        if r.waitHook then r.waitHook(ms)end;return coroutine.yield(ms)end
    for _,name in ipairs({'IsControlPressed','IsDisabledControlPressed'})do
        r.native[name]=function(_,key)return r.controls[key]==true end
    end
    for _,name in ipairs({'IsControlJustPressed','IsDisabledControlJustPressed'})do
        r.native[name]=function(_,key)return r.just[key]==true end
    end
    for _,name in ipairs({'DisableControlAction','DisablePlayerFiring','DrawLine','DrawSphere'})do
        r.native[name]=function(...)r.record(name,...)end
    end
    r.native.DrawSpotLight=function(...)r.record('draw-light',...);r.draws[#r.draws+1]=table.pack(...)end
    local e=H.environment({vector3=R.vector,PlayerPedId=r.native.PlayerPedId,GetGameTimer=r.native.GetGameTimer,Wait=r.native.Wait,
        GetWorldCoordFromScreenCoord=function()return R.vector(),R.vector(0,1,0)end,
        GetFinalRenderedCamRot=function()return R.vector()end,GetFinalRenderedCamCoord=function()return R.vector()end,
        StartShapeTestLosProbe=function(...)r.record('shape-start',...);return 77 end,
        GetShapeTestResultIncludingMaterial=function(id)
            assert(id==77)
            if r.shapeError then error('fixture-raycast',0)end
            if (r.shapePending or 0)>0 then r.shapePending=r.shapePending-1;return 1 end
            local p=table.remove(r.rays,1)or R.vector(4,6,3)
            return 2,r.rayMiss and 0 or 1,p,R.vector(0,0,1),0,0
        end})
    r.library.raycast=H.load('../pr_bridge/bridge/fivem/raycast/client.lua',e)
    r.textui=H.load('../pr_bridge/interface/client/modules/textui.lua',H.environment({
        SetNuiZIndex=function(...)r.record('z-index',...)end}))({
        send=function(name,data)r.record('textui',name,data);r.uiMessages[#r.uiMessages+1]={name=name,data=H.copy(data)}end})
    r.library.ShowTextUI=r.textui.ShowTextUI;r.library.HideTextUI=r.textui.HideTextUI
    r.library.Notify=function(...)r.record('notice',...)end
    r.inputs=r.inputs or{}
    r.library.menus=r.library.menus or{}
    if not r.library.menus.InputDialog then r.library.menus.InputDialog=function(...)
        r.record('input',...);if r.inputHook then return r.inputHook(...)end;return table.remove(r.inputs,1)
    end end
end
function R.bindRuntime(r,ported)
    r.value=nil;r.initial={};r.subscriptions={}
    r.world={peek=function(key)assert(key=='spotlights');return r.value end}
    if ported then
        r.runtime=H.load('kernel/client/spotlights.lua',R.env())({config=r.config,library=r.library,native=r.native,world=r.world,translate=r.translate})
        r.spotlights=r.runtime.Spotlights;r.initial=r.runtime.Threads;r.subscriptions=r.runtime.Subscriptions
    else
        local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore={Client={},State=r.world,t=r.translate}})
        for n,fn in pairs(r.native)do e[n]=fn end
        e.CreateThread=function(fn)r.initial[#r.initial+1]=fn end
        r.world.onChange=function(key,fn)r.subscriptions[#r.subscriptions+1]={key=key,handler=fn}end
        H.load('client/spotlights/main.lua',e);r.spotlights=e.ForgeCore.Client.Spotlights
    end
    assert(#r.initial==1 and #r.subscriptions==1 and not r.spotlights.editorActive and #r.spotlights.lights==0)
    function r.apply(value)r.value=value;r.subscriptions[1].handler(value)end
    function r.run(fn,...)local args=table.pack(...);local co=coroutine.create(function()return fn(table.unpack(args,1,args.n))end)
        local ok,a,b=coroutine.resume(co);assert(ok,a);return co,a,b end
    function r.resume(co)local ok,a,b=coroutine.resume(co);assert(ok,a);return a,b end
    function r.tick()if not r.worker then r.worker=coroutine.create(r.initial[1])end;return r.resume(r.worker)end
    function r.finish(co,confirm)r.just={[confirm==false and 177 or 201]=true};r.controls={}
        local a,b=r.resume(co);r.just={};assert(coroutine.status(co)=='dead');return a,b end
end
function R.client(ported)
    local r=W.world(ported,false);r.config={Spotlights=R.config(ported),NotifyPos='top-right'}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    R.platform(r);R.bindRuntime(r,ported)
    assert(#r.trace==0 and #r.queue==0,'inert client no drawing/worker/UI')
    return r
end
function R.clientCase(name,fn)
    local a,b=R.client(false),R.client(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(P.snapshot(b.spotlights),P.snapshot(a.spotlights),name..' state')
    H.same(b.uiMessages,a.uiMessages,name..' UI')
end
function R.menu(ported)
    local r=W.menu(ported);r.config.Spotlights=R.config(ported)
    r.translate=function(k,p)r.record('translate',k,p);return k end
    R.platform(r);R.bindRuntime(r,ported)
    r.payload=R.seed();r.value=r.payload
    local parentAwait=r.library.callback.await
    r.library.callback.await=function(name,timeout,...)
        if not name:find(':spotlights:',1,true)then return parentAwait(name,timeout,...)end
        assert(timeout==10000);r.record('spotlight-rpc',name,timeout,...)
        if r.rpcHook then return r.rpcHook(name,...)end
        if name==r.config.Spotlights.Callbacks.getAll then return true,H.copy(r.payload)end
        if name==r.config.Spotlights.Callbacks.createLight then return true,99,H.copy(r.payload)end
        return true,H.copy(r.payload)
    end
    if ported then
        r.menuApi=H.load('kernel/client/menu/spotlights.lua',R.env())({
            config=r.config,library=r.library,native=r.native,menu=r.menu,shared=r.shared,spotlights=r.spotlights})
    else
        r.env.ForgeCore.Client.Spotlights=r.spotlights
        H.load('client/menu/menu_spotlights.lua',r.env)
    end
    r.trace={};return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' return');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts')
    H.same(P.snapshot(b.spotlights),P.snapshot(a.spotlights),name..' state')
end
return R
