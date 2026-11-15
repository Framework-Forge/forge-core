local T=dofile('tests/kernel_qbx_relay_harness.lua');local H=T.H;local count=0
local function check(fn)local r=T.new('server');fn(r);r.finish();count=count+1 end
check(function(r)r.invoker='foreign';assert(not pcall(r.gateway.Describe));assert(not pcall(r.gateway.Call,'core103-A','GetJobs','forged'));r.invoker='qbx_core'end)
check(function(r)assert(r.installRelay());assert(not pcall(r.gateway.Call,'old-epoch','GetJobs','consumer103'))end)
check(function(r)r.gatewayReady=false;assert(not pcall(r.relay.Prepare));assert(next(r.published)==nil)end)
check(function(r)r.resource='other';assert(not pcall(r.relayFactory,'server',r.relayPorts))end)
check(function(r)assert(r.installRelay());r.caller=nil;assert(not pcall(r.published.GetJobs));r.caller='qbx_core';assert(not pcall(r.published.GetJobs))end)
check(function(r)r.foreign.GetJobs=true;assert(r.relay.Prepare());assert(not r.relay.Install());assert(next(r.published)==nil)end)
check(function(r)local seen=false;r.publishHook=function(_,fn)seen=true;assert(not pcall(fn));end;assert(r.installRelay());assert(seen)end)
check(function(r)local n=0;r.publishHook=function()n=n+1;if n==3 then error('publish103')end end
    assert(r.relay.Prepare());assert(not r.relay.Install());for _,fn in pairs(r.published)do assert(not pcall(fn))end;assert(r.api.IsCurrent())
end)
check(function(r)r.describeHook=function()coroutine.yield()end
    local co=coroutine.create(function()assert(not r.relay.Prepare())end);assert(coroutine.resume(co));assert(not r.relay.Close())
    assert(coroutine.resume(co));assert(r.relay.Progress().complete and next(r.published)==nil)
end)
check(function(r)assert(r.installRelay());r.callHook=function()coroutine.yield()end
    local co=coroutine.create(function()r.published.GetJobs()end);assert(coroutine.resume(co));assert(not r.relay.Close())
    r.callHook=nil;assert(coroutine.resume(co));assert(r.relay.Progress().complete and r.api.IsCurrent())
end)
check(function(r)assert(r.installRelay());r.gateway.Close();assert(not pcall(r.published.GetJobs));assert(r.api.IsCurrent())end)
check(function(r)assert(r.installRelay());r.graph.PlayerCore.State.Players={};assert(not pcall(r.published.GetPlayer,2))end)
check(function(r)assert(r.installRelay());local ok=pcall(r.published.GetPlayerByCitizenId,{});assert(not ok or r.relay.Progress().pending==0)
    assert(r.gateway.Progress().pending==0 and r.origin.Progress().pending==0)
end)
check(function(r)r.dataHook=function(data)data.side='client'end;assert(not pcall(r.relay.Prepare));assert(next(r.published)==nil)end)
assert(count==14);print('PASS lot103 scope:14 cases;authenticated local transport,epoch/side/identity/readiness,namespace/precommit/partial failure,Close during handshake/call,stale graph/provider/error drain;virtual only')
