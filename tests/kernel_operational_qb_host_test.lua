local f=assert(io.open('../../../../.planning/migration/staging/279/pr_bridge/bridge/compat/qb/host.lua','rb'));local code=f:read('*a');f:close()
for _,side in ipairs({'server','client'})do
 local published={};local object={Shared={Jobs={}}};local reads=0
 local env=setmetatable({ActiveBridges={frameworks='forge'},PRCore={forgeLateBinding={NativeHost={GetCoreObject=function(filters)reads=reads+1;assert(filters=='filters');return object end}}},
 exports=function(name,fn)assert(name=='getQBCoreObject');published[name]=fn end,
 GetResourceState=function()error('no guessing original core from resource name')end,
 AddEventHandler=function()error('no duplicate QB aliases')end,RegisterNetEvent=function()error('no second QB callbacks')end},{__index=_G})
 assert(load(code,'@@pr_bridge/bridge/compat/qb/host.lua','t',env))()
 assert(reads==0 and published.getQBCoreObject('filters')==object and reads==1)
end
print('PASS279 Forge QB host returns the same native object;does not misclassify QBX shim or create QB aliases/callback runtime')
