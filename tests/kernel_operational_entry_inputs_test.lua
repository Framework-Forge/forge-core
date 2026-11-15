--Real staged entry/definition/options/contract;Cfx functions are virtual and provenance normalized only here.
local H=dofile('tests/kernel_native_foundation_harness.lua').H
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
for _,side in ipairs({'server','client'})do
 local live,now=true,0;local threads={};local public={};local pr={};local cache={}
 local e=setmetatable({},{__index=_G});e._G=e
 for _,path in ipairs({'kernel/entry/physical_boot_capture_v2.lua','kernel/entry/physical_client_capture_v2.lua','kernel/entry/compatibility_physical_ports_v5.lua'})do
  for name in read(path):gmatch("['\"]([A-Z][%w_]*)['\"]")do e[name]=function()error('unexercised Cfx:'..name)end end
 end
 for _,schema in ipairs({'server','client'})do
  local names=assert(load(read('kernel/entry/'..schema..'_engine_schema.lua')))()()
  for _,name in pairs(names)do if name:sub(1,1)~='$'then e[name]=function()error('unexercised Cfx:'..name)end end end
 end
 e.GetCurrentResourceName=function()return'forge-core'end;e.IsDuplicityVersion=function()return side=='server'end
 e.GetResourceState=function()return'started'end;e.GetInvokingResource=function()return nil end
 e.GetConvar=function(key,default)return({['forge:kernel']='true',['forge:bootGeneration']='g279',['qbx:enablebridge']='true'})[key]or default end
 e.GetConvarInt=function(_,d)return d end;e.GetGameTimer=function()return now end
 e.GetResourceMetadata=function(_,key)return key=='forge_kernel_bootstrap'and'owned/1'end;e.GetNumResourceMetadata=function()return 0 end
 e.GetRegisteredCommands=function()return{}end;e.AddEventHandler=function()return 1 end;e.RemoveEventHandler=function()end
 e.CreateThread=function(fn)threads[#threads+1]=coroutine.create(fn)end;e.Wait=function()now=now+25;coroutine.yield()end
 e.vec3=function(x,y,z)return{x=x,y=y,z=z}end;e.vec4=function(x,y,z,w)return{x=x,y=y,z=z,w=w}end;e.joaat=function()return 0 end
 e.LocalPlayer={state={}};e.GlobalState={};e.json={encode=function()return'{}'end,decode=function()return{}end};e.promise={new=function()return{}end};e.Citizen={Await=function()end}
 local info=debug.getinfo
 e.debug={getinfo=function(fn,what)local d=info(fn,what);if d.source:find('tests/',1,true)then d.source='@@cfx/virtual-input' end;return d end,traceback=debug.traceback}
 e.LoadResourceFile=function(resource,path)
  if resource=='forge-core'then
   if path=='kernel/entry/boot_candidate_entry.lua'then return read('../../../../.planning/migration/staging/276/forge-core/'..path)end
   return read(path)
  end
  error('unexpected Cfx resource read:'..resource)
 end
 e.exports=setmetatable({},{__index=function(t,name)local value=setmetatable({},{__index=function()return function()error('consumer not started')end end});rawset(t,name,value);return value end,__call=function(_,name,fn)cache[name]=fn end})
 e.pr_lib=public;e.PRCore=pr;pr.forgeCoreBootstrap={Public=public}
 pr.load=function(path,env)
  local name=path:gsub('^@pr_bridge/','')..'.lua';local source=read('../pr_bridge/'..name)
  return assert(load(source,'@@pr_bridge/'..name,'t',env or e))()
 end
 local boot=read('../../../../.planning/migration/staging/278/forge-core/kernel/entry/boot_runtime_entry.lua')
 assert(load(boot,'@@forge-core/kernel/entry/boot_runtime_entry.lua','t',e))()
 assert(pr.forgeOperationalRuntime and #threads==1 and type(cache.ForgeRuntimeStatus)=='function')
 local candidate=assert(pr.forgeBootCandidate);local report=candidate.Inspect()
 if not report.accepted then for _,issue in ipairs(report.issues)do print(side..':'..issue.path..':'..issue.reason)end end
 if not report.accepted then
  local controls={};for k,v in pairs(pr.forgeBootProviders.physicalOptions)do controls[k]=v end
  controls.environment=e;controls.prCore=pr;controls.originOwner=candidate.OriginOwner;controls.barrier=candidate.Activation.Barrier
  local function mod(name)local target=setmetatable({},{__index=e});target.require=mod;return assert(load(read(name:gsub('%.','/')..'.lua'),'@@forge-core/'..name,'t',target))()end
  local ok,err=pcall(mod('kernel.entry.physical_boot_options_v5')(controls),side);print('builder diagnostic',ok,err)
 end
 assert(report.accepted and candidate.GetPreparedEntry()==nil)
 assert(pr.forgeBootProviders.physicalOptions.public==public and pr.forgeBootProviders.activationAssembly.generation=='g279')
 assert(pr.forgeOperationalRuntime.Close())
end
print('PASS279 staged runtime entry and definition construct concrete profile/options/compat/proofs on both sides;input contract accepts;no A-F/native IO/SQL execution;Cfx/provenance virtual')
