local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local H=N.H
local reads,raw=0,0
local path='../../../../.planning/migration/staging/239/forge-core/kernel/entry/boot_candidate_entry.lua'
local function env(server,providers)
 local core={forgeBootProviders=providers}
 core.load=function()raw=raw+1;error('no raw or PR constructor permitted for missing inputs')end
 local e=H.environment({GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return server end,
  GetInvokingResource=function()return nil end,PRCore=core,debug=debug,load=load,print=function()end})
 e.LoadResourceFile=function(resource,file)
  assert(resource=='forge-core');reads=reads+1;local f=assert(io.open(file,'rb'));local s=f:read('*a');f:close();return s
 end
 return core,e
end
for _,server in ipairs({true,false})do
 local core,e=env(server)
 H.load(path,e);assert(core.forgeBootCandidate)
 assert(not core.forgeBootCandidate.Inspect().accepted)
 assert(not core.forgeBootCandidate.Start());assert(not core.forgeBootCandidate.Poll())
 assert(core.forgeBootCandidate.Stop()and core.forgeBootCandidate.Poll())
 local c,x=env(server,{activationAssembly={},physicalOptions={}})
 assert(not pcall(H.load,path,x)and c.forgeBootCandidate==nil)
 local d,y=env(server,{activationAssembly={},activation={},physicalOptions={}})
 assert(not pcall(H.load,path,y)and d.forgeBootCandidate==nil)
end
assert(reads>0 and raw==0)
print('PASS239 installed-source entry both sides;corrected coordinator;missing/ambiguous assembly denied without raw/PR construction')
