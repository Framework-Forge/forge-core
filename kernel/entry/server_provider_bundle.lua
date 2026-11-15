-- Complete server provider input from installed modules. No test scaffold or legacy core state.
local environmentFactory=require 'kernel.entry.server_graph_environment'
local centralFactory=require 'kernel.entry.server_central_bundle'
local domainsFactory=require 'kernel.entry.server_domain_bundle'
local controlFactory=require 'kernel.entry.server_context_control'
return function(f,s,ports)
 assert(f.Side=='server'and f.IsCurrent(),'server provider foundation required')
 local closed=false;local children={};local api={OperationalReady=false}
 local function current()return not closed and f.IsCurrent()and s.IsCurrent()end
 local function own(name,scope)children[#children+1]={name=name,scope=scope};api[name]=scope;return scope end
 function api.Close()
  closed=true
  for i=#children,1,-1 do local c=children[i];if not c.done then local ok,v=pcall(c.scope.Close)
   if not ok or v~=true then return false end;c.done=true
  end end;return true
 end
 local ok,problem=pcall(function()
  local p={};for k,v in pairs(ports)do p[k]=v end
  local values=own('Values',environmentFactory(f,s,p));local loadPR=assert(p.loadPR)
  local dc=f.Seed.Registry.Require('kernel.entry.native_domain_configuration')({requireLocal=f.Seed.Registry.Require,
   getConvar=f.Seed.Execution.Native.GetConvar,vec3=f.Seed.Execution.Bind({'vec3'}).vec3,locale=f.DomainLocale,isCurrent=current})
  api.DomainConfiguration=dc;p.config,p.translate=dc.Config,dc.Translate
  local libraryScope=own('LibraryScope',loadPR('@pr_bridge/bridge/delivery/forge_server_library_ports')({foundation=f,support=s,values=values,
   loadPR=loadPR,environment=p.environment,native=p.native,config=dc.Config,rpc=p.rpc,services=p.services}))
  local lib=libraryScope.Library
  lib.table=loadPR('@pr_bridge/bridge/delivery/forge_graph_table_compat',p.environment)(lib.table)
  local function player(src)local pc=f.Base.PlayerCore;return pc and pc.Lookup.GetPlayer(src)end
  local integration=own('Integrations',loadPR('@pr_bridge/bridge/delivery/forge_server_integrations')({foundation=f,native=p.native,
   external=p.external,environment=p.environment,loadPR=loadPR,identity={GetPlayer=player,GetIdentifier=function(src)
    local entry=player(src);return entry and entry.PlayerData.citizenid end},
   httpRequest=s.Logging.DeliveryPorts.httpRequest,debug=function(level,...)local fn=lib.debug[tostring(level):lower()]or lib.debug.log;return fn(...)end,
   lang=f.DomainLocale()}))
  lib.ace,lib.phone,lib.weather=integration.Ace,integration.Phone,integration.Weather
  for _,name in ipairs({'addAce','removeAce','addPrincipal','removePrincipal'})do lib[name]=integration.Ace[name]end
  local extensions={};for k,x in pairs(lib)do if k~='callback'then extensions[k]=x end end
  local library=s.MakeLibrary(lib.callback,extensions,{}, {'table.clone','table.freeze','math.round','callback.await'})
  api.Library=library
  local selected={};for _,e in ipairs(f.EngineInputs.Describe())do selected[#selected+1]=e.name end
  local native=f.EngineInputs.Select(selected)
  -- World35 names the local emitter literally;server177 catalogs the same native as emit.
  native.TriggerEvent=native.emit
  local central=centralFactory(f,s,values,library,integration,p)
  local domains=domainsFactory(f,s,values,library,integration,p)
  for _,domain in pairs(domains.domains)do domain.native.TriggerEvent=native.TriggerEvent end
  local context=controlFactory(f,s,values,library,p)
  local audio=assert(loadPR('@pr_bridge/bridge/delivery/forge_media',p.environment))({nativeSound=s.Sound.Raw,
   resourceState=p.native.GetResourceState,sendClient=p.native.TriggerClientEvent,isCurrent=current})
  own('HelperMedia',audio)
  local helpers={library=library,native=native,cache=f.NativeCache.Cache,audio=audio.Audio,warn=library.print.warn}
  api.Bundle={config=dc.Config,central=central,domain=domains,context=context,helpers=helpers}
 end)
 if not ok then api.Close();error(problem,0)end
 function api.IsCurrent()return current()end
 function api.Progress()
  local out={};local complete=closed
  for _,c in ipairs(children)do local p=c.scope.Progress and c.scope.Progress()or{complete=c.done==true};out[c.name]=p;complete=complete and c.done==true end
  return{closed=closed,children=out,complete=complete,operationalReady=false}
 end
 return api
end
