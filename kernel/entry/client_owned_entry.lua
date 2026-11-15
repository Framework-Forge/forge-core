-- Client225 with installed capabilities224/one UI222;raw/RPC/foundation remain unique.
local createEntry=require 'kernel.entry.supported_foundation_entry'
local createProviders=require 'kernel.entry.client_provider_bundle'
return function(raw,ports)
 assert(ports.foundation.side=='client','explicit client entry required')
 local p={};for k,v in pairs(ports)do p[k]=v end
 local providers,capabilities;local api={OperationalReady=false}
 p.profile={};for k,v in pairs(ports.profile)do p.profile[k]=v end
 local originalLoad=assert(p.profile.loadPR)
 p.profile.loadPR=function(path,env)
  if path=='@pr_bridge/bridge/delivery/forge_native_client_ui'then path='@pr_bridge/bridge/delivery/forge_native_client_ui_v2'end
  return originalLoad(path,env)
 end
 p.buildProviders=function(f,services,support)
  local previous=f.Close
  f.Close=function()
   if capabilities and not capabilities.Close()then return false,'client_capabilities_not_drained'end
   if providers and not providers.Close()then return false,'client_providers_not_drained'end
   return previous()
  end
  local inputs={};for k,v in pairs(assert(ports.providers))do inputs[k]=v end
  inputs.services,inputs.rpc,inputs.prCore=services,raw.RPC,ports.prCore
  capabilities=inputs.loadPR('@pr_bridge/bridge/delivery/forge_client_capabilities',inputs.environment)({
   foundation=f,prCore=ports.prCore,environment=inputs.environment,loadPR=inputs.loadPR,
   createTasks=f.Factories.Get('tasks'),running=inputs.running,onError=inputs.onError,
   targetSelection=assert(inputs.targetSelection),debug={}})
  api.Capabilities=capabilities;inputs.capabilities=capabilities.Capabilities
  providers=createProviders(f,support,inputs);api.Providers=providers
  return providers.Bundle
 end
 local entry=createEntry(raw,p);api.Entry=entry
 function api.Prepare(...)
  local r=table.pack(entry.Prepare(...));api.Foundation,api.Profile,api.Bootstrap=entry.Foundation,entry.Profile,entry.Bootstrap
  return table.unpack(r,1,r.n)
 end
 function api.Stop()if capabilities then capabilities.BeginDrain()end;return entry.Stop()end
 function api.Poll()if capabilities then capabilities.BeginDrain()end;return entry.Poll()end
 function api.Install()
  if not providers then return false,'client_entry_not_prepared'end
  local services=raw.Services
  if services.Progress().phase~='open'then local ok,why=services.Open();if not ok then api.Stop();return false,why end end
  local ok,why=entry.Install();if ok~=true then return false,why end
  local opened,reason=capabilities.Open();if not opened then api.Stop();return false,reason end;return true
 end
 function api.Start()if not capabilities or not capabilities.IsReady()then return false,'client_capabilities_not_ready'end;return entry.Start()end
 function api.IsCurrent()return entry.IsCurrent()end
 function api.Progress()return{entry=entry.Progress(),providers=providers and providers.Progress(),capabilities=capabilities and capabilities.Progress(),
  complete=entry.Progress().complete,operationalReady=false}end
 return api
end
