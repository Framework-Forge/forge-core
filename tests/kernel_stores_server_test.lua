local R=dofile('tests/kernel_stores_harness.lua')
local H=R.H;local n=0
local function case(name,fn,noStart)R.case(name,fn,noStart);n=n+1 end
H.same(R.P.snapshot(R.config(true)),R.P.snapshot(R.config(false)),'whole stores config');n=n+1
case('initial stock model',function(r)
    local p=r.service.getAll();assert(p.settings.stockModelVersion==4 and #p.stores[1].points==2)
    assert(r.service.dailyStock.market.burger==20 and r.shops.forge_core_store_market.inventory[1].price==10)
    return p
end)
case('load is not triggered by constructor',function(r)return r.service.initialized,#r.storeEvents end,true)
for _,value in ipairs({false,0,1,'yes','sim','false','true'})do case('settings coercion '..tostring(value),function(r)return r.service.saveSettings(1,{enabled=value,blacklist={'burger'}})end)end
case('nonadmin denied',function(r)r.jobResult=false;local ok,e=r.service.saveSettings(1,{});assert(not ok and e=='no_permission');return ok,e end)
case('console bypass',function(r)r.jobResult=false;return r.service.saveSettings(0,{enabled=true})end)
case('missing job service uses ACE',function(r)r.services.JobService=nil;r.ace=false;return r.service.createStore(1,{label='Denied'})end)
for _,label in ipairs({'','   ','A store!','Épicerie','same_same'})do case('store id '..label,function(r)return r.service.createStore(1,{label=label,coords={x=9,y=1,z=2},items={{name='water',price=3.9,dailyStock=6.8}}})end)end
case('duplicate id',function(r)return r.service.createStore(1,{label='Market',id=' MARKET '})end)
case('load dedupe/items migration',function(r)
    r.m.seed(r.config.Stores.Storage.file,{settings={stockModelVersion=1},stores={{id='A',label='A',owner='',stock={burger=99},items={{name='burger'},{name='burger'}}},{id='A'}}})
    r.service.load();local p=r.service.getAll();assert(#p.stores==1 and #p.stores[1].items==1 and p.stores[1].stock.burger==nil);return p
end)
for _,distance in ipairs({0,50,50.001,100})do case('point radius '..distance,function(r)
    local ok,p=r.service.updateStore(1,'market',{points={{coords={x=0,y=0,z=0}},{coords={x=distance,y=0,z=0},rotation=45}}})
    assert(ok==(distance<=50));return ok,p
end)end
case('legacy coords replace points',function(r)return r.service.updateStore(1,'market',{coords={1,2,3},heading=270})end)
case('rotation only updates primary',function(r)return r.service.updateStore(1,'market',{rotation=111})end)
case('owner edit refuses outsider',function(r)return r.service.updateOwnerStore(1,'market',{label='No'})end)
case('setItem resets unowned daily stock',function(r)
    assert(r.service.buyItem(1,'market','burger',2));local ok,p=r.service.setItem(1,'market',{name='burger',price=17,dailyStock=8})
    assert(ok and r.service.dailyStock.market.burger==8 and p.stores[1].items[1].price==17);return ok,p
end)
case('owned item editor preserves stock',function(r)
    assert(r.service.buyStore(1,'market','cash'));assert(r.service.addStockFromPlayer(1,'market','burger',2,15))
    local ok,p=r.service.setItem(1,'market',{name='burger',price=21,dailyStock=800});assert(ok and p.stores[1].stock.burger==2);return ok,p
end)
for _,item in ipairs({'','not-known','burger'})do case('set item '..item,function(r)return r.service.setItem(1,'market',{name=item,price=-1,dailyStock=-3})end)end
case('blacklisted set/remove listing',function(r)
    assert(r.service.saveSettings(1,{enabled=true,blacklist={burger=true}}));local ok,p=r.service.getItems(1)
    for _,v in ipairs(p)do assert(v.name~='burger')end;return r.service.setItem(1,'market',{name='burger'})
end)
for _,id in ipairs({'market','missing'})do
    case('read '..id,function(r)return r.service.getStore(1,id)end)
    case('open '..id,function(r)return r.service.openShop(1,id)end)
    case('delete '..id,function(r)return r.service.deleteStore(1,id)end)
    case('remove product '..id,function(r)return r.service.removeItem(1,id,'burger')end)
end
for _,method in ipairs({'buyItem','buyStore','withdraw','transferStore','addManager','removeManager','addStockFromPlayer','setItem','updateStore','updateOwnerStore'})do
    case('incident denies '..method,function(r)r.service.incidents.market={operation='test'};local ok,e=r.service[method](1,'market');assert(not ok and e=='reconciliation_required');return ok,e end)
end
for _,currency in ipairs({'money','cash','bank','token'})do case('fixed price currency '..currency,function(r)
    r.service.state.stores[1].items[1].currency=currency
    local ok,p=r.service.buyItem(1,'market','burger',2);assert(ok and p.total==20 and p.stock==18);return ok,p
end)end
case('cash fallback bank',function(r)r.players[1].PlayerData.money.cash=0;assert(r.service.buyItem(1,'market','burger',2));assert(r.players[1].PlayerData.money.bank==1980)end)
for _,count in ipairs({-3,0,1,2.9,20,21})do case('count '..count,function(r)return r.service.buyItem(1,'market','burger',count)end)end
case('insufficient money',function(r)r.players[1].PlayerData.money={cash=0,bank=0};return r.service.buyItem(1,'market','burger',1)end)
case('cannot carry',function(r)r.carryResult=false;return r.service.buyItem(1,'market','burger',1)end)
case('nil can carry keeps permissive default',function(r)r.carryResult=nil;return r.service.buyItem(1,'market','burger',1)end)
case('blacklist rejects before charge',function(r)r.service.state.settings.blacklist.burger=true;return r.service.buyItem(1,'market','burger',1)end)
case('groups secondary job',function(r)r.service.state.stores[1].groups={police=2};return r.service.buyItem(1,'market','burger',1)end)
case('groups grade refusal',function(r)r.service.state.stores[1].groups={police=3};return r.service.buyItem(1,'market','burger',1)end)
case('groups primary fallback',function(r)r.players[1].PlayerData.jobs={};r.service.state.stores[1].groups={police=2};return r.service.buyItem(1,'market','burger',1)end)
case('paused buyItem inherited policy',function(r)r.service.state.stores[1].salesPaused=true;assert(not r.service.openShop(1,'market'));assert(r.service.buyItem(1,'market','burger',1))end)
case('disabled refuses',function(r)r.service.state.settings.enabled=false;return r.service.buyItem(1,'market','burger',1)end)
case('item lock busy',function(r)r.service.locks['market:burger']=true;return r.service.buyItem(1,'market','burger',1)end)
case('delivery failure refunds',function(r)r.addResult=false;local before=r.players[1].PlayerData.money.cash;local ok,e=r.service.buyItem(1,'market','burger',1);assert(not ok and e=='add_item_failed'and r.players[1].PlayerData.money.cash==before);return ok,e end)
case('delivery ambiguous marks incident',function(r)r.addError=true;local ok,e=r.service.buyItem(1,'market','burger',1);assert(not ok and e=='reconciliation_required');return ok,e end)
case('charge ambiguous marks incident',function(r)r.chargeError=true;return r.service.buyItem(1,'market','burger',1)end)
case('refund fails marks incident',function(r)r.addResult=false;r.creditResult=false;return r.service.buyItem(1,'market','burger',1)end)
case('save failure removes delivery and refunds',function(r)
    local cash=r.players[1].PlayerData.money.cash;r.m.onWrite=function()return false end
    local ok,e=r.service.buyItem(1,'market','burger',2);assert(not ok and e=='save_failed'and r.players[1].PlayerData.money.cash==cash and r.service.dailyStock.market.burger==20);return ok,e
end)
case('save failure failed delivery rollback incident',function(r)r.m.onWrite=function()return false end;r.removeResult=false;return r.service.buyItem(1,'market','burger',2)end)
case('raw inventory fallback retains signatures',function(r)
    r.library.inventory.AddItem=nil;r.library.inventory.RemoveItem=nil;r.library.inventory.GetItemCount=nil;r.library.inventory.Items=nil
    r.service.state.stores[1].items[1].currency='token';return r.service.buyItem(1,'market','burger',2)
end)
case('raw items fallback',function(r)r.library.inventory.Items=nil;return r.service.getItems(1)end)
case('raw unavailable fallback',function(r)r.library.inventory.Items=nil;r.resource='stopped';return r.service.getItems(1)end)
case('inventory return numeric one is not delivery true',function(r)r.addResult=1;return r.service.buyItem(1,'market','burger',1)end)
case('buy store resets stock',function(r)
    local ok,p=r.service.buyStore(1,'market','bank');assert(ok and p.stores[1].owner=='CID1'and p.stores[1].stock.burger==0 and not r.service.dailyStock.market);return ok,p
end)
case('ownership save failure refunds',function(r)r.m.onWrite=function()return false end;return r.service.buyStore(1,'market','cash')end)
case('owner transfer keeps stock resets managers',function(r)
    assert(r.service.buyStore(1,'market','cash'));assert(r.service.addManager(1,'market',2));return r.service.transferStore(1,'market',2)
end)
case('manager add duplicate and remove',function(r)
    assert(r.service.buyStore(1,'market','cash'));assert(r.service.addManager(1,'market',2));local ok,e=r.service.addManager(1,'market',2);assert(not ok and e=='already_manager')
    return r.service.removeManager(1,'market','CID2')
end)
case('manager stock access owner edit denied',function(r)
    assert(r.service.buyStore(1,'market','cash'));assert(r.service.addManager(1,'market',2));r.jobResult=false
    assert(r.service.setItem(2,'market',{name='water',price=9}));return r.service.updateOwnerStore(2,'market',{label='No'})
end)
case('metadata slots deposit',function(r)
    assert(r.service.buyStore(1,'market','cash'));local ok,p=r.service.addStockFromPlayer(1,'market','burger',8,19)
    assert(ok and p.stores[1].stock.burger==8 and p.stores[1].items[1].price==19 and r.items[1][1].count==0 and r.items[1][2].count==2);return ok,p
end)
case('deposit failure restores metadata',function(r)
    assert(r.service.buyStore(1,'market','cash'));r.m.onWrite=function()return false end;return r.service.addStockFromPlayer(1,'market','burger',8,19)
end)
case('deposit insufficient items',function(r)return r.service.addStockFromPlayer(1,'market','burger',100,19)end)
case('deposit ambiguous removal',function(r)r.removeError=true;return r.service.addStockFromPlayer(1,'market','burger',2,19)end)
case('withdraw success',function(r)assert(r.service.buyStore(1,'market','cash'));r.service.state.stores[1].balance=80;return r.service.withdraw(1,'market')end)
case('withdraw save failure rolls back credit',function(r)
    assert(r.service.buyStore(1,'market','cash'));r.service.state.stores[1].balance=80;r.m.onWrite=function()return false end;return r.service.withdraw(1,'market')
end)
case('withdraw ambiguous marks incident',function(r)assert(r.service.buyStore(1,'market','cash'));r.service.state.stores[1].balance=80;r.creditError=true;return r.service.withdraw(1,'market')end)
case('post purchase updates stock and balance once',function(r)
    r.purchase(true,{source=1,shopType='forge_core_store_market',itemName='burger',count=2,totalPrice=20,currency='money'})
    assert(r.service.dailyStock.market.burger==18 and r.service.state.stores[1].balance==20 and r.players[1].PlayerData.money.cash==1000)
end)
case('post purchase refusal no effect',function(r)r.purchase(false,{source=1,shopType='forge_core_store_market',itemName='burger',count=2,totalPrice=20})end)
case('post purchase save failure incident',function(r)r.m.onWrite=function()return false end;r.purchase(true,{source=1,shopType='forge_core_store_market',itemName='burger',count=2,totalPrice=20});assert(r.service.incidents.market)end)
case('post purchase json busy incident',function(r)
    local co=coroutine.create(function()r.library.withJsonLock(r.config.Stores.Storage.file,function()coroutine.yield('held')end)end)
    assert(coroutine.resume(co));r.purchase(true,{source=1,shopType='forge_core_store_market',itemName='burger',count=1,totalPrice=10})
    assert(r.service.incidents.market)
    assert(coroutine.resume(co))
end)
case('incident hook rejects further checkout',function(r)r.service.incidents.market={};assert(r.hooks[r.service.purchaseHookId]({shopType='forge_core_store_market'})==false)end)
case('inventory restart subscription',function(r)
    r.fireStore('onResourceStop','ox_inventory');assert(not r.service.purchaseHookId)
    r.fireStore('onResourceStart','ox_inventory');r.advance(0);assert(r.service.purchaseHookId)
end)
case('inventory reload coalesces',function(r)r.fireStore('forge-core:server:inventory:reloaded');r.fireStore('forge-core:server:inventory:reloaded');r.advance(0)end)
case('new date only on load',function(r)r.date='2026-10-22';r.service.load();assert(r.service.state.settings.lastRestock=='2026-10-22')end)
case('import backup shops source',function(r)
    r.m.files[r.config.Stores.Storage.file]=nil
    r.rawShops[r.config.Stores.Storage.oxBackupFile]="return {Test={name='Original',inventory={{name='water',price=4}},locations={vec3(1,2,3)}}}"
    r.service.load();assert(r.service.state.stores[1].id=='test_1')
end,true)
case('bad imported source',function(r)r.m.files[r.config.Stores.Storage.file]=nil;r.rawShops[r.config.Stores.Storage.oxFile]='not lua';r.service.load();assert(#r.service.state.stores==0)end,true)
case('service missing registration remains false open',function(r)r.library.inventory.RegisterShop=nil;return r.service.openShop(1,'market')end)
case('getPlayerItems dedupes without sum inherited',function(r)local ok,p=r.service.getPlayerItems(1);assert(ok and p[1].count==6);return ok,p end)
print('PASS stores server/config differentials '..n)
