local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local H=N.H;local calls=0
for _,side in ipairs({'server','client'})do
 local e=H.environment({});setmetatable(e,{__index=function(_,key)return function()error('unexercised Cfx:'..key)end end})
 local names={};for _,target in pairs(req('kernel.entry.'..side..'_engine_schema')())do if target:sub(1,1)~='$'then names[target]=true end end
 for _,key in ipairs({'GetCurrentResourceName','IsDuplicityVersion','GetGameName','LoadResourceFile','SaveResourceFile','Wait','CreateThread','SetTimeout','GetGameTimer','GetConvar','GetConvarInt','GetResourceState','GetResourceMetadata','GetInvokingResource','AddEventHandler','RemoveEventHandler','RegisterNetEvent','RegisterCommand','GetVehicleNumberPlateText','vec4','vec3','joaat','TriggerEvent','PerformHttpRequest'})do names[key]=true end
 for key in pairs(names)do e[key]=function()calls=calls+1;error('must not invoke:'..key)end end
 e.GetCurrentResourceName=function()return'forge-core'end;e.IsDuplicityVersion=function()return side=='server'end
 e.exports={};e.json={};e.os=os;e.math=math;e.coroutine=coroutine;e.promise={new=function()return{}end};e.Citizen={Await=function(x)return x end};e.LocalPlayer={}
 local fn=function()return true end;local p={environment=e,prCore={load=function()error('no PR loading')end},public={},registration={available=fn,prCommand=fn,oxCommand=fn,publishExport=fn},
 barrier={WrapIngress=fn,IsIngressOpen=fn},isReady=fn,isCurrent=fn,inventoryBridgeProbe=fn,pullLocale=fn,onError=error}
 p.targetSelection='native';p.originOwner=req('kernel.entry.activation_origin')({running=coroutine.running,getInvokingResource=e.GetInvokingResource,isCurrent=fn})
 e.LocalPlayer.state={}
 local o=req('kernel.entry.physical_boot_options_v5')(p)(side)
 assert(o.foundation.native==o.support.native and o.support.native==o.providers.native)
 assert(o.bootstrap.registration.available==o.foundation.registration.available and o.base==nil and o.seed==nil)
 assert(calls==0 and o.constructionApproved==nil)
 assert(req('kernel.entry.owned_boot_input_contract_v2').Inspect(o,side,function()return{source='@cfx/virtual.lua'}end).accepted)
 if side=='client'then
  assert(p.public.settings==nil and o.profile.progress.settingsOwner==p.public)
  assert(not pcall(o.profile.progress.settings.get,'locale'))
  p.public.settings={get=function(key)return key=='locale'and'pt-br'end}
  assert(o.profile.progress.settings.get('locale')=='pt-br')
  assert(not req('kernel.entry.owned_boot_input_contract_v2').Inspect(o,side,function()return{source='@cfx/virtual.lua'}end).accepted)
  p.public.settings=nil;o.profile.progress.settingsOwner={}
  assert(not req('kernel.entry.owned_boot_input_contract_v2').Inspect(o,side,function()return{source='@cfx/virtual.lua'}end).accepted)
 end
 e.Wait=false;assert(not pcall(req('kernel.entry.physical_boot_options_v5')(p),side))
end
print('PASS264 deferred client settings bound to one public owner;slot empty before seed;closed input contract and wrong-owner/missing-native refusals;no Cfx effects')
