local N=dofile('tests/kernel_native_foundation_harness.lua');local H=N.H;local req=N.loader()
local createTasks=H.load('../pr_bridge/bridge/runtime/owned_tasks.lua',H.environment())
for _,mode in ipairs({'ready','refused','limit'})do
 local state='installed';local calls=0;local queued={};local current=true
 local candidate={Progress=function()return{phase=state,complete=state=='closed'}end,
 Stop=function()state='closed';return true end,Poll=function()return state=='closed'end,
 Coordinator={Progress=function()return{closing=false}end}}
 candidate.Activate=function()calls=calls+1;if mode=='refused'then candidate.Coordinator=nil;return false,'denied'end
 if mode=='ready'and calls==2 then state='running';return true end;return false,{'banking'}end
 local driver=req('kernel.entry.activation_driver')({candidate=candidate,isCurrent=function()return current end,
 maxAttempts=3,interval=5,running=coroutine.running,createTasks=createTasks,
 scheduler={CreateThread=function(fn)queued[#queued+1]=coroutine.create(fn)end,Wait=function()coroutine.yield()end}})
 assert(not driver.Poll());assert(driver.Run()and not driver.Run())
 for i=1,5 do for _,t in ipairs(queued)do if coroutine.status(t)~='dead'then assert(coroutine.resume(t))end end end
 if mode=='ready'then assert(calls==2 and driver.Progress().phase=='committed')else
 assert(driver.Progress().lastError~=nil and calls==(mode=='limit'and 3 or 1))end
 assert(driver.Stop()or driver.Poll());assert(driver.Poll()and driver.Progress().complete)
end
print('PASS266 bounded owned retry commits without duplicate worker;terminal refusal/limit stops;Poll passive and cleanup complete')
