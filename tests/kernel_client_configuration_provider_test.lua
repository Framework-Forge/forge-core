local T=dofile('tests/kernel_client_configuration_harness.lua');local H,P=T.H,T.P;local count=0
local function compare(name,setup,plate,vehicle)
    local a,b=T.provider(),T.provider();a.mount();b.mount();local old,new=a.config(false),b.config(true)
    assert(#a.trace==0 and #b.trace==0,'construction does not consult resources/keys/wait')
    assert(a.vectors==14 and b.vectors==14 and a.hashes==3 and b.hashes==3,'only explicit vector/hash construction')
    H.same(P.snapshot(new),P.snapshot(old),'complete installed config')
    setup(a);setup(b);assert(b.api.Open())
    local x,y=table.pack(pcall(old.hasKeys,plate,vehicle)),table.pack(pcall(new.hasKeys,plate,vehicle))
    H.same(P.snapshot(y),P.snapshot(x),name..' returns');H.same(b.trace,a.trace,name..' trace');count=count+1
end
for _,pr in ipairs({'started','starting','stopped'})do for _,qbx in ipairs({'started','starting','stopped'})do
    compare(pr..qbx,function(r)r.states={pr_carkeys=pr,qbx_vehiclekeys=qbx};r.keyState:AddPermanentKey('AB C',{});r.qbxResult=true end,'  ab c ',7)
end end
compare('temporary',function(r)r.states.pr_carkeys='started';r.keyState:AddTempKey('ABC')end,'abc',7)
compare('missing key',function(r)r.states.pr_carkeys='started'end,'UNKNOWN',7)
compare('nil plate',function(r)r.states.pr_carkeys='started'end,nil,nil)
compare('native plate',function(r)r.states.pr_carkeys='started';r.plate='  a b c ';r.keyState:AddTempKey('ABC')end,nil,7)
compare('empty',function(r)r.states.pr_carkeys='started'end,'',7)
compare('false native plate',function(r)r.states.pr_carkeys='started';r.plate=false end,false,7)
compare('PR error',function(r)r.states.pr_carkeys='started';r.keyError=true end,'ABC',7)
compare('QBX false',function(r)r.states.qbx_vehiclekeys='starting';r.qbxResult=false end,nil,7)
compare('QBX nil tuple',function(r)r.states.qbx_vehiclekeys='started'end,nil,7)
compare('QBX error',function(r)r.states.qbx_vehiclekeys='started';r.keyError=true end,nil,7)
assert(count==19)
local waits=0
local function waitCase(name,make,args)
    local a,b=T.provider(),T.provider();b.mount();assert(b.api.Open());local callsA,callsB=0,0
    local ca=make(function()callsA=callsA+1;return callsA end);local cb=make(function()callsB=callsB+1;return callsB end)
    local x=table.pack(pcall(a.waitFor,ca,table.unpack(args,1,args.n)))
    local y=table.pack(pcall(b.api.WaitFor,cb,table.unpack(args,1,args.n)))
    -- The installed error's source location depends on its caller; compare message suffix.
    if not x[1]then x[2]=tostring(x[2]):match('([^:]+)$');y[2]=tostring(y[2]):match('([^:]+)$')end
    H.same(P.snapshot(y),P.snapshot(x),name);H.same(b.trace,a.trace,name..' waits');assert(callsA==callsB);waits=waits+1
end
waitCase('false is a terminal result',function(next)return function()next();return false end end,table.pack())
waitCase('immediate value',function(next)return function()return next()end end,table.pack())
waitCase('eventual value',function(next)return function()if next()==3 then return'loaded'end end end,table.pack(nil,10))
waitCase('default timeout',function(next)return function()next()end end,table.pack())
waitCase('zero timeout',function(next)return function()next()end end,table.pack(nil,0))
waitCase('numeric string timeout',function(next)return function()next()end end,table.pack(nil,'2'))
waitCase('unlimited eventual',function(next)return function()if next()==5 then return 9 end end end,table.pack(nil,false))
waitCase('message error',function(next)return function()next()end end,table.pack('timeout sentinel',2))
waitCase('raise error',function(next)return function()next()end end,table.pack(nil,2,true))
waitCase('callback error',function()return function()error('callback sentinel',0)end end,table.pack())
waitCase('invalid callback',function()return 7 end,table.pack())
assert(waits==11)
print('PASS lot70 provider:19 whole-config/key comparisons,11 installed PR waitFor comparisons;real key cache/sanitization/export bodies,optional QBX proxy only;virtual effects')
