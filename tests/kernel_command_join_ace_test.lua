-- First join must reuse the already-owned ACE integration, not bootstrap it again.
local T=dofile('tests/kernel_owned_rpc_harness.lua');local H=T.H;local originalLoad=H.load
H.load=function(path,env)if path==T.path then env.debug=debug end;return originalLoad(path,env)end
local w=T.new();H.load=originalLoad;w.open()
local timers,events,commands,suggestions={}, {}, {}, {};local live=true;local executed=0;local aceLoads=0
local aceEnv=H.environment({Config={},Bridge={framework={GetIdentifier=function()return nil end,GetPlayer=function()return nil end}},
 GetConvar=function(key,default)return key=='pr_bridge:admin'and'license:admin'or default end,
 GetPlayerIdentifiers=function(src)return src==9 and{'license:admin'}or{}end,
 IsPrincipalAceAllowed=function(_,name)return name=='command.allowed'end,
 IsPlayerAceAllowed=function(_,name)return name=='command.allowed'end,
 ExecuteCommand=function()end,GetCurrentResourceName=function()return'forge-core'end,
 AddEventHandler=function()return{}end})
local records={};aceEnv.PRCore={callback={register=function(name,fn)records[#records+1]={name=name,fn=fn}end}}
local ace=H.load('../pr_bridge/bridge/ace/server.lua',aceEnv)
assert(#records==1 and records[1].name=='pr_bridge:checkPlayerAce')
local lease=w.scopes.server.Owners.native.Reserve(records[1].name)
assert(w.scopes.server.Owners.native.Bind(lease,records[1].fn))
local seed={IsCurrent=function()return live end,Library={Library={}}}
local integration={Ace=ace,IsCurrent=function()return live end}
local e=H.environment({PRAce=false,Bridge={},source=7,GetCurrentResourceName=function()return'forge-core'end,
 IsDuplicityVersion=function()return true end,GetResourceState=function()return'started'end,
 GetResourceMetadata=function(_,key)return key=='forge_kernel_bootstrap'and'owned/1'or nil end,
 GetNumResourceMetadata=function()return 0 end,GetRegisteredCommands=function()return{}end,
 SetTimeout=function(_,fn)timers[#timers+1]=fn end,
 AddEventHandler=function(name,fn)local t={name=name,handler=fn};events[#events+1]=t;return t end,
 RemoveEventHandler=function(t)t.removed=true end,RegisterCommand=function(name,fn)commands[name]=fn end,
 GetPlayers=function()return{'7','9'}end,DoesPlayerExist=function()return true end,
 IsPrincipalAceAllowed=aceEnv.IsPrincipalAceAllowed,IsPlayerAceAllowed=aceEnv.IsPlayerAceAllowed,
 TriggerClientEvent=function(name,target,suggestion)suggestions[#suggestions+1]={event=name,target=target,name=suggestion}end,
 ExecuteCommand=function()end,Config={}})
local public={};e.pr_lib=public
e.PRCore={forgeCoreBootstrap={Public=public},callback=w.scopes.server.Native}
e.PRCore.load=function(path,target)
 if path=='@pr_bridge/bridge/ace/server'then aceLoads=aceLoads+1 end
 return H.load(path:gsub('^@pr_bridge/','../pr_bridge/'):gsub('^@forge%-core/','')..'.lua',target or e)
end
e.exports=setmetatable({},{__call=function()end})
local entry={Foundation={Seed=seed},Providers={Integrations=integration}}
local config=H.load('kernel/pr_integration/core_runtime_configuration.lua',H.environment())({environment=e,
 profile={Generation='join',Get=function()return{instance='ox'}end},getCandidate=function()return{GetPreparedEntry=function()return entry end}end})
local register=config.PhysicalOptions.registration.prCommand
assert(register('public',{},function()executed=executed+1 end))
assert(register('denied',{restricted=true},function()executed=executed+1 end))
assert(register('allowed',{restricted=true},function()executed=executed+1 end))
assert(#events==1 and events[1].name=='playerJoining')
local before=w.scopes.server.Progress().leases
events[1].handler() -- pre-fix: owned_registration.lua registration outside owned capture
assert(aceLoads==0,'join must not load a second ACE module or register an unowned callback')
local function contains(target,name)
 for _,s in ipairs(suggestions)do if s.target==target and s.name=='/'..name then return true end end
 return false
end
assert(contains(7,'public')and contains(7,'allowed')and not contains(7,'denied'),'ACL filters suggestions')
commands.denied(7,{},'denied');assert(executed==0,'unauthorized command must stay denied')
commands.allowed(7,{},'allowed');assert(executed==1)
commands.denied(9,{},'denied');assert(executed==2,'existing PR admin whitelist remains effective')
timers[1]();assert(contains(9,'denied')and aceLoads==0,'online-player fanout reuses ACE')
assert(w.scopes.server.Progress().leases==before,'join/command/timer must not add RPC leases')
live=false;local count=#suggestions;events[1].handler();timers[1]();assert(#suggestions==count,'seed revocation fences observers')
assert(config.Close());assert(w.scopes.server.Owners.native.Release(lease));w.close()
print('PASS first join and suggestion timer reuse installed ACE; no duplicate RPC/module; command ACL/admin whitelist retained; closed seed fenced')
