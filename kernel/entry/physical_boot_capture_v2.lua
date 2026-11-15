-- Capture installed Cfx functions without constructing raw/base/cache/seed or approving activation.
local serverSchema=require 'kernel.entry.server_engine_schema'
local clientSchema=require 'kernel.entry.client_engine_schema'
return function(ports)
 local e,pr=assert(ports.environment),assert(ports.prCore)
 local reg,barrier=assert(ports.registration),assert(ports.barrier)
 for _,name in ipairs({'available','prCommand','oxCommand','publishExport'})do assert(type(reg[name])=='function','publication coordinator required:'..name)end
 for _,name in ipairs({'WrapIngress','IsIngressOpen'})do assert(type(barrier[name])=='function','activation barrier required:'..name)end
 local current,ready=assert(ports.isCurrent),assert(ports.isReady)
 local probe,pull=assert(ports.inventoryBridgeProbe),assert(ports.pullLocale)
 local function need(name)local value=e[name];assert(type(value)=='function','Cfx function required:'..name);return value end
 return function(side)
  assert(side=='server'or side=='client','physical option side required')
  assert(need('GetCurrentResourceName')()=='forge-core'and (not not need('IsDuplicityVersion')())==(side=='server'),'physical option resource/side mismatch')
  local n={};local names={'GetCurrentResourceName','IsDuplicityVersion','GetGameName','LoadResourceFile',
   'Wait','CreateThread','SetTimeout','GetGameTimer','GetConvar','GetConvarInt','GetResourceState','GetResourceMetadata','GetInvokingResource',
   'AddEventHandler','RemoveEventHandler','RegisterNetEvent','RegisterCommand','GetVehicleNumberPlateText','vec4','vec3','joaat','TriggerEvent'}
  local extra=side=='server'and{'SaveResourceFile','TriggerClientEvent','GetPlayerIdentifiers','GetPlayerIdentifierByType','GetPlayerIdentifier','GetNumPlayerIdentifiers',
   'GetPlayerName','GetPlayerPed','SetPedArmour','Player','DoesEntityExist','GetEntityCoords','GetEntityHeading','SetVehicleDoorsLocked','PerformHttpRequest'}or{
   'PlayerId','PlayerPedId','GetPlayerServerId','GetVehiclePedIsIn','GetVehicleMaxNumberOfPassengers','GetPedInVehicleSeat',
   'GetCurrentPedWeapon','GetSelectedPedWeapon','AddStateBagChangeHandler','RemoveStateBagChangeHandler',
   'RegisterKeyMapping','IsPauseMenuActive','GetControlInstructionalButton','RequestScriptAudioBank','GetSoundId',
   'PlaySoundFromCoord','PlaySoundFromEntity','PlaySoundFrontend','ReleaseSoundId'}
  for _,name in ipairs(names)do n[name]=need(name)end
  for _,name in ipairs(extra)do n[name]=need(name)end
  for _,target in pairs((side=='server'and serverSchema or clientSchema)())do if target:sub(1,1)~='$'then n[target]=need(target)end end
  local running=assert(e.coroutine.running);local loadPR=function(path,target)return pr.load(path,target or e)end
  local adjuncts={newPromise=assert(e.promise.new),awaitPromise=assert(e.Citizen.Await)}
  if side=='server'then
   local wall=assert(e.os,'server os library required')
   adjuncts.time,adjuncts.date=assert(wall.time),assert(wall.date)
  end
  local registration={running=running,getSource=function()return e.source end,available=reg.available,
   publishExport=reg.publishExport,prCommand=reg.prCommand,oxCommand=reg.oxCommand}
  local f={side=side,native=n,environment=e,registration=registration,json=assert(e.json),public=assert(ports.public),
   compile=need('load'),loadPR=loadPR,running=running,pullLocale=pull,inventoryBridgeProbe=probe,adjuncts=adjuncts}
  local support={native=n,environment=e,external=assert(e.exports),loadPR=loadPR,running=running,onError=assert(ports.onError)}
  local p={prCore=pr,isCurrent=current,foundation=f,support=support,
   providers={native=n,environment=e,external=e.exports,loadPR=loadPR,running=running,onError=ports.onError,isCurrent=current,isReady=ready},
   profile={side=side,prCore=pr,public=ports.public,environment=e,external=e.exports,loadPR=loadPR,barrier=barrier,
    nativeAdjuncts=adjuncts,random=e.math.random,running=running,onError=ports.onError},
   bootstrap={registration={available=reg.available}}}
  if side=='client'then
   local public=assert(ports.public);local bound;local settings={get=function(...)
    assert(current()==true,'settings owner expired');local value=assert(public.settings,'settings not prepared')
    bound=bound or value;assert(bound==value,'settings owner replaced');return value.get(...)
   end}
   p.profile.progress={localPlayer=assert(e.LocalPlayer),settings=settings,settingsOwner=public}
  end
  return p
 end
end
