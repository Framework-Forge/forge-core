local H=dofile('tests/kernel_native_foundation_harness.lua').H
local create=H.load('../pr_bridge/bridge/frameworks/forge/activation_control_publication.lua',H.environment())
local invoker='forge-core';local fn;local pending=0;local closed=false;local phase='allocated';local hold=true
local control={Prepare=function()phase='prepared';return true end,Attach=function()
 pending=pending+1;coroutine.yield('attach-pending');pending=pending-1;return not closed end,
 Describe=function()return{phase=phase}end,Close=function()closed=true;if hold then return false end;return pending==0 end,
 Progress=function()return{phase=phase,pending=pending,complete=closed and not hold and pending==0}end}
local a=create{control=control,generation='246',instance='consumer',getInvokingResource=function()return invoker end,
 available=function()return true end,publishExport=function(name,handler)assert(name=='ForgePrActivationControl');fn=handler end}
assert(a.Install());assert(fn('Prepare','246','consumer'));invoker='intruder';assert(fn('Describe','246','consumer')==nil)
invoker='forge-core';assert(fn('Prepare','old','consumer')==nil)
local thread=coroutine.create(function()return fn('Attach','246','consumer')end);assert(coroutine.resume(thread))
assert(not fn('Close','246','consumer'));assert(fn('Describe','246','consumer')==nil)
assert(fn('Progress','246','consumer').complete==false)
hold=false;assert(not fn('Poll','246','consumer'))
local ok,result=coroutine.resume(thread);assert(ok and result==false)
assert(fn('Poll','246','consumer')and fn('Progress','246','consumer').complete)
assert(fn('Prepare','246','consumer')==nil)
local b;local published=0
b=create{control=control,generation='reentry',instance='consumer',getInvokingResource=function()return invoker end,
 available=function()assert(b.Close());return true end,publishExport=function()published=published+1 end}
assert(not b.Install()and published==0 and b.Progress().complete)
local c=create{control=control,generation='refusal',instance='consumer',getInvokingResource=function()return invoker end,
 available=function()return true end,publishExport=function()return false end}
assert(not c.Install()and c.Progress().complete)
print('PASS246 consumer-local control export;Forge/generation/instance required;pending Close observable and retryable after ingress revocation')
