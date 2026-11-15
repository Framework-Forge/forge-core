--244: compose the existing QB/QBX compatibility on one graph;no runtime authority in the shim.
local server=require 'kernel.entry.server_compatibility_factory'
local client=require 'kernel.entry.client_compatibility_factory'
local createBinding=require 'kernel.compat.qb.binding_context'
local createCatalog=require 'kernel.compat.qbx.export_catalog'
local createGateway=require 'kernel.compat.qbx.export_gateway'
local createQB=require 'kernel.compat.qbx.qb_gateway'
local createPublication=require 'kernel.compat.qbx.gateway_binding'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(graph,side,entry,p)
 assert(side=='server'or side=='client')
 local originOwner=assert(entry.ActivationOriginOwner,'pre-graph origin owner required')
 local origin=assert(originOwner.Origin);assert(originOwner.IsCurrent(),'origin owner unavailable')
 assert(entry.Bootstrap.Graph==graph,'compatibility graph mismatch')
 local phase='preparing';local children={};local qb,binding,catalog,gateway,qbGateway,publication
 local api={Graph=graph,Origin=origin,OperationalReady=false}
 local function current()return phase~='closing'and phase~='closed'and entry.IsCurrent()and originOwner.IsCurrent()end
 local function own(c)children[#children+1]=assert(c);return c end
 local function structural()
  local state=entry.Bootstrap.Progress().phase
  return current()and(state=='installed'or state=='running')
 end
 local function guarded(fn)return function(...)if phase=='installed'and p.barrier.CanServe()and current()then return fn(...)end end end
 local public=copy(entry.Bootstrap.Transport.Public)
 public.publishExport=function(name,fn)return entry.Bootstrap.Transport.Public.publishExport(name,guarded(fn))end
 local events=copy(entry.Bootstrap.Transport.Events)
 events.listen=function(name,fn,...)return entry.Bootstrap.Transport.Events.listen(name,guarded(fn),...)end
 function api.Close()
  phase='closing';local clean=true
  for i=#children,1,-1 do local ok,v=pcall(children[i].Close);if not ok or v~=true then clean=false end end
  if clean then phase='closed'end;return api.Progress().complete
 end
 function api.Progress()
  local pending,clean=0,true
  for _,c in ipairs(children)do local s=c.Progress();pending=pending+(s.pending or 0);clean=clean and s.complete==true end
  return{phase=phase,pending=pending,complete=phase=='closed'and pending==0 and clean,operationalReady=false}
 end
 function api.IsCurrent()return current()and qb and qb.IsCurrent()and catalog and catalog.IsCurrent()or false end
 function api.IsReady()
  return phase=='installed'and api.IsCurrent()and publication.Progress().phase=='installed'
   and(binding.Progress().phase=='installed'or not qb.Enabled)
 end
 local ok,why=pcall(function()
  local ports=assert(p.makePorts)(graph,side,entry,origin)
  ports=copy(ports);ports.origin=origin;ports.isCurrent=current
  -- Descriptor construction needs the prepared graph,not globally open ingress.
  ports.isReady=current
  qb=own((side=='server'and server or client)(graph,ports))
  api.GetCoreObject=qb.GetCoreObject;api.Enabled=qb.Enabled
  binding=own(createBinding(graph,qb.Bridge,qb.Backend,{side=side,isCurrent=current,isReady=structural,
   events=events,public=public,externalAliases=ports.externalQBAliases==true,aliasAvailable=assert(p.aliasAvailable)}))
  catalog=createCatalog(graph,side,{isCurrent=current})
  --102 owns references only;its synchronous Close has no Progress/pending contract.
  local revoked=false
  own({Close=function()revoked=catalog.Close()==true;return revoked end,
   Progress=function()return{pending=0,complete=revoked}end})
  local gp={generation=assert(p.generation),publicAliases=ports.externalQBAliases==true,transportResource=ports.externalQBAliases and'pr_bridge'or'qbx_core',isCurrent=current,isReady=structural,getInvokingResource=assert(p.getInvokingResource)}
  gateway=own(createGateway(catalog,origin,gp))
  qbGateway=own(createQB(side,qb.Bridge,binding,origin,gp))
  publication=own(createPublication(gateway,qbGateway,{side=side,isCurrent=current,isReady=structural,public=public}))
  assert(current());phase='prepared'
 end)
 if not ok then api.Close();error(why,0)end
 function api.Install()
  if phase~='prepared'or not structural()then return false,'compatibility_not_prepared'end;phase='installing'
  local ok,why=pcall(function()
   if qb.Enabled then assert(binding.Install())end
   assert(current()and phase=='installing');assert(gateway.Open())
   assert(publication.Install());assert(current()and phase=='installing')
  end)
  if not ok then api.Close();return false,why end;phase='installed';return true
 end
 return api
end
