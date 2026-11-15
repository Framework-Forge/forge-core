local T=dofile('tests/kernel_qb_bridge_harness.lua');local H=T.H;local n=0
local r=T.new(true);local object=r.object;local handler=r.events['baseevents:enteredVehicle'].handler
r.ready=false;assert(not pcall(r.api.GetCoreObject));assert(not pcall(handler,2,10,-1,'car',100));assert(r.api.Progress().pending==0);n=n+1
r.ready=true;r.readyHook=function()coroutine.yield('ready_wait')end
local co=coroutine.create(r.api.GetCoreObject);assert(coroutine.resume(co));assert(r.api.Progress().pending==1)
r.api.Close();assert(not r.api.Progress().complete);r.readyHook=nil
local ok,value=coroutine.resume(co);assert(not ok and tostring(value):find('qb_bridge_replaced',1,true))
assert(r.api.Progress().complete and r.backendClosed and object.Players==r.state.Players)
assert(not pcall(r.api.GetCoreObject)and not pcall(handler,2,10,-1,'car',100));n=n+1
-- Retained mutable core is deliberately characterized, not falsely claimed to be revoked by Close.
object.Functions.SetField('retained_legacy',9);assert(r.state.retained_legacy==9);n=n+1
local r=T.new(true);r.readyHook=function()coroutine.yield('ready')end
local co=coroutine.create(function()r.fire('baseevents:enteredVehicle',2,10,-1,'car',100)end);assert(coroutine.resume(co))
r.current=false;r.readyHook=nil;local ok=coroutine.resume(co);assert(not ok and #r.trace==0);n=n+1
local r=T.new(true);r.ports.convertItems=function()coroutine.yield('conversion_wait');r.rec('late accepted conversion')end
local co=coroutine.create(r.api.InitializeLegacyItems);assert(coroutine.resume(co));r.api.Close();assert(not r.api.Progress().complete)
assert(coroutine.resume(co));assert(r.api.Progress().complete and r.trace[1][1]=='late accepted conversion');n=n+1
-- Extra legacy mutator branches: partial AddItems keeps earlier writes and valid removal emits the old nil payload.
local a,b=T.S.new(false),T.S.new(true)
for _,x in ipairs({a,b})do x.object.Shared.Items.bread={old=true};x.Functions.UpdateItem('bread',{new=true});x.Functions.RemoveItem('bread')end
H.same(a.trace,b.trace);H.same(a.object.Shared.Items,b.object.Shared.Items);n=n+1
local a,b=T.S.new(false),T.S.new(true)
for _,x in ipairs({a,b})do
    local items={bread={label='Bread'},[1]={label='Invalid'}}
    setmetatable(items,{__pairs=function(t)local i=0;return function()i=i+1;if i==1 then return'bread',t.bread elseif i==2 then return 1,t[1]end end end})
    local ok,reason,bad=x.Functions.AddItems(items)
    assert(ok==false and reason=='invalid_item_name'and bad==items[1]and x.object.Shared.Items.bread==items.bread)
end
H.same(a.trace,b.trace);H.same(a.object.Shared.Items,b.object.Shared.Items);n=n+1
print('PASS lot89 bridge scope:'..n..' checks;readiness/Close/owner/await accounting,new ingress rejected,accepted conversion and retained mutable object explicitly characterized;virtual only')
