local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local contract=req('kernel.entry.server_boot_input_contract');local fn=function()return true end
local n,env,loadPR={},{},fn;local reg={available=fn};local options={prCore={},isCurrent=fn,
 foundation={side='server',native=n,environment=env,registration=reg,compile=fn,json={},public={},loadPR=loadPR,pullLocale=fn,inventoryBridgeProbe=fn,adjuncts={},running=fn},
 support={native=n,environment=env,external={},loadPR=loadPR,running=fn,onError=fn},
 providers={native=n,environment=env,external={},loadPR=loadPR,running=fn,onError=fn,isCurrent=fn,isReady=fn},
 profile={environment=env,external={},loadPR=loadPR,barrier={WrapIngress=fn,IsIngressOpen=fn},nativeAdjuncts={},running=fn,onError=fn},
 bootstrap={registration={available=fn}}}
local nativeInfo=function()return{source='@native/virtual-options.lua'}end
assert(contract.Inspect(options,'server',nativeInfo).accepted)
assert(not contract.Inspect(options,'server',function(f)return debug.getinfo(f,'S')end).accepted)
options.base={};assert(not contract.Inspect(options,'server',nativeInfo).accepted);options.base=nil
options.bootstrap.registration.available=function()end;assert(not contract.Inspect(options,'server',nativeInfo).accepted);options.bootstrap.registration.available=fn
local calls=0;local candidate=req('kernel.entry.server_boot_preparation')({side='server',inspectFunction=nativeInfo,providers={buildInput=function()return options end},
 createRaw=function()calls=calls+1;error('no construction approved')end})
assert(candidate.Inspect().accepted and not candidate.Prepare()and calls==0)
local blocked=req('kernel.entry.server_boot_preparation')({side='server',inspectFunction=function(f)return debug.getinfo(f,'S')end,
 providers={buildInput=function()error('test builder must not run')end},createRaw=function()calls=calls+1 end})
assert(not blocked.Inspect().accepted and not blocked.Prepare()and calls==0)
for _,server in ipairs({true,false})do
 local core={};local rawCalls=0
 local env=N.H.environment({GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return server end,
  PRCore=core,debug=debug,load=load,print=function()end})
 env.LoadResourceFile=function(resource,path)assert(resource=='forge-core');local file=assert(io.open(path,'rb'));local text=file:read('*a');file:close();return text end
 core.load=function()rawCalls=rawCalls+1;error('missing providers must not construct')end
 N.H.load('../../../../.planning/migration/staging/209/forge-core/kernel/entry/boot_candidate_entry.lua',env)
 assert(core.forgeBootCandidate and not core.forgeBootCandidate.Inspect().accepted and rawCalls==0)
end
print('PASS209 server contract over unchanged169;virtual provenance positive,actual fixture origin/legacy base/mismatched namespace refused;unapproved construction has no raw/seed')
