local T=dofile('tests/kernel_late_binding_harness.lua');local count=0
local function one(fn)local r=T.new();fn(r);r.finish();count=count+1 end
one(function(r)r.ready=false;assert(not r.late.Attach()and r.constructed==0 and r.late.Progress().complete)end)
one(function(r)r.metadata.forge_compat_protocol='wrong';assert(not r.late.Attach()and r.ox.active()==0 and r.late.Progress().complete)end)
one(function(r)r.ox.listenHook=function()r.late.Close()end;assert(not r.late.Attach()and r.ox.active()==0 and r.late.Progress().complete)end)
one(function(r)r.ox.scheduleHook=function()return false end;assert(not r.late.Attach()and r.ox.active()==0 and r.late.Progress().complete)end)
one(function(r)assert(r.late.Attach());r.ox.refuseRemove=true;assert(not r.late.Close()and not r.late.Progress().complete)
    r.ox.refuseRemove=false;assert(r.late.Close()and r.late.Progress().complete)end)
one(function(r)assert(r.late.Attach());r.ox.server.setPlayerData=function()return'foreign'end
    assert(not pcall(r.late.Inventory.setPlayerData,r.ox.player.PlayerData));r.late.Close();assert(r.ox.server.setPlayerData()=='foreign')end)
one(function(r)r.ox.ports.Inventory.GetAccountItemCounts=function()coroutine.yield('account114');return nil end
    assert(r.late.Attach());local co=coroutine.create(function()r.late.Inventory.syncInventory({id=2,items={}})end);assert(coroutine.resume(co))
    assert(not r.late.Close()and r.late.Progress().pending>0);assert(coroutine.resume(co));assert(r.late.Close()and r.late.Progress().complete)end)
one(function(r)r.latePorts.inventoryServer=nil;r.late=r.lateFactory(r.latePorts)
    assert(next(r.late.Inventory)==nil and r.late.Attach()and r.ox.active()==0 and r.late.Framework.GetIdentifier(2)=='LATE114');assert(r.late.Close())end)
assert(count==8)
print('PASS lot114 eight late-commit cases:unready/identity,Close during registration,schedule refusal,removal retry,foreign target,in-flight work/drain,framework-only consumer;no eager waits or core close')
