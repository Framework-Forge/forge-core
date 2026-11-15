local T=dofile('tests/kernel_qb_bridge_harness.lua');local H,P=T.H,T.P;local n=0
local function same(a,b,where)H.same(a.trace,b.trace,where);n=n+1 end
local a,b=T.new(false),T.new(true)
assert(#b.trace==0,'ported constructor conversion/IO');b.api.InitializeLegacyItems();same(a,b,'explicit conversion parity')
local function snapshot(v,seen)
    if type(v)=='function'then return'<function>'end
    if type(v)~='table'then return v end
    if getmetatable(v)==false then return'<legacy Items blocked>'end
    seen=seen or{};if seen[v]then return'<cycle>'end;seen[v]=true
    local out={};for key,value in pairs(v)do out[key]=snapshot(value,seen)end;seen[v]=nil;return out
end
H.same(snapshot(a.object),snapshot(b.object),'complete core object')
assert(b.object.Players==b.state.Players and b.object.Shared.Jobs==b.jobs and b.object.Shared.Gangs==b.gangs)
assert(b.shared.Items==nil and a.shared.Items~=nil,'canonical Shared separation')
for _,filters in ipairs({{}, {'Functions'}, {'Shared'}, {bad=true}})do assert(b.api.GetCoreObject(filters)==b.object and a.api.GetCoreObject(filters)==a.object);n=n+1 end
for name,d in pairs(a.events)do assert(b.events[name]and d.network==b.events[name].network,name)end
for name in pairs(b.events)do assert(a.events[name],name)end
for _,name in ipairs({'baseevents:enteringVehicle','baseevents:enteredVehicle','baseevents:leftVehicle','baseevents:enteringAborted','QBCore:DebugSomething',
    'qbx_core:server:onJobUpdate','qbx_core:server:onGangUpdate'})do
    local x,y=T.new(false),T.new(true);x.trace={};y.trace={}
    local args=name:find('onJob')or name:find('onGang')
    if args then x.fire(name,2,'test',{label='New'});y.fire(name,2,'test',{label='New'})
    elseif name=='QBCore:DebugSomething'then x.fire(name,2,{a=1});y.fire(name,2,{a=1})
    else x.fire(name,2,200,-1,'car',100);y.fire(name,2,200,-1,'car',100)end
    same(x,y,name);H.same(x.jobs,y.jobs);H.same(x.gangs,y.gangs)
end
for _,allowed in ipairs({false,true})do for _,missing in ipairs({false,true})do
    local x,y=T.new(false),T.new(true);x.trace={};y.trace={};x.ace=allowed;y.ace=allowed;x.missing=missing;y.missing=missing
    x.fire('QBCore:CallCommand',2,'cmd',{'one','two'});y.fire('QBCore:CallCommand',2,'cmd',{'one','two'});same(x,y,'command')
end end
for _,r in ipairs({a,b})do
    r.trace={};local f=r.object.Functions
    f.CreateCallback('echo',function(src,cb,...)r.rec('server-callback',src,...);cb(nil,'tail')end)
    r.fire('QBCore:Server:TriggerCallback',2,'echo',1,nil,3)
    r.fire('QBCore:Server:TriggerCallback',2,'missing')
    f.TriggerClientCallback('client',2,function(...)r.rec('client-callback',...)end,'request')
    r.fire('QBCore:Server:TriggerClientCallback',2,'client',false,nil,'tail')
    r.fire('QBCore:Server:TriggerClientCallback',2,'client','ignored')
    assert(r.object.ClientCallbacks.client==nil)
    for _,name in ipairs({'QBCore:Server:SpawnVehicle','QBCore:Server:CreateVehicle'})do
        r.fire('QBCore:Server:TriggerCallback',2,name,'car',nil,false)
    end
end
same(a,b,'callback/vehicle payloads')
-- Installed callback slots are keyed only by name; later player replaces earlier, and throwing callbacks stay installed.
for _,r in ipairs({a,b})do
    local f=r.object.Functions;r.trace={}
    f.TriggerClientCallback('collision',2,function()r.rec('old')end)
    f.TriggerClientCallback('collision',7,function()r.rec('new')end)
    r.fire('QBCore:Server:TriggerClientCallback',2,'collision')
    f.TriggerClientCallback('throw',2,function()error('fixture_callback_failure')end)
    assert(not pcall(r.fire,'QBCore:Server:TriggerClientCallback',2,'throw')and r.object.ClientCallbacks.throw~=nil)
end
same(a,b,'legacy collisions/errors')
local x,y=T.new(false),T.new(true);x.trace={};y.trace={}
x.env.GetInvokingResource=function()return nil end;y.ports.native.GetInvokingResource=function()return nil end
x.fire('QBCore:DebugSomething',2,{fallback=true});y.fire('QBCore:DebugSomething',2,{fallback=true});same(x,y,'debug fallback')
for _,setting in ipairs({'false','true','FALSE','0'})do
    local x,y=T.new(false,{convars={['qbx:enablebridge']=setting}}),T.new(true,{convars={['qbx:enablebridge']=setting}})
    assert(x.api.Enabled==y.api.Enabled);if setting=='false'then assert(next(x.events)==nil and next(y.events)==nil and y.api.GetCoreObject==nil)end;n=n+1
end
print('PASS lot89 full installed main/events/debug parity:'..n..' comparisons;10 descriptors,whole object/getter filters/callback payloads/legacy collisions/error retention,explicit conversion separation')
