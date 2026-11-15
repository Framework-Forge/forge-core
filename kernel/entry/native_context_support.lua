-- Concrete common PR leaves for182/183. Central/domain-specific services remain explicit.
local createLibrary=require 'kernel.entry.native_graph_library'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(foundation,ports)
 assert(foundation.IsCurrent(),'current support foundation required')
 local side=foundation.Side;assert(side=='server'or side=='client','support side required')
 local phase='preparing';local children={};local closing=false
 local api={OperationalReady=false,Foundation=foundation}
 local function current()return phase~='closing'and phase~='closed'and foundation.IsCurrent()end
 local borrowed=copy(foundation);borrowed.IsCurrent=current
 local loadPR,environment=assert(ports.loadPR),assert(ports.environment)
 local native,services=assert(ports.native),assert(ports.services)
 local running,onError=assert(ports.running),assert(ports.onError)
 local function own(name,scope)assert(type(scope.Close)=='function','support scope Close required:'..name)
  children[#children+1]={name=name,scope=scope};api[name]=scope;return scope end
 function api.Close()
  if phase=='closed'then return true end
  phase='closing';if closing then return false end;closing=true
  for i=#children,1,-1 do local child=children[i]
   if not child.done then local ok,value=pcall(child.scope.Close)
    if not ok or value~=true then api.CloseError=ok and nil or value;closing=false;return false end
    child.done=true
   end
  end
  phase='closed';closing=false;return true
 end
 local function factory(name)return assert(loadPR('@pr_bridge/bridge/delivery/'..name,environment))end
 local ok,problem=pcall(function()
  own('Dependencies',factory('forge_dependency_ports')({native=native,loadPR=loadPR,environment=environment,side=side,isCurrent=current}))
  own('Cache',factory('forge_cache_ports')({foundation=borrowed,native=native,external=assert(ports.external),running=running}))
  own('Utilities',factory('forge_graph_utilities')({foundation=borrowed,loadPR=loadPR,environment=environment,checkDependency=api.Dependencies.CheckDependency}))
  own('Configuration',factory('forge_native_configuration')({execution=foundation.Seed.Execution,external=ports.external,side=side,
   keys=services.Keys,random=api.Utilities.Random,running=running,
   load=function(path,target)return loadPR(path,target or environment)end,isCurrent=current}))
  own('Sound',factory('forge_sound_ports')({foundation=borrowed,native=native,external=ports.external}))
  if side=='client'then
   own('Streaming',factory('forge_streaming_ports')({prCore=assert(ports.prCore),foundation=borrowed}))
   own('Input',factory('forge_state_input_ports')({prCore=ports.prCore,foundation=borrowed,native=native}))
  else
   own('Logging',factory('forge_logging_ports')({foundation=borrowed,native=native,events=foundation.Events,loadPR=loadPR,
    environment=environment,clock=api.Utilities.Clock,createTasks=foundation.Factories.Get('tasks'),
    running=running,onError=onError,checkDependency=api.Dependencies.CheckDependency}))
  end
 end)
 if not ok then api.Close();error(problem,0)end
 phase='prepared'
 function api.Open()
  if phase~='prepared'or not current()then return false,'support_unavailable'end
  if api.Logging then local opened,reason=api.Logging.Open();if not opened then api.Close();return false,reason end end
  if not current()then api.Close();return false,'support_cancelled'end
  phase='open';return true
 end
 function api.Context(control)
  assert(current(),'support unavailable');local out=copy(control)
  assert(type(out.isReady)=='function','explicit readiness required')
  local owner=assert(out.isCurrent)
  out.isCurrent=function()return current()and owner()==true end
  out.running,out.onError=running,onError
  out.delivery,out.configuration=api.Cache.Ports,api.Configuration.Configuration
  out.media=copy(api.Sound.Ports)
  if side=='client'then
   out.input=api.Input.Ports;out.media.streaming=api.Streaming.Streaming;out.media.running=running
  else
   out.shared=api.Configuration.Shared
   out.loggingDelivery,out.logger,out.hooks=api.Logging.DeliveryPorts,api.Logging.LoggerPorts,api.Logging.HookPorts
   out.resourceState=assert(native.GetResourceState)
   --123/135 adopt these exact installed providers before context construction.
   local public=assert(services.Public);local external=assert(ports.external)
   out.inventory={inventory=assert(public.inventory),custom=assert(external.ox_inventory),resourceState=native.GetResourceState,
    owner='forge-core',executingResource=assert(native.GetCurrentResourceName)}
   out.operations={inventory=public.inventory,custom=external.ox_inventory,resourceState=native.GetResourceState,
    readResourceFile=assert(foundation.Seed.IO.Files.LoadResourceFile)}
   out.banking={banking=assert(public.banking),renewed=assert(external['Renewed-Banking']),resourceState=native.GetResourceState}
   out.vehicles={vehicleKey=assert(public.vehicle_key),prCarkeys=assert(external.pr_carkeys),resourceState=native.GetResourceState,
    selected=function()return 'pr_carkeys'end,sendClient=assert(native.TriggerClientEvent)}
  end
  return out
 end
 function api.MakeLibrary(callback,extensions,fields,required)
  assert(current(),'support unavailable');local source=copy(api.Utilities.Library)
  local merged=copy(source);for k,v in pairs(extensions or{})do merged[k]=v end
  return own('Library'..tostring(#children),createLibrary({library=source,callback=callback,extensions=merged,
   fields=fields or{},required=required,isCurrent=current})).Library
 end
 function api.IsCurrent()return current()end
 function api.Progress()
  local states={};for _,child in ipairs(children)do
   states[child.name]=child.scope.Progress and child.scope.Progress()or{complete=child.done==true}
  end
  return{phase=phase,complete=phase=='closed',children=states,closeError=api.CloseError,operationalReady=false}
 end
 return api
end
