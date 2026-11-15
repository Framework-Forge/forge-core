-- Whole installed Billboards sources vs private factories; PR persistence/cache/RPC/context/streaming/blips are installed code.
local V=dofile('tests/kernel_vinewood_harness.lua')
local H,P,W=V.H,V.P,V.W
local R={H=H,P=P,W=W,V=V,env=V.env}
function R.config(ported)
    if ported then return H.load('kernel/config/forge_billboards.lua',R.env())()end
    local e=H.environment({PR={}});H.load('shared/billboards.lua',e);return e.PR.Billboards
end
function R.seed()return{enabled=true,renderDistance=120,editDistance=10,nextGroupId=3,nextBillboardId=2,
    groups={{id=1,name='Group A'},{id=2,name='Empty'}},
    billboards={{id=1,groupId=1,name='Board A',enabled=true,url='fixture://image-A',width=1280,height=720,offset=0.03,
        vertices={{x=0,y=1,z=2},{x=2,y=1,z=2},{x=0,y=1,z=0},{x=2,y=1,z=0}}}}}end
function R.new(ported)
    local r=V.new(ported);r.config.Billboards=R.config(ported)
    r.m.seed(r.config.Billboards.Storage.file,R.seed());r.callbacks={}
    if ported then
        r.service=H.load('kernel/server/billboards.lua',R.env())({config=r.config,library=r.library,native=r.native,
            services=r.services,translate=r.translate,world=r.state})
        for _,d in ipairs(H.load('kernel/server/billboards_callbacks.lua',R.env())({config=r.config,service=r.service}))do
            assert(d.options.access==(d.name==r.config.Billboards.Callbacks.getAll and'player'or'admin'))
            r.callbacks[d.name]=d.handler
        end
    else
        local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore=r.services,
            GetGameTimer=r.native.GetGameTimer,IsPlayerAceAllowed=r.native.IsPlayerAceAllowed})
        r.services.Callbacks={register=function(n,fn)r.callbacks[n]=fn end}
        H.load('server/billboards/service.lua',e);H.load('server/billboards/callbacks.lua',e);r.service=r.services.BillboardsService
    end
    assert(not r.service.started and #r.trace==0 and #r.m.trace==0 and #r.queue==0,'inactive Billboards service')
    function r.stateSnapshot()return P.snapshot({r.service,r.state.getRecord('billboards'),r.m.files})end
    return r
end
function R.case(name,fn,withoutStart)
    local a,b=R.new(false),R.new(true)
    local function action(r)if not withoutStart then r.service.start()end;return fn(r)end
    H.same(V.outcome(action,b),V.outcome(action,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(b.m.trace,a.m.trace,name..' persistence')
    H.same(b.stateSnapshot(),a.stateSnapshot(),name..' state')
end
local L=dofile('tests/kernel_spotlights_harness.lua')
R.vector=L.vector
R.natives={'DestroyDui','CreateRuntimeTxd','CreateDui','GetDuiHandle','CreateRuntimeTextureFromDuiHandle','DrawSpritePoly','Wait','DisableControlAction','DisablePlayerFiring','PlayerId','DrawSphere','DrawLine','IsControlJustPressed','IsDisabledControlJustPressed','IsControlPressed','IsDisabledControlPressed','GetEntityCoords','PlayerPedId','GetCurrentResourceName'}
function R.platform(r)
    L.platform(r)
    r.duis={};r.nextDui=200;r.polys={}
    r.rays={R.vector(1.12345,2.23456,3.34567),R.vector(4.12345,2.23456,3.34567),
        R.vector(1.12345,2.23456,1.34567),R.vector(4.12345,2.23456,1.34567)}
    r.native.GetCurrentResourceName=function()return'forge-core'end
    r.native.CreateRuntimeTxd=function(name)r.record('create-txd',name);return'txd:'..name end
    r.native.CreateDui=function(url,w,h)
        r.record('create-dui',url,w,h)
        if r.duiError then error('fixture-createDui',0)end
        r.nextDui=r.nextDui+1;local id=r.duiZero and 0 or r.nextDui
        r.duis[id]={url=url,width=w,height=h};return id
    end
    r.native.DestroyDui=function(id)
        r.record('destroy-dui',id);if r.destroyError then error('fixture-destroyDui',0)end
        r.duis[id]=nil
    end
    r.native.GetDuiHandle=function(id)r.record('dui-handle',id);return'handle:'..id end
    r.native.CreateRuntimeTextureFromDuiHandle=function(...)r.record('dui-texture',...)end
    r.native.DrawSpritePoly=function(...)r.record('poly',...);r.polys[#r.polys+1]=table.pack(...)end
end
function R.resume(co)local ok,a,b=coroutine.resume(co);assert(ok,a);return a,b end
function R.completeCapture(r,co)
    local a,b
    for i=1,4 do
        r.just={[38]=true};assert(R.resume(co)==250)
        r.just={};a,b=R.resume(co)
        if i<4 then assert(a==0)end
    end
    return a,b
end
function R.bindRuntime(r,ported)
    r.value=nil;r.initial={};r.subscriptions={};r.events={}
    r.world={peek=function(key)assert(key=='billboards');return r.value end}
    if ported then
        r.runtime=H.load('kernel/client/billboards.lua',R.env())({config=r.config,library=r.library,native=r.native,world=r.world,translate=r.translate})
        r.billboards=r.runtime.Billboards;r.initial=r.runtime.Threads;r.subscriptions=r.runtime.Subscriptions;r.events=r.runtime.Events
    else
        local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore={Client={},State=r.world,t=r.translate}})
        for n,fn in pairs(r.native)do e[n]=fn end
        e.CreateThread=function(fn)r.initial[#r.initial+1]=fn end
        e.AddEventHandler=function(n,fn)r.events[#r.events+1]={name=n,handler=fn,network=false}end
        r.world.onChange=function(key,fn)r.subscriptions[#r.subscriptions+1]={key=key,handler=fn}end
        H.load('client/billboards/main.lua',e);r.billboards=e.ForgeCore.Client.Billboards
    end
    assert(#r.initial==1 and #r.subscriptions==1 and #r.events==1 and not r.billboards.captureActive and next(r.billboards.duis)==nil)
    function r.apply(v)r.value=v;r.subscriptions[1].handler(v)end
    function r.run(fn,...)local args=table.pack(...);local co=coroutine.create(function()return fn(table.unpack(args,1,args.n))end)
        local a,b=R.resume(co);return co,a,b end
    r.resume=R.resume
    function r.tick()if not r.worker then r.worker=coroutine.create(r.initial[1])end;return R.resume(r.worker)end
    function r.finish(co,confirm)r.just={[confirm==false and 177 or 201]=true};r.controls={};local a,b=R.resume(co);r.just={};assert(coroutine.status(co)=='dead');return a,b end
    function r.stop(n)r.events[1].handler(n or'forge-core')end
end
function R.client(ported)
    local r=W.world(ported,false);r.config={Billboards=R.config(ported),NotifyPos='top-right'}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    R.platform(r);R.bindRuntime(r,ported)
    assert(#r.trace==0 and #r.queue==0 and next(r.duis)==nil,'inert DUI client no creation/UI/worker')
    return r
end
function R.clientCase(name,fn)
    local a,b=R.client(false),R.client(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(P.snapshot(b.billboards),P.snapshot(a.billboards),name..' state')
    H.same(b.duis,a.duis,name..' native DUI state');H.same(b.uiMessages,a.uiMessages,name..' UI')
end
function R.menu(ported)
    local r=W.menu(ported);r.config.Billboards=R.config(ported)
    r.translate=function(k,p)r.record('translate',k,p);return k end
    R.platform(r);R.bindRuntime(r,ported)
    r.payload=R.seed();r.value=r.payload
    local parentAwait=r.library.callback.await
    r.library.callback.await=function(name,timeout,...)
        if not name:find(':billboards:',1,true)then return parentAwait(name,timeout,...)end
        assert(timeout==10000);r.record('billboard-rpc',name,timeout,...)
        if r.rpcHook then return r.rpcHook(name,...)end
        if name==r.config.Billboards.Callbacks.getAll then return true,H.copy(r.payload)end
        if name==r.config.Billboards.Callbacks.createBillboard then return true,99,H.copy(r.payload)end
        return true,H.copy(r.payload)
    end
    if ported then
        r.menuApi=H.load('kernel/client/menu/billboards.lua',R.env())({
            config=r.config,library=r.library,native=r.native,menu=r.menu,shared=r.shared,billboards=r.billboards})
    else
        r.env.ForgeCore.Client.Billboards=r.billboards
        H.load('client/menu/menu_billboards.lua',r.env)
    end
    r.trace={};return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' return');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts')
    H.same(P.snapshot(b.billboards),P.snapshot(a.billboards),name..' state');H.same(b.duis,a.duis,name..' native DUI state')
end
return R
