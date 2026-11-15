-- Installed whole client vs private ports. Platform/UI/RPC/character provider are explicit test boundaries.
local H=dofile('tests/kernel_harness.lua')
local P=dofile('tests/kernel_job_catalog_harness.lua').P
local Cache=dofile('tests/cache_harness.lua')
local M=dofile('tests/kernel_admin_menu_harness.lua')
local R={H=H,P=P,M=M}
function R.env()
    local e=H.environment()
    e.require=function(name)assert(name:match('^kernel%.'));return H.load(name:gsub('%.','/')..'.lua',e)end
    e.math.random=function(n)return n or 0.5 end
    return e
end
function R.config()
    return {Whitelist=H.load('kernel/config/forge_whitelist.lua',R.env())(),
        Afk=H.load('kernel/config/forge_afk.lua',R.env())(),NotifyPos='top-right',Debug=true}
end
local function vector(x,y,z)
    return setmetatable({x=x,y=y,z=z},{__sub=function(a,b)return vector(a.x-b.x,a.y-b.y,a.z-b.z)end,
        __len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end})
end
R.vector=vector
local NAMES={"AddBlipForCoord","AddTextComponentString","BeginTextCommandSetBlipName","ClearDrawOrigin","CreateThread","DoScreenFadeIn","DoScreenFadeOut","DoesBlipExist","DrawMarker","DrawText","EndTextCommandSetBlipName","GetEntityCoords","GetGameTimer","IsControlJustPressed","PlayerPedId","RemoveBlip","SetBlipAsShortRange","SetBlipColour","SetBlipScale","SetBlipSprite","SetDrawOrigin","SetEntityCoords","SetEntityHeading","SetTextCentre","SetTextEntry","SetTextFont","SetTextScale","SetTimeout","Wait","FreezeEntityPosition","GetEntityHeading","IsControlJustReleased","IsDisabledControlJustReleased","RequestCollisionAtCoord"}
function R.find(fn,key,seen)
    if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
    for i=1,100 do
        local n,v=debug.getupvalue(fn,i);if not n then break end
        if n==key then return v end
        if n~='_ENV'then local found=R.find(v,key,seen);if found~=nil then return found end end
    end
end
function R.new(ported)
    local r=Cache.new(false);local e=r.env
    r.trace={};r.inputs={};r.alerts={};r.ped=11;r.pos=vector(0,0,0);r.heading=0;r.loaded=true;r.creation=false;r.resource='stopped'
    r.blips={};r.zones={};r.initial={};r.descriptors={};r.config=R.config()
    r.config.Whitelist.Defaults.spawnCoords={x=1,y=2,z=3,w=90}
    r.cfg=H.copy(r.config.Whitelist.Defaults);r.cfg.enabled=true
    r.cfg.citizenZone={coords={x=1,y=2,z=3},size={x=100,y=100,z=100}}
    r.cfg.examCoords={x=1,y=2,z=3,w=90};r.cfg.completionCoords={x=9,y=8,z=7,w=45}
    r.cfg.questions={{question='Question',options={{label='Yes',value=true},{label='No',value=false}}}}
    r.cfg.preExam={enabled=false};r.cfg.interactionMode='both';r.cfg.blip={enabled=true}
    function r.record(k,...)r.trace[#r.trace+1]={kind=k,args=P.snapshot(table.pack(...))}end
    r.native={vector3=vector,vec3=vector}
    for _,n in ipairs(NAMES)do r.native[n]=function(...)r.record(n,...)end end
    local oldWait=e.Wait
    r.native.Wait=function(ms)return oldWait(math.max(10,ms))end
    r.native.SetTimeout=e.SetTimeout;r.native.CreateThread=e.CreateThread
    r.native.PlayerPedId=function()return r.ped end
    r.native.GetEntityCoords=function()return r.pos end
    r.native.GetEntityHeading=function()return r.heading end
    r.native.GetGameTimer=function()return r.now end
    r.native.SetEntityCoords=function(p,x,y,z,...)r.record('teleport',p,x,y,z,...);r.pos=vector(x,y,z)end
    r.native.SetEntityHeading=function(p,w)r.record('heading',p,w);r.heading=w end
    r.native.AddBlipForCoord=function(...)r.record('add-blip',...);r.blips[33]=true;return 33 end
    r.native.DoesBlipExist=function(id)return r.blips[id]==true end
    r.native.RemoveBlip=function(id)r.record('remove-blip',id);r.blips[id]=false end
    r.native.IsControlJustPressed=function()local p=r.press;r.press=false;return p end
    r.native.IsControlJustReleased=function(_,key)return r.controls and r.controls[key]==true end
    r.native.IsDisabledControlJustReleased=function()return false end
    r.library=e.pr_lib;r.library.framework=nil
    r.library.Notify=function(...)r.record('notify',...)end
    r.library.menus={InputDialog=function(...)r.record('input',...);if r.inputHook then return r.inputHook(...)end;return table.remove(r.inputs,1)end,
        AlertDialog=function(...)r.record('alert',...);if r.alertHook then return r.alertHook(...)end;return table.remove(r.alerts,1)end}
    r.library.target={addBoxZone=function(data)r.record('target-add',data);r.target=data;r.zones[44]=data;return 44 end,
        removeZone=function(id)r.record('target-remove',id);r.zones[id]=nil end}
    r.library.callback.await=function(name,timeout,...)
        assert(timeout==10000);r.record('await',name,...)
        if r.awaitHook then return r.awaitHook(name,...)end
        local c=r.config.Whitelist.Callbacks
        if name==c.check then return r.allowed==true,H.copy(r.cfg)end
        if name==c.getConfig then return true,H.copy(r.cfg)end
        if name==c.add then return r.addAllowed==true,'no_permission'end
        return true
    end
    r.integration={resourceState=function(n)assert(n=='spacebox_multichar');r.record('resource-state',n);return r.resource end,
        isInCharacterCreation=function(n)assert(n=='spacebox_multichar');r.record('creation',n)
            if r.creationError then error('fixture-creation',0)end;return r.creation end}
    r.session={isLoaded=function()return r.loaded end}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    local oldAdd=e.AddEventHandler
    local function listen(d)r.descriptors[#r.descriptors+1]=d;oldAdd(d.name,d.handler)end
    for n,fn in pairs(r.native)do e[n]=fn end
    if ported then
        r.api=H.load('kernel/client/access_runtime.lua',R.env())({config=r.config,library=r.library,native=r.native,
            session=r.session,translate=r.translate,characterIntegration=r.integration})
        assert(#r.trace==0 and #r.queue==0,'inactive runtime constructor')
        r.state=r.api.State;r.callbacks=r.api.Callbacks;r.initial=r.api.Threads
        for _,d in ipairs(r.api.Events)do listen(d)end
    else
        e.ForgeCore={Session=r.session,t=r.translate};e.PR=r.config
        e.GetResourceState=r.integration.resourceState
        e.exports.spacebox_multichar={isInCharacterCreation=function()return r.integration.isInCharacterCreation('spacebox_multichar')end}
        e.math=H.copy(math);e.math.random=function(n)return n or 0.5 end
        e.CreateThread=function(fn)r.initial[#r.initial+1]=fn end
        e.RegisterNetEvent=function(n,fn)listen({name=n,handler=fn,network=true})end
        e.AddEventHandler=function(n,fn)listen({name=n,handler=fn,network=false})end
        H.load('client/whitelist/main.lua',e);e.CreateThread=r.native.CreateThread
        r.callbacks=r.callbacks
        r.state=assert(R.find(r.descriptors[#r.descriptors].handler,'Whitelist'))
    end
    function r.fn(key)
        for _,fn in pairs(r.callbacks)do local v=R.find(fn,key);if v~=nil then return v end end
        for _,d in ipairs(r.descriptors)do local v=R.find(d.handler,key);if v~=nil then return v end end
        error('test upvalue missing '..key)
    end
    function r.run(fn,...)local args=table.pack(...);r.native.CreateThread(function()fn(table.unpack(args,1,args.n))end)end
    function r.start(cfg,force)r.run(r.fn('startWhitelist'),cfg or r.cfg,force)end
    function r.stop()r.fn('stopWhitelist')()end
    function r.cb(key,...)r.run(assert(r.callbacks[r.config.Whitelist.Callbacks[key]]),...)end
    r.trace={}
    return r
end
function R.outcome(fn,r)
    local out=table.pack(pcall(fn,r))
    if not out[1]then
        local err=tostring(out[2])
        assert(err:find('fixture-',1,true),'Unexpected test error: '..err)
        out[2]=err:gsub('[^\n]-:%d+: ','')
    end
    return P.snapshot(out)
end
function R.case(name,fn)
    local a,b=R.new(false),R.new(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return')
    H.same(b.trace,a.trace,name..' effects');H.same(b.state,a.state,name..' state')
    H.same(P.snapshot({b.pos,b.heading,b.zones,b.blips}),P.snapshot({a.pos,a.heading,a.zones,a.blips}),name..' platform')
end
function R.menu(ported)
    local r=M.new(ported);r.config.Whitelist=R.config().Whitelist;r.config.Afk=R.config().Afk
    r.cfg=H.copy(r.config.Whitelist.Defaults);r.cfg.questions={{question='Q',options={{label='Yes',value=true}}}}
    r.native.SetTimeout=r.native.setTimeout;r.native.PlayerPedId=function()return 11 end
    r.native.GetEntityCoords=function()return vector(1.23456,2.34567,3.45678)end
    r.native.GetEntityHeading=function()return 89.567 end
    for _,n in ipairs({"CreateThread","DoScreenFadeIn","DoScreenFadeOut","FreezeEntityPosition","GetEntityCoords","GetEntityHeading","IsControlJustReleased","IsDisabledControlJustReleased","PlayerPedId","RequestCollisionAtCoord","SetEntityCoords","SetEntityHeading","SetTimeout","Wait"})do
        if not r.native[n]then r.native[n]=function(...)r.record(n,...)end end
    end
    r.workers={};r.native.CreateThread=function(fn)r.workers[#r.workers+1]=coroutine.create(fn)end
    r.native.Wait=function(ms)r.record('wait',ms);coroutine.yield(ms)end
    r.native.IsControlJustReleased=function(_,key)return r.controls and r.controls[key]==true end
    r.native.IsDisabledControlJustReleased=function()return false end
    r.library.ShowTextUI=function(...)r.record('show-text',...)end;r.library.HideTextUI=function(...)r.record('hide-text',...)end
    r.laser={};r.library.devlaser={start=function(opts)r.record('laser-start',opts);r.laser.opts=opts;r.laser.active=true end,
        isActive=function()return r.laser.active end,getTarget=function()return r.laser.target end,
        stop=function(silent)r.record('laser-stop',silent);r.laser.active=false end}
    r.library.callback.await=function(name,timeout,...)
        assert(timeout==10000);r.record('await',name,timeout,...)
        if r.awaitHook then return r.awaitHook(name,...)end
        if name==r.config.Whitelist.Callbacks.getConfig then return true,H.copy(r.cfg)end
        if name==r.config.Whitelist.Callbacks.listPlayers then return true,H.copy(r.list or {})end
        if name==r.config.Whitelist.Callbacks.saveConfig then r.saved=H.copy((...))end
        return true,{}
    end
    if ported then
        local ports={menu=r.menu,shared=r.shared,config=r.config,library=r.library,native=r.native}
        -- Shared22 intentionally contains ten boundary helpers; central25 completes clone/boolLabel.
        -- Load that whole installed port, as the canonical WorkMenus composition does.
        ports.client={Menu=r.menu};ports.translate=r.translate;ports.integrations={}
        H.load('kernel/client/menu/central.lua',R.env())(ports)
        r.boundary=H.load('kernel/client/menu/whitelist.lua',R.env())(ports)
        r.afk=H.load('kernel/client/menu/afk.lua',R.env())(ports)
    else
        local e=r.env;e.PR=r.config
        for n,fn in pairs(r.native)do e[n]=fn end
        r.library.framework={ShowTextUI=r.library.ShowTextUI,HideTextUI=r.library.HideTextUI}
        H.load('client/menu/menu_whitelist.lua',e);H.load('client/menu/menu_server.lua',e)
        r.menu.openServerSettingsMenu=function()r.record('parent-settings')end
    end
    function r.tick()
        local co=assert(r.workers[1]);local ok,err=coroutine.resume(co);assert(ok,err)
    end
    r.trace={}
    return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return')
    H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts')
    H.same(b.saved,a.saved,name..' config')
end
return R
