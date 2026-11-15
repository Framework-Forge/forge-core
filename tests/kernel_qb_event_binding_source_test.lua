local T=dofile('tests/kernel_qb_event_binding_harness.lua');local H=T.H;local n=0
local r=T.new('server');r.prepare();r.installCore();r.install();r.bridge.trace={}
r.bus.emit('baseevents:enteredVehicle',47,200,-1,'car',100)
local last=r.bridge.trace[#r.bridge.trace];assert(last[1]=='client'and last[2][1]=='QBCore:Client:VehicleInfo'and last[2][2]==47);n=n+1
r.bus.emit('QBCore:DebugSomething',999,{value='debug'})
last=r.bridge.trace[#r.bridge.trace];assert(last[1]=='log:debug'and last[2][1]=='legacy_consumer'and last[2][2].value=='debug');n=n+1
local result
r.bridge.object.Functions.CreateCallback('source94',function(src,cb,a,b,c)result=table.pack(src,a,b,c);cb('tail',nil,7)end)
r.bus.emit('QBCore:Server:TriggerCallback',51,'source94','one',nil,'three')
H.same(result,table.pack(51,'one',nil,'three'));last=r.bridge.trace[#r.bridge.trace]
assert(last[2][2]==51);n=n+1
r.bridge.object.Functions.CreateCallback('error94',function()error('fixture94_failure')end)
assert(not pcall(r.bus.emit,'QBCore:Server:TriggerCallback',51,'error94'))
assert(r.events.Progress().pending==0);n=n+1
r.events.Dispose();r.core.Dispose();r.bridge.api.Close()
print('PASS lot94 origin policy:'..n..' cases;server source-first vehicle/callback tuples,debug keeps payload-first,error accounting,distinct event registry semantics unchanged')
