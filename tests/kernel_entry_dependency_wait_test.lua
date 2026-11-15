local H=dofile('tests/kernel_harness.lua')
local profileFactory=H.load('kernel/pr_integration/operational_profile.lua',H.environment())
local runtimeFactory=H.load('kernel/pr_integration/core_activation_runtime.lua',H.environment())
local tasks=H.load('../pr_bridge/bridge/runtime/owned_tasks.lua',H.environment())
for _,side in ipairs({'server','client'})do
 for _,failure in ipairs({'none','dependencies','missing','generation','instance','stale','providers','phase'})do
  local now,activated,stops,describes=0,0,0,{};local threads,logs={},{};local pr={};local generation='entry29'
  local env=H.environment({PRCore=pr,os={time=function()return 1 end},coroutine=coroutine,
   IsDuplicityVersion=function()return side=='server'end,GetCurrentResourceName=function()return'forge-core'end,
   GetConvar=function(key,default)return key=='forge:bootGeneration'and generation or default end,
   SetConvarReplicated=function(_,v)generation=v end,GetGameTimer=function()return now end,
   GetResourceState=function(name)assert(name=='forge-loadscreen');return'stopped'end,
   CreateThread=function(fn)threads[#threads+1]=coroutine.create(fn)end,Wait=function()coroutine.yield()end,
   AddEventHandler=function()return{}end,RemoveEventHandler=function()return true end,print=function(s)logs[#logs+1]=s end})
  pr.load=function(path,target)
   local file=path:sub(1,12)=='@forge-core/'and path:sub(13)or('../pr_bridge/'..path:gsub('^@pr_bridge/',''))
   return H.load(file..'.lua',target or env)
  end
  local profile=profileFactory(env)
  env.exports=setmetatable({},{__index=function(_,resource)
   assert(resource~='forge-loadscreen','inactive optional UI must not be probed')
   return{ForgePrActivationControl=function(_,op,g,instance)
    assert(op=='Describe'and g==profile.Generation and instance==resource..':'..side);describes[resource]=(describes[resource]or 0)+1
    local d={current=true,generation=g,instance=instance,phase='prepared',providersReady=true}
    if resource=='ox_inventory'then
     if failure=='missing'then return nil end
     if failure=='generation'then d.generation='old'end
     if failure=='instance'then d.instance='foreign'end
     if failure=='stale'then d.current=false end
     if failure=='providers'then d.providersReady=false end
     if failure=='phase'then d.phase='allocated'end
    end
    return d
   end}
  end})
  local candidate={Activate=function()activated=activated+1;return true end,GetPreparedEntry=function()end,
   Stop=function()stops=stops+1;return true end,Poll=function()return true end}
  local config={IsCurrent=function()return true end,Ready=function()return failure~='dependencies'end,Close=function()return true end,
   PhysicalOptions={registration={publishExport=function()return true end}}}
  local runtime=runtimeFactory({environment=env,profile=profile,candidate=candidate,configuration=config,timeout=1000,interval=25,createTasks=tasks})
  assert(runtime.Run());assert(coroutine.resume(threads[1]))
  if coroutine.status(threads[1])~='dead'then now=1001;assert(coroutine.resume(threads[1]))end
  local status=runtime.Status()
  if failure=='none'then
   assert(status.phase=='running'and activated==1 and stops==0)
   local count=0;for _ in pairs(describes)do count=count+1 end;assert(count==43,'all mandatory consumers must be checked')
  else
   assert(status.phase=='failed'and activated==0 and stops==1,'mandatory prerequisites must never be bypassed')
   local expected=failure=='dependencies'and'core dependencies'or'consumer ox_inventory'
   assert(status.error:find(expected,1,true)and status.waitingFor:find(expected,1,true)and #logs==1,'timeout must identify the pending prerequisite')
  end
 end
end
print('PASS core declaration runtime with 43 mandatory consumers without loading UI, both sides; missing/mismatched/stale/not-ready consumers and dependencies still stop activation with precise reason')
