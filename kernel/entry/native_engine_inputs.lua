-- Resolve requested native aliases directly from installed schemas;never seed function slots with stubs.
local serverSchema=require 'kernel.entry.server_engine_schema'
local clientSchema=require 'kernel.entry.client_engine_schema'
return function(ports)
 local side=assert(ports.side);assert(side=='server'or side=='client','native input side required')
 local schema=(side=='server'and serverSchema or clientSchema)()
 local p={};for k,v in pairs(assert(ports.adjuncts))do p[k]=v end
 p.execution,p.side,p.isCurrent=assert(ports.execution),side,assert(ports.isCurrent)
 local engine=assert(ports.loadPR)('@pr_bridge/bridge/delivery/forge_native_ports')(p)
 local api={Engine=engine,OperationalReady=false,Side=side}
 function api.Select(names)
  local selected={}
  for _,name in ipairs(names)do
   assert(type(name)=='string'and schema[name],'uncatalogued native input:'..tostring(name))
   selected[name]=schema[name]
  end
  return engine.Select(selected)
 end
 function api.Describe()
  local out={};for name,target in pairs(schema)do out[#out+1]={name=name,target=target}end
  table.sort(out,function(a,b)return a.name<b.name end);return out
 end
 function api.IsCurrent()return engine.IsCurrent()end
 function api.Close()return engine.Close()end
 function api.Progress()return engine.Progress()end
 return api
end
