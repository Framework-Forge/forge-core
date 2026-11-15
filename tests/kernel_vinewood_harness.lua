-- Whole installed sources vs inactive factories. IO, network, entities and time are virtual.
local W=dofile('tests/kernel_world_harness.lua')
local H,P=W.H,W.P
local J=dofile('tests/kernel_job_catalog_harness.lua')
local R={H=H,P=P,W=W,env=W.env}
function R.config(ported)
    local vector3=function(x,y,z)return{x=x,y=y,z=z}end
    if ported then return H.load('kernel/config/forge_vinewood.lua',R.env())({vector3=vector3})end
    local e=H.environment({PR={},vector3=vector3});H.load('shared/vinewood.lua',e);return e.PR.Vinewood
end
function R.new(ported)
    local m=J.persistence();local r=W.world(ported,true,m.api)
    r.m=m;r.config={Vinewood=R.config(ported),NotifyPos='top-right',AdminAce='forge-core.admin'}
    r.library.table=H.load('../pr_bridge/bridge/utils/tables.lua',R.env())
    r.library.utils={trim=function(v)return tostring(v or ''):match('^%s*(.-)%s*$')end}
    r.jobResult=true;r.ace=true
    r.native.IsPlayerAceAllowed=function(src,ace)r.record('ace',src,ace);return r.ace end
    r.services={JobService={canManage=function(src)r.record('job-access',src)
        if r.jobError then error('fixture-job',0)end;return r.jobResult end}}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    r.library.debug={success=function(...)r.record('log-success',...)end}
    r.library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    r.m.seed(r.config.Vinewood.Storage.file,{enabled=true,text='FORGE',color='#FFFFFF'})
    r.callbacks={}
    if ported then
        r.service=H.load('kernel/server/vinewood.lua',R.env())({config=r.config,library=r.library,native=r.native,
            services=r.services,translate=r.translate,world=r.state})
        for _,d in ipairs(H.load('kernel/server/vinewood_callbacks.lua',R.env())({config=r.config,service=r.service}))do
            assert(d.options.access=='admin');r.callbacks[d.name]=d.handler
        end
    else
        local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore=r.services,
            GetGameTimer=r.native.GetGameTimer,IsPlayerAceAllowed=r.native.IsPlayerAceAllowed})
        r.services.t=r.translate;r.services.State=r.state
        r.services.Callbacks={register=function(name,fn)r.callbacks[name]=fn end}
        H.load('server/vinewood/service.lua',e);H.load('server/vinewood/callbacks.lua',e)
        r.service=r.services.VinewoodService
    end
    assert(not r.service.started and #r.trace==0 and #r.m.trace==0 and #r.queue==0,'inactive Vinewood server constructor')
    function r.stateSnapshot()return P.snapshot({r.service,r.state.getRecord('vinewood'),r.m.files})end
    return r
end
function R.outcome(fn,r)
    local out=table.pack(pcall(fn,r))
    if not out[1]then
        local err=tostring(out[2]);assert(err:find('fixture-',1,true),'Unexpected test error: '..err)
        out[2]=err:gsub('stack traceback:[%s%S]*',''):gsub('[^\n]-:%d+: ',''):gsub('%s+$','')
    end
    return P.snapshot(out)
end
function R.case(name,fn)
    local a,b=R.new(false),R.new(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(b.m.trace,a.m.trace,name..' persistence')
    H.same(b.stateSnapshot(),a.stateSnapshot(),name..' state')
end
R.natives={'DoesEntityExist','DeleteEntity','RemoveReplaceTexture','CreateRuntimeTxd','CreateRuntimeTexture',
    'SetRuntimeTexturePixel','CommitRuntimeTexture','AddReplaceTexture','joaat','RequestModel','GetGameTimer',
    'HasModelLoaded','Wait','CreateObject','SetEntityHeading','FreezeEntityPosition','SetModelAsNoLongerNeeded','GetCurrentResourceName'}
function R.platform(r)
    r.entities={};r.nextEntity=100;r.loaded=true;r.sessionLoaded=true;r.mathError=false;r.waited=0
    r.library.math=H.load('../pr_bridge/bridge/utils/numbers.lua',R.env())
    local hex=r.library.math.hexToRGB
    r.library.math.hexToRGB=function(...)if r.mathError then error('fixture-color',0)end;return hex(...)end
    r.native.GetCurrentResourceName=function()return'forge-core'end
    r.native.joaat=function(model)return'hash:'..tostring(model):lower()end
    r.native.RequestModel=function(model)r.record('request-model',model)end
    r.native.HasModelLoaded=function()return r.loaded end
    r.native.DoesEntityExist=function(entity)return r.entities[entity]==true end
    r.native.DeleteEntity=function(entity)r.record('delete',entity);r.entities[entity]=nil end
    r.native.CreateObject=function(...)r.record('create',...);r.nextEntity=r.nextEntity+1
        local id=r.createZero and 0 or r.nextEntity;r.entities[id]=true;return id end
    for _,name in ipairs({'RemoveReplaceTexture','SetRuntimeTexturePixel','CommitRuntimeTexture','AddReplaceTexture',
        'SetEntityHeading','FreezeEntityPosition','SetModelAsNoLongerNeeded'})do
        r.native[name]=function(...)r.record(name,...);if r.nativeHook then r.nativeHook(name,...)end end
    end
    r.native.CreateRuntimeTxd=function(...)r.record('txd',...);return 201 end
    r.native.CreateRuntimeTexture=function(...)r.record('texture',...);return 202 end
end
function R.client(ported)
    local r=W.world(ported,false);r.config={Vinewood=R.config(ported)}
    R.platform(r);r.value=nil;r.initial={};r.subscriptions={};r.events={}
    r.world={peek=function(key)assert(key=='vinewood');return r.value end}
    r.session={isLoaded=function()return r.sessionLoaded end}
    r.native.Wait=function(ms)
        r.record('wait',ms);r.waited=r.waited+1;r.now=r.now+math.max(ms,1000)
        if r.waitHook then r.waitHook(ms)end
        return coroutine.yield(ms)
    end
    if ported then
        r.runtime=H.load('kernel/client/vinewood.lua',R.env())({config=r.config,library=r.library,native=r.native,
            world=r.world,session=r.session})
        r.initial,r.subscriptions,r.events=r.runtime.Threads,r.runtime.Subscriptions,r.runtime.Events
    else
        local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore={Client={},State=r.world,Session=r.session}})
        for name,fn in pairs(r.native)do e[name]=fn end
        e.CreateThread=function(fn)r.initial[#r.initial+1]=fn end
        r.world.onChange=function(key,fn)r.subscriptions[#r.subscriptions+1]={key=key,handler=fn}end
        e.AddEventHandler=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=false}end
        H.load('client/vinewood/main.lua',e)
    end
    assert(#r.initial==1 and #r.events==1 and #r.subscriptions==1 and #r.trace==0 and #r.queue==0,'inactive renderer descriptors')
    function r.run(fn,...)local args=table.pack(...);local co=coroutine.create(function()fn(table.unpack(args,1,args.n))end)
        local ok,ms=coroutine.resume(co);assert(ok,ms);return co,ms end
    function r.resume(co)local ok,ms=coroutine.resume(co);assert(ok,ms);return ms end
    function r.apply(value)return r.run(r.subscriptions[1].handler,value)end
    function r.stop(resource)return r.run(r.events[1].handler,resource or'forge-core')end
    return r
end
function R.clientCase(name,fn)
    local a,b=R.client(false),R.client(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(b.entities,a.entities,name..' entities')
    H.same(b.now,a.now,name..' clock')
end
function R.menu(ported,nativeCommand)
    local r=W.menu(ported);r.config.Vinewood=R.config(ported)
    r.vinewoodSettings=H.copy(r.config.Vinewood.Defaults);r.commands={}
    r.library.command=function(name,a,b)r.commands[#r.commands+1]={transport='pr',name=name,properties=a,handler=b}end
    if nativeCommand then r.library.command=nil end
    r.native.RegisterCommand=function(name,a,b)r.commands[#r.commands+1]={transport='native',name=name,handler=a,restricted=b}end
    local await=r.library.callback.await
    r.library.callback.await=function(name,timeout,...)
        if name~=r.config.Vinewood.Callbacks.getSettings and name~=r.config.Vinewood.Callbacks.saveSettings then return await(name,timeout,...)end
        assert(timeout==10000);r.record('vinewood-rpc',name,timeout,...)
        if r.vinewoodHook then return r.vinewoodHook(name,...)end
        if name==r.config.Vinewood.Callbacks.getSettings then return true,H.copy(r.vinewoodSettings)end
        r.vinewoodSettings=H.copy((...));return true,H.copy(r.vinewoodSettings)
    end
    if ported then
        r.vinewood=H.load('kernel/client/menu/vinewood.lua',R.env())({config=r.config,library=r.library,native=r.native,menu=r.menu,shared=r.shared})
        r.commands=r.vinewood.Commands
    else
        r.env.RegisterCommand=r.native.RegisterCommand
        H.load('client/menu/menu_vinewood.lua',r.env)
    end
    assert(#r.commands==1,'one unbound command descriptor');r.trace={};return r
end
function R.menuCase(name,fn,nativeCommand)
    local a,b=R.menu(false,nativeCommand),R.menu(true,nativeCommand)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts')
    H.same(b.vinewoodSettings,a.vinewoodSettings,name..' settings')
    H.same(P.snapshot(b.commands),P.snapshot(a.commands),name..' command contract')
end
return R
