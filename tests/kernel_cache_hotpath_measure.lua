local T=dofile('tests/kernel_cache_delivery_harness.lua')
local r=T.context();r.prepareDelivery();assert(r.installDelivery())
local cfg,media=r.api.Context,r.api.Context.Context
local calls=0
for _,scope in ipairs({cfg,media})do
 local original=scope.Progress
 scope.Progress=function(...)calls=calls+1;return original(...)end
end
local producer=r.graph.Central.Parts.Producers.Cache.Producer
local data=r.fixture.state.PlayerData
data.citizenid='PERF';data.metadata={health=200,oxygen=100}
producer.player(data);producer.session(true)
calls=0
local start=os.clock()
for i=1,100 do
 data.metadata.oxygen=i%100
 producer.status({health=100,oxygen=i%100},{oxygen=i%100})
end
print(('CACHE_HOTPATH status=100 seconds=%.6f progress=%d'):format(os.clock()-start,calls))
assert(calls==0,'status must not build lifecycle reports')
assert(r.cacheDelivery.host.GetMetadata('oxygen')==0)
assert(r.api.Stop() and r.api.Progress().complete)
assert(not pcall(producer.status,{oxygen=1},{oxygen=1}),'closed owner remains revoked')
