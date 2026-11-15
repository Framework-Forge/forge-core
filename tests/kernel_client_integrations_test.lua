local H=dofile('tests/kernel_harness.lua');local calls={};local env=H.environment()
local function loadPR(path,e)return H.load('../pr_bridge/'..path:sub(12)..'.lua',e)end
local ext={};for _,r in ipairs({'forge-loadscreen','spawnmanager','illenium-appearance','test'})do
 local proxy={};ext[r]=proxy;setmetatable(proxy,{__index=function(_,method)return function(self,...)
  assert(self==proxy);calls[#calls+1]={r,method,table.pack(...)};return true end end})
end
local n={GetResourceState=function()return'started'end,TriggerEvent=function(...)calls[#calls+1]=table.pack(...)end,
 TriggerServerEvent=function(...)calls[#calls+1]=table.pack(...)end,ExecuteCommand=function()end}
local api=loadPR('@pr_bridge/bridge/delivery/forge_client_integrations',env)({foundation={Side='client',IsCurrent=function()return true end},
 native=n,external=ext,environment=env,loadPR=loadPR})
assert(#calls==0);assert(api.Character.finishLoadingScreen());assert(calls[1][2]=='FinishLoadingScreen')
api.Work.emitClientMenu('forge-pause:client:openAdminMenu','forge_core_main','forge-core')
assert(calls[2][2]=='forge_core_main'and calls[2][3]=='forge-core')
api.Npcs.resolveExports('test').Demo(12);assert(calls[3][3][1]==12)
assert(api.Progression.client().values);assert(api.Close());assert(not pcall(api.Character.finishLoadingScreen))
assert(#calls==3)
print('PASS213 receiver-aware PR integrations; loading timer delegated intact; parent menus; NPC arguments; closed calls refused')
