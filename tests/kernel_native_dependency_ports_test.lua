local H=dofile('tests/kernel_harness.lua');local path='../pr_bridge/bridge/delivery/forge_dependency_ports.lua'
for _,side in ipairs({'server','client'})do
 local states={pr_bridge='started',ox_lib='missing'};local versions={ox_inventory='2.42.1',ox_lib='1.0.0'};local traces={};local current=true
 local env=H.environment({print=function(...)traces[#traces+1]=table.pack(...)end})
 local n={GetCurrentResourceName=function()return'forge-core'end,GetInvokingResource=function()return nil end,
 GetResourceState=function(resource)return states[resource]or'missing'end,GetResourceMetadata=function(resource)return versions[resource]end}
 local function loadPR(path,target)return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end
 local a=H.load(path,H.environment())({side=side,native=n,environment=env,loadPR=loadPR,isCurrent=function()return current end})
 assert(#traces==0 and a.CheckDependency('ox_lib','3.20.0',false))
 assert(a.CheckDependency('ox_inventory','2.42.1',false));local ok,reason=a.CheckDependency('ox_inventory','2.43.0',false);assert(not ok and reason:find('2.43.0',1,true))
 states.ox_lib='started';assert(not a.CheckDependency('ox_lib','3.20.0',false),'original OX must retain its actual version')
 states.ox_lib='missing';states.pr_bridge='stopped';assert(not a.CheckDependency('ox_lib','3.20.0',false))
 states.pr_bridge='started';a.Close();assert(not pcall(a.CheckDependency,'ox_inventory','1.0.0',false))
end
print('PASS191 installed PR github/config/OX contract on both sides;original-vs-alias version,no HTTP/framework bootstrap,revocation')
