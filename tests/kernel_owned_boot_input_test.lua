local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local H=N.H;local calls=0
for _,side in ipairs({'server','client'})do
 local e=H.environment({});setmetatable(e,{__index=function(_,key)return function()error('unexercised Cfx:'..key)end end})
 local names={};for _,target in pairs(req('kernel.entry.'..side..'_engine_schema')())do if target:sub(1,1)~='$'then names[target]=true end end
 for _,key in ipairs({'GetCurrentResourceName','IsDuplicityVersion','GetGameName','LoadResourceFile','SaveResourceFile','Wait','CreateThread','SetTimeout','GetGameTimer','GetConvar','GetConvarInt','GetResourceState','GetResourceMetadata','GetInvokingResource','AddEventHandler','RemoveEventHandler','RegisterNetEvent','RegisterCommand','GetVehicleNumberPlateText','vec4','vec3','joaat','TriggerEvent','PerformHttpRequest'})do names[key]=true end
 for key in pairs(names)do e[key]=function()calls=calls+1;error('must not invoke:'..key)end end
 e.GetCurrentResourceName=function()return'forge-core'end;e.IsDuplicityVersion=function()return side=='server'end
 e.exports={};e.json={};e.os=os;e.math=math;e.coroutine=coroutine;e.promise={new=function()return{}end};e.Citizen={Await=function(x)return x end};e.LocalPlayer={state={}}
 local fn=function()return true end;local p={environment=e,prCore={load=function()error('no PR loading')end},targetSelection='native',public={settings={get=function()end}},registration={available=fn,prCommand=fn,oxCommand=fn,publishExport=fn},
 barrier={WrapIngress=fn,IsIngressOpen=fn},isReady=fn,isCurrent=fn,inventoryBridgeProbe=fn,pullLocale=fn,onError=error}
 local o=req('kernel.entry.physical_boot_options_v3')(p)(side)
 assert(o.foundation.native==o.support.native and o.support.native==o.providers.native)
 assert(o.bootstrap.registration.available==o.foundation.registration.available and o.base==nil and o.seed==nil)
 assert(calls==0 and o.constructionApproved==nil)
 local contract=req('kernel.entry.owned_boot_input_contract');local info=function()return{source='@native/virtual.lua'}end
 assert(contract.Inspect(o,side,info).accepted)
 assert(not contract.Inspect(o,side,function(fn)return debug.getinfo(fn,'S')end).accepted)
 o.base={};assert(not contract.Inspect(o,side,info).accepted);o.base=nil
 if side=='client'then
  assert(o.providers.capabilities==nil and o.providers.targetSelection=='native')
  o.providers.capabilities={};assert(not contract.Inspect(o,side,info).accepted);o.providers.capabilities=nil
  o.providers.targetSelection='ox';assert(not contract.Inspect(o,side,info).accepted)
 end
 e.Wait=false;assert(not pcall(req('kernel.entry.physical_boot_options_v3')(p),side))
end
print('PASS226 native options/owner225 contract on both sides;legacy capability injection/duplicate state/origin/selection refused;no seed')
