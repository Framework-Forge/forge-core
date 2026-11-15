--245: capture the installed Cfx/PR ports;never resolve a framework or call an inventory export.
local names={server={"CreateThread","CreateVehicle","DoesEntityExist","DropPlayer","GetConvar","GetEntityCoords","GetEntityHeading","GetInvokingResource","GetPlayerIdentifierByType","GetPlayerPed","GetPlayerPing","GetPlayers","GetResourceState","GetVehiclePedIsIn","IsPlayerAceAllowed","NetworkGetEntityFromNetworkId","NetworkGetEntityOwner","NetworkGetNetworkIdFromEntity","TaskWarpPedIntoVehicle","TriggerClientEvent","TriggerEvent","Wait","joaat","vec4"},client={"AttachEntityToEntity","ClearVehicleCustomPrimaryColour","ClearVehicleCustomSecondaryColour","CreateObject","CreateVehicle","DoesEntityExist","ExecuteCommand","GetActivePlayers","GetClockHours","GetClockMinutes","GetConvar","GetEntityBoneIndexByName","GetEntityCoords","GetEntityHeading","GetEntityType","GetGameBuildNumber","GetGamePool","GetGroundZFor_3dCoord","GetPedBoneIndex","GetPedInVehicleSeat","GetVehicleColours","GetVehicleExtraColours","GetVehicleHeadlightsColour","GetVehicleWheelHealth","GetWorldPositionOfEntityBone","IsModelInCdimage","IsVehicleDoorDamaged","IsVehicleWindowIntact","NetworkGetEntityFromNetworkId","NetworkGetEntityIsNetworked","NetworkGetEntityOwner","NetworkGetNetworkIdFromEntity","RemoveVehicleWindow","SetDriftTyresEnabled","SetModelAsNoLongerNeeded","SetNetworkIdCanMigrate","SetParticleFxLoopedAlpha","SetParticleFxLoopedColour","SetParticleFxLoopedEvolution","SetParticleFxNonLoopedAlpha","SetParticleFxNonLoopedColour","SetPtfxAssetNextCall","SetVehRadioStation","SetVehicleAutoRepairDisabled","SetVehicleBodyHealth","SetVehicleColours","SetVehicleCustomPrimaryColour","SetVehicleCustomSecondaryColour","SetVehicleDashboardColor","SetVehicleDirtLevel","SetVehicleDoorBroken","SetVehicleEngineHealth","SetVehicleExtra","SetVehicleExtraColours","SetVehicleFuelLevel","SetVehicleHasBeenOwnedByPlayer","SetVehicleHeadlightsColour","SetVehicleInteriorColor","SetVehicleLivery","SetVehicleMod","SetVehicleModColor_1","SetVehicleModColor_2","SetVehicleModKit","SetVehicleNeedsToBeHotwired","SetVehicleNeonLightEnabled","SetVehicleNeonLightsColour","SetVehicleNumberPlateText","SetVehicleNumberPlateTextIndex","SetVehicleOilLevel","SetVehiclePetrolTankHealth","SetVehicleRoofLivery","SetVehicleTyreBurst","SetVehicleTyreSmokeColor","SetVehicleTyresCanBurst","SetVehicleWheelHealth","SetVehicleWheelSize","SetVehicleWheelType","SetVehicleWheelWidth","SetVehicleWindowTint","SetVehicleXenonLightsColor","StartParticleFxLoopedAtCoord","StartParticleFxLoopedOnEntity","StartParticleFxLoopedOnEntityBone","StartParticleFxNonLoopedAtCoord","StartParticleFxNonLoopedOnEntity","StartParticleFxNonLoopedOnPedBone","StopParticleFxLooped","TaskWarpPedIntoVehicle","ToggleVehicleMod","TriggerEvent","TriggerServerEvent","UseParticleFxAssetNextCall","Wait","joaat","vec2","vec3","vec4"}}
return function(p)
 local environment=assert(p.environment)
 return function(graph,side,entry,origin)
  assert(side=='server'or side=='client');assert(entry.Bootstrap.Graph==graph,'compatibility port graph mismatch')
  local f=assert(entry.Foundation);assert(f.Side==side and f.IsCurrent(),'compatibility foundation mismatch')
  assert(entry.ActivationOriginOwner and entry.ActivationOriginOwner.Origin==origin,'compatibility origin mismatch')
  local raw=assert(p.getRaw());local services=assert(raw.Services)
  local state=services.Progress().phase;assert(state=='prepared'or state=='open','prepared PR raw services required')
  local search=assert(services.Public.inventory.Search,'PR inventory search required')
  assert(type(search)=='function')
  local function current()return entry.IsCurrent()and f.IsCurrent()and p.isCurrent()==true end
  local native={}
  for _,name in ipairs(names[side])do
   local fn=assert(environment[name],'compatibility Cfx function required:'..name);assert(type(fn)=='function')
   native[name]=function(...)assert(current(),'compatibility Cfx ports unavailable');return fn(...)end
  end
  native.GetInvokingResource=origin.GetInvokingResource
  native.source=assert(f.Events.source,'canonical event source required')
  local providers=assert(entry.Providers,'prepared core providers required')
  assert(providers.IsCurrent(),'prepared core providers not current')
  local library=assert(providers.Library,'prepared core provider library required')
  local ports={native=native,lib=library,library=library,isCurrent=current,isReady=current,
   inventory={search=function(...)assert(current(),'compatibility inventory unavailable');return search(...)end}}
  if side=='server'then
   local legacy=assert(p.legacyConversion,'explicit legacy conversion ports/gate required')
   ports.convertItems=assert(legacy.convertItems);ports.inventoryItems=assert(legacy.inventoryItems);ports.legacyItems=assert(legacy.legacyItems)
  else
   ports.sharedConfig=assert(p.sharedConfig,'prepared client shared config required')
   local createThread,wait=assert(environment.CreateThread),assert(environment.Wait)
   ports.scheduler={createThread=function(fn)assert(current());return createThread(fn)end,wait=wait}
  end
  return ports
 end
end
