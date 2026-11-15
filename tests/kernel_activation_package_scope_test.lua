local T=dofile('tests/kernel_activation_package_harness.lua');local count=0
local function case(fn)local r=T.new('server');fn(r);r.finish();count=count+1 end
case(function(r)assert(not pcall(r.entryFactory,r.pr,r.public,{},nil));assert(r.pr.forgeConsumerEntry==nil)end)
case(function(r)r.boundResource='forge-core';assert(not pcall(r.enter))end)
case(function(r)local foreign={};r.pr.forgeConsumerEntry=foreign;assert(not pcall(r.enter)and r.pr.forgeConsumerEntry==foreign)end)
case(function(r)r.enter();r.boundReady=false;assert(r.nativeAPI.Install());assert(not r.entry.Attach()and r.entry.Progress().complete)end)
case(function(r)r.enter();assert(r.nativeAPI.Install());r.handshakeHook=function()r.entry.Close()end;assert(not r.entry.Attach()and r.entry.Progress().complete)end)
case(function(r)r.enter();r.refuseRemove=true;assert(not r.entry.Close()and r.pr.forgeConsumerEntry==r.entry);r.refuseRemove=false;assert(r.entry.Close()and r.entry.Progress().complete)end)
case(function(r)r.listenHook=function()r.pr.forgeConsumerEntry.Close()end;assert(not pcall(r.enter));assert(r.pr.forgeConsumerEntry==nil)end)
assert(count==7)
print('PASS lot120 seven physical entry scope cases;missing ports,internal core/foreign owner,unready,Close handshake/listen and native cleanup retry')
