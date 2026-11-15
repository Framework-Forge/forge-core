--236: observations only; no start, resource-state inference or approval defaults.
return function(p)
 local generation,getCandidate=assert(p.generation),assert(p.getCandidate)
 local publication,consumers=assert(p.publication),assert(p.consumers)
 local external={};for _,name in ipairs({'oxHooks','catalogs','banking','keys','decisions','environment'})do
  external[name]=assert(p.external[name],'physical readiness probe required: '..name)
  assert(type(external[name])=='function')
 end
 local closed,armed,pending=false,false,0;local api={OperationalReady=false,Probes={}}
 local function identities()
  if closed then return end
  local c=getCandidate();if not c then return end
  local e,r=c.GetPreparedEntry(),c.GetPreparedRaw()
  if not e or not r or e.IsCurrent()~=true then return end
  if not e.Foundation or not e.Profile or e.Profile.Seed~=e.Foundation.Seed then return end
  return c,e,r
 end
 local function probe(fn)
  return function(epoch)
   if closed or epoch~=generation then return false end
   pending=pending+1;local result=table.pack(pcall(fn));pending=pending-1
   if not result[1]then error(result[2],0)end
   return not closed and result[2]==true
  end
 end
 api.Probes.allocations=probe(function()return identities()~=nil and consumers.IsPrepared()end)
 api.Probes.rawProviders=probe(function()local _,_,r=identities();return r and r.Services.Progress().phase=='open'or false end)
 api.Probes.bootstrap=probe(function()
  local _,e=identities();if not e then return false end;local phase=e.Bootstrap.Progress().phase
  return phase=='installed'or phase=='running'
 end)
 api.Probes.nativeAPI=probe(function()return identities()~=nil and publication.IsInstalled()end)
 api.Probes.compatIdentity=probe(function()return identities()~=nil and publication.CompatibilityReady()end)
 api.Probes.consumerBindings=probe(function()return identities()~=nil and consumers.IsAttached()end)
 for name,fn in pairs(external)do api.Probes[name]=probe(function()
  local c,e,r=identities()
  return armed and c~=nil and fn(generation,e,r)==true
 end)end
 function api.Arm(c)
  if closed or armed or c~=getCandidate()then return false,'readiness_not_armable'end
  for _,name in ipairs({'allocations','rawProviders','bootstrap','nativeAPI','compatIdentity','consumerBindings'})do
   if not api.Probes[name](generation)then return false,'structural_probe_missing:'..name end
  end
  local _,e=identities();if e.Capabilities and not e.Capabilities.IsReady()then return false,'client_capabilities_not_ready'end
  armed=true;return true
 end
 function api.Close()closed=true;armed=false;return pending==0 end
 function api.Progress()return{closed=closed,armed=armed,pending=pending,complete=closed and pending==0,operationalReady=false}end
 return api
end
