local H=dofile('tests/kernel_native_foundation_harness.lua').H
local create=H.load('../pr_bridge/bridge/frameworks/forge/core_activation_runtime.lua',H.environment())
local tasks=H.load('../pr_bridge/bridge/runtime/owned_tasks.lua',H.environment())
local now,prepared,open,stopped=0,false,false,false;local calls=0;local threads={};local alive=true
local config={IsCurrent=function()return alive end,Ready=function()return prepared end,Close=function()alive=false;return true end,
 PhysicalOptions={registration={publishExport=function(name,fn)assert(name=='ForgeRuntimeStatus');return true end}}}
local phase='allocated';local candidate={GetPreparedEntry=function()end,Progress=function()return{phase=phase}end,
 Coordinator={Progress=function()return{closing=false}end},Activation={Barrier={Progress=function()return{stage=open and 6 or 5,ingressOpen=open}end}},
 Stop=function()stopped=true;phase='closed';return true end,Poll=function()return stopped end}
candidate.Activate=function()calls=calls+1;phase='running';if calls==2 then open=true;return true end;return false,{'catalogs'}end
local profile={Generation='g276',Consumers=function()return{{name='consumer',instance='i276'}}end}
local e={IsDuplicityVersion=function()return true end,coroutine=coroutine,GetGameTimer=function()return now end,print=function()end,
 AddEventHandler=function()return 1 end,RemoveEventHandler=function()end,CreateThread=function(fn)threads[#threads+1]=coroutine.create(fn)end,
 Wait=function()coroutine.yield()end,exports={consumer={ForgePrActivationControl=function()return{current=true,generation='g276',instance='i276',providersReady=prepared,phase='prepared'}end}}}
local owner=create({environment=e,candidate=candidate,profile=profile,configuration=config,timeout=1000,interval=1,createTasks=tasks})
assert(owner.Run());assert(coroutine.resume(threads[1]));assert(calls==0)
prepared=true;now=10;assert(coroutine.resume(threads[1]));assert(calls==1)
now=20;assert(coroutine.resume(threads[1]));assert(calls==2 and owner.Status().ingressOpen)
assert(owner.Close()and owner.Progress().complete)
local wait=H.load('../pr_bridge/bridge/frameworks/forge/consumer_boot_wait.lua',H.environment())
local stage=0;local reads=0;local facade={GetResourceName=function()error('unattached identity')end,GetFrameworkJobs=function()reads=reads+1;return{}end}
wait({facade=facade,isCurrent=function()return true end,isAttached=function()return stage>=4 end,generation='g276',clock=function()return now end,
 readStatus=function()return{generation='g276',stage=stage,ingressOpen=false}end,wait=function()now=now+1;stage=4 end,timeout=1000})
assert(facade.GetResourceName()=='forge-core');assert(type(facade.GetFrameworkJobs())=='table'and reads==1)
print('PASS276 dependencies and real declarations precede A-F;pending activation retries once;owned shutdown;identity/catalog waits do not invent core state')
