local H = dofile('tests/cache_harness.lua')
local saved = assert(load(io.read('a'), '@stores JSON fixture', 't', {}))()
assert(type(saved.stores) == 'table' and #saved.stores > 0)
local server, client = H.new(true), H.new(false)
local se, ce = server.env, client.env
local function vector(x,y,z,w) return {x=x,y=y,z=z,w=w,__vector=z and (w and 'vector4' or 'vector3') or 'vector2'} end
for _, e in ipairs({se,ce}) do
    e.vector2, e.vector3, e.vector4, e.vec3 = vector, vector, vector, vector
    e.type = function(v) return type(v)=='table' and v.__vector or type(v) end
    e.ForgeCore.t = function(key) return key end
    e.os = setmetatable({date=function(format) return format=='%Y-%m-%d' and saved.settings.lastRestock or os.date(format) end}, {__index=os})
    e._G = e
end
-- Use the production loader/recovery, never a stub returning the state directly.
se.LoadResourceFile = function(resource, name)
    if resource=='forge-core' and name=='data/stores.json' then return 'fixture:stores' end
    if resource=='pr_bridge' then
        local file=io.open(H.bridge..name,'rb')
        if file then local raw=file:read('a');file:close();return raw end
    end
end
se.json.decode = function(raw) assert(raw=='fixture:stores');return H.copy(saved) end
se.SaveResourceFile = function() error('Startup must not write current-version, current-day store fixture') end
server.load(H.bridge..'bridge/core.lua')
se.pr_lib.loadJsonRecovery = se.PRCore.loadJsonRecovery
se.pr_lib.jsonDraft = se.PRCore.jsonDraft
local shops, hooks, hookRegistrations = {}, {}, 0
local function read(path) local f=assert(io.open(path,'rb'));local raw=f:read('a');f:close();return raw end
local oxShopSource=read('../../../[ox]/ox_inventory/modules/shops/server.lua')
local setup=assert(oxShopSource:match('(local function setupShopItems.-)\n%-%-%-@param shopType string'))
local register=assert(oxShopSource:match('(local function registerShopType.-)\n%-%-%-@param shopType string'))
local registerOx=assert(load('local Shops,Items,Inventory=...\nlocal server={randomprices=false};local locations="targets"\n'
    ..setup..register..'\nreturn registerShopType','@real OX shop registration','t',se))(shops,
    function(name) return {name=name,weight=1} end,{SlotWeight=function() return 1 end})
se.ActiveBridges.inventory = 'ox'
se.Debug = function() end;se.Lang = {t=function(_,key) return key end}
se.exports.ox_inventory = {
    RegisterShop=function(_,id,data) registerOx(id,H.copy(data)) end,
    Items=function(_,name) return {name=name,label=name,weight=1} end,
    registerHook=function(_,event,fn) hookRegistrations=hookRegistrations+1;hooks[event]=fn;return 'forge-core:'..event..':1' end,
}
se.pr_lib.inventory = server.load(H.bridge..'bridge/inventories/ox/server.lua')
-- Real secure callback transport, with only native messages/promises simulated.
ce.promise = {new=function() return {resolve=function(self,value) self.value=value end} end}
ce.Citizen = {Await=function(p) while not p.value do ce.Wait(1) end;return p.value end}
ce.TriggerServerEvent = function(name,...) server.fire(name,1,...) end
local baseSend = se.TriggerClientEvent
se.TriggerClientEvent = function(name,target,...)
    baseSend(name,target,...)
    client.fire(name,65535,...)
end
se.pr_lib.callback = server.load(H.bridge..'bridge/callback/secure_server.lua')
ce.pr_lib.callback = client.load(H.bridge..'bridge/callback/secure_client.lua')
ce.pr_lib.math = client.load(H.bridge..'bridge/utils/numbers.lua')
local zones = client.load(H.bridge..'bridge/targets/native/zones.lua')
ce.PRCore = {load=function(name)
    if name=='bridge.targets.native.zones' then return zones end
    if name=='bridge.targets.native.pickups' then return {} end
    error(name)
end}
ce.GetInvokingResource = function() return 'forge-core' end
local api = client.load(H.bridge..'bridge/targets/native/api.lua')
ce.exports.pr_bridge = setmetatable({}, {__index=function(_,name) return function(_,...) return assert(api[name])( ... ) end end})
ce.ActiveBridges.target = 'native'
ce.pr_lib.target = client.load(H.bridge..'bridge/targets/native/client.lua')
local blips = 0
ce.AddBlipForCoord = function() blips=blips+1;return blips end
for _, name in ipairs({'SetBlipSprite','SetBlipDisplay','SetBlipScale','SetBlipColour','SetBlipAsShortRange',
    'BeginTextCommandSetBlipName','AddTextComponentSubstringPlayerName','EndTextCommandSetBlipName','RemoveBlip'}) do ce[name]=function() end end
ce.DoesBlipExist = function() return true end
server.load('shared/stores.lua');server.load('shared/cache.lua');server.load('server/stores/service.lua')
client.load('shared/stores.lua');client.load('shared/cache.lua');client.load('client/stores/main.lua')
-- Hydrate a late join from the actual server snapshot, not a direct refresh call.
server.env.ForgeCore.StoresService.start()
client.advance(0);server.advance(1);client.advance(2000)
local payload = assert(ce.ForgeCore.State.get('stores'),'Stores were not hydrated')
assert(#payload.stores==#saved.stores,'JSON stores were lost')
local expectedPoints, registeredShops = 0, 0
for _, store in ipairs(payload.stores) do
    if store.enabled~=false then
        local ok,id=se.ForgeCore.StoresService.openShop(1,store.id)
        assert(ok and shops[id], 'Shop not registered: '..store.id)
        assert(shops[id].type=='shop' and type(shops[id].items)=='table','OX shop shape invalid')
        for _, item in ipairs(shops[id].items) do
            local definition
            for _, candidate in ipairs(store.items) do if candidate.name==item.name then definition=candidate;break end end
            assert(definition and item.price==definition.price,'JSON price changed in OX registration')
            assert(item.count>0 and item.slot and item.weight,'OX stock/slot not initialized')
        end
        registeredShops=registeredShops+1
        for _, point in ipairs(store.points) do expectedPoints=expectedPoints+1 end
    end
end
assert(#ce.ForgeCore.Client.Stores.zones==expectedPoints, ('Missing targets: %s/%s'):format(#ce.ForgeCore.Client.Stores.zones,expectedPoints))
assert(hooks.buyItem,'Purchase hook absent')
print(('PASS real store JSON -> recovery -> PRBridge shop registration -> secure callback/cache -> native targets: %s stores, %s points'):format(registeredShops,expectedPoints))
-- Exercise the real post-purchase accounting/persistence in memory only.
local probe
for _, store in ipairs(payload.stores) do
    local ok,id=se.ForgeCore.StoresService.openShop(1,store.id)
    if ok and shops[id].items[1] then probe={store=store,id=id,item=shops[id].items[1]};break end
end
assert(probe,'No stocked JSON shop to test')
local memory, encoded, serial = {['data/stores.json']='fixture:stores'}, {}, 0
local baseLoad=se.LoadResourceFile
se.LoadResourceFile=function(resource,name) return resource=='forge-core' and memory[name] or baseLoad(resource,name) end
se.json.encode=function(value) serial=serial+1;local raw='write:'..serial;encoded[raw]=H.copy(value);return raw end
se.json.decode=function(raw) return raw=='fixture:stores' and H.copy(saved) or H.copy(assert(encoded[raw])) end
se.SaveResourceFile=function(resource,name,raw) assert(resource=='forge-core');memory[name]=raw;return true end
local purchased={source=1,shopType=probe.id,itemName=probe.item.name,fromSlot=probe.item,count=1,
    price=probe.item.price,totalPrice=probe.item.price,currency=probe.item.currency}
assert(hooks.buyItem(purchased)~=false)
server.fire('forge-core:buyItem:1',nil,true,purchased)
local updated=se.ForgeCore.StoresService.getAll()
local result
for _, store in ipairs(updated.stores) do if store.id==probe.store.id then result=store;break end end
assert(result.balance==probe.store.balance+probe.item.price,'Purchase must credit the store once')
assert(#result.sales==math.min(50,#probe.store.sales+1),'Purchase must record one sale')
assert(shops[probe.id].items[1].count==probe.item.count-1,'Purchase must decrease available OX stock once')
server.fire('forge-core:buyItem:1',nil,false,purchased)
assert(se.ForgeCore.StoresService.getAll().stores[1].balance==updated.stores[1].balance,'Rejected purchase cannot credit balance')
print('PASS store purchase integration: JSON price, stock decrement, balance, sale record and rejected-purchase guard (memory-only writes)')
local before=hookRegistrations
server.fire('onResourceStop',nil,'ox_inventory')
shops={};hooks={}
-- The real OX module would have a fresh registry after resource restart.
se.exports.ox_inventory.RegisterShop=function(_,id,data) shops[id]=data end
server.fire('onResourceStart',nil,'ox_inventory');server.advance(0)
assert(hookRegistrations==before+1 and hooks.buyItem,'Restart must renew the OX purchase hook')
local liveHandlers=0
for _, handle in ipairs(server.events['forge-core:buyItem:1']) do if handle.fn then liveHandlers=liveHandlers+1 end end
assert(liveHandlers==1,'Restart cannot duplicate purchase handlers')
local count=0;for _ in pairs(shops) do count=count+1 end
assert(count==registeredShops,'Restart must register every JSON shop again')
before=hookRegistrations
server.fire('forge-core:server:inventory:reloaded',nil)
server.fire('forge-core:server:inventory:reloaded',nil);server.advance(0)
assert(hookRegistrations==before,'Item catalog reload must preserve a single purchase hook')
print('PASS OX lifecycle: all stores re-registered, one purchase hook after restart/catalog reload, production JSON untouched')
