local T=dofile('tests/kernel_consumer_ports_harness.lua');local count=0
local function one(fn)local r=T.new('client');local c=r.consumerPorts();fn(r,c);r.finish();count=count+1 end
one(function(r,c)c.target.ForgeQbxConsumerPorts={foreign=true};assert(not pcall(c.provider.Install));assert(c.target.ForgeQbxConsumerPorts.foreign);c.target.ForgeQbxConsumerPorts=nil end)
one(function(r,c)c.providerReady=false;assert(not c.provider.Install()and rawget(c.target,'ForgeQbxConsumerPorts')==nil)end)
one(function(r,c)c.providerReadyHook=function()c.provider.Close()end;assert(not c.provider.Install()and c.provider.Progress().complete)end)
one(function(r,c)c.providerPorts.resource='forge-core';assert(not pcall(r.portsFactory,c.providerPorts))end)
one(function(r,c)c.providerPorts.audio={};assert(not pcall(r.portsFactory,c.providerPorts))end)
one(function(r,c)c.providerPorts.inventory={};assert(not pcall(r.portsFactory,c.providerPorts))end)
one(function(r,c)assert(c.provider.Install());local settings=c.target.ForgeQbxConsumerPorts;c.target.ForgeQbxConsumerPorts={foreign=true}
    assert(not pcall(settings.consumer.getPlayerData));assert(c.provider.Close()and c.target.ForgeQbxConsumerPorts.foreign)end)
one(function(r,c)assert(c.provider.Install());local p=c.target.package;c.target.package={}
    assert(not pcall(c.loadEntry,'modules/lib.lua'));c.target.package=p end)
one(function(r,c)assert(c.provider.Install());c.providerCurrent=false;assert(not pcall(c.loadEntry,'modules/lib.lua')and rawget(c.target,'__forge_qbx_consumer_delivery107')==nil)end)
one(function(r,c)c.providerPorts.inventory.Search=function()coroutine.yield('Search109');return true,nil,'tail'end
    c.provider=r.portsFactory(c.providerPorts);r.providers[#r.providers+1]=c.provider;assert(c.provider.Install())
    local search=c.target.ForgeQbxConsumerPorts.consumer.utils.searchInventory
    local task=coroutine.create(function()local result=table.pack(search('hamburger'));assert(result.n==3 and result[1]==true and result[3]=='tail')end)
    assert(coroutine.resume(task));assert(not c.provider.Close()and c.provider.Progress().pending==1)
    assert(coroutine.resume(task));assert(c.provider.Progress().complete and not pcall(search,'again'))end)
assert(count==10)
print('PASS lot109 ten scope cases:foreign settings,readiness,Close during readiness,internal loop identity,missing PR audio/Search,foreign replacement,package/current drift,in-flight tuple/pending')
