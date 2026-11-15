-- Strict installed-body vs inactive-factory fixtures. All items, time, props and wire effects are simulated.
local I=dofile('tests/kernel_inventory_harness.lua')
local H,P=I.H,I.P
local C={H=H,P=P,I=I}
local function packed(...)return P.snapshot(table.pack(...))end
function C.new(side,ported,options)
    local r={side=side,ported=ported,trace={},events={},exports={},callbacks={},threads={},workers={},timers={},keybinds={},
        registered={},items={burger={name='burger',active=true,interaction={enabled=true,duration=1000,remove=1,effects={hunger={min=5,max=5}}}}},
        response=true,removed=true,registerResult=true,now=0,ped=10,entities={[10]=true},nextEntity=100,modelLoaded=true,
        progress=true,anim=true,dead=false,playing=true,invoker=nil}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=packed(...)}end
    r.env=H.environment({source=0})
    local env=r.env
    env.math.random=function(a,b)r.record('random',a,b);return r.randomMax and b or a end
    local function listen(name,fn,network)r.events[#r.events+1]={name=name,handler=fn,network=network==true}end
    function r.dispatch(name,src,...)
        for _,e in ipairs(r.events)do if e.name==name then
            if ported and side=='server' and (e.network or name=='playerDropped')then e.handler(src,...)
            else env.source=src;e.handler(...)end
        end end
    end
    local function emitClient(...)r.record('client',...);if r.onClient then r.onClient(...)end end
    local function emit(...)r.record('event',...);if r.onEvent then r.onEvent(...)end end
    local native={emitClient=emitClient,getInvokingResource=function()return r.invoker end,
        setTimeout=function(ms,fn)r.record('timer',ms);r.timers[#r.timers+1]={ms=ms,fn=fn}end,
        print=function(...)r.record('print',...)end}
    r.native=native
    r.integrations={useLockpick=function(src,advanced)emitClient('lockpicks:UseLockpick',src,advanced);emit('lockpicks:UseLockpick',src,advanced)end,
        setEvidenceStatus=function(...)emit('evidence:client:SetStatus',...)end}
    r.services={InventoryService={
        getItem=function(name)r.record('get-item',name);return r.items[name]end,
        getPayload=function()r.record('payload');local list={};for _,key in ipairs({'burger','water','lockpick','advancedlockpick'})do
            if r.items[key]then list[#list+1]=r.items[key]end end;return {items=list}end}}
    r.usable={RegisterUsableItem=function(name,cb,opts)
        r.record('register',name,opts);r.registered[#r.registered+1]={name=name,cb=cb,opts=opts};return r.registerResult end}
    r.library={callback={awaitClient=function(...)
        r.record('await',...);if r.awaitHook then return r.awaitHook(...)end
        if r.awaitError then error('simulated-await',0)end;return r.response
    end},inventory={RegisterUsableItem=r.usable.RegisterUsableItem,RemoveItem=function(...)
        r.record('remove',...);if r.removeHook then return r.removeHook(...)end
        if r.removeError then error('simulated-remove',0)end;return r.removed
    end}}
    r.status={AddStatuses=function(values)r.record('statuses',values);if r.statusError then error('simulated-status',0)end;return true end,
        ApplyStatusEffects=function(values)emit('qbx_core:client:applyStatusEffects',values)end}
    r.config=I.config(true)
    local function effect(name)return function(...)r.record(name,...)end end
    for _,name in ipairs({'DetachEntity','SetEntityAsMissionEntity','StopAnimTask','AttachEntityToEntity',
        'SetModelAsNoLongerNeeded','SetCurrentPedWeapon','AnimpostfxStop','SetRunSprintMultiplierForPlayer',
        'AnimpostfxPlay','SetFlash','RestorePlayerStamina','SetPedToRagdoll','ClearPedBloodDamage'})do native[name]=effect(name)end
    native.PlayerPedId=function()return r.ped end;native.PlayerId=function()return 7 end
    native.DoesEntityExist=function(id)return r.entities[id]==true end
    native.IsEntityDead=function()return r.dead end;native.IsEntityPlayingAnim=function()return r.playing end
    native.GetEntityCoords=function()return {x=1,y=2,z=3}end
    native.CreateObject=function(...)r.record('CreateObject',...);if r.objectFail then return 0 end
        r.nextEntity=r.nextEntity+1;r.entities[r.nextEntity]=true;return r.nextEntity end
    native.DeleteEntity=function(id)r.record('DeleteEntity',id);r.entities[id]=nil end
    native.GetPedBoneIndex=function(_,bone)return bone+1 end
    native.GetHashKey=function(name)return #name end
    native.GetCurrentResourceName=function()return'forge-core'end
    native.GetGameTimer=function()return r.now end
    native.Wait=function(ms)return coroutine.yield(ms)end
    native.IsPedRunning=function()return r.running==true end
    native.spawn=function(fn)r.record('spawn');r.workers[#r.workers+1]=fn end
    r.library.playAnim=function(data)r.record('anim',data);if r.animHook then return r.animHook(data)end;return r.anim end
    r.library.requestModel=function(model,timeout)r.record('model',model,timeout);if r.modelHook then return r.modelHook(model,timeout)end
        return r.modelLoaded,r.modelLoaded and #tostring(model)or nil end
    r.library.progressBar=function(data)r.record('progress',data);return r.progress end
    r.library.Notify=effect('notify')
    r.library.addKeybind=function()error('Live keybind registration forbidden')end
    if options then options(r)end
    if ported then
        r.api=H.load('kernel/'..side..'/inventory/consumables.lua',env)({services=r.services,library=r.library,native=native,
            integrations=r.integrations,usable=r.usable,config=r.config,status=r.status})
        assert(#r.trace==0 and #r.timers==0 and #r.workers==0,'constructor effects')
        r.events=r.api.Events;r.exports=r.api.Exports or {};r.callbacks=r.api.Callbacks or {}
        r.threads=r.api.Threads or {};r.keybinds=r.api.Keybinds or {}
        if side=='server'and not r.noInit then assert(r.api.Initialize());assert(not r.api.Initialize())end
    else
        env.ForgeCore=r.services;env.pr_lib=r.library;env.PR={Inventory=r.config}
        env.TriggerClientEvent=emitClient;env.TriggerEvent=function(name,...)
            if name=='qbx_core:client:applyStatusEffects'then return r.status.ApplyStatusEffects(...)end
            return emit(name,...)end
        env.GetInvokingResource=native.getInvokingResource;env.SetTimeout=native.setTimeout
        env.RegisterNetEvent=function(name,fn)listen(name,fn,true)end;env.AddEventHandler=function(name,fn)listen(name,fn,false)end
        env.exports=setmetatable({qbx_core={AddStatuses=function(_,...)return r.status.AddStatuses(...)end}},
            {__call=function(_,name,fn)r.exports[name]=fn end})
        for name,fn in pairs(native)do if name:match('^[A-Z]')then env[name]=fn end end
        env.CreateThread=function(fn)if r.loaded then native.spawn(fn)else r.threads[#r.threads+1]=fn end end
        r.library.callback.register=function(name,fn)r.callbacks[name]=fn end
        r.library.addKeybind=function(data)r.keybinds[#r.keybinds+1]=data end
        H.load(side..'/inventory/consumables.lua',env)
        r.api=side=='server'and r.services.ConsumableService or {}
    end
    r.loaded=true
    function r.runTimers()local timers=r.timers;r.timers={};for _,v in ipairs(timers)do v.fn()end end
    function r.use(src,name,slot)
        name=name or'burger';local cb
        for _,v in ipairs(r.registered)do if v.name==name then cb=v.cb;break end end
        return assert(cb,'Missing usable '..name)(src,{name=name,slot=slot or 3})
    end
    function r.interact(data,name)return r.callbacks['forge-core:client:inventory:useInteraction'](name or'burger',data)end
    function r.effects(data)r.dispatch('forge-core:client:inventory:applyInteractionEffects',0,data)end
    function r.resume(fn,co)
        co=co or coroutine.create(fn);local out=table.pack(coroutine.resume(co));assert(out[1],out[2])
        return co,table.unpack(out,2,out.n)
    end
    function r.step(index,worker)
        local list=worker and r.workers or r.threads
        local key=(worker and'w'or't')..index;r.cos=r.cos or {}
        local co,delay=r.resume(assert(list[index]),r.cos[key]);r.cos[key]=co
        return delay,coroutine.status(co)
    end
    return r
end
function C.pair(side,options)
    local a,b=C.new(side,false,options),C.new(side,true,options)
    local pair={a=a,b=b,count=0}
    function pair.run(label,fn)
        local function run(r)local ret=table.pack(pcall(fn,r));assert(ret[1],label..': unexpected test error '..tostring(ret[2]));return P.snapshot(ret)end
        H.same(run(b),run(a),label..': returns')
        H.same(b.trace,a.trace,label..': effects')
        if side=='server'then H.same(b.api.busy,a.api.busy,label..': busy');H.same(b.api.registered,a.api.registered,label..': registered')end
        H.same(b.entities,a.entities,label..': entities')
        pair.count=pair.count+1
    end
    return pair
end
function C.registry(ported,options)
    local r={trace={},timers={},hooks={},items={},hookResult=true,localResult=nil}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=packed(...)}end
    local register=function(name,cb)r.record('local-register',name);if r.localError then error('local-error',0)end
        r.items[name]=cb;return r.localResult end
    local hook=function(name,cb,opts)r.record('hook',name,opts);if r.hookError then error('hook-error',0)end
        r.hooks[#r.hooks+1]={name=name,handler=cb,opts=opts};return r.hookResult end
    r.native={setTimeout=function(ms,fn)r.record('timer',ms);r.timers[#r.timers+1]=fn end,print=function(...)r.record('print',...)end}
    r.debug=function(...)r.record('debug',...)end
    if options then options(r)end
    if ported then
        r.api=H.load('kernel/server/inventory/usable_registry.lua',H.environment())({library={inventory={RegisterHook=hook}},
            native=r.native,registerLocal=register,debug=r.debug})
        assert(#r.trace==0,'registry constructor registers nothing')
    else
        r.api=H.load('../pr_bridge/bridge/inventories/ox/server.lua',H.environment({
            ActiveBridges={inventory='ox',frameworks='qbx'},Bridge={framework={RegisterUsableItem=register}},
            exports={ox_inventory={registerHook=function(_,...)return hook(...)end}},
            Debug=r.debug,Lang={t=function(_,key)return key end},print=r.native.print,SetTimeout=r.native.setTimeout}))
        r.trace={} -- detection log is adapter startup, not usable registration
    end
    return r
end
function C.registryPair(options)
    local a,b=C.registry(false,options),C.registry(true,options);local p={a=a,b=b,count=0}
    function p.run(label,fn)
        local function run(r)local v=table.pack(pcall(fn,r));assert(v[1],label..': test error '..tostring(v[2]));return P.snapshot(v)end
        H.same(run(b),run(a),label..': returns');H.same(b.trace,a.trace,label..': effects');p.count=p.count+1
    end
    return p
end
return C
