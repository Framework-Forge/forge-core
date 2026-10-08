local H = dofile('tests/cache_harness.lua')
local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function boot(name, key)
    local r = H.new(true); local e = r.env
    local function vector(x, y, z, w) return {x=x,y=y,z=z,w=w} end
    e.vector3=vector;e.vector4=vector;e.vec3=vector;e.vec4=vector;e.joaat=function() return 1 end
    e.ForgeCore.t=function(k) return k end
    r.players[1]={citizenid='owner',charinfo={firstname='Test',lastname='Owner'}}
    e.pr_lib.framework.GetPlayerData=function(src) return r.players[src] end
    e.pr_lib.inventory.Items=function(n) return {name=n,label=n} end
    r.load('shared/cache.lua');r.load('shared/'..name..'.lua');r.load('server/'..name..'/service.lua')
    local service=e.ForgeCore[key]; service.load = service.load or service.start; service.load()
    return r, e, service
end
for _, spec in ipairs({
    {'objects','ObjectsService','createScene','Scene'}, {'npcs','NpcsService','createGroup','Group'},
    {'spotlights','SpotlightsService','createGroup','Group'}, {'billboards','BillboardsService','createGroup','Group'},
    {'farms','FarmsService','createFarm',{label='Farm'}},
}) do
    local r,e,s=boot(spec[1],spec[2]);local original=s.state;local before=H.copy(original)
    local revision=e.ForgeCore.State.getRecord(spec[1]).revision
    e.SaveResourceFile=function() return false end
    assert(not s[spec[3]](0,spec[4]));assert(s.state==original and equal(s.state,before),spec[1]..' dirty state')
    assert(e.ForgeCore.State.getRecord(spec[1]).revision==revision)
    e.SaveResourceFile=function() return true end
    assert(s[spec[3]](0,spec[4]));assert(not equal(s.state,before));assert(equal(original,before))
    print('PASS draft isolation: '..spec[1])
end
for _, spec in ipairs({{'density','DensityService'},{'vinewood','VinewoodService'}}) do
    local _,e,s=boot(spec[1],spec[2]);local before=H.copy(s.settings);local original=s.settings
    local draft=s.getSettings();draft.enabled=not draft.enabled
    e.SaveResourceFile=function() return false end
    assert(not s.save(0,draft));assert(s.settings==original and equal(s.settings,before))
end
do
    local _,e,s=boot('character_slots','CharacterSlotService');local original=s.previews
    e.SaveResourceFile=function() return false end
    assert(not s.savePreview(nil,{x=1,y=2,z=3,heading=10,animation='stand'}))
    assert(s.previews==original and #s.previews==0)
end
local function economy(e)
    local ledger={cash=1000,water=20,bread=20,adds=0,removes=0,shops=0}
    e.pr_lib.framework.getPlayerMoney=function() return ledger.cash end
    e.pr_lib.framework.removePlayerMoney=function(_,_,amount)
        if ledger.debitFail then return false end
        ledger.cash=ledger.cash-amount;return true
    end
    e.pr_lib.framework.addPlayerMoney=function(_,_,amount)
        if ledger.creditFail then return false end
        ledger.cash=ledger.cash+amount;return true
    end
    e.pr_lib.inventory.CanCarryItem=function() return true end
    e.pr_lib.inventory.GetItemCount=function(_,name) return ledger[name] or 0 end
    e.pr_lib.inventory.AddItem=function(_,name,count,metadata)
        if ledger.addFail==name then return false end
        ledger[name]=(ledger[name] or 0)+count;ledger.adds=ledger.adds+1;ledger.metadata=metadata;return true
    end
    e.pr_lib.inventory.RemoveItem=function(_,name,count,metadata,slot)
        if ledger.removeFail then return false end
        assert((ledger[name] or 0)>=count);ledger[name]=ledger[name]-count;ledger.removes=ledger.removes+1;return true
    end
    e.pr_lib.inventory.GetPlayerInventory=function()
        return {{name='water',count=ledger.water,slot=1,metadata={quality=42}}}
    end
    e.pr_lib.inventory.RegisterShop=function() ledger.shops=ledger.shops+1 end
    return ledger
end
do
    local r,e,s=boot('stores','StoresService');local l=economy(e)
    assert(s.createStore(0,{id='test',label='Test',owner='owner',stock={water=10},
        items={{name='water',price=5,enabled=true}},enabled=true,balance=50}))
    local original=s.state;local before=H.copy(original);local shops=l.shops
    e.SaveResourceFile=function() return false end
    assert(not s.buyItem(1,'test','water',2));assert(l.water==20 and l.cash==1000)
    assert(s.state==original and equal(s.state,before));assert(l.shops==shops)
    assert(not s.addStockFromPlayer(1,'test','water',2,5));assert(l.water==20 and l.metadata.quality==42)
    assert(equal(s.state,before))
    assert(not s.withdraw(1,'test'));assert(l.cash==1000 and equal(s.state,before))
    e.SaveResourceFile=function() return true end;r.advance(1)
    assert(s.buyItem(1,'test','water',2));assert(l.water==22 and l.cash==990)
    assert(s.state.stores[1].stock.water==8 and l.shops==shops+1,'register only affected store')
    assert(s.withdraw(1,'test'));assert(s.state.stores[1].balance==0)
    local cash=l.cash;assert(not s.withdraw(1,'test'));assert(l.cash==cash,'no repeated withdrawal')
    e.SaveResourceFile=function() return false end;l.removeFail=true
    assert(not s.buyItem(1,'test','water',1));assert(s.incidents.test)
    local adds=l.adds;local ok,err=s.buyItem(1,'test','water',1)
    assert(not ok and err=='reconciliation_required' and l.adds==adds,'uncertain compensation must block replay')
end
do
    local _,e,s=boot('starterpack','StarterpackService');local l=economy(e)
    assert(s.setItem(0,{id='water',name='water',count=2,enabled=true}))
    assert(s.setItem(0,{id='bread',name='bread',count=3,enabled=true}))
    local original=s.state;local before=H.copy(original)
    e.SaveResourceFile=function() return false end
    assert(not s.claim(1,false));assert(l.water==20 and l.bread==20)
    assert(s.state==original and equal(s.state,before))
    e.SaveResourceFile=function() return true end;l.addFail='bread'
    assert(not s.claim(1,false));assert(l.water==20 and not s.state.claimed.owner,'undo partial pack')
    l.addFail=nil;assert(s.claim(1,false));assert(l.water==22 and l.bread==23)
    local adds=l.adds;assert(not s.claim(1,false));assert(l.adds==adds,'committed claim must not repeat')
end
do
    local _,e,s=boot('farms','FarmsService')
    assert(s.createFarm(0,{label='test',items={{id='water',reward='water',enabled=true,
        limits={enabled=true,cooldownMinutes=10}}}}))
    local original=s.state;local before=H.copy(original)
    e.SaveResourceFile=function() return false end
    assert(not s.startRoute(1,1,'water'));assert(s.state==original and equal(s.state,before))
    assert(next(s.activeRoutes)==nil)
end
print('PASS persistence services: 10 domains, rollback, metadata, economy compensation, partial grants, replay guards')
