-- Concrete central/domain/control client bundle. Optional runtime hosts are never fabricated.
local createCentral=require 'kernel.entry.client_central_bundle'
local createDomains=require 'kernel.entry.client_domain_bundle'
local createControl=require 'kernel.entry.client_context_control'
return function(f,s,p)
 assert(f.Side=='client'and f.IsCurrent(),'current client foundation required')
 local closed=false;local children={};local api={OperationalReady=false}
 local function current()return not closed and f.IsCurrent()and s.IsCurrent()end
 local function own(name,scope)children[#children+1]={name=name,scope=scope};api[name]=scope;return scope end
 function api.Close()
  closed=true
  for i=#children,1,-1 do local c=children[i];if not c.done then
   local ok,v=pcall(c.scope.Close);if not ok or v~=true then return false end;c.done=true
  end end;return true
 end
 local ok,problem=pcall(function()
  local q={};for k,v in pairs(p)do q[k]=v end
  local dc=f.Seed.Registry.Require('kernel.entry.native_domain_configuration')({requireLocal=f.Seed.Registry.Require,
   getConvar=f.Seed.Execution.Native.GetConvar,vec3=f.Seed.Execution.Bind({'vec3'}).vec3,locale=f.DomainLocale,isCurrent=current})
  api.DomainConfiguration=dc;q.config,q.translate=dc.Config,dc.Translate
  local loadPR=assert(p.loadPR)
  local libScope=own('LibraryScope',loadPR('@pr_bridge/bridge/delivery/forge_client_library_ports',p.environment)({
   foundation=f,support=s,prCore=assert(p.prCore),loadPR=loadPR,environment=p.environment,config=dc.Config,
   rpc=p.rpc,services=p.services,capabilities=assert(p.capabilities)}))
  local extensions={};for k,v in pairs(libScope.Library)do if k~='callback'then extensions[k]=v end end
  local lib=s.MakeLibrary(p.rpc.Ox,extensions,{}, {'table.clone','table.freeze','callback.await','inventory.Search','progressBar','addKeybind'})
  api.Library=lib;q.ui=libScope.UI
  local integrations=own('Integrations',loadPR('@pr_bridge/bridge/delivery/forge_client_integrations',p.environment)({
   foundation=f,native=p.native,external=p.external,environment=p.environment,loadPR=loadPR}))
  local domains=createDomains(f,s,lib,integrations,q)
  domains.domains.World.native.TriggerClientEvent=function()error('TriggerClientEvent is server-only',0)end
  api.Bundle={config=dc.Config,central=createCentral(f,s,lib,integrations,q),domain=domains,
   context=createControl(f,s,q)}
 end)
 if not ok then api.Close();error(problem,0)end
 function api.IsCurrent()return current()end
 function api.Progress()
  local out={};local complete=closed
  for _,c in ipairs(children)do out[c.name]=c.scope.Progress and c.scope.Progress()or{complete=c.done==true};complete=complete and c.done==true end
  return{closed=closed,children=out,complete=complete,operationalReady=false}
 end
 return api
end
