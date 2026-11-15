local H=dofile('tests/kernel_native_foundation_harness.lua').H
local function loadPR(path,env)return H.load('../pr_bridge/'..path..'.lua',env or H.environment())end
local create=loadPR('bridge/frameworks/forge/core_runtime_configuration')
for _,side in ipairs({'server','client'})do
 local published,commands={},{};local e=H.environment({GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return side=='server'end,
 GetRegisteredCommands=function()return commands end,GetNumResourceMetadata=function()return 0 end,
 GetResourceMetadata=function(_,key)return key=='forge_kernel_bootstrap'and'owned/1'end,GetResourceState=function()return'started'end})
 e.exports=setmetatable({ox_inventory={ForgeOwnedHookSnapshot=function()return{owner='forge-core',generation='g273'}end,
 ForgePrActivationControl=function(_,op,g,i)assert(op=='Describe'and g=='g273'and i=='ox273');return{phase='prepared'}end},
 ['Renewed-Banking']={ForgeBankingReadiness=function()return{generation='g273',phase='loading'}end},pr_carkeys={ForgeKeysReadiness=function()return{generation='g273',ready=true}end}},
 {__call=function(_,name,fn)published[name]=fn end})
 local public={};e.pr_lib=public;e.PRCore={forgeCoreBootstrap={Public=public},load=function(path,env)return loadPR(path:gsub('^@pr_bridge/',''),env)end}
 local profile={Generation='g273',Get=function()return{instance='ox273'}end};local count=0
 local candidate={GetPreparedEntry=function()return{Foundation={Seed={Library={Library={addCommand=function()count=count+1 end}}}}}end}
 local config=create({environment=e,profile=profile,getCandidate=function()return candidate end})
 assert(config.Ready()and config.PhysicalOptions.public==public and config.PhysicalOptions.inventoryBridgeProbe().phase=='prepared')
 local r=config.PhysicalOptions.registration;assert(r.available('get:characters','pr:callback:characters'))
 assert(r.available('export','x'));r.publishExport('x',function()end);assert(not r.available('export','x'))
 r.prCommand('c',{},function()end);assert(count==1 and not r.available('command','c'))
 commands[1]={name='foreign'};assert(not r.available('command','FOREIGN'))
 assert(config.Close()and config.Progress().complete and not config.Ready())
end
print('PASS273 actual namespace/PR command adapter with explicit physical source and public;external collision/closed owner refused;no framework route')
