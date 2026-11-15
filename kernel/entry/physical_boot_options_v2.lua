-- Revision219:client provider ownership/progress inputs, preserving immutable211.
local capture=require 'kernel.entry.physical_boot_options'
return function(p)
 local build=capture(p)
 return function(side)
  local options=build(side)
  if side=='client'then
   options.providers.prCore=assert(p.prCore)
   options.providers.capabilities=assert(p.clientCapabilities,'owned PR client capabilities required')
   -- Progress160 needs these explicit Cfx functions,including names not used by core177.
   for _,name in ipairs({'ExecuteCommand','GetCurrentResourceName','GetInvokingResource','GetGameTimer','Wait','PlayerPedId','PlayerId',
    'IsEntityDead','IsPedRagdoll','IsPedCuffed','IsPedFalling','IsPedSwimming','IsModelAPed','IsModelAVehicle','GetModelDimensions',
    'DisableControlAction','DisablePlayerFiring','IsControlJustPressed','TaskPlayAnim','TaskStartScenarioInPlace','StopAnimTask',
    'ClearPedTasks','TriggerEvent','TriggerServerEvent'})do
    local fn=p.environment[name];assert(type(fn)=='function','client Cfx input required:'..name);options.foundation.native[name]=fn
   end
  end
  return options
 end
end
