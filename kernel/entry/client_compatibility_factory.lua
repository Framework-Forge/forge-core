--243: actual QB backend/bridge on the already prepared Forge graph.
local createBackend=require 'kernel.client.qb_compat_backend'
local createBridge=require 'kernel.compat.qb.client_main'
return function(graph,p)
 local origin=assert(p.origin);assert(origin.IsCurrent(),'current canonical origin required')
 assert(p.native.GetInvokingResource==origin.GetInvokingResource,'QB native origin mismatch')
 local closed=false;local backend,bridge;local api={Graph=graph,Origin=origin,OperationalReady=false}
 local function current()return not closed and p.isCurrent()==true and origin.IsCurrent()end
 local ports={};for k,v in pairs(p)do ports[k]=v end;ports.isCurrent=current
 local ok,why=pcall(function()
  backend=createBackend(graph,ports);api.Backend=backend
  bridge=createBridge(backend,ports);api.Bridge=bridge
  api.Enabled=bridge.Enabled
  if bridge.Enabled then api.GetCoreObject=assert(bridge.GetCoreObject)end
 end)
 function api.Close()
  closed=true;local clean=true
  for _,c in ipairs({bridge or false,backend or false})do if c then local ok,v=pcall(c.Close);if not ok or v~=true then clean=false end end end
  return clean and api.Progress().complete
 end
 function api.IsCurrent()return current()and backend and backend.IsCurrent()and bridge and bridge.IsCurrent()end
 function api.Progress()
  local a,b=bridge and bridge.Progress(),backend and backend.Progress()
  return{phase=closed and'closed'or'prepared',pending=(a and a.pending or 0)+(b and b.pending or 0),
   complete=closed and(not a or a.complete)and(not b or b.complete),operationalReady=false}
 end
 if not ok then api.Close();error(why,0)end
 return api
end
