local T=dofile('tests/kernel_native_foundation_harness.lua');local req,env=T.loader();local f=req('kernel.entry.native_context_factories')
local W=dofile('tests/kernel_worker_harness.lua')
for _,side in ipairs({'server','client'})do
 local current=true;local loads={}
 local a=f({side=side,isCurrent=function()return current end,environment=env,loadPR=function(path,target)
  loads[#loads+1]=path;return T.H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target)
 end})
 assert(#loads==0)
 for _,item in ipairs(a.Describe())do local x=a.Get(item.name);assert(type(x)=='function'and x==a.Get(item.name))end
 assert(#loads==#a.Describe());assert(not pcall(a.Get,'framework'))
 local clock=W.clock();local tasks=a.Get('tasks')({isCurrent=function()return true end,running=coroutine.running,onError=error})
 local native=tasks.WrapNative(clock.native);assert(tasks.Open());local executed=0
 native.SetTimeout(30,function()executed=executed+1 end);clock.advance(10);assert(executed==0)
 a.Close();clock.advance(30);assert(executed==0 and tasks.Snapshot().quiescent)
 assert(not pcall(a.Get,'tasks'));assert(not pcall(a.Get,'media'));tasks.Close()
end
local a=f({side='client',isCurrent=function()return true end,loadPR=function()return nil end})
assert(not pcall(a.Get,'tasks'))
print('PASS178 installed PR context factory resolution on both sides;no eager load or framework;real owned_tasks cancellation and missing factory refusal')
