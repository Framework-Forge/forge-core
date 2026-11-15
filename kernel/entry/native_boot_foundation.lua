-- Native foundation for the full bootstrap builders. Does not manufacture missing context graphs.
local createCache=require 'kernel.entry.native_import_cache'
local createRegistration=require 'kernel.entry.native_registration_input'
local createSeed=require 'kernel.entry.native_seed'
local createRegistry=require 'kernel.entry.native_factory_registry'
local createServer=require 'kernel.entry.native_server_base'
local createClient=require 'kernel.entry.native_client_base'
local createLocale=require 'kernel.entry.native_locale_ports'
local createEngine=require 'kernel.entry.native_engine_inputs'
local createFactories=require 'kernel.entry.native_context_factories'
return function(ports)
 local pr,side=assert(ports.prCore),assert(ports.side)
 assert(side=='server'or side=='client','foundation side required')
 assert(pr.forgeNativeFoundation==nil,'native foundation already owned')
 local phase='allocating';local owner=assert(ports.isCurrent);local api={OperationalReady=false,Side=side}
 local scopes={};local seed,registration,bootstrap;local convars={};local observerAdd,observerRemove;pr.forgeNativeFoundation=api
 local function current()
  if phase=='closing'or phase=='closed'or pr.forgeNativeFoundation~=api then return false end
  local ok,v=pcall(owner);return ok and v==true
 end
 local function own(name,scope)scopes[#scopes+1]={name=name,scope=scope};api[name]=scope;return scope end
 local function removeConvars()
  local done=true
  for i=#convars,1,-1 do local record=convars[i]
   if record.uncertain then done=false end
   if record.active then
    local ok,value=pcall(observerRemove,record.token)
    if ok and value~=false then record.active=false else done=false end
   end
  end
  return done
 end
 function api.Close()
  if phase=='closed'then return true end
  if bootstrap and not bootstrap.Progress().complete then return false,'foundation_bootstrap_not_drained'end
  phase='closing';local done=removeConvars()
  for i=#scopes,1,-1 do local s=scopes[i]
   -- Seed is released last; all consumers keep IO/library/execution while draining.
   if s.scope~=seed then local ok,v=pcall(s.scope.Close);done=ok and v==true and done end
  end
  if seed and done then local ok,v=pcall(seed.Close);done=ok and v==true and done end
  if done then phase='closed';if pr.forgeNativeFoundation==api then pr.forgeNativeFoundation=nil end end
  return done
 end
 function api.Poll()if phase~='closing'then return false,'foundation_not_closing'end;return api.Close()end
 function api.IsCurrent()return current()and(not seed or seed.IsCurrent())end
 function api.Progress()
  local children={};for _,s in ipairs(scopes)do if s.scope.Progress then children[s.name]=s.scope.Progress()end end
  local active,queued,uncertain=0,0,0;for _,r in ipairs(convars)do
   if r.active then active=active+1 else queued=queued+1 end;if r.uncertain then uncertain=uncertain+1 end
  end
  return{phase=phase,complete=phase=='closed',children=children,bootstrapBound=bootstrap~=nil,bootstrapGraphBuilt=false,convarActive=active,convarQueued=queued,convarUncertain=uncertain,operationalReady=false}
 end
 local ok,problem=pcall(function()
  local n=assert(ports.native);local cache=own('NativeCache',createCache({native=n,isCurrent=current}))
  local rp={};for k,v in pairs(assert(ports.registration))do rp[k]=v end
  rp.native,rp.side,rp.isCurrent=n,side,current
  registration=own('Registration',createRegistration(rp))
  local environment={};for k,v in pairs(assert(ports.environment))do environment[k]=v end
  -- PR console's optional observer is queued until explicit installation;no physical registration during Prepare.
  environment.AddConvarChangeListener=function(pattern,callback)
   assert(current()and phase=='allocating','convar observer must be declared during foundation allocation')
   assert(type(pattern)=='string'and type(callback)=='function','convar observer declaration required')
   convars[#convars+1]={pattern=pattern,callback=callback};return #convars
  end
  environment.RemoveConvarChangeListener=nil
  seed=own('Seed',createSeed({prCore=pr,rpc=assert(ports.rpc),native=n,json=assert(ports.json),
   public=assert(ports.public),environment=environment,nativeCache=cache.Cache,events=registration.Events,
   running=assert(ports.running),getSource=registration.Events.source,isCurrent=current,
   compile=assert(ports.compile),inventoryBridgeProbe=assert(ports.inventoryBridgeProbe),
   createRegistry=createRegistry,loadPR=assert(ports.loadPR)}))
  local prepared,reason=seed.Prepare();assert(prepared,reason)
  local base=own('State',(side=='server'and createServer or createClient)({native=n,io=seed.IO,library=seed.Library.Library,isCurrent=current}))
  api.Base=base.Base
  local locales=own('Locales',createLocale({io=seed.IO,library=seed.Library.Library,public=ports.public,
   loadPR=ports.loadPR,environment=ports.environment,getConvar=seed.Execution.Native.GetConvar,
   pullLocale=assert(ports.pullLocale),running=ports.running,isCurrent=current}))
  api.DomainLocale=locales.DomainLocale
  api.Locale=function(...)
   assert(current(),'native foundation unavailable')
   return assert(bootstrap and bootstrap.Context.Locale,'canonical bootstrap locale not bound').Translate(...)
  end
  local adjuncts={};for k,v in pairs(assert(ports.adjuncts))do adjuncts[k]=v end;adjuncts.locale=api.Locale
  own('EngineInputs',createEngine({side=side,execution=seed.Execution,adjuncts=adjuncts,loadPR=ports.loadPR,isCurrent=current}))
  own('Factories',createFactories({side=side,loadPR=ports.loadPR,environment=ports.environment,isCurrent=current}))
  api.Public,api.Events,api.RegistrationInput=ports.public,registration.Events,registration.Input
  assert(current(),'native foundation cancelled during construction')
 end)
 if not ok then api.Close();error(problem,0)end;phase='prepared'
 function api.BindBootstrap(value)
  assert(current()and bootstrap==nil,'bootstrap already bound or foundation unavailable')
  assert(value.Side==side and type(value.Progress)=='function'and type(value.Context)=='table','matching bootstrap required')
  assert(type(value.Context.Locale)=='table'and type(value.Context.Locale.Translate)=='function','canonical bootstrap locale required')
  registration.Bind(assert(value.Transport));bootstrap=value;return true
 end
 function api.OpenObservers()
  if not current()or not bootstrap or bootstrap.Transport.Progress().phase~='open'then return false,'bootstrap_transport_not_open'end
  local add=assert(ports.environment.AddConvarChangeListener,'native convar registration required')
  local remove=assert(ports.environment.RemoveConvarChangeListener,'native convar removal required')
  assert(type(add)=='function'and type(remove)=='function','native convar functions required')
  if observerAdd and(observerAdd~=add or observerRemove~=remove)then return false,'convar_provider_changed'end
  observerAdd,observerRemove=add,remove
  for _,record in ipairs(convars)do if not record.active then
   local result=table.pack(pcall(add,record.pattern,function(...)if current()then return record.callback(...)end end))
   if not result[1]or result[2]==nil or result[2]==false then
    phase='closing';record.uncertain=true;return false,'convar_registration_uncertain'
   end
   record.token,record.active=result[2],true
   if not current()then removeConvars();return false,'foundation_closed_during_observer_install'end
  end end
  return true
 end
 return api
end
