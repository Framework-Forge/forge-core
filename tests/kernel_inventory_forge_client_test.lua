local H=dofile('tests/kernel_harness.lua');local base='../../../[ox]/ox_inventory/'
local f=assert(io.open(base..'modules/bridge/forge/client.lua','rb'),'Forge inventory client branch missing');f:close()
local events,loads={},{};local effects={close=0,disarm=0,reset=0,shops=0};local sent=0
local e=H.environment({client={drops={}},PlayerData={loaded=false,groups={}},
 AddEventHandler=function(name,fn)events[name]=fn end,RegisterNetEvent=function(name,fn)events[name]=fn end,
 TriggerServerEvent=function()sent=sent+1 end,TriggerEvent=function()sent=sent+1 end})
e.pr_lib={table={contains=function(list,v)for _,x in pairs(list)do if x==v then return true end end;return false end},
 print={error=function(err)error('bridge unexpectedly failed: '..tostring(err))end}}
local libs={['modules.shops.client']={wipeShops=function()effects.shops=effects.shops+1 end},
 ['modules.utils.client']={DeleteEntity=function()error('no entities in fixture')end},
 ['modules.weapon.client']={Disarm=function()effects.disarm=effects.disarm+1 end},['modules.items.client']={},
 ['modules.state.client']={reset=function()effects.reset=effects.reset+1 end}}
e.require=function(path)return assert(libs[path],path)end
e.pr_lib.load=function(path)loads[#loads+1]=path;return H.load(base..path:gsub('%.','/')..'.lua',e)end
e.shared={framework='forge'};e.OnPlayerData=function(key,value)assert(e.PlayerData[key]==value)end
e.client.closeInventory=function()effects.close=effects.close+1 end
H.load(base..'modules/bridge/client.lua',e)
assert(e.pr_lib and #loads==1 and loads[1]=='modules.bridge.forge.client','actual framework selector resolves Forge')
e.PlayerData.loaded=true;events['qbx_core:client:onGroupUpdate']('police',2);assert(e.PlayerData.groups.police==2)
assert(e.client.hasGroup({police=1})=='police')
events['qbx_core:client:onGroupUpdate']('police',false);assert(e.PlayerData.groups.police==nil)
events['qbx_core:client:setGroups']({ambulance=3});assert(e.client.hasGroup({ambulance={1,3}})=='ambulance')
assert(e.client.setPlayerStatus({hunger=15})==nil and sent==0,'consumption/status effects stay server-owned')
events['pr_bridge:client:OnPlayerUnloaded']();assert(not e.PlayerData.loaded and effects.close==1 and effects.disarm==1 and effects.reset==1)
events['QBCore:Client:OnPlayerUnload']();assert(effects.close==1,'duplicate legacy unload is idempotent')
print('PASS actual inventory Forge client selection; PR retained, group replacement/removal/grade filtering, server-owned status, idempotent unload; no core exports or writes')
