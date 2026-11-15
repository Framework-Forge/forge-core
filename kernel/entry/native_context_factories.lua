-- Resolve installed PR factories for the native context constructors;no public PR/framework init.
return function(ports)
 local side,loadPR,current=assert(ports.side),assert(ports.loadPR),assert(ports.isCurrent)
 assert(side=='client'or side=='server','context factory side required')
 local paths={tasks='bridge/runtime/owned_tasks',imports='bridge/delivery/forge_runtime_imports',
  locale='bridge/delivery/forge_locale',delivery='bridge/delivery/forge_cache',logging='bridge/logging/forge_delivery'}
 if side=='server'then
  paths.media='bridge/delivery/forge_media';paths.configuration='bridge/vehicle_key/forge_configuration'
  paths.inventory='bridge/inventories/ox/forge_provider';paths.operations='bridge/inventories/ox/forge_operations'
  paths.banking='bridge/banking/forge_society';paths.keys='bridge/vehicle_key/forge_provider'
 else paths.media='bridge/delivery/forge_client_media';paths.configuration='bridge/delivery/forge_client_configuration'end
 local closed=false;local cached={};local api={OperationalReady=false}
 local function live()local ok,v=pcall(current);return not closed and ok and v==true end
 function api.Get(name)
  assert(live(),'native context factories closed')
  if cached[name]then return cached[name]end
  local path=assert(paths[name],'uncatalogued PR context factory:'..tostring(name))
  local factory=loadPR('@pr_bridge/'..path,ports.environment)
  assert(live()and type(factory)=='function','installed PR context factory unavailable:'..name)
  cached[name]=function(input)
   assert(live(),'native context factories closed')
   local p={};for k,v in pairs(input)do p[k]=v end;local owner=assert(p.isCurrent,'context owner required')
   p.isCurrent=function()return live()and owner()==true end
   return factory(p)
  end
  return cached[name]
 end
 function api.Describe()
  local out={};for name,path in pairs(paths)do out[#out+1]={name=name,path='@pr_bridge/'..path}end
  table.sort(out,function(a,b)return a.name<b.name end);return out
 end
 function api.Close()closed=true;return true end
 function api.IsCurrent()return live()end
 return api
end
