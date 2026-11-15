--273: bind installed PR/Cfx ports to the one core bootstrap;no framework adapter or second seed.
return function(p)
 local e,profile=assert(p.environment),assert(p.profile)
 local pr=assert(e.PRCore);local bootstrap=assert(pr.forgeCoreBootstrap)
 assert(e.GetCurrentResourceName()=='forge-core'and bootstrap.Public==e.pr_lib,'matching primitive bootstrap required')
 local public=bootstrap.Public;local closed=false;local getCandidate=assert(p.getCandidate)
 local function current()return not closed and pr.forgeCoreBootstrap==bootstrap end
 local function module(path)if path:sub(1,1)~='@'then path='@pr_bridge/'..path end;return pr.load(path,e)end
 local function library()
  local candidate=getCandidate();local entry=candidate and candidate.GetPreparedEntry()
  return assert(entry and entry.Foundation.Seed.Library.Library,'prepared PR command library required')
 end
 local commandProvider,commandSeed;local commandTokens={}
 local function commandCurrent()return current()and commandSeed and commandSeed.IsCurrent()end
 local function command(name,properties,fn)
  -- The lazy foundation library has no addCommand field. Load the native PR provider only on request,
  -- with resource callbacks fenced to this configuration and the SAME prepared seed.
  library()
  if not commandProvider then
   commandSeed=assert(getCandidate().GetPreparedEntry().Foundation.Seed)
   local env=setmetatable({},{__index=e});env._G=env
   if e.IsDuplicityVersion()then
    local entry=assert(getCandidate().GetPreparedEntry())
    local integration=assert(entry.Providers and entry.Providers.Integrations,'prepared command ACE integration required')
    local ace=assert(integration.Ace,'prepared command ACE required')
    env.PRAce={}
    for _,name in ipairs({'isPlayerAceAllowed','isPrincipalAceAllowed','isAdminWhitelisted','isWhitelisted','hasFrameworkAccess','ensureAce'})do
     local fn=assert(ace[name],'command ACE method required:'..name)
     env.PRAce[name]=function(...)
      assert(commandCurrent()and getCandidate().GetPreparedEntry()==entry and integration.IsCurrent()
       and entry.Providers.Integrations==integration and integration.Ace==ace and ace[name]==fn,'prepared command ACE changed')
      return fn(...)
     end
    end
   end
   env.SetTimeout=function(delay,callback)return e.SetTimeout(delay,function(...)
    if commandCurrent()then return callback(...)end
   end)end
   env.AddEventHandler=function(event,callback)
    local token=e.AddEventHandler(event,function(...)if commandCurrent()then return callback(...)end end)
    assert(token~=nil and token~=false,'PR command event registration refused')
    commandTokens[#commandTokens+1]=token;return token
   end
   commandProvider=pr.load('@pr_bridge/bridge/addCommand/'..(e.IsDuplicityVersion()and'server'or'client'),env)
  end
  assert(commandCurrent(),'prepared PR command provider unavailable')
  return commandProvider(name,properties,fn)
 end
 local oxCommand=module('bridge/compat/ox_lib/ox_command')(command)
 local function exclusive()
  return e.GetResourceMetadata('forge-core','forge_kernel_bootstrap',0)=='owned/1'
 end
 local function available(kind,name)
  if not current()or not exclusive()then return false end
  if kind=='command'then
   for _,v in ipairs(e.GetRegisteredCommands())do if v.name:lower()==name:lower()then return false end end
  elseif kind=='export'then
   local key=e.IsDuplicityVersion()and'server_export'or'export'
   for i=0,e.GetNumResourceMetadata('forge-core',key)-1 do if e.GetResourceMetadata('forge-core',key,i)==name then return false end end
  elseif kind~='event'and kind~='callback'then return false end
  return true
 end
 local namespace=module('@forge-core/kernel/pr_integration/activation_namespace')({isCurrent=current,available=available,
 publishExport=function(name,fn)return e.exports(name,fn)end,prCommand=command,oxCommand=oxCommand})
 local inventory=module('bridge/inventories/ox/forge_control')(e)
 local banking=module('bridge/banking/renewed/forge_control')(e)
 local keys=module('bridge/vehicle_key/pr_carkeys/forge_control')(e)
 local generation=profile.Generation
 local ox=assert(profile.Get('ox_inventory','server'),'OX server consumer required')
 local function inventoryProbe()
  local ok,value=pcall(function()return inventory.Describe(generation,ox.instance)end)
  return ok and value or nil
 end
 local function rawReady()
  if not current()then return false end
  if e.GetResourceState('pr_bridge')~='started'or inventory.State()~='started'then return false end
  if e.IsDuplicityVersion()then
   for _,name in ipairs({'oxmysql','Renewed-Banking','pr_carkeys'})do if e.GetResourceState(name)~='started'then return false end end
   local ok,ready=pcall(function()
    local hooks=inventory.GetOwnedHookSnapshot()
    local bank=banking.Readiness()
    local keys=keys.Readiness()
    return hooks.owner=='forge-core'and hooks.generation==generation and bank.generation==generation
     and(bank.phase=='loading'or bank.phase=='ready')and keys.generation==generation and keys.ready==true
   end)
   if not ok or ready~=true then return false end
  end
  return true
 end
 local registration={};for k,v in pairs(namespace.Registration)do registration[k]=v end
 registration.available=function(kind,name)
  if kind=='export'or kind=='event'or kind=='command'or kind=='callback'then return namespace.Available(kind,name)end
  -- RPC122 asks (callbackName,wireName);the graph boundary asks (kind,name).
  return namespace.Available('callback',kind)
 end
 local physical={public=public,registration=registration,isCurrent=current,isReady=rawReady,
 inventoryBridgeProbe=inventoryProbe,pullLocale=function(resource,key)return e.exports[resource]:getLocale(key)end,
 onError=function(problem)error(problem,0)end,targetSelection='native'}
 local api={PhysicalOptions=physical,Namespace=namespace,OperationalReady=false}
 function api.IsCurrent()return current()end
 function api.Ready()return rawReady()end
 function api.Close()
  closed=true;local done=namespace.Close()
  for i=#commandTokens,1,-1 do
   local ok,value=pcall(e.RemoveEventHandler,commandTokens[i])
   if ok and value~=false then table.remove(commandTokens,i)else done=false end
  end
  return done
 end
 function api.Progress()local s=namespace.Progress();return{closed=closed,namespace=s,commandEvents=#commandTokens,
  complete=closed and s.complete and #commandTokens==0,operationalReady=false}end
 return api
end
