-- Whole installed NPC sources vs private factories; PR persistence/cache/RPC/context/streaming/blips are installed code.
local V=dofile('tests/kernel_vinewood_harness.lua')
local H,P,W=V.H,V.P,V.W
local R={H=H,P=P,W=W,V=V,env=V.env}
function R.config(ported)
    local cfg={}
    local translate=function(k)return k end
    if ported then
        for _,name in ipairs({'forge_npcs','forge_npcs_peds','forge_npcs_animations'})do
            H.load('kernel/config/'..name..'.lua',R.env())(cfg,translate)
        end
    else
        local e=H.environment({PR=cfg,ForgeCore={t=translate}})
        for _,name in ipairs({'npcs','npcs_peds','npcs_animations'})do H.load('shared/'..name..'.lua',e)end
    end
    return cfg.Npcs
end
function R.seed()return{enabled=true,spawnDistance=120,nextGroupId=3,nextNpcId=2,
    groups={{id=1,name='Group A',description='A'},{id=2,name='Empty',description=''}},
    npcs={{id=1,groupId=1,model='a_m_m_business_01',name='Test',description='NPC',enabled=true,
        coords={x=1,y=2,z=3},rotation={x=0,y=0,z=40},heading=60,
        interaction={mode='both',label='Talk',event='fixture:talk',distance=5,access={job='',gang=''}},
        animation={scenario='',animDict='',animName=''}}}}end
function R.new(ported)
    local r=V.new(ported);r.config.Npcs=R.config(ported)
    r.m.seed(r.config.Npcs.Storage.file,R.seed());r.callbacks={}
    if ported then
        r.service=H.load('kernel/server/npcs.lua',R.env())({config=r.config,library=r.library,native=r.native,
            services=r.services,translate=r.translate,world=r.state})
        for _,d in ipairs(H.load('kernel/server/npcs_callbacks.lua',R.env())({config=r.config,service=r.service}))do
            assert(d.options.access==(d.name==r.config.Npcs.Callbacks.getAll and'player'or'admin'))
            r.callbacks[d.name]=d.handler
        end
    else
        local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore=r.services,
            GetGameTimer=r.native.GetGameTimer,IsPlayerAceAllowed=r.native.IsPlayerAceAllowed})
        r.services.Callbacks={register=function(n,fn)r.callbacks[n]=fn end}
        H.load('server/npcs/service.lua',e);H.load('server/npcs/callbacks.lua',e);r.service=r.services.NpcsService
    end
    assert(not r.service.started and #r.trace==0 and #r.m.trace==0 and #r.queue==0,'inactive Npcs service')
    function r.stateSnapshot()return P.snapshot({r.service,r.state.getRecord('npcs'),r.m.files})end
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
R.natives={'DoesEntityExist','SetEntityAsMissionEntity','DeleteEntity','SetEntityCollision','SetEntityAlpha','FreezeEntityPosition','ResetEntityAlpha','SetEntityHeading','ClearPedTasksImmediately','TaskStartScenarioInPlace','SetTimeout','RequestAnimDict','GetGameTimer','HasAnimDictLoaded','Wait','TaskPlayAnim','SetEntityInvincible','SetBlockingOfNonTemporaryEvents','SetPedCanRagdoll','SetEntityDynamic','SetEntityCoords','PlayerPedId','GetEntityCoords','IsControlJustPressed','GetCurrentResourceName'}
function R.platform(r)
    local O=dofile('tests/kernel_objects_harness.lua')
    O.platform(r)
    r.targets={};r.groups={job={name='police',grade={level=2}},gang={name='ballas',grade=1}}
    r.session={group=function(k)return r.groups[k]end}
    r.resourceStatus='started';r.exportTable={}
    r.integration={resourceState=function()return r.resourceStatus end,
        resolveExports=function(resource)return r.exportTable[resource]end,
        command=function(...)r.record('command',...)end,event=r.native.TriggerEvent or function(...)r.record('interaction-event',...)end}
    r.native.IsEntityAPed=function()return true end
    for _,name in ipairs(R.natives)do
        if not r.native[name]then r.native[name]=function(...)r.record(name,...)end end
    end
    r.animLoaded=true
    r.native.RequestAnimDict=function(...)r.record('request-anim',...)end
    r.native.HasAnimDictLoaded=function()return r.animLoaded end
    r.native.IsControlJustPressed=function()return r.pressed==true end
    r.native.CreatePed=function(pedType,model,x,y,z,heading,...)
        r.record('create-ped',pedType,model,x,y,z,heading,...)
        if r.createError then error('fixture-create',0)end
        if r.createZero then return 0 end
        r.nextEntity=r.nextEntity+1;local id=r.nextEntity;r.entities[id]=true;r.positions[id]=R.vector(x,y,z);r.headings[id]=heading
        return id
    end
    local e=H.environment({Bridge={debug={warn=function(...)r.record('stream-warning',...)end}}})
    for name,fn in pairs(r.native)do e[name]=fn end
    e.IsModelValid=function()return false end
    r.library.fivem.streaming=H.load('../pr_bridge/bridge/fivem/streaming/client.lua',e)
    r.library.fivem.drawtext={drawText3d=function(...)r.record('drawtext',...)end}
    r.library.target.addLocalEntity=function(id,options)r.record('target-add',id,options);r.targets[id]=options end
    r.library.target.removeLocalEntity=function(id,name)r.record('target-remove',id,name);r.targets[id]=nil end
    r.library.devtools={drawPedBox=function(...)r.record('pedbox',...)end,
        placePed=function(model,slots,cb,opts)
            r.record('place-ped',model,slots,opts);r.placeCallback=cb;r.placeOptions=opts
            if r.placeError then error('fixture-place',0)end
            return not r.placeFailed
        end}
    function r.finish(value)assert(r.placeCallback,'No placement session');r.placeCallback(value)end
end
function R.bindRuntime(r,ported)
    r.value=nil;r.initial={};r.subscriptions={};r.events={}
    r.world={peek=function(key)assert(key=='npcs');return r.value end}
    if ported then
        r.runtime=H.load('kernel/client/npcs.lua',R.env())({config=r.config,library=r.library,native=r.native,world=r.world,translate=r.translate,session=r.session,integration=r.integration})
        r.npcs=r.runtime.Npcs;r.initial=r.runtime.Threads;r.subscriptions=r.runtime.Subscriptions;r.events=r.runtime.Events
    else
        local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore={Client={},State=r.world,t=r.translate,Session=r.session},
            GetResourceState=r.integration.resourceState,ExecuteCommand=r.integration.command,TriggerEvent=r.integration.event,
            exports=setmetatable({},{__index=function(_,resource)return r.integration.resolveExports(resource)end})})
        for name,fn in pairs(r.native)do e[name]=fn end
        e.CreateThread=function(fn)r.initial[#r.initial+1]=fn end
        e.AddEventHandler=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=false}end
        r.world.onChange=function(key,fn)r.subscriptions[#r.subscriptions+1]={key=key,handler=fn}end
        H.load('client/npcs/main.lua',e);r.npcs=e.ForgeCore.Client.Npcs
    end
    assert(#r.initial==2 and #r.subscriptions==1 and #r.events==1 and next(r.npcs.entries)==nil,'two inert workers/subscription/stop')
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
    local r=W.world(ported,false);r.config={Npcs=R.config(ported),NotifyPos='top-right'}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    r.native.Wait=function(ms)r.record('wait',ms);r.now=r.now+math.max(ms,1000);return coroutine.yield(ms)end
    R.platform(r);R.bindRuntime(r,ported)
    assert(#r.trace==0 and #r.queue==0,'inactive renderer no entity/IO/timer')
    return r
end
function R.clientCase(name,fn)
    local a,b=R.client(false),R.client(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(P.snapshot(b.npcs),P.snapshot(a.npcs),name..' npc state')
    H.same(P.snapshot({b.entities,b.positions,b.rotations,b.collisions}),P.snapshot({a.entities,a.positions,a.rotations,a.collisions}),name..' platform')
end
function R.menu(ported,nativeCommand)
    local r=W.menu(ported);r.config.Npcs=R.config(ported)
    local parentAwait=r.library.callback.await
    r.translate=function(k,p)r.record('translate',k,p);return k end
    R.platform(r);R.bindRuntime(r,ported)
    r.payload=R.seed();r.value=r.payload;r.apply(r.payload);r.commands={}
    r.library.command=function(name,a,b)r.commands[#r.commands+1]={transport='pr',name=name,properties=a,handler=b}end
    if nativeCommand then r.library.command=nil end
    r.env.RegisterCommand=function(name,fn,restricted)r.commands[#r.commands+1]={transport='native',name=name,handler=fn,restricted=restricted}end
    local await=r.library.callback.await
    r.library.callback.await=function(name,timeout,...)
        if not name:find(':npcs:',1,true)then return parentAwait(name,timeout,...)end
        assert(timeout==10000);r.record('menu-npc-rpc',name,timeout,...)
        if r.rpcHook then return r.rpcHook(name,...)end
        if name==r.config.Npcs.Callbacks.getAll then return true,H.copy(r.payload)end
        return true,99,H.copy(r.payload)
    end
    r.groupRegistry={GetJobs=function()if r.groupError then error('fixture-jobs',0)end;return r.jobs end,
        GetGangs=function()if r.groupError then error('fixture-gangs',0)end;return r.gangs end}
    r.jobs={police={label='Police'},ambulance={label='Ambulance'}};r.gangs={ballas={label='Ballas'}}
    r.isReady=function()return not r.notReady end
    local parentResourceState=rawget(r.env,'GetResourceState')or r.native.GetResourceState
    r.env.GetResourceState=function(name)if name=='qbx_core'then return r.isReady()and'started'or'stopped'end;return parentResourceState(name)end
    r.env.exports={qbx_core={GetJobs=r.groupRegistry.GetJobs,GetGangs=r.groupRegistry.GetGangs}}
    if ported then
        r.menuApi=H.load('kernel/client/menu/npcs.lua',R.env())({config=r.config,library=r.library,native=r.native,menu=r.menu,shared=r.shared,npcs=r.npcs,groups=r.groupRegistry,isReady=r.isReady})
        r.commands=r.menuApi.Commands
    else
        r.env.ForgeCore.Client.Npcs=r.npcs
        r.env.joaat=r.native.joaat;r.env.IsModelInCdimage=r.native.IsModelInCdimage
        H.load('client/menu/menu_npcs.lua',r.env)
    end
    r.trace={};return r
end
function R.menuCase(name,fn,nativeCommand)
    local a,b=R.menu(false,nativeCommand),R.menu(true,nativeCommand)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' return');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts')
    H.same(P.snapshot(b.npcs),P.snapshot(a.npcs),name..' npcs')
    H.same(P.snapshot(b.commands),P.snapshot(a.commands),name..' command contract')
end
return R
