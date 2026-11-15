local T=dofile('tests/kernel_qb_event_binding_harness.lua');local n=0
local r=T.new('client');r.prepare();r.installCore();r.bus.failAt=r.bus.nextId+2
assert(not r.events.Install()and r.bus.active()==2 and r.events.Progress().complete);n=n+1
local r=T.new('client');r.prepare();r.installCore();r.install()
r.bridge.api.Events[1].name='changed'
assert(not r.events.IsCurrent());local before=#r.bridge.trace
r.bus.emit('qb-core:client:DrawText',0,'ignored','left');assert(#r.bridge.trace==before)
r.events.Dispose();assert(r.bus.active()==2);n=n+1
local r=T.new('server');r.prepare();r.installCore();r.install()
r.core.Dispose();local before=#r.bridge.trace
r.bus.emit('QBCore:CallCommand',2,'command',{});assert(#r.bridge.trace==before and not r.events.IsCurrent())
r.events.Dispose();r.bridge.api.Close();n=n+1
local r=T.new('client');r.prepare();r.installCore()
r.bus.onListen=function()coroutine.yield('listen')end
local co=coroutine.create(r.events.Install);assert(coroutine.resume(co));assert(not r.events.Dispose())
r.bus.onListen=nil;assert(coroutine.resume(co));assert(r.bus.active()==2 and r.events.Progress().complete);n=n+1
local r=T.new('client');r.prepare();r.installCore();r.install()
local token
for t,d in pairs(r.bus.records)do if d.name=='qb-core:client:DrawText'then token=t end end
r.bus.failRemove=token.id;assert(not r.events.Dispose()and r.events.Progress().phase=='close-failed')
local before=#r.bridge.trace;r.bus.emit('qb-core:client:DrawText',0,'ignored');assert(#r.bridge.trace==before)
r.bus.failRemove=nil;assert(r.events.Dispose()and r.bus.active()==2);n=n+1
local r=T.new('client');r.prepare();r.installCore();r.install()
r.bridge.keyHook=function()coroutine.yield('keys')end
local co=coroutine.create(function()r.bus.emit('QBCore:Client:VehicleInfo',0,{netId=1,seat=0,event='Entered'})end)
assert(coroutine.resume(co));assert(r.events.Progress().pending==1)
r.events.Dispose();assert(not r.events.Progress().complete);r.bridge.keyHook=nil
assert(coroutine.resume(co)and r.events.Progress().complete);n=n+1
print('PASS lot94 scope:'..n..' checks;partial listen rollback,changed descriptor,core retirement,Dispose during registration,failed removal retry,accepted await drain;no foreign/core cleanup')
