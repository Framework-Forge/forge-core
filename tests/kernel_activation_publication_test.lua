local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local H=N.H
local T=dofile('tests/kernel_activation_barrier_harness.lua');local r=T.new();r.nativeAPI.Close()
local cp='prepared';local compat={Graph=r.graph,Origin=r.origin,GetCoreObject=r.boundAPI.getCoreObject,
 IsCurrent=function()return cp~='closed'and r.api.IsCurrent()end,IsReady=function()return cp=='installed'end,
 Install=function()cp='installed';return true end,Close=function()cp='closed';return true end,
 Progress=function()return{phase=cp,complete=cp=='closed'}end}
local instance='publication235'
local pub=req('kernel.entry.activation_publication')({side='server',generation='barrier119',barrier=r.policy,consumers={r.boundResource},
 getInvokingResource=function()return r.nativeCaller end,
 loadPR=function(path)return H.load('../pr_bridge/'..path,H.environment())end,
 createCompatibility=function(graph)assert(graph==r.graph);return compat end,
 describeConsumer=function(name)return{protocol='forge-pr-consumer/1',resource=name,side='server',instance=instance,
 current=r.api.IsCurrent(),phase=r.bindings.Progress().phase,proxyReady=r.proxy and r.proxy.Progress().phase=='prepared'or false}end})
local candidate={GetPreparedBarrier=function()return r.policy end,GetPreparedEntry=function()return{IsCurrent=r.api.IsCurrent,
 Bootstrap={Graph=r.graph,Transport=r.api.Transport}}end}
assert(pub.Prepare(candidate));assert(r.bindings.Prepare());assert(pub.ObservePrepared())
--Existing harness probes borrow the publication state without starting an extra API.
r.nativeAPI={Progress=function()return{phase=pub.IsInstalled()and'installed'or'allocated'}end,Close=function()return true end}
for i=1,3 do assert(r.policy.Advance(i))end
assert(pub.Install()and pub.CompatibilityReady());assert(r.policy.Advance(4))
r.makeProxy();assert(r.proxy.Prepare())
assert(r.surface.exports.ForgePrConsumerState('barrier119',instance,'attaching'))
r.bindingPorts.api=r.proxy.API;assert(r.bindings.Attach())
assert(r.surface.exports.ForgePrConsumerState('barrier119',instance,'committed'));assert(r.policy.Advance(5))
assert(r.proxy.API.framework.GetPlayer(2)==r.graph.PlayerCore.State.Players[2])
local held=r.surface.exports.ForgePrCall
assert(pub.Close()and pub.Progress().complete)
assert(held('barrier119','framework','GetPlayer',2)==nil);assert(not pub.IsInstalled())
r.finish()
print('PASS235 actual native API/admission/export registration with one real graph; compatibility factory virtual')
