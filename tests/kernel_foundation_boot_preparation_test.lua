local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local H=N.H;local calls=0
for _,side in ipairs({'server','client'})do
 local e=H.environment({});setmetatable(e,{__index=function(_,key)return function()error('unexercised Cfx:'..key)end end})
 local names={};for _,target in pairs(req('kernel.entry.'..side..'_engine_schema')())do if target:sub(1,1)~='$'then names[target]=true end end
 for _,key in ipairs({'GetCurrentResourceName','IsDuplicityVersion','GetGameName','LoadResourceFile','SaveResourceFile','Wait','CreateThread','SetTimeout','GetGameTimer','GetConvar','GetConvarInt','GetResourceState','GetResourceMetadata','GetInvokingResource','AddEventHandler','RemoveEventHandler','RegisterNetEvent','RegisterCommand','GetVehicleNumberPlateText','vec4','vec3','joaat','TriggerEvent','PerformHttpRequest'})do names[key]=true end
 for key in pairs(names)do e[key]=function()calls=calls+1;error('must not invoke:'..key)end end
 e.GetCurrentResourceName=function()return'forge-core'end;e.IsDuplicityVersion=function()return side=='server'end
 e.exports={};e.json={};e.os=os;e.math=math;e.coroutine=coroutine;e.promise={new=function()return{}end};e.Citizen={Await=function(x)return x end};e.LocalPlayer={state={}}
 local fn=function()return true end;local p={environment=e,prCore={load=function()error('no PR loading')end},public={settings={get=function()end}},registration={available=fn,prCommand=fn,oxCommand=fn,publishExport=fn},
 barrier={WrapIngress=fn,IsIngressOpen=fn},isReady=fn,isCurrent=fn,inventoryBridgeProbe=fn,pullLocale=fn,onError=error}
 p.clientCapabilities={target={},raycast={},devtools={},devlaser={},fivem={blips={},drawtext={},gizmo={},getVehicleProperties=fn},
  getNearbyVehicles=fn,setVehicleProperties=fn,playAnim=fn,openVisualAdminMenu=fn}
 for _,name in ipairs({'addBoxZone','removeZone','addLocalEntity','removeLocalEntity','disableTargeting'})do p.clientCapabilities.target[name]=fn end
 p.clientCapabilities.raycast.FromCamera=fn
 for _,name in ipairs({'placePed','placeVehicle','drawPedBox'})do p.clientCapabilities.devtools[name]=fn end
 for _,name in ipairs({'getPedImageUrl','getPropImageUrl','getVehicleImageUrl','getPropHashId'})do p.clientCapabilities.fivem.blips[name]=fn end
 p.clientCapabilities.fivem.gizmo={start=fn,stop=fn};p.clientCapabilities.fivem.drawtext.drawText3d=fn
 local o=req('kernel.entry.physical_boot_options_v2')(p)(side)
 assert(o.foundation.native==o.support.native and o.support.native==o.providers.native)
 assert(o.bootstrap.registration.available==o.foundation.registration.available and o.base==nil and o.seed==nil)
 assert(calls==0 and o.constructionApproved==nil)
 local contract=req('kernel.entry.foundation_boot_input_contract')
 local info=function()return{source='@native/virtual.lua'}end
 assert(contract.Inspect(o,side,info).accepted)
 assert(not contract.Inspect(o,side,function(fn)return debug.getinfo(fn,'S')end).accepted)
 o.base={};assert(not contract.Inspect(o,side,info).accepted);o.base=nil
 if side=='client'then
  local target=o.providers.capabilities.target;o.providers.capabilities.target=fn;assert(not contract.Inspect(o,side,info).accepted);o.providers.capabilities.target=target
 end
 local rawCalls=0;local candidate=req('kernel.entry.foundation_boot_preparation')({side=side,inspectFunction=info,
  providers={buildInput=function()return o end},createRaw=function()rawCalls=rawCalls+1 end})
 assert(candidate.Inspect().accepted and not candidate.Prepare()and rawCalls==0)
 e.Wait=false;assert(not pcall(req('kernel.entry.physical_boot_options_v2')(p),side))
end
for _,server in ipairs({true,false})do
 local core={};local rawCalls=0
 local env=N.H.environment({GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return server end,
  PRCore=core,debug=debug,load=load,print=function()end})
 env.LoadResourceFile=function(resource,path)assert(resource=='forge-core');local file=assert(io.open(path,'rb'));local text=file:read('*a');file:close();return text end
 core.load=function()rawCalls=rawCalls+1;error('missing providers must not construct')end
 N.H.load('../../../../.planning/migration/staging/219/forge-core/kernel/entry/boot_candidate_entry.lua',env)
 assert(core.forgeBootCandidate and not core.forgeBootCandidate.Inspect().accepted and rawCalls==0)
end
print('PASS219 both physical option/contract/preparation paths; origin, duplicate state, capability shape and approval gates;no raw/seed')
