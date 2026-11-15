local H=dofile('tests/kernel_native_foundation_harness.lua').H
local reads,raw=0,0
for _,side in ipairs({'server','client'})do
 local core={}
 local env=H.environment({GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return side=='server'end,
 GetInvokingResource=function()return nil end,PRCore=core,coroutine=coroutine,debug=debug,load=load,print=function()end})
 env.LoadResourceFile=function(resource,path)
  assert(resource=='forge-core');reads=reads+1;local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s
 end
 core.load=function()raw=raw+1;error('unexpected raw/consumer construction')end
 H.load('../../../../.planning/migration/staging/269/forge-core/kernel/entry/boot_candidate_entry.lua',env)
 local c=core.forgeBootCandidate;assert(c and not c.Inspect().accepted and not c.Poll()and not c.StartPreparedCore())
 assert(c.Stop()and c.Poll()and c.Progress().complete)
end
assert(reads>0 and raw==0)
local read=assert(io.open('../../../../.planning/migration/staging/269/forge-core/kernel/entry/boot_candidate_entry.lua','rb'))
local text=read:read('*a');read:close()
assert(text:find('compatibility_physical_ports_v5.lua',1,true)and text:find('coordinated_boot_preparation_v8.lua',1,true))
print('PASS269 review entry selects corrected library/server/client chain;both sides refuse missing physical config with no raw effects')

local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local state='allocated';local queued={};local calls=0
local c={Progress=function()return{phase=state,complete=state=='closed'}end,Stop=function()state='closed';return true end,Poll=function()return state=='closed'end}
c.Activate=function()calls=calls+1;c.Coordinator={Progress=function()return{closing=false}end};return false,'pending'end
local driver=req('kernel.entry.activation_driver_binding')(c,{isCurrent=function()return true end,maxAttempts=3,interval=1,running=coroutine.running,
 createTasks=H.load('../pr_bridge/bridge/runtime/owned_tasks.lua',H.environment()),scheduler={CreateThread=function(fn)queued[1]=coroutine.create(fn)end,Wait=function()coroutine.yield()end}})
assert(driver.Run()and coroutine.resume(queued[1]));assert(calls==1 and not c.Progress().complete)
assert(not c.Stop());assert(coroutine.resume(queued[1]));assert(c.Poll()and c.Progress().complete)
assert(calls==1 and driver.Progress().complete)
print('PASS269 binding public Stop/Poll drains worker before complete;no retry after close')
