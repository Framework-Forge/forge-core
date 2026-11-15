local T=dofile('tests/kernel_qbx_qb_extension_harness.lua');local count=0
local function check(fn)local r=T.new();fn(r);r.finish();count=count+1 end
check(function(r)r.invoker='foreign';assert(not pcall(r.qbGateway.Describe));assert(not pcall(r.qbGateway.Call,'core106','SetField','forge-core','x',true));r.invoker='qbx_core'end)
check(function(r)r.extensionReady=false;assert(not pcall(r.extraRelay.Prepare));assert(r.published.SetField==nil)end)
check(function(r)assert(r.extraStart());assert(not pcall(r.qbGateway.Call,'old106','SetField','consumer','x',true));assert(r.graph.PlayerCore.State.x==nil)end)
check(function(r)r.published.SetField=function()return'foreign106'end;assert(r.extraRelay.Prepare());assert(not r.extraRelay.Install());assert(r.published.SetField()=='foreign106')end)
check(function(r)r.extraPublishHook=function(_,fn)assert(not pcall(fn));r.extraRelay.Close()end
    assert(r.extraRelay.Prepare());assert(not r.extraRelay.Install());assert(not pcall(r.published.SetField))
end)
check(function(r)assert(r.extraStart());r.qbBinding.Close();assert(not pcall(r.published.SetField,'after106',true));assert(r.api.IsCurrent())end)
check(function(r)assert(r.extraStart());r.qb.ResourceExports.SetField=function()error('replaced')end;assert(not pcall(r.published.SetField,'replaced106',true))end)
assert(count==7);print('PASS lot106 scope:7 cases;transport/readiness/epoch,foreign export,precommit Close,closed QB95/replaced handler;same Forge authority,all native/SQL boundaries virtual')
