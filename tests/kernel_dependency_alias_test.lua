local H=dofile('tests/kernel_harness.lua')
local factoryPath='../pr_bridge/bridge/delivery/forge_dependency_ports.lua'
local file=assert(io.open('../pr_bridge/fxmanifest.lua','rb'));local manifest=file:read('*a');file:close()
local prVersion=assert(manifest:match('version%("([^"]+)"%)'))
local prName=assert(manifest:match('name%("([^"]+)"%)'))
assert(manifest:find('provide("ox_lib")',1,true)and prName=='pr_bridge')
for _,side in ipairs({'server','client'})do
 local states={ox_lib='started',pr_bridge='started'}
 local metadata={ox_lib={name=prName,version=prVersion},ox_inventory={name='ox_inventory',version='2.42.1'}}
 local calls,traces,current,enabled=0,{},true,true
 local env=H.environment({print=function(s)traces[#traces+1]=s end})
 local native={GetCurrentResourceName=function()return'forge-core'end,GetInvokingResource=function()end,
  GetResourceState=function(resource)calls=calls+1;return states[resource]or'missing'end,
  GetResourceMetadata=function(resource,key)calls=calls+1;return(metadata[resource]or{})[key]end}
 local function loadPR(path,target)
  local result=H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)
  if path=='@pr_bridge/bridge/config'then target.Config.compatOx_lib=enabled end
  return result
 end
 local function make()return H.load(factoryPath,H.environment())({side=side,native=native,environment=env,
  loadPR=loadPR,isCurrent=function()return current end})end
 local a=make();assert(calls==0 and #traces==0,'construction must remain passive')
 assert(a.CheckDependency('ox_lib','3.8.0',true),'started PR alias must use the OX compatibility contract')
 assert(a.CheckDependency('ox_lib','3.20.0',true)and #traces==0)
 local ok,why=a.CheckDependency('ox_lib','99.0.0',false);assert(not ok and why:find('99.0.0',1,true),'never bypass version checks')
 states.ox_lib='starting';assert(a.CheckDependency('ox_lib','3.20.0',false))
 states.ox_lib='missing';assert(a.CheckDependency('ox_lib','3.20.0',false))
 states.ox_lib='started';metadata.ox_lib={name='ox_lib',version='3.7.0'}
 ok,why=a.CheckDependency('ox_lib','3.8.0',false);assert(not ok and why:find('3.7.0',1,true),'preserve original OX version')
 metadata.ox_lib.version='3.38.0';assert(a.CheckDependency('ox_lib','3.20.0',false))
 metadata.ox_lib={version='3.7.0'};assert(not a.CheckDependency('ox_lib','3.8.0',false),'unknown provider must not be claimed as PR')
 metadata.ox_lib={name=prName,version=prVersion}
 enabled=false;local disabled=make();assert(not disabled.CheckDependency('ox_lib','3.8.0',false));assert(disabled.Close());enabled=true
 states.pr_bridge='stopped';assert(not a.CheckDependency('ox_lib','3.8.0',false));states.pr_bridge='started'
 assert(a.CheckDependency('ox_inventory','2.42.1',false));assert(not a.CheckDependency('ox_inventory','2.43.0',false))
 current=false;local before=calls;assert(not pcall(a.CheckDependency,'ox_lib','3.8.0',true)and calls==before)
 assert(a.Close()and a.Progress().complete)
end
print('PASS physical PR alias on server/client; installed metadata, passive construction, enabled/disabled, original versions, unrelated dependency, revocation')
