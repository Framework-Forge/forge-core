-- Concrete server values over one foundation/raw provider owner. No gameplay starts here.
return function(foundation,support,ports)
 assert(foundation.Side=='server'and foundation.IsCurrent(),'current server foundation required')
 local loadPR,env=assert(ports.loadPR),assert(ports.environment)
 local services=assert(ports.services);local seed=foundation.Seed;local closed=false;local scopes={}
 local api={OperationalReady=false}
 local function current()return not closed and foundation.IsCurrent()and support.IsCurrent()end
 local function own(s)scopes[#scopes+1]=s;return s end
 local function guarded(fn)return function(...)assert(current(),'server graph environment unavailable');return fn(...)end end
 function api.Close()
  closed=true;for i=#scopes,1,-1 do if scopes[i].Close()~=true then return false end end;return true
 end
 local ok,problem=pcall(function()
  local execution=assert(seed.Execution)
  api.Platform=own(loadPR('@pr_bridge/bridge/delivery/forge_native_platform')({execution=execution,events=foundation.Events,
   side='server',isCurrent=current,time=support.Utilities.Clock.time,locale=foundation.Locale}))
  api.Database=own(loadPR('@pr_bridge/bridge/database/forge_native_await')({database=assert(services.Public.database),isCurrent=current}))
  local conf={};for k,v in pairs(support.Configuration.Configuration)do conf[k]=v end;conf.isCurrent=current
  local boundary=own(support.Configuration.CreateConfiguration(conf))
  api.Server=seed.Registry.Require('kernel.config.server')(boundary.Ports)
  local n=execution.Bind({'GetConvar','GetConvarInt','GetCurrentResourceName','vec4','GetPlayerRoutingBucket'})
  api.Shared=seed.Registry.Require('kernel.config.shared')({vec4=n.vec4})
  local codec=assert(seed.IO.Codec)
  api.Settings={maxJobs=n.GetConvarInt('qbx:max_jobs_per_player',1),maxGangs=n.GetConvarInt('qbx:max_gangs_per_player',1),
   setJobReplaces=n.GetConvar('qbx:setjob_replaces','true')=='true',setGangReplaces=n.GetConvar('qbx:setgang_replaces','true')=='true',
   accounts=codec.decode(n.GetConvar('inventory:accounts','["money"]'))}
  assert(type(api.Settings.accounts)=='table','inventory accounts JSON must be a table')
  -- Forge: sem statebag/GlobalState. O estado global (PVPEnabled, PlayerCount, MaxPlayers) fica numa
  -- tabela local do servidor; cada mudanca vai para os clientes por evento
  -- 'qbx_core:client:globalState:<chave>' e o cliente pede o estado inicial com
  -- 'qbx_core:server:requestGlobalState' (server/events.lua).
  local globalData={}
  local sendClient=assert(execution.Bind({'TriggerClientEvent'}).TriggerClientEvent)
  api.GlobalState=setmetatable({},{__index=globalData,__newindex=function(_,key,value)
   assert(current(),'global state view unavailable')
   if globalData[key]==value then return end
   globalData[key]=value
   sendClient('qbx_core:client:globalState:'..key,-1,value)
  end})
  -- A transparent view:the initialized PlayerCount lives in the global state view,not a second counter table.
  api.Counters=setmetatable({},{__index=function(_,key)
   assert(current(),'counter view unavailable');local v=api.GlobalState[key]
   if key=='PlayerCount'and v==nil then return 0 end;return v
  end,__newindex=function(_,key,value)assert(current(),'counter view unavailable');api.GlobalState[key]=value end})
  api.NewPromise=guarded(assert(assert(env.promise).new));api.AwaitPromise=guarded(assert(assert(env.Citizen).Await))
  api.Clock=support.Utilities.Clock;api.Random=support.Utilities.Random
  api.GetBucket=guarded(n.GetPlayerRoutingBucket);api.Compile=guarded(assert(env.load))
  api.Resource=n.GetCurrentResourceName();assert(api.Resource=='forge-core','server graph resource mismatch')
 end)
 if not ok then api.Close();error(problem,0)end
 function api.IsCurrent()return current()end
 function api.Progress()return{closed=closed,complete=closed and api.Database.Progress().complete,operationalReady=false}end
 return api
end
