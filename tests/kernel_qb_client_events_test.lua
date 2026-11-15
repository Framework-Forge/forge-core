local D=dofile('tests/kernel_qb_client_events_harness.lua');local H=D.H;local n=0
local function test(name,fn)
    local a,b=D.new(false),D.new(true)
    H.same(a.capture(fn,a),b.capture(fn,b),name..' returns');H.same(a.trace,b.trace,name..' effects');n=n+1
end
for _,position in ipairs({'left','right','top','bottom-center','invalid',false})do for _,method in ipairs({'DrawText','ChangeText'})do
    test(method..tostring(position),function(r)return r.exported[method]('Text',position or nil)end)
    test('event:'..method,function(r)return r.fire('qb-core:client:'..method,'Text',position or nil)end)
end end
for _,name in ipairs({'HideText','KeyPressed'})do
    test(name,function(r)local result=table.pack(r.exported[name]());for i=1,#r.tasks do r.runTask(i)end;return table.unpack(result,1,result.n)end)
    test('event:'..name,function(r)r.fire('qb-core:client:'..name);for i=1,#r.tasks do r.runTask(i)end end)
end
for _,kind in ipairs({'Entering','Entered','Left'})do for _,hasKeys in ipairs({false,true})do for _,modelName in ipairs({false,'car'})do
    test('vehicle:'..kind,function(r)r.hasKeys=hasKeys;return r.fire('QBCore:Client:VehicleInfo',{netId=200,seat=-1,event=kind,name='server-name',modelName=modelName or nil})end)
end end end
test('command',function(r)return r.fire('QBCore:Command:CallCommand','command literal arguments')end)
test('command error',function(r)r.executeError=true;return r.fire('QBCore:Command:CallCommand','bad')end)
test('key error',function(r)r.keyError=true;return r.fire('QBCore:Client:VehicleInfo',{netId=1,seat=0,event='Entered'})end)
test('malformed info',function(r)return r.fire('QBCore:Client:VehicleInfo',{})end)
local a,b=D.new(false),D.new(true);local count=0
for name,d in pairs(a.events)do assert(b.events[name]and d.network==b.events[name].network);count=count+1 end
assert(count==6);for name in pairs(b.events)do assert(a.events[name],name)end
H.same(D.P.snapshot(a.exported),D.P.snapshot(b.exported));assert(a.exported.DrawText and b.exported.ChangeText and b.exported.HideText and b.exported.KeyPressed)
print('PASS lot91 whole installed drawtext/events parity:'..n..' cases;6 events/4 exports,positions/order/returns/timer/payload/modelName mismatch/errors,zero construction effects')
