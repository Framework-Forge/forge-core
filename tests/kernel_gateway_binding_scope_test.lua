local T=dofile('tests/kernel_gateway_binding_harness.lua');local count=0
local function one(fn)local r=T.new('server');fn(r);r.finish();count=count+1 end
one(function(r)r.bindingReady=false;assert(not r.binding.Install());assert(r.surface.exports.ForgeQbxCompatCall==nil)end)
one(function(r)r.surface.exports.ForgeQbxCompatQBCall=function()return'foreign'end
    assert(not r.binding.Install());assert(r.surface.exports.ForgeQbxCompatQBCall()=='foreign'and r.surface.exports.ForgeQbxCompatDescribe==nil)end)
one(function(r)r.surface.failAt=(r.surface.published or 0)+2;assert(not r.binding.Install())
    assert(r.surface.exports.ForgeQbxCompatDescribe()==nil and r.binding.Progress().complete)end)
one(function(r)r.surface.onPublish=function()r.binding.Close()end;assert(not r.binding.Install());assert(r.binding.Progress().complete)end)
one(function(r)assert(r.binding.Install());r.invoker='foreign';assert(not pcall(r.surface.exports.ForgeQbxCompatDescribe));r.invoker='qbx_core'end)
one(function(r)assert(r.binding.Install());local d=r.surface.exports.ForgeQbxCompatDescribe()
    assert(not pcall(r.surface.exports.ForgeQbxCompatCall,d.generation..'old','GetQBPlayers','consumer108'))end)
one(function(r)assert(r.binding.Install());r.loadPhysical();r.bindingReady=false;assert(not pcall(r.published.SetField,'bad108',true))
    assert(r.graph.PlayerCore.State.bad108==nil)end)
one(function(r)assert(r.binding.Install());local prior=r.gateway.Call;r.gateway.Call=function()error('foreign')end
    assert(r.surface.exports.ForgeQbxCompatDescribe()==nil);r.gateway.Call=prior end)
one(function(r)assert(r.binding.Install());r.loadPhysical();r.caller='qbx_core';assert(not pcall(r.published.SetField,'loop108',true))
    assert(r.graph.PlayerCore.State.loop108==nil)end)
one(function(r)assert(r.binding.Install());local prior=r.gateway.Describe
    -- Replace before allocating a second independent binding to test an accepted/yielding endpoint.
    r.binding.Close();r.gateway.Describe=function()coroutine.yield('entered108');return'nil-tail',nil,9 end
    r.binding=r.bindingFactory(r.gateway,r.qbGateway,{side='server',public={available=function()return true end,
        publishExport=function(name,fn)r.held=r.held or{};r.held[name]=fn end,prCommand=function()end,oxCommand=function()end,nativeCommand=function()end},
        isCurrent=function()return r.api.IsCurrent()end,isReady=function()return true end})
    assert(r.binding.Install());local task=coroutine.create(function()local values=table.pack(r.held.ForgeQbxCompatDescribe());assert(values.n==3 and values[1]=='nil-tail'and values[2]==nil and values[3]==9)end)
    assert(coroutine.resume(task));assert(not r.binding.Close()and r.binding.Progress().pending==1)
    assert(coroutine.resume(task));assert(r.binding.Progress().complete);r.gateway.Describe=prior end)
assert(count==10)
print('PASS lot108 ten scope cases:readiness,collision,partial publication,Close during publication,transport,epoch,late readiness,replacement,self-loop,in-flight nil tuple/pending')
