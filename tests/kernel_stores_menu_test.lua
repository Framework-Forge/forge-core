local R=dofile('tests/kernel_stores_harness.lua')
local n=0
local function case(name,fn)R.menuCase(name,fn);n=n+1 end
case('root parent',function(r)r.menu.openStoresAdminMenu();assert(r.last.menu=='forge_core_server_settings'and #r.last.options==4)end)
case('load refusal',function(r)r.rpcHook=function()return false,'no_permission'end;r.menu.openStoresAdminMenu()end)
case('load malformed',function(r)r.rpcHook=function()return true,false end;r.menu.openStoresAdminMenu();assert(#r.last.options==3)end)
case('admin actions parent',function(r)r.menu.openStoreAdmin('market');assert(#r.last.options==6 and r.last.menu=='forge_core_stores_admin')end)
case('teleport native path',function(r)r.menu.openStoreAdmin('market');r.select(3)end)
case('points parent radius and primary',function(r)r.menu.openStorePoints('market');assert(#r.last.options==3 and r.last.menu=='forge_core_store_admin_market')end)
case('owner points parent',function(r)r.menu.openStorePoints('market',true);assert(r.last.menu=='forge_core_store_owner_market')end)
case('owner points denied',function(r)r.storeInfo.isOwner=false;r.menu.openStorePoints('market',true)end)
case('remove secondary point',function(r)r.alerts={'confirm'};r.menu.openStorePoints('market');r.select(3);r.runTimers()end)
case('cancel remove secondary',function(r)r.alerts={'cancel'};r.menu.openStorePoints('market');r.select(3)end)
case('products parent',function(r)r.menu.openStoreProducts('market');assert(#r.last.options==3 and r.last.menu=='forge_core_store_admin_market')end)
case('product actions parent',function(r)r.menu.openStoreProductActions('market',{name='burger'});assert(r.last.menu=='forge_core_store_products_market')end)
case('product remove',function(r)r.menu.openStoreProductActions('market',{name='burger'});r.select(2);r.runTimers()end)
case('product no stock duplicate field',function(r)
    r.inputHook=function(_,fields)assert(#fields==4 and fields[2].label=='inputs.store_item_price'and fields[3].label=='inputs.store_item_daily_stock');return{'burger',11,9,'true'}end
    r.menu.openStoreProductEditor('market',{name='burger',price=10,dailyStock=20})
end)
case('shop opens provider false still true inherited',function(r)assert(r.menu.openStoreInventory('market')==true)end)
case('shop missing provider',function(r)r.library.inventory=nil;assert(r.menu.openStoreInventory('market')==false)end)
case('shop denied',function(r)r.rpcHook=function()return false,'sales_paused'end;assert(not r.menu.openStoreInventory('market'))end)
case('front owner manage route',function(r)r.storeInfo.store.owner='CID1';r.menu.openStorefront('market');r.select(1);assert(r.last.id=='forge_core_store_owner_market')end)
case('front outsider opens inventory directly',function(r)r.storeInfo.store.owner='CID2';r.storeInfo.hasAccess=false;r.menu.openStorefront('market')end)
case('owner manager options',function(r)r.storeInfo.isOwner=false;r.menu.openStoreOwnerMenu('market');assert(#r.last.options==3 and r.last.options[2].disabled)end)
case('owner all options',function(r)r.menu.openStoreOwnerMenu('market');assert(#r.last.options==8 and r.last.menu=='forge_core_storefront_market')end)
case('withdraw option',function(r)r.menu.openStoreOwnerMenu('market');r.select(8);r.runTimers()end)
case('manager list delete',function(r)r.storeInfo.store.managers={{citizenid='CID2',name='Two'}};r.menu.openStoreManagers('market');assert(r.last.menu=='forge_core_store_owner_market');r.select(2);r.runTimers()end)
case('no inventory items',function(r)r.rpcHook=function(n)if n==r.config.Stores.Callbacks.getPlayerItems then return true,{}end;return true,r.storeInfo end;r.menu.openStoreOwnerStock('market')end)
local forms={
    {'settings','openStoresSettings',function(r)return{r.payload.settings}end,{'true','true','true',50}},
    {'blacklist','openStoresBlacklist',function(r)return{r.payload.settings}end,{'burger, water burger'}},
    {'edit','openStoreEdit',function(r)return{r.storeInfo.store}end,{'New',123,'true','false','Buy'}},
    {'product','openStoreProductEditor',function()return{'market',{name='burger'}}end,{'burger',7,12,'true'}},
    {'purchase','openStoreBuyStore',function()return{'market'}end,{'bank'}},
    {'buy item','openStoreBuyItem',function()return{'market',{name='burger',label='Burger'}}end,{2}},
    {'owner edit','openStoreOwnerEdit',function(r)return{r.storeInfo.store}end,{'New','Open'}},
    {'owner settings','openStoreOwnerSettings',function(r)return{r.storeInfo.store}end,{'true','true',120}},
    {'transfer','openStoreTransfer',function()return{'market'}end,{2}},
    {'add manager','openStoreAddManager',function()return{'market'}end,{2}},
    {'stock deposit','openStoreOwnerStock',function()return{'market'}end,{'burger',3,11}},
}
for _,f in ipairs(forms)do
    case(f[1]..' canceled',function(r)r.menu[f[2]](table.unpack(f[3](r)))end)
    case(f[1]..' saved',function(r)r.inputs={f[4]};r.menu[f[2]](table.unpack(f[3](r)));r.runTimers()end)
end
case('settings save refused',function(r)
    r.inputs={{'true','true','true',50}};r.rpcHook=function(n)if n==r.config.Stores.Callbacks.saveSettings then return false,'save_failed'end;return true,r.payload end
    r.menu.openStoresSettings(r.payload.settings);r.runTimers()
end)
case('delete store confirmed',function(r)r.alerts={'confirm'};r.menu.openStoreAdmin('market');r.select(6);r.runTimers()end)
case('delete store canceled',function(r)r.alerts={'cancel'};r.menu.openStoreAdmin('market');r.select(6)end)
local function resumeCapture(r,key)
    local co=coroutine.create(assert(r.dynamicThreads[1]));assert(coroutine.resume(co));r.just={[key]=true};assert(coroutine.resume(co));r.runTimers()
end
case('create capture confirmed',function(r)r.inputs={{'New',100,'true','Buy'}};r.menu.openStoreCreate();assert(r.textActive);resumeCapture(r,201);assert(not r.textActive)end)
case('create capture canceled',function(r)r.inputs={{'New',100,'true','Buy'}};r.menu.openStoreCreate();resumeCapture(r,177)end)
case('create form canceled',function(r)r.menu.openStoreCreate();assert(#r.dynamicThreads==0)end)
case('laser absent',function(r)r.library.devlaser=nil;r.inputs={{'New',100,'true','Buy'}};r.menu.openStoreCreate()end)
case('add point capture',function(r)r.menu.openStorePoints('market');r.select(1);resumeCapture(r,201)end)
case('primary recapture',function(r)r.menu.openStorePoints('market');r.select(2);resumeCapture(r,201)end)
case('laser external stop',function(r)r.inputs={{'New',100,'true','Buy'}};r.menu.openStoreCreate();r.laserActive=false;r.laserOptions.onStop();assert(not r.textActive)end)
case('laser reentry refused',function(r)r.inputs={{'New',100,'true','Buy'},{'Again',100,'true','Buy'}};r.menu.openStoreCreate();r.menu.openStoreCreate();assert(#r.dynamicThreads==1)end)
print('PASS stores menu differentials '..n)
