local T=dofile('tests/kernel_inventory_bridge_harness.lua');local count=0
local function one(fn)local r=T.fixture(true);fn(r);r.api.Close();count=count+1 end
one(function(r)r.current=false;assert(not r.api.Install()and r.active()==0)end)
one(function(r)r.server.UseItem=function()return'foreign'end;assert(not r.api.Install()and r.server.UseItem()=='foreign')end)
one(function(r)r.listenHook=function()r.api.Close()end;assert(not r.api.Install()and r.active()==0 and r.api.Progress().complete)end)
one(function(r)r.scheduleHook=function()return false end;assert(not r.api.Install()and r.active()==0)end)
one(function(r)assert(r.api.Install());r.server.UseItem=function()return'foreign'end;r.api.Close();assert(r.server.UseItem()=='foreign')end)
one(function(r)assert(r.api.Install());r.refuseRemove=true;assert(not r.api.Close()and r.api.Progress().listeners==5);r.refuseRemove=false;assert(r.api.Close()and r.api.Progress().complete)end)
one(function(r)assert(r.api.Install());r.setupHook=function(_,isCurrent)r.fire('QBCore:Server:OnPlayerUnload',2);assert(not isCurrent())end
    r.runTimers();for _,e in ipairs(r.trace)do assert(e.kind~='item','stale ticket must not hydrate money')end end)
one(function(r)r.listenHook=function()error('uncertain113')end;assert(not r.api.Install()and r.api.Progress().uncertainRegistrations==1 and not r.api.Progress().complete)
    for _,e in ipairs(r.events)do e.removed=true end end)
assert(count==8)
print('PASS lot113 eight lifecycle/ticket cases:closed owner,foreign method,stop in registration,schedule refusal,foreign replacement,removal retry,stale setup ticket,uncertain token diagnosis')
