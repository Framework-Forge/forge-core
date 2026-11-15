-- Whole installed menus vs inactive ports. UI, timers, JSON codec and network are simulated.
local I=dofile('tests/kernel_inventory_harness.lua')
local W=dofile('tests/kernel_weapon_harness.lua')
local H,P,J=I.H,I.P,I.J
local M={I=I,W=W,H=H,P=P,J=J}
M.methods={'openInventoryMenu','openInventoryEntries','openInventoryEntryDetails','openInventoryEntryEditor','openInventoryInteractionEditor',
    'openWeaponsMenu','openWeaponDetails','openWeaponEditor'}
function M.new(ported,options)
    local r={trace={},contexts={},timers={},inputs={},alerts={},responses={},now=0,qbxState='started',source=2,
        jobs={taxi={label='Z Taxi'},police={label='A Police'}},gangs={ballas={label='Ballas'}},events={}}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    r.config={Inventory=I.config(true),Weapons=W.config(true),Vip=H.load('kernel/config/forge_vip.lua',H.environment())(),NotifyPos='top-right'}
    r.item={name='burger',label='Burger',weight=100,active=true,stack=true,close=true,interaction={enabled=true,duration=5000}}
    r.ammo={name='ammo-9',label='Ammo',weight=5,active=true}
    r.component={name='comp',label='Comp',active=false}
    r.weapon={name='weapon_pistol',label='Pistol',weapontype='Pistol',ammotype='AMMO_PISTOL',active=true}
    r.payload={items={r.item},ammo={r.ammo},components={r.component}}
    r.weaponPayload={weapons={r.weapon}}
    local memory=J.persistence()
    r.json={encode=function(value)if r.encodeError then error('codec-error',0)end;return memory.codec.encode(value)end,
        decode=function(value)if r.decodeError then error('codec-error',0)end;return memory.codec.decode(value)end}
    r.codec=memory.codec
    r.menu={openServerSettingsMenu=function()r.record('parent-settings')end}
    r.native={setTimeout=function(ms,fn)r.record('timer',ms);r.timers[#r.timers+1]={ms=ms,fn=fn}end,
        playerId=function()return 7 end,getPlayerServerId=function(id)assert(id==7);return r.source end}
    r.translate=function(key,params)r.record('translate',key,params);return key end
    local function notify(...)r.record('notify',...)end
    local function input(...)
        r.record('input',...);if r.inputHook then return r.inputHook(...)end
        local response=table.remove(r.inputs,1);return response
    end
    local function alert(...)r.record('alert',...);return table.remove(r.alerts,1)end
    r.library={Notify=notify,table={clone=function(value)return H.copy(value)end,count=function(value)local n=0;for _ in pairs(value)do n=n+1 end;return n end}}
    r.library.menus={RegisterContext=function(ctx)
        r.record('register',ctx);r.contexts[ctx.id]=ctx;r.last=ctx
        if r.registerHook then return r.registerHook(ctx)end;return r.contextReturn
    end,
    ShowContext=function(id)r.record('show',id);if r.showHook then return r.showHook(id)end;return r.contextReturn end,
    InputDialog=input,AlertDialog=alert}
    r.library.inventory={GetImagePath=function(image)r.record('image',image)
        if r.imageError then error('image-error',0)end
        if r.imageResult~=nil then return r.imageResult end;return'nui://fixture/'..image
    end}
    r.library.callback={await=function(name,timeout,...)
        assert(timeout==10000);r.record('await',name,timeout,...)
        if r.awaitHook then return r.awaitHook(name,...)end
        local result=r.responses[name];if result=='throw'then error('callback-error',0)end
        if result then return table.unpack(H.copy(result),1,result.n)end
        if name==r.config.Inventory.Callbacks.getAll then return true,H.copy(r.payload)
        elseif name==r.config.Weapons.Callbacks.getAll then return true,H.copy(r.weaponPayload)
        elseif name==r.config.Vip.Callbacks.getTiers then return true,{{id='gold',label='Gold'}}end
        return true,{}
    end}
    r.groups={GetJobs=function()r.record('jobs');if r.jobsError then error('jobs-error',0)end;return r.jobs end,
        GetGangs=function()r.record('gangs');if r.gangsError then error('gangs-error',0)end;return r.gangs end}
    if options then options(r)end
    local env=H.environment()
    if ported then
        r.shared=H.load('kernel/client/menu/shared.lua',env)({library=r.library,translate=r.translate,notifyPosition=r.config.NotifyPos})
        local ports={menu=r.menu,shared=r.shared,config=r.config,library=r.library,native=r.native,json=r.json,groups=r.groups,
            isReady=function()return r.qbxState=='started'end}
        for _,name in ipairs({'inventory','weapons'})do H.load('kernel/client/menu/'..name..'.lua',env)(ports)end
        assert(#r.trace==0 and #r.timers==0,'constructors must not register UI/query/start timers')
    else
        env.ForgeCore={Client={Menu=r.menu},t=r.translate};env.pr_lib=r.library;env.PR=r.config;env.json=r.json
        env.GetResourceState=function(resource)assert(resource=='qbx_core');return r.qbxState end
        env.exports={qbx_core={GetJobs=function()return r.groups.GetJobs()end,GetGangs=function()return r.groups.GetGangs()end}}
        env.SetTimeout=r.native.setTimeout;env.PlayerId=r.native.playerId;env.GetPlayerServerId=r.native.getPlayerServerId
        env.AddEventHandler=function(name,fn)r.events[name]=fn end
        H.load('client/menu/menu.lua',env) -- whole installed parent/shared source; no event dispatched
        r.shared=env.ForgeCore.Client.MenuShared
        H.load('client/menu/menu_inventory.lua',env);H.load('client/menu/menu_weapons.lua',env)
    end
    r.env=env
    function r.select(index,context,force)
        context=context or r.last;assert(context,'No context')
        local option=assert(context.options[index],'Missing option '..index)
        if not force and(option.disabled or option.readOnly)then return end
        assert(type(option.onSelect)=='function','Option has no action');return option.onSelect()
    end
    function r.runTimers(ms)
        local list=r.timers;r.timers={}
        for _,v in ipairs(list)do if not ms or v.ms==ms then v.fn()else r.timers[#r.timers+1]=v end end
    end
    function r.reply(name,...)r.responses[name]=table.pack(...)end
    function r.count(kind)local n=0;for _,event in ipairs(r.trace)do if event.kind==kind then n=n+1 end end;return n end
    function r.lastRequest(name)
        for i=#r.trace,1,-1 do local event=r.trace[i];if event.kind=='await'and(not name or event.args[1]==name)then return event.args end end
    end
    return r
end
function M.pair(options)
    local a,b=M.new(false,options),M.new(true,options);local p={a=a,b=b,count=0}
    function p.run(label,fn)
        local function run(r)local value=table.pack(pcall(fn,r));assert(value[1],label..': unexpected test error '..tostring(value[2]));return P.snapshot(value)end
        H.same(run(b),run(a),label..': returns')
        H.same(b.trace,a.trace,label..': UI/requests/timers')
        H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),label..': retained contexts')
        H.same({item=b.item,ammo=b.ammo,component=b.component,weapon=b.weapon},
            {item=a.item,ammo=a.ammo,component=a.component,weapon=a.weapon},label..': input mutation')
        p.count=p.count+1
    end
    return p
end
function M.context()
    local r={frames={},timers={},focus=0,events={}}
    local function noUnexpected(...)error('Unexpected platform context boundary',0)end
    local factory=H.load('../pr_bridge/interface/client/modules/context.lua',H.environment({
        GetCurrentResourceName=function()return'forge-core'end,Bridge={debug={error=noUnexpected,warn=noUnexpected}},
        SetTimeout=function(ms,fn)assert(ms==75);r.timers[#r.timers+1]=fn end,
        TriggerEvent=function(...)r.events[#r.events+1]=table.pack(...)end,TriggerServerEvent=noUnexpected,ExecuteCommand=noUnexpected}))
    r.api=factory({send=function(name,data)r.frames[#r.frames+1]={name=name,data=data}end,
        setFocus=function()r.focus=r.focus+1 end,ensureFocus=function()end,resetFocus=function()r.focus=0 end})
    return r
end
return M
