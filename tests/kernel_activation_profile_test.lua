local H=dofile('tests/kernel_native_foundation_harness.lua').H
local create=H.load('../pr_bridge/bridge/frameworks/forge/activation_profile.lua',H.environment())
local source={authority='forge-core',generation='261',qbEnabled=true,consumers={
 {name='ox_inventory',server={instance='inventory-a',inventory=true}},
 {name='forge-garage',client={instance='garage-a',inventory=false},server={instance='garage-server',inventory=false}}}}
local p=create(source);source.consumers[1].server.instance='tampered'
assert(p.Get('ox_inventory','server').instance=='inventory-a'and p.Get('ox_inventory','client')==nil)
local a=p.Consumers('server');assert(#a==2 and a[1].name=='forge-garage')
a[1].instance='foreign';assert(p.Get('forge-garage','server').instance=='garage-server')
local q=p.Get('ox_inventory','server');assert(q.generation=='261'and q.qbEnabled and q.inventory)
source.qbEnabled=nil;assert(not pcall(create,source));source.qbEnabled=true
source.consumers[2].name='ox_inventory';assert(not pcall(create,source))
source.consumers[2].name='qbx_core';assert(not pcall(create,source))
print('PASS261 explicit cross-resource/side instances and inventory ownership;copies resist mutation;missing capability/duplicates/shim refused')
