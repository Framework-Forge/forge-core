local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local H=N.H
local calls=0
for _,side in ipairs({'client','server'})do
 local p={side=side,inspectFunction=function(fn)return debug.getinfo(fn,'S')end,providers={startApproved=true},
  createRaw=function()calls=calls+1;error('must not construct')end}
 local a=req('kernel.entry.coordinated_boot_preparation')(p)
 assert(not a.Start()and not a.Activate()and not a.Prepare()and calls==0)
 assert(a.Stop()and a.GetPreparedEntry()==nil)
end
for _,server in ipairs({true,false})do
 local core={};local env=H.environment({GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return server end,
 PRCore=core,debug=debug,load=load,print=function()end})
 env.LoadResourceFile=function(resource,path)assert(resource=='forge-core');local f=assert(io.open(path,'rb'));local t=f:read('*a');f:close();return t end
 core.load=function()calls=calls+1;error('missing physical controls')end
 H.load('../../../../.planning/migration/staging/229/forge-core/kernel/entry/boot_candidate_entry.lua',env)
 assert(core.forgeBootCandidate and not core.forgeBootCandidate.Inspect().accepted and not core.forgeBootCandidate.Start()and calls==0)
end
print('PASS229 coordinated physical entry both sides;Start cannot bypass118;missing/unapproved inputs produce no raw/seed effects')
