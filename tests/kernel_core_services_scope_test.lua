local T=dofile('tests/kernel_core_services_harness.lua');local count=0
local function case(fn)local r=T.new();fn(r);r.close();count=count+1 end
case(function(r)r.allocate();assert(not r.api.Prepare())end)
case(function(r)r.ports.rpc.Side='client';assert(not pcall(r.allocate))end)
case(function(r)r.open();assert(not pcall(r.allocate))end)
case(function(r)r.wire.open();r.external.ox_inventory.SetItemDefinition=nil;r.allocate();assert(not r.api.Prepare()and r.api.Progress().complete)end)
case(function(r)r.wire.open();r.allocate();assert(r.api.Prepare());r.state['Renewed-Banking']='stopped';assert(not r.api.Open()and r.api.Progress().complete)end)
case(function(r)r.wire.open();r.allocate();assert(r.api.Prepare());r.state.pr_carkeys='starting';assert(r.api.Open())end)
case(function(r)r.open();local held=r.api.Public.banking.GetJobAccountBalance;r.current=false;assert(not pcall(held,'society123'))end)
case(function(r)r.wire.open();r.allocate();r.loadHook=function(path)if path:find('forge_society',1,true)then r.api.Close()end end;assert(not r.api.Prepare()and r.api.Progress().complete)end)
assert(count==8);print('PASS lot123 eight missing-RPC/side/ownership/custom-contract/open/stale/reentry cases;borrowed RPC retained and provider legacy states preserved')
