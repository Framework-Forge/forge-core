local H=dofile('tests/kernel_native_foundation_harness.lua').H
local create=H.load('kernel/pr_integration/core_bootstrap.lua',H.environment())
for _,side in ipairs({'server','client'})do
 local registrations=0
 local e=H.environment({GetCurrentResourceName=function()return'forge-core'end,
 IsDuplicityVersion=function()return side=='server'end,GetResourceState=function()return'started'end,
 GetInvokingResource=function()return nil end,GetConvar=function(_,default)return default end,
 load=load,exports={pr_bridge={GetCachedState=function()return nil end}},RegisterNetEvent=function()registrations=registrations+1 end,
 AddEventHandler=function()registrations=registrations+1 end})
 local prior=getmetatable(e).__index
 getmetatable(e).__index=function(t,key)if key=='PRCore'or key=='PRDebug'or key=='PRBridgeLocale'or key=='Locale'then return nil end;return prior(t,key)end
 e.LoadResourceFile=function(resource,name)assert(resource=='pr_bridge');local f=io.open('../pr_bridge/'..name,'rb');if not f then return nil end;local t=f:read('*a');f:close();return t end
 e._G=e
 local owner=create(e);assert(e.PRCore.resource=='forge-core'and e.PRCore.context==side)
 assert(type(e.Lang)=='table'and type(e.Lang.t)=='function','minimal bootstrap must initialize the PR provider locale')
 assert(e.Lang:t('Debug.InventoryDetected',{inventory='Ox Inventory'})~='Debug.InventoryDetected','provider translations must load from installed PR files')
 if side=='server'then
  e.ActiveBridges={inventory='ox',vehicle_key='pr_carkeys'};e.exports.ox_inventory={};e.exports.pr_carkeys={}
  local inventory=e.PRCore.load('@pr_bridge/bridge/inventories/ox/server',e)
  local keys=e.PRCore.load('@pr_bridge/bridge/vehicle_key/pr_carkeys/server',e)
  assert(type(inventory.AddItem)=='function'and type(keys.GiveTempKeys)=='function')
 end
 assert(owner.Public==e.pr_lib and e.Bridge==e.pr_lib)
 assert(e.PRCore.callback._transportInstalled==nil and rawget(e.PRCore,'forgeOwnedCallbacks')==nil)
 assert(rawget(e.pr_lib,'settings')==nil and rawget(e.pr_lib,'cache')==nil)
 assert(registrations==0 and not pcall(create,e))
end
print('PASS272 real PR primitives loaded on both sides without framework/callback/cache/settings or registration;duplicate/full bootstrap refused')
