-- Isolated whole-installed comparisons. PR recovery/RPC helpers execute; SQL/provider/native/codec are virtual.
local A=dofile('tests/kernel_player_admin_harness.lua')
local C=dofile('tests/kernel_character_harness.lua')
local F=dofile('tests/kernel_finance_harness.lua')
local H,P=A.H,A.P
local R={H=H,P=P,A=A,C=C,F=F,env=A.env}
function R.config(ported)
    if ported then return H.load('kernel/config/forge_character_slots.lua',R.env())()end
    local e=H.environment({PR={}});H.load('shared/character_slots.lua',e);return e.PR.CharacterSlots
end
function R.new(ported)
    local r={trace={},queue={},handlers={},events={},exports={},ready=true,stock=2,registerResult=true,removeResult=true,addResult=true,public={}}
    function r.record(name,...)r.trace[#r.trace+1]={kind=name,args=P.snapshot(table.pack(...))}end
    r.slots=C.slots(true);r.vip=F.new(true,'vip');r.m=F.J.persistence()
    r.config={CharacterSlots=R.config(ported),Vip=r.vip.vipConfig,NotifyPos='top-right'}
    r.library={};for k,v in pairs(r.m.api)do r.library[k]=v end
    r.items={new_slot={label='New Slot'},water={label='Water'},phone={label='Phone'},disabled={label='Disabled',disabled=true}}
    r.library.inventory={Items=function()r.record('items');return r.items end,
        RemoveItem=function(...)r.record('remove',...);if r.removeError then error('fixture-remove',0)end;if r.removeResult then r.stock=r.stock-1 end;return r.removeResult end,
        AddItem=function(...)r.record('refund',...);if r.addResult then r.stock=r.stock+1 end;return r.addResult end,
        RegisterUsableItem=function(name,fn,opts)r.record('usable',name,opts);r.useItem=fn;return r.registerResult end}
    r.library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    r.world={publish=function(key,value)r.record('publish',key,value);r.public[key]=value end,get=function(key)return r.public[key]end}
    r.services={InventoryService={getItem=function(name)r.record('item-get',name);return r.existingItem end,
        upsertItem=function(...)r.record('item-upsert',...);return not r.ensureFail,'fixture-item' end},VipService=r.vip.api}
    r.native={GetPlayerName=function(src)r.record('name',src);return not r.offline and 'Player'end,
        TriggerClientEvent=function(...)r.record('emit',...)end,SetTimeout=function(ms,fn)r.record('timer',ms);r.queue[#r.queue+1]={ms=ms,fn=fn}end}
    r.internal={};for name,fn in pairs(r.slots.exports)do r.internal[name]=fn end
    r.internal.GetPlayer=function(src)r.record('lookup',src);return r.slots.players[src]end
    r.internal.Logout=function(src)r.record('logout',src);return r.logoutResult~=false end
    for name,fn in pairs(r.internal)do r.internal[name]=function(...)
        if r.callHook then return r.callHook(name,...)end;return fn(...)
    end end
    r.print=function(...)r.record('print',...)end;r.clock={date=function(fmt,t)return os.date(fmt,t)end}
    if ported then
        local api=H.load('kernel/server/character_admin.lua',R.env())({config=r.config,services=r.services,library=r.library,world=r.world,
            internal=r.internal,isReady=function()return r.ready end,native=r.native,print=r.print,usable=r.library.inventory})
        r.service,r.events,r.exports=api.Service,api.Events,api.Exports
        for _,list in ipairs({H.load('kernel/server/character_admin_callbacks.lua',R.env())({config=r.config,service=r.service,library=r.library}),
            H.load('kernel/server/vip/callbacks.lua',R.env())({config=r.config,service=r.vip.api,clock=r.clock})})do
            for _,d in ipairs(list)do r.handlers[d.name]=d.handler end
        end
    else
        local e=H.environment({PR=r.config,ForgeCore=r.services,pr_lib=r.library,print=r.print,os=r.clock})
        r.services.State=r.world;r.services.Callbacks={register=function(n,fn)r.handlers[n]=fn end}
        for k,v in pairs(r.native)do e[k]=v end
        e.GetResourceState=function(n)assert(n=='qbx_core');return r.ready and 'started' or 'stopped'end
        local proxy={};for n,fn in pairs(r.internal)do proxy[n]=function(_,...)return fn(...)end end
        local exports={qbx_core=proxy,ox_inventory={Items=function()return r.library.inventory.Items()end}}
        e.exports=setmetatable(exports,{__call=function(_,n,fn)r.exports[n]=fn end})
        e.AddEventHandler=function(n,fn)r.events[#r.events+1]={name=n,handler=function(src,...)e.source=src;return fn(...)end}end
        H.load('server/character_slots/service.lua',e);r.service=r.services.CharacterSlotService
        H.load('server/character_slots/callbacks.lua',e);H.load('server/vip/callbacks.lua',e)
    end
    assert(#r.trace==0 and #r.queue==0 and not r.service.loaded and #r.events==2,'inert service constructor')
    function r.rpc(module,key,...)local cfg=r.config[module];local names=cfg.callbacks or cfg.Callbacks;return r.handlers[assert(names[key])](2,...)end
    function r.playerRpc(key,src,...)return r.handlers[r.config.CharacterSlots.playerCallbacks[key]](src,...)end
    function r.fire(name,src,...)for _,d in ipairs(r.events)do if d.name==name then d.handler(src,...)end end end
    function r.timers()local q=r.queue;r.queue={};for _,v in ipairs(q)do v.fn()end end
    r.trace={};return r
end
function R.outcome(fn,r)
    local out=table.pack(pcall(fn,r));if not out[1]then out[2]=tostring(out[2]):gsub('\nstack traceback:.*',''):gsub('^.-:%d+: ','')end
    return P.snapshot(out)
end
function R.case(name,fn)
    local a,b=R.new(false),R.new(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(b.m.trace,a.m.trace,name..' recovery');H.same(b.slots.trace,a.slots.trace,name..' slots');H.same(b.vip.trace,a.vip.trace,name..' VIP')
    H.same(P.snapshot({b.service,b.stock,b.public,b.slots.purchased,b.slots.blocked,b.m.files}),P.snapshot({a.service,a.stock,a.public,a.slots.purchased,a.slots.blocked,a.m.files}),name..' state')
end
function R.menu(ported)
    local r=A.menu(ported);r.config.CharacterSlots=R.config(ported);r.config.Vip=H.load('kernel/config/forge_vip.lua',R.env())()
    for _,n in ipairs({'openPlayerCharacterSlots','openPlayerVipAdmin','openCharacterCreationSettings','openVipClassesMenu'})do r.menu[n]=nil end
    r.settings={maxSlots=4,requireItem=true,slotsPerItem=1,loseSlotOnDelete=true,firstNamePlaceholder='Hank',lastNamePlaceholder='Jordan',
        minimumAgeEnabled=true,minimumAge=18,termsEnabled=true,termsTitle='Terms',termsVersion='1',termsText='Content',
        starterItems={{name='water',amount=2}},itemOptions={{value='water',label='Water'},{value='phone',label='Phone'}},
        previewAnimations=r.config.CharacterSlots.previewAnimations,previewModel='mp_m_freemode_01',previews={{x=1,y=2,z=3,heading=90,animation='phone'}}}
    r.tiers={{id='gold',label='Gold',color='#ffaa00',principal='group.gold',slots=3,weight=20000,xpMultiplier=1.25,salary={enabled=true,account='bank',amount=1000}}}
    r.current={tier='standard',label='Standard',expiresAtFormatted='Sem VIP'}
    r.slotData={settings=r.settings,maxSlots=4,unlockedCount=2,unlocked={[1]=true,['2']=true},blocked={['2']=true},occupied={[1]='John Doe'}}
    local parent=r.library.callback.await
    local tracked={};for _,c in ipairs({r.config.CharacterSlots.callbacks,r.config.CharacterSlots.playerCallbacks,r.config.Vip.Callbacks})do for _,v in pairs(c)do tracked[v]=true end end
    r.library.callback.await=function(n,timeout,...)
        if not tracked[n]then return parent(n,timeout,...)end;r.record('admin46-rpc',n,timeout,...)
        if r.adminHook then return r.adminHook(n,...)end
        if n==r.config.CharacterSlots.callbacks.getSettings then return true,H.copy(r.settings)end
        if n==r.config.CharacterSlots.callbacks.getPlayer then return true,H.copy(r.slotData)end
        if n==r.config.Vip.Callbacks.getTiers then return true,H.copy(r.tiers)end
        if n==r.config.Vip.Callbacks.get then return true,H.copy(r.current)end
        return true,{}
    end
    r.library.fivem={devtools={placeAnimatedPed=function(...)
        r.record('animated-placement',...);r.placement=table.pack(...);return not r.placementFalse
    end}}
    function r.finishPlacement(result)assert(r.placement)[4](result)end
    if ported then
        local ports={config=r.config,menu=r.menu,shared=r.shared,native=r.native,library=r.library}
        H.load('kernel/client/menu/vip.lua',R.env())(ports);H.load('kernel/client/menu/character_slots.lua',R.env())(ports)
    else H.load('client/menu/menu_vip.lua',r.env);H.load('client/menu/menu_character_slots.lua',r.env)end
    r.trace={};return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts')
end
return R
