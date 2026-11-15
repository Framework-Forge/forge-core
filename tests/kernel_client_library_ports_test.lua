local H=dofile('tests/kernel_harness.lua')
local prpath='../pr_bridge/'
local function loadPR(path,env)return H.load(prpath..path:sub(12)..'.lua',env)end
local calls=0;local current=true
local env=H.environment({PRDebug=false,GetCurrentResourceName=function()return'forge-core'end})
for _,k in ipairs({'GetEntityCoords','PlayerPedId','GetActivePlayers','PlayerId','GetPlayerPed'})do env[k]=function()error('unexercised query native')end end
local utils={table=loadPR('@pr_bridge/bridge/utils/tables',env),math={},string={},print={warn=function()end}}
local p={foundation={Side='client',IsCurrent=function()return current end,Public={settings={}},NativeCache={Cache={}},RegistrationInput={prCommand=function()end}},
 support={IsCurrent=function()return current end,Utilities={Library=utils},Streaming={Streaming={requestModel=function(x)return true,42 end,requestAnimDict=function(x)return true,x end}}},
 prCore={},config={},loadPR=loadPR,environment=env,rpc={Ox={await=function()end}},services={Public={inventory={}}},
 capabilities={fivem={blips={},drawtext={},gizmo={},getVehicleProperties=function()end},target={},raycast={},devtools={},devlaser={},
 getNearbyVehicles=function()end,setVehicleProperties=function()end,playAnim=function()end,openVisualAdminMenu=function()end}}
local create=loadPR('@pr_bridge/bridge/delivery/forge_client_library_ports',env)
local api=create(p);assert(not pcall(api.Library.Notify,{}))
p.prCore.forgeClientUI={Library={notify=function()calls=calls+1 end}}
p.prCore.forgeProgressScope={Library={doProgressbar=function()return true end}}
assert(api.Library.progress.doProgressbar());api.Library.Notify({});assert(calls==1)
assert(api.Library.requestModel('x')==42 and api.Library.fivem.streaming==p.support.Streaming.Streaming)
local frozen=api.Library.table.freeze({a={n=1}});assert(api.Library.table.clone(frozen).a.n==1)
assert(api.Close());assert(not pcall(api.Library.Notify,{}));assert(calls==1)
p.capabilities.target=nil;assert(not pcall(create,p))
print('PASS212 explicit client library; borrowed UI/progress; protected tables; missing providers and closed calls refused')
