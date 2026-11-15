local C=dofile('tests/kernel_native_library_harness.lua');local H=C.H;local r=C.new('client');r.allocate();assert(r.api.Prepare())
local current=true;local events={};local calls=0
local f={Seed={Library=r.api},NativeCache={Cache=r.nativeCache},IsCurrent=function()return current end}
local scope=H.load('../pr_bridge/bridge/delivery/forge_cache_ports.lua',H.environment())({foundation=f,running=coroutine.running,
 native={TriggerEvent=function(...)events[#events+1]=table.pack(...)end,GetResourceState=function()return'started'end},
 external={pr_bridge={accessCacheState=function(self,...)calls=calls+1;return r.host.access(...)end}}})
assert(calls==0 and #events==0 and scope.Ports.cache==r.api.Cache)
local delivery=H.load('../pr_bridge/bridge/delivery/forge_cache.lua',H.environment())(scope.Ports);assert(delivery.Open())
delivery.Delivery.writeCache('set','cash',42);assert(r.host.access('get','cash')==42 and calls==1)
delivery.Delivery.emit('qbx_core:client:cacheChanged',{cash=true});assert(events[1][1]=='qbx_core:client:cacheChanged')
assert(delivery.Cache.get('cash')==42)
scope.Close();assert(not pcall(delivery.Delivery.writeCache,'set','cash',99));assert(r.host.access('get','cash')==42)
delivery.Close();r.finish()
print('PASS192 native cache host ports feed actual forge_cache;one passive cache,no collectors/initial pulls,writes/events and close')
