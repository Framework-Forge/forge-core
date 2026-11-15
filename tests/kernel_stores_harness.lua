-- Whole installed sources vs private factories. Actual PR persistence/cache/RPC/context/OX adapter; virtual provider effects.
local V=dofile('tests/kernel_vinewood_harness.lua')
local B=dofile('tests/kernel_billboards_harness.lua')
local H,P,W=V.H,V.P,V.W
local R={H=H,P=P,W=W,V=V,vector=B.vector}
function R.env()local e=V.env();e.load=load;e.print=function()end;return e end
local vectorMeta=getmetatable(R.vector(0,0,0))
function R.environment()
    local e=R.env();e.type=function(v)if type(v)=='table'and getmetatable(v)==vectorMeta then return'vector3'end;return type(v)end
    return e
end
function R.config(ported)
    if ported then return H.load('kernel/config/forge_stores.lua',R.env())({vec3=R.vector})end
    local e=H.environment({PR={},vec3=R.vector});H.load('shared/stores.lua',e);return e.PR.Stores
end
function R.seed()
    return{settings={enabled=true,salesEnabled=true,dailyStockEnabled=true,stockModelVersion=4,lastRestock='2026-10-21',blacklist={}},
        stores={{id='market',label='Market',owner='',ownerName='',ownerPhone='',managers={},balance=0,salesPaused=false,targetLabel='',
        blip={enabled=true,sprite=59,color=69,scale=0.8},purchasePrice=100,enabled=true,points={{coords={x=1,y=2,z=3},rotation=90},{coords={x=5,y=2,z=3},rotation=180}},
        items={{name='burger',label='Burger',price=10,dailyStock=20,metadata={quality=99}},{name='water',label='Water',price=5,dailyStock=10}},stock={}}}}
end
function R.ox(r)
    local ox={};r.catalog={burger={label='Burger'},water={label='Water'},token={label='Token'}}
    r.items={[1]={{name='burger',count=6,metadata={quality=87},slot=1},{name='burger',count=4,metadata={quality=98},slot=2},{name='token',count=100,slot=3}},[2]={}}
    r.shops={};r.hooks={};r.purchaseListeners={};r.resource='started';r.rawShops={};r.hookCount=0
    function ox:Items(name)r.record('items',name);if r.itemsError then error('fixture-items',0)end;return name and r.catalog[name]or r.catalog end
    function ox:AddItem(src,name,count,metadata,slot,cb)
        r.record('add-item',src,name,count,metadata,slot)
        if r.addError then error('fixture-add',0)end
        if r.addResult~=nil then return r.addResult end
        r.items[src]=r.items[src]or{};table.insert(r.items[src],{name=name,count=count,metadata=H.copy(metadata),slot=#r.items[src]+1})
        return true,{name=name,count=count}
    end
    function ox:RemoveItem(src,name,count,metadata,slot)
        r.record('remove-item',src,name,count,metadata,slot)
        if r.removeError then error('fixture-remove',0)end
        if r.removeResult~=nil then return r.removeResult end
        local remaining=count
        for _,item in pairs(r.items[src]or{})do
            if item.name==name and (slot==nil or item.slot==slot)and remaining>0 then
                local n=math.min(item.count,remaining);item.count=item.count-n;remaining=remaining-n
            end
        end
        return remaining==0
    end
    function ox:GetItemCount(src,name)r.record('item-count',src,name);local n=0;for _,i in pairs(r.items[src]or{})do if i.name==name then n=n+i.count end end;return n end
    function ox:Search(src,kind,name)assert(kind=='count');return self:GetItemCount(src,name)end
    function ox:CanCarryItem(...)r.record('can-carry',...);return r.carryResult end
    function ox:GetInventoryItems(src)r.record('player-inventory',src);return r.items[src]end
    function ox:RegisterShop(id,shop)r.record('register-shop',id,shop);r.shops[id]=H.copy(shop);return r.registerResult end
    function ox:registerHook(event,fn,options)
        r.record('register-hook',event,options);r.hookCount=r.hookCount+1
        local id='forge-core:'..event..':'..r.hookCount;r.hooks[id]=fn;return id
    end
    local e=H.environment({ActiveBridges={inventory='ox'},exports={ox_inventory=ox},Debug=function()end,Lang={t=function(_,k)return k end}})
    local inv=H.load('../pr_bridge/bridge/inventories/ox/server.lua',e)
    -- Exact installed inventory_normalizer GetPlayerInventory/GetItemLabel contracts used here, no extra provider feature invented.
    inv.GetPlayerInventory=inv.GetInventoryItems
    inv.GetItemLabel=function(name)local data=inv.Items(name);return type(data)=='table'and(data.label or data.name)or name end
    r.library.inventory=inv;r.carryResult=true
    r.inventoryIntegration={
        resourceState=function()r.record('inventory-state');return r.resource end,
        readShopFile=function(name)r.record('read-shops',name);return r.rawShops[name]end,
        addItemRaw=function(...)return ox:AddItem(...)end,removeItemRaw=function(...)return ox:RemoveItem(...)end,
        searchCountRaw=function(src,name)return ox:Search(src,'count',name)end,itemsRaw=function()return ox:Items()end,
        onPurchaseResult=function(name,fn)r.record('listen-purchase',name);r.purchaseListeners[name]=fn;return name end,
        removePurchaseResult=function(handle)r.record('remove-purchase-listener',handle);r.purchaseListeners[handle]=nil end,
    }
    r.ox=ox
    return inv
end
function R.players(r)
    r.players={[1]={PlayerData={citizenid='CID1',charinfo={firstname='One',lastname='Player',phone='111'},money={cash=1000,bank=2000},jobs={police=2},job={name='police',grade={level=2}}}},
        [2]={PlayerData={citizenid='CID2',charinfo={firstname='Two',lastname='Admin',phone='222'},money={cash=1000,bank=2000},jobs={}}}}
    local provider={}
    function provider:GetPlayer(src)return r.players[tonumber(src)]end
    function provider:GetMoney(src,account)r.record('get-money',src,account);local p=self:GetPlayer(src);return p and p.PlayerData.money[account]or 0 end
    function provider:AddMoney(src,account,amount,reason)
        r.record('add-money',src,account,amount,reason);if r.creditError then error('fixture-credit',0)end
        if r.creditResult~=nil then return r.creditResult end
        local p=self:GetPlayer(src);if not p then return false end;p.PlayerData.money[account]=(p.PlayerData.money[account]or 0)+amount;return true
    end
    function provider:RemoveMoney(src,account,amount,reason)
        r.record('remove-money',src,account,amount,reason);if r.chargeError then error('fixture-charge',0)end
        if r.chargeResult~=nil then return r.chargeResult end
        local p=self:GetPlayer(src);if not p or(p.PlayerData.money[account]or 0)<amount then return false end
        p.PlayerData.money[account]=p.PlayerData.money[account]-amount;return true
    end
    r.player=H.load('../pr_bridge/bridge/frameworks/qbx/server.lua',H.environment({ActiveBridges={frameworks='qbx'},
        exports={qbx_core=provider},Debug=function()end,Lang={t=function(_,k)return k end}}))
end
function R.new(ported)
    local r=V.new(ported);r.config.Stores=R.config(ported);r.callbacks={};r.storeEvents={}
    R.ox(r);R.players(r)
    r.clock={time=function()return 1792530000 end,date=function()return r.date or'2026-10-21'end}
    r.native.GetPlayerName=function(src)return'Player'..src end;r.native.vec3=R.vector
    r.m.seed(r.config.Stores.Storage.file,R.seed())
    if ported then
        r.boundary=H.load('kernel/server/stores.lua',R.env())({config=r.config,library=r.library,native=r.native,
            clock=r.clock,services=r.services,translate=r.translate,world=r.state,player=r.player,inventoryIntegration=r.inventoryIntegration})
        r.service=r.boundary.Service;r.storeEvents=r.boundary.Events
        for _,d in ipairs(H.load('kernel/server/stores_callbacks.lua',R.env())({config=r.config,service=r.service}))do r.callbacks[d.name]=d.handler end
    else
        r.library.framework=r.player
        local e=H.environment({PR=r.config,ForgeCore=r.services,pr_lib=r.library,os=r.clock,state=false,load=load,print=function()end})
        for n,fn in pairs(r.native)do e[n]=fn end
        e.AddEventHandler=function(name,fn)
            if name:find('forge-core:buyItem:',1,true)==1 then return r.inventoryIntegration.onPurchaseResult(name,fn)end
            r.storeEvents[#r.storeEvents+1]={name=name,handler=fn,network=false}
        end
        e.RemoveEventHandler=r.inventoryIntegration.removePurchaseResult;e.GetResourceState=function(n)assert(n=='ox_inventory');return r.inventoryIntegration.resourceState()end
        e.LoadResourceFile=function(n,file)assert(n=='ox_inventory');return r.inventoryIntegration.readShopFile(file)end
        e.exports={ox_inventory=r.ox};r.services.Callbacks={register=function(n,fn)r.callbacks[n]=fn end}
        H.load('server/stores/service.lua',e);H.load('server/stores/callbacks.lua',e);r.service=r.services.StoresService
    end
    assert(#r.storeEvents==3 and #r.trace==0 and #r.m.trace==0 and not r.service.initialized,'inert store server')
    function r.fireStore(name,...)for _,d in ipairs(r.storeEvents)do if d.name==name then d.handler(...)end end end
    function r.purchase(success,payload)
        local fn=assert(r.purchaseListeners[r.service.purchaseHookId]);return fn(success,payload)
    end
    function r.stateSnapshot()return P.snapshot({r.service,r.state.getRecord('stores'),r.m.files,r.shops,r.players,r.items})end
    return r
end
function R.case(name,fn,withoutStart)
    local a,b=R.new(false),R.new(true)
    local function action(r)if not withoutStart then r.service.start()end;return fn(r)end
    H.same(V.outcome(action,b),V.outcome(action,a),name..' returns')
    H.same(b.trace,a.trace,name..' effects');H.same(b.m.trace,a.m.trace,name..' persistence')
    H.same(b.stateSnapshot(),a.stateSnapshot(),name..' state')
end
R.clientNatives={'DoesBlipExist','RemoveBlip','AddBlipForCoord','SetBlipSprite','SetBlipDisplay','SetBlipScale','SetBlipColour','SetBlipAsShortRange','BeginTextCommandSetBlipName','AddTextComponentSubstringPlayerName','EndTextCommandSetBlipName','Wait','SetTimeout','GetCurrentResourceName','vec3'}
function R.platform(r)
    r.native.vec3=R.vector;r.native.GetCurrentResourceName=function()return'forge-core'end
    r.library.math={toVector=function(v)if r.vectorError then error('fixture-vector',0)end;return R.vector(v.x,v.y,v.z)end}
    r.targets={};r.blips={};r.targetId=0;r.blipId=100
    r.library.target={addBoxZone=function(data)
        r.record('target-add',data);if r.targetError then error('fixture-target',0)end
        if r.targetFalse then return false end;r.targetId=r.targetId+1;r.targets[r.targetId]=data;return r.targetId
    end,removeZone=function(id)r.record('target-remove',id);r.targets[id]=nil end}
    r.native.AddBlipForCoord=function(...)r.record('blip-add',...);r.blipId=r.blipId+1;r.blips[r.blipId]=true;return r.blipId end
    r.native.DoesBlipExist=function(id)return r.blips[id]==true end
    r.native.RemoveBlip=function(id)r.record('blip-remove',id);r.blips[id]=nil end
    for _,n in ipairs({'SetBlipSprite','SetBlipDisplay','SetBlipScale','SetBlipColour','SetBlipAsShortRange','BeginTextCommandSetBlipName','AddTextComponentSubstringPlayerName','EndTextCommandSetBlipName'})do r.native[n]=function(...)r.record(n,...)end end
    r.playerData={citizenid='CID1'};r.player={GetPlayerIdentifier=function()return r.playerData.citizenid or r.playerData.identifier or r.playerData.charId end}
end
function R.bindClient(r,ported)
    r.value=nil;r.initial={};r.subscriptions={};r.storeEvents={};r.menu=r.menu or{}
    r.world={get=function(key)assert(key=='stores');return r.value end}
    if ported then
        r.runtime=H.load('kernel/client/stores.lua',R.environment())({config=r.config,library=r.library,native=r.native,
            world=r.world,menu=r.menu,translate=r.translate,player=r.player})
        r.stores=r.runtime.Stores;r.initial=r.runtime.Threads;r.subscriptions=r.runtime.Subscriptions;r.storeEvents=r.runtime.Events
    else
        r.library.framework=r.player
        local e=R.environment();e.PR=r.config;e.pr_lib=r.library;e.ForgeCore={Client={Menu=r.menu},State=r.world,t=r.translate}
        for n,fn in pairs(r.native)do e[n]=fn end
        e.CreateThread=function(fn)r.initial[#r.initial+1]=fn end
        e.AddEventHandler=function(n,fn)r.storeEvents[#r.storeEvents+1]={name=n,handler=fn,network=false}end
        r.world.onChange=function(key,fn)r.subscriptions[#r.subscriptions+1]={key=key,handler=fn}end
        H.load('client/stores/main.lua',e);r.stores=e.ForgeCore.Client.Stores
    end
    assert(#r.initial==1 and #r.subscriptions==1 and #r.storeEvents==4 and not r.stores.ready)
    function r.apply(payload)r.value=payload;r.subscriptions[1].handler(payload)end
    function r.fireStore(name,...)for _,d in ipairs(r.storeEvents)do if d.name==name then d.handler(...)end end end
end
function R.client(ported)
    local r=W.world(ported,false);r.config={Stores=R.config(ported),NotifyPos='top-right'}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    R.platform(r);R.bindClient(r,ported);assert(#r.trace==0 and #r.queue==0,'inert store client');return r
end
function R.clientCase(name,fn)
    local a,b=R.client(false),R.client(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot({b.stores,b.targets,b.blips}),P.snapshot({a.stores,a.targets,a.blips}),name..' client state')
end
function R.menu(ported)
    local r=W.menu(ported);r.config.Stores=R.config(ported);r.payload=R.seed();r.dynamicThreads={};r.just={}
    r.storeInfo={store=r.payload.stores[1],isOwner=true,hasAccess=true,canManage=true}
    r.library.inventory={openInventory=function(...)r.record('open-inventory',...);return false end}
    r.native.GetEntityCoords=function()return R.vector(1.12345,2.23456,3.34567)end
    r.native.PlayerPedId=function()return 42 end;r.native.GetEntityHeading=function()return 90.123 end
    for _,n in ipairs({'IsControlJustReleased','IsDisabledControlJustReleased'})do r.native[n]=function(_,key)return r.just[key]or false end end
    r.native.CreateThread=function(fn)r.dynamicThreads[#r.dynamicThreads+1]=fn end
    r.native.Wait=function(ms)r.record('wait',ms);return coroutine.yield(ms)end
    for _,n in ipairs({'SetEntityCoords','SetEntityHeading'})do r.native[n]=function(...)r.record(n,...)end end
    r.library.devlaser={start=function(options)r.record('laser-start',options);r.laserOptions=options;r.laserActive=true end,
        stop=function(v)r.record('laser-stop',v);r.laserActive=false end,isActive=function()return r.laserActive end,
        getTarget=function()return{coords=r.targetCoords or R.vector(8.12345,9.23456,10.34567)}end}
    r.library.ShowTextUI=function(...)r.record('textui-show',...);r.textActive=true end
    r.library.HideTextUI=function()r.record('textui-hide');r.textActive=false end
    local parent=r.library.callback.await
    r.library.callback.await=function(name,timeout,...)
        if not name:find(':stores:',1,true)then return parent(name,timeout,...)end
        assert(timeout==10000);r.record('stores-rpc',name,timeout,...)
        if r.rpcHook then return r.rpcHook(name,...)end
        if name==r.config.Stores.Callbacks.getAll then return true,H.copy(r.payload)end
        if name==r.config.Stores.Callbacks.getStore then return true,H.copy(r.storeInfo)end
        if name==r.config.Stores.Callbacks.getItems then return true,{{name='burger',label='Burger'}}end
        if name==r.config.Stores.Callbacks.getPlayerItems then return true,{{name='burger',label='Burger',count=10}}end
        if name==r.config.Stores.Callbacks.openShop then return true,'forge_core_store_market'end
        if name==r.config.Stores.Callbacks.buyItem then return true,{label='Burger',count=2,total=20}end
        if name==r.config.Stores.Callbacks.withdraw then return true,80 end
        return true,H.copy(r.payload)
    end
    if ported then r.menuApi=H.load('kernel/client/menu/stores.lua',R.env())({config=r.config,library=r.library,native=r.native,menu=r.menu,shared=r.shared})
    else
        r.env.CreateThread=r.native.CreateThread
        for n,fn in pairs(r.native)do r.env[n]=fn end
        H.load('client/menu/menu_stores.lua',r.env)
    end
    r.trace={};return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts');assert(#b.dynamicThreads==#a.dynamicThreads,name..' dynamic thread count')
end
return R
