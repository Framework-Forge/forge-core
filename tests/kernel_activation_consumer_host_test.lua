local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local H=N.H
local T=dofile('tests/kernel_activation_barrier_harness.lua');local r=T.new();r.nativeAPI.Close();r.bindings.Close()
local phase='prepared';local compat={Graph=r.graph,Origin=r.origin,GetCoreObject=r.boundAPI.getCoreObject,
 IsCurrent=function()return phase~='closed'and r.api.IsCurrent()end,IsReady=function()return phase=='installed'end,
 Install=function()phase='installed';return true end,Close=function()phase='closed';return true end,
 Progress=function()return{phase=phase,complete=phase=='closed'}end}
local exported
r.bindingPorts.native.GetInvokingResource=function()return'forge-core'end
local bindingPorts={};for k,v in pairs(r.bindingPorts)do bindingPorts[k]=v end;bindingPorts.api=nil
r.nativeProxy.ForgePrConsumerState=function(_,...)return assert(r.surface.exports.ForgePrConsumerState)(...)end
local publication=H.load('../pr_bridge/bridge/frameworks/forge/activation_consumer_host.lua',H.environment())({
 native=r.bindingPorts.native,prCore=r.pr,generation='barrier119',instance='consumer237',isCurrent=r.api.IsCurrent,
 external={['forge-core']=r.nativeProxy},expected=r.expected,bindingPorts=bindingPorts,
 load=function(path)
  local create=H.load('../pr_bridge/'..path..'.lua',H.environment())
  if path=='bridge/frameworks/forge/native_bindings_factory'then return function(p)r.bindings=create(p);return r.bindings end end
  return create
 end,
 available=function()return true end,publishExport=function(_,fn)exported=fn end})
assert(publication.Install())
local external={[r.boundResource]={ForgePrActivationControl=function(_,...)return exported(...)end}}
local control=H.load('../pr_bridge/bridge/frameworks/forge/activation_remote_control.lua',H.environment())({
 native={GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return true end},
 external=external,resource=r.boundResource,generation='barrier119',instance='consumer237',isCurrent=r.api.IsCurrent})
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
assert(r.pr.forgeNormalizedFacade.GetIdentifier(2)=='LATE114')
assert(r.pr.forgeNormalizedFacade.GetIdentifier(2)=='LATE114')
local describe=control.Describe
control.Describe=function()local d=describe();d.instance='replaced';return d end
assert(not group.IsAttached());control.Describe=describe;assert(group.IsAttached())
--A held native method is routed through the actual proxy installed at construction.
assert(pub.Close());assert(r.pr.forgeNormalizedFacade.GetIdentifier(2)==nil)
assert(group.Close()and group.Progress().complete);assert(not group.IsAttached())
r.finish()
assert(publication.Close()and publication.Progress().complete and r.pr.forgeActivationHost==nil)
print('PASS256 actual consumer host/proxy/bindings/admission/export control assembled;one PR owner/Player;cleanup releases host')
