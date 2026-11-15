-- Concrete central49 inputs. All PlayerData/status/character state remains assembly-owned.
return function(f,s,library,integrations,p)
 assert(f.Side=='client'and f.IsCurrent(),'client central bundle required')
 local u=s.Utilities;local n=f.Seed.Execution.Bind({'vec4'})
 local shared=f.Seed.Registry.Require('kernel.config.shared')({vec4=n.vec4})
 local cache=s.Cache.Ports
 local audio=setmetatable({},{__index=function(_,name)return function(...)
  assert(f.IsCurrent(),'client foundation unavailable')
  return assert(f.Base.ClientMediaContext,'client media not prepared').Media.Audio[name](...)
 end end})
 return{library=library,rpc=assert(p.rpc),config={Inventory=assert(p.config.Inventory)},random=u.Random,strsplit=u.Strsplit,
  audio=audio,delivery={getResourceState=cache.getResourceState,writeCache=cache.accessCacheState,emit=cache.emit},
  notify=assert(library.Notify),notifyPosition=p.config.NotifyPos,searchInventory=assert(p.services.Public.inventory.Search),
  globalState={},streaming={requestModel=assert(library.requestModel),requestAnimDict=assert(library.requestAnimDict)},
  setPedAppearance=integrations.SetPedAppearance,defaultSpawn=shared.defaultSpawn,ui=assert(p.ui),
  characterIntegrations=integrations.Character,groupdigits=assert(u.Groupdigits),consumptionIntegrations=integrations.Consumption}
end
