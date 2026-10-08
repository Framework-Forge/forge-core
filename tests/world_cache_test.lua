local H=dofile('tests/cache_harness.lua')
local server=H.new(true);server.players[1]={PlayerData={citizenid='A'}}
server.load('shared/cache.lua')
local S=server.env.ForgeCore.State
local domains={'stores','objects','npcs','density','vinewood','starterpack','farms','billboards','characterPreviews','spotlights'}
for _,key in ipairs(domains) do assert(S.publish(key,{value=key}));assert(not S.publish(key,{value=key})) end
server.advance(0)
assert(#server.out==1,'Publications in one tick must be coalesced')
local snapshot=server.callbacks['forge-core:cache:snapshot'](1)
assert(snapshot.ready and snapshot.states.characterPreviews)
assert(not server.callbacks['forge-core:cache:snapshot'](1),'Snapshot requests must be throttled')
local copy=S.get('stores');copy.value='tamper';assert(S.get('stores').value=='stores')
local public=server.env.pr_lib.cache.GetResourceState('forge-core','stores')
public.value='tamper';assert(S.get('stores').value=='stores')
assert(server.env.pr_lib.cache:GetResourceState('forge-core','stores').value=='stores')
assert(not server.env.pr_lib.cache.GetResourceState('forge-core','unknown'))
local calls=0;local cancel=server.env.pr_lib.cache.OnResourceState('forge-core','stores',function(data) calls=calls+1;assert(data.value=='changed') end)
S.publish('stores',{value='changed'});assert(calls==1);cancel();S.publish('stores',{value='latest'});assert(calls==1)
local latest=S.getRecord('stores');server.advance(0)
assert(server.out[2].args[1].states.stores.revision==latest.revision and not server.out[2].args[1].states.npcs)

local client=H.new(false);client.load('shared/cache.lua')
local C=client.env.ForgeCore.State
local seen={};C.onChange('stores',function(data) seen[#seen+1]=data and data.value or 'cleared' end)
client.fire('forge-core:cache:world',23,snapshot);assert(not C.get('stores'),'Local spoof must be ignored')
assert(C.apply(snapshot));client.advance(0);assert(C.get('stores').value=='stores')
local packet={generation=snapshot.generation,ready=true,states={stores=latest}}
assert(C.apply(packet));assert(C.apply(snapshot));client.advance(0);assert(C.get('stores').value=='latest','Late snapshot must not overwrite delta')
local broken=H.copy(packet);broken.states.fake={data={}};assert(not C.apply(broken));assert(C.get('stores').value=='latest')
local newer=H.copy(snapshot);newer.generation=newer.generation+1
for key,record in pairs(newer.states) do record.generation=newer.generation;record.revision=1;record.data.value='restarted '..key end
assert(C.apply(newer));client.advance(0)
assert(C.get('stores').value=='restarted stores' and seen[#seen]=='restarted stores','Queued nil reset cannot clear a new generation')
assert(not C.apply(packet),'Old generation must be rejected')
local finishes={}
C.onChange('objects',function(data) client.env.Wait(10);finishes[#finishes+1]=data and data.value or 'cleared' end)
local one=H.copy(newer.states.objects);one.revision=2;one.data.value='one'
local two=H.copy(one);two.revision=3;two.data.value='two'
assert(C.apply({generation=newer.generation,states={objects=one}}));client.advance(0)
assert(C.apply({generation=newer.generation,states={objects=two}}));client.advance(20)
assert(finishes[1]=='one' and finishes[2]=='two','Yielding handlers must finish in order')
client.fire('onResourceStop',nil,'forge-core');client.advance(0);assert(not C.get('stores') and seen[#seen]=='cleared')
server.fire('playerDropped',1);server.advance(600)
assert(server.callbacks['forge-core:cache:snapshot'](1))
local restart=H.new(true);restart.now=server.now+1;restart.load('shared/cache.lua')
restart.env.ForgeCore.State.publish('stores',{new=true})
assert(restart.env.ForgeCore.State.getRecord('stores').generation>snapshot.generation)
print('PASS world cache: 10 domains, copies, coalescing, provider API, cancellation, spoof/late/invalid packets, restart and cleanup')
