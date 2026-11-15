local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local H=N.H
local T=dofile('tests/kernel_activation_barrier_harness.lua');local r=T.new();r.nativeAPI.Close();r.bindings.Close()
local phase='prepared';local compat={Graph=r.graph,Origin=r.origin,GetCoreObject=r.boundAPI.getCoreObject,
 IsCurrent=function()return phase~='closed'and r.api.IsCurrent()end,IsReady=function()return phase=='installed'end,
 Install=function()phase='installed';return true end,Close=function()phase='closed';return true end,
 Progress=function()return{phase=phase,complete=phase=='closed'}end}
local control=H.load('../pr_bridge/bridge/frameworks/forge/activation_consumer_control.lua',H.environment())({
 native=r.bindingPorts.native,generation='barrier119',instance='consumer237',isCurrent=r.api.IsCurrent,
 createProxy=r.makeProxy,createBindings=function(api)r.bindingPorts.api=api;return r.makeBindings()end,
 claim=function(...)return assert(r.surface.exports.ForgePrConsumerState)(...)end})
local group=req('kernel.entry.activation_consumers')({side='server',generation='barrier119',barrier=r.policy,
 isCurrent=r.api.IsCurrent,consumers={{name=r.boundResource,control=control}}})
local pub=req('kernel.entry.activation_publication')({side='server',generation='barrier119',barrier=r.policy,
 consumers={r.boundResource},getInvokingResource=function()return r.nativeCaller end,
 loadPR=function(path)return H.load('../pr_bridge/'..path,H.environment())end,createCompatibility=function()return compat end,
 describeConsumer=group.Describe})
assert(pub.Prepare({GetPreparedBarrier=function()return r.policy end,
 GetPreparedEntry=function()return{IsCurrent=r.api.IsCurrent,Bootstrap={Graph=r.graph,Transport=r.api.Transport}}end}))
assert(group.Prepare()and group.IsPrepared());assert(pub.ObservePrepared())
r.nativeAPI={Progress=function()return{phase=pub.IsInstalled()and'installed'or'allocated'}end,Close=function()return true end}
for i=1,3 do assert(r.policy.Advance(i))end
assert(pub.Install()and r.policy.Advance(4));assert(group.Attach()and group.IsAttached());assert(r.policy.Advance(5))
assert(r.proxy.API.framework.GetPlayer(2)==r.graph.PlayerCore.State.Players[2])
assert(r.pr.forgeNormalizedFacade.GetIdentifier(2)=='LATE114')
local describe=control.Describe
control.Describe=function()local d=describe();d.instance='replaced';return d end
assert(not group.IsAttached());control.Describe=describe;assert(group.IsAttached())
--A held native method is routed through the actual proxy installed at construction.
assert(pub.Close());assert(r.pr.forgeNormalizedFacade.GetIdentifier(2)==nil)
assert(group.Close()and group.Progress().complete);assert(not group.IsAttached())
r.finish()
print('PASS237 actual resource-local proxy117/bindings118/admission124; committed verified by group; revocation reaches facade')
