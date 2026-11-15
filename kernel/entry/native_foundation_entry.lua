-- One native entry:179 foundation ->188 tree ->181 profile. The raw125 services/RPC are borrowed.
local createFoundation=require 'kernel.entry.native_boot_foundation'
local createTree=require 'kernel.entry.native_bootstrap_builder'
local createProfile=require 'kernel.entry.native_foundation_profile'
return function(raw,ports)
 local pr=assert(ports.prCore);assert(pr.forgeRawEntry==raw and pr.forgeOwnedCallbacks==raw.RPC,'prepared raw125 owner required')
 assert(pr.forgeNativeFoundationEntry==nil,'native foundation entry already owned')
 local phase='allocated';local foundation,profile;local owner=assert(ports.isCurrent)
 local api={OperationalReady=false};pr.forgeNativeFoundationEntry=api
 local function current()local ok,v=pcall(owner);return phase~='closed'and pr.forgeNativeFoundationEntry==api and ok and v==true end
 local function finish()
  if profile then if not profile.Progress().complete then return false end
  elseif foundation and not foundation.Close()then return false end
  phase='closed';if pr.forgeNativeFoundationEntry==api then pr.forgeNativeFoundationEntry=nil end;return true
 end
 function api.Stop()
  if phase=='closed'then return true end;phase='closing'
  if profile then profile.Stop()end;return finish()
 end
 function api.Poll()
  if phase=='closed'then return true end
  if phase~='closing'then return false,'foundation_entry_not_stopping'end
  if profile then profile.Poll()end;return finish()
 end
 function api.Prepare(...)
  if phase~='allocated'or not current()then return false,'foundation_entry_unavailable'end
  phase='preparing';local args=table.pack(...)
  local ok,result,reason=pcall(function()
   local fp={};for k,v in pairs(assert(ports.foundation))do fp[k]=v end
   fp.prCore,fp.rpc,fp.isCurrent=pr,raw.RPC,current
   foundation=createFoundation(fp);api.Foundation=foundation
   local bundle=assert(ports.buildProviders,'native provider bundle builder required')(foundation,raw.Services)
   assert(type(bundle)=='table','native provider bundle required')
   local tree,audit=createTree(foundation,bundle);api.PortAudit=audit
   local p={};for k,v in pairs(assert(ports.profile))do p[k]=v end
   p.side,p.prCore,p.rpc,p.services,p.bootstrap=foundation.Side,pr,raw.RPC,raw.Services,tree
   profile=createProfile(foundation,p);api.Profile,api.Bootstrap=profile,profile.Bootstrap
   assert(profile.Seed==foundation.Seed and pr.forgeNativeSeed==foundation.Seed,'duplicate seed allocation')
   return profile.Prepare(table.unpack(args,1,args.n))
  end)
  if not ok or result~=true or phase~='preparing'or not current()then
   api.Stop();return false,ok and reason or result
  end
  phase='prepared';return true
 end
 local function run(name,expected,target)
  if phase~=expected or not current()then return false,'foundation_entry_unavailable'end
  local active=name:lower()..'ing';phase=active
  local out=table.pack(pcall(profile[name]))
  if not out[1]then api.Stop();error(out[2],0)end
  if out[2]~=true or phase~=active or not current()then api.Stop();return false,out[3]or'foundation_entry_cancelled'end
  phase=target;return table.unpack(out,2,out.n)
 end
 function api.Install()return run('Install','prepared','installed')end
 function api.Start()return run('Start','installed','running')end
 function api.IsCurrent()return current()and(not foundation or foundation.IsCurrent())end
 function api.Progress()return{phase=phase,foundation=foundation and foundation.Progress(),profile=profile and profile.Progress(),complete=phase=='closed',operationalReady=false}end
 return api
end
