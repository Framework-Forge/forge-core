-- Server entry with207 provider owner,over199. One foundation/seed/raw/RPC.
local createEntry=require 'kernel.entry.supported_foundation_entry_v2'
local createProviders=require 'kernel.entry.server_provider_bundle_v2'
return function(raw,ports)
 assert(ports.foundation.side=='server','explicit server entry required')
 local p={};for k,v in pairs(ports)do p[k]=v end
 local providers;local api={OperationalReady=false}
 p.buildProviders=function(f,services,support)
  local previous=f.Close
  f.Close=function()
   if providers and not providers.Close()then return false,'server_providers_not_drained'end
   return previous()
  end
  local inputs={};for k,v in pairs(assert(ports.providers))do inputs[k]=v end
  inputs.services,inputs.rpc=services,raw.RPC
  providers=createProviders(f,support,inputs);api.Providers=providers
  return providers.Bundle
 end
 local entry=createEntry(raw,p);api.Entry=entry
 function api.Prepare(...)
  local r=table.pack(entry.Prepare(...));api.Foundation,api.Profile,api.Bootstrap=entry.Foundation,entry.Profile,entry.Bootstrap
  return table.unpack(r,1,r.n)
 end
 function api.Install()
  if not providers then return false,'server_entry_not_prepared'end
  local services=raw.Services
  if services.Progress().phase~='open'then local ok,why=services.Open();if not ok then entry.Stop();return false,why end end
  local ok,why=entry.Install();if ok~=true then return false,why end
  local out=table.pack(pcall(providers.Integrations.Open,raw.RPC.Owners.native,assert(ports.profile.barrier).WrapIngress))
  if not out[1]or out[2]~=true then entry.Stop();return false,out[1]and out[3]or out[2]end
  return true
 end
 function api.Start()return entry.Start()end
 function api.Stop()return entry.Stop()end
 function api.Poll()return entry.Poll()end
 function api.IsCurrent()return entry.IsCurrent()end
 function api.Progress()return{entry=entry.Progress(),providers=providers and providers.Progress(),
  complete=entry.Progress().complete,operationalReady=false}end
 return api
end
