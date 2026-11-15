local H=dofile('tests/kernel_harness.lua')
local seedCurrent,removable=true,false
local timers,events,registered={}, {}, {};local reads=0
local e=H.environment({PRAce=false,Bridge={},GetCurrentResourceName=function()return'forge-core'end,
 IsDuplicityVersion=function()return true end,GetResourceState=function()return'started'end,
 GetResourceMetadata=function(_,key)return key=='forge_kernel_bootstrap'and'owned/1'or nil end,
 GetNumResourceMetadata=function()return 0 end,GetRegisteredCommands=function()return{}end,
 SetTimeout=function(_,fn)timers[#timers+1]=fn end,
 AddEventHandler=function(name,fn)local token={name=name,handler=fn};events[#events+1]=token;return token end,
 RemoveEventHandler=function(token)if not removable then return false end;token.removed=true end,
 RegisterCommand=function(name,fn)registered[name]=fn end,
 GetPlayers=function()reads=reads+1;return{}end,IsPrincipalAceAllowed=function()return false end,
 TriggerClientEvent=function()error('empty audience must not send')end,ExecuteCommand=function()end})
local public={};e.pr_lib=public
e.PRCore={forgeCoreBootstrap={Public=public}}
e.PRCore.load=function(path,target)
 local file=path:gsub('^@pr_bridge/','../pr_bridge/'):gsub('^@forge%-core/','')
 return H.load(file..'.lua',target or e)
end
e.exports=setmetatable({},{__call=function()end})
local ace={};for _,name in ipairs({'isPlayerAceAllowed','isPrincipalAceAllowed','isAdminWhitelisted','isWhitelisted','hasFrameworkAccess','ensureAce'})do ace[name]=function()return false end end
local entry={Foundation={Seed={IsCurrent=function()return seedCurrent end,Library={Library={}}}},
 Providers={Integrations={Ace=ace,IsCurrent=function()return seedCurrent end}}}
local candidate={GetPreparedEntry=function()return entry end}
local create=H.load('kernel/pr_integration/core_runtime_configuration.lua',H.environment())
local a=create({environment=e,profile={Generation='scope',Get=function()return{instance='ox'}end},getCandidate=function()return candidate end})
assert(#timers==0 and #events==0 and next(registered)==nil,'command module stays lazy')
assert(a.PhysicalOptions.registration.prCommand('probe',{},function()end))
assert(type(registered.probe)=='function'and #timers==1 and #events==1,'one native PR provider')
assert(a.PhysicalOptions.registration.prCommand('second',{},function()end))
assert(#timers==1 and #events==1,'reuse cached provider')
seedCurrent=false;events[1].handler(2);timers[1]();assert(reads==0,'closed seed fences library callbacks before config.Close')
assert(not a.Close()and not a.Progress().complete and a.Progress().commandEvents==1,'removal refusal remains explicit')
events[1].handler(2);timers[1]();assert(reads==0,'callbacks fenced before removal retry')
removable=true;assert(a.Close()and a.Progress().complete and events[1].removed)
assert(not a.PhysicalOptions.registration.prCommand('late',{},function()end)and registered.late==nil)
assert(a.Close(),'idempotent cleanup')
print('PASS lazy PR command provider cache/seed/config fencing, late timer/event suppression, refused listener removal and retry, closed registration refusal')
