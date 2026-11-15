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
 H.load('../../../../.planning/migration/staging/259/forge-core/kernel/entry/boot_candidate_entry.lua',env)
 local c=core.forgeBootCandidate;assert(c and not c.Inspect().accepted and not c.Poll()and not c.StartPreparedCore())
 assert(c.Stop()and c.Poll()and c.Progress().complete)
end
assert(reads>0 and raw==0)
local read=assert(io.open('../../../../.planning/migration/staging/259/forge-core/kernel/entry/boot_candidate_entry.lua','rb'))
local text=read:read('*a');read:close()
assert(text:find('compatibility_physical_ports_v5.lua',1,true)and text:find('coordinated_boot_preparation_v7.lua',1,true))
print('PASS259 review entry selects corrected library/server/client chain;both sides refuse missing physical config with no raw effects')
