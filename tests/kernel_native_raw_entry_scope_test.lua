local T=dofile('tests/kernel_native_raw_entry_harness.lua');local C=dofile('tests/kernel_central_pr_entry_harness.lua');local count=0
local function case(fn)local r=T.raw('server');fn(r);r.finish();count=count+1 end
case(function(r)r.options.namespaceAvailable=nil;assert(not pcall(r.enter)and r.wire.server.active()==0)end)
case(function(r)r.enter();assert(not pcall(r.enter));assert(r.wire.server.active()==0)end)
case(function(r)r.enter();r.current=false;assert(not r.entry.Prepare());r.current=true end)
case(function(r)r.external.ox_inventory.SetItemDefinition=nil;r.enter();assert(not r.entry.Prepare()and r.entry.Progress().complete and r.wire.server.active()==0)end)
case(function(r)r.enter();assert(r.entry.Prepare());r.allowClose=false;assert(not r.entry.Close()and r.wire.server.active()>0);r.allowClose=true;assert(r.entry.Close())end)
case(function(r)r.enter();assert(r.entry.Prepare());r.options.beforeClose=function()error('cleanup125')end;assert(not r.entry.Close());r.options.beforeClose=nil;assert(r.entry.Close())end)
do local r=C.new();r.servicesFixture.api.Close();r.allocateBootstrap();assert(r.api.Prepare('en'));r.surface.Open();assert(not r.api.Install());r.api.Stop();r.servicesFixture.close();count=count+1 end
do local r=C.new();r.servicesFixture.api.Open();r.allocateBootstrap();assert(r.api.Prepare('en'));r.installNewPR();assert(r.fixture.base.ServerInventoryContext.Inventory==r.adopted.Inventory)
    r.api.Stop();r.clock.advance(1200000);r.api.Poll();r.servicesFixture.close();count=count+1 end
assert(count==8);print('PASS lot125 eight native options/ownership/stale/partial/cleanup/provider-closed/already-open cases;providers adopted once,core drain precedes raw teardown')
