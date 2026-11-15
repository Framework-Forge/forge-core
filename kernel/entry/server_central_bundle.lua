-- Concrete13-part input for186/47. No QBX forwarding or adopted player state.
return function(f,s,v,library,integrations,ports)
 assert(f.Side=='server'and f.IsCurrent(),'current server central foundation required')
 local raw=assert(ports.services);local rpc=assert(ports.rpc);local config=assert(ports.config)
 local codec=f.Seed.IO.Codec;local n=f.Seed.Execution.Native;local clock=v.Clock
 local platform=v.Platform.Player();platform.getIdentifiers=v.Platform.Select({'GetPlayerIdentifiers'}).GetPlayerIdentifiers
 local function localSupport()return assert(f.Base.ServerSupportContext,'canonical internal support not constructed')end
 local logger={log=function(...)return localSupport().Logger.log(...)end}
 local function trigger(...)return localSupport().Hooks.Hooks.trigger(...)end
 local time=clock.time;local trans=assert(ports.translate);local lib=assert(library)
 local function part(extra)
  local out={library=lib,native={},time=time,translate=trans,json=codec,resource='forge-core',
   notifyPosition=config.NotifyPos,adminAce=config.AdminAce}
  for k,x in pairs(extra or{})do out[k]=x end;return out
 end
 local inv=assert(raw.Operations.Raw);local defs=assert(raw.Inventory);local keys=assert(raw.Keys)
 local parts={
  session={player={config=v.Server,defaultSpawn=v.Shared.defaultSpawn,db=v.Database.Database,json=codec,library=lib,
   platform=platform,inventory=inv,logger=logger,triggerHook=trigger,counters=v.Counters,settings=v.Settings,
   utils={},warn=assert(lib.print.warn),date=clock.date,resource='forge-core'},
   status={config=v.Server.player.status,awaitSnapshot=assert(rpc.Ox.await)},getBucket=v.GetBucket,
   delivery={getResourceState=s.Cache.Ports.getResourceState,writeCache=s.Cache.Ports.accessCacheState,emit=s.Cache.Ports.emit}},
  slots={db=v.Database.Database,json=codec,calendar=clock,native={}},
  lifecycle=part({config=v.Server,logger=logger,globalState=v.GlobalState,newPromise=v.NewPromise,clock=assert(ports.environment.os.clock),
   queue={enabled=n.GetConvar('qbx:enablequeue','true')~='false',maxPlayers=n.GetConvarInt('sv_maxclients',48)},
   notify=assert(lib.notify.NotifyPlayer),date=clock.date,resource='forge-core',serverName=v.Shared.serverName,
   notifyPosition=v.Shared.notifyPosition,querySchema=v.Database.Database.query.await,
   disablePersistence=function(...)return assert(f.Base.Helpers,'canonical Helpers not constructed').Persistence.DisablePersistence(...)end}),
  runtime=part({config=v.Server,logger=logger,globalState=v.GlobalState,newPromise=v.NewPromise,awaitPromise=v.AwaitPromise,random=v.Random,
   locale=f.Locale,removeKeyItem=keys.VehicleKey.RemoveKeyItem,
   chatMessage=function(target,data)return s.Sound.Ports.sendClient('chat:addMessage',target,data)end}),
  character=part({config=v.Server,starterItems=v.Shared.starterItems,logger=logger,locale=f.Locale,inventory=inv,documents=integrations.Documents}),
  catalog=part({config=config.Job}),jobs=part({dependencies={},command=config.Command}),
  finance=part({vipConfig=config.Vip,integrations={inventoryReady=raw.Operations.IsReady,applyPlayerInventoryBonus=inv.ApplyPlayerInventoryBonus}}),
  business=part({integrations={inventoryReady=defs.InventoryReady,removeInventoryHooks=defs.RemoveHooks,httpRequest=s.Logging.DeliveryPorts.httpRequest}}),
  inventory=part({config=config.Inventory,compile=v.Compile,integrations={inventoryReady=defs.InventoryReady,inventoryState=defs.InventoryState,
   setItemDefinition=defs.SetItemDefinition,disableItemDefinition=defs.DisableItemDefinition,removeItemDefinition=defs.RemoveItemDefinition}}),
  consumption=part({integrations=integrations.Consumption}),
  weapons=part({config=config.Weapons,integrations={inventoryReady=defs.InventoryReady,inventoryState=defs.InventoryState,
   SetWeaponItem=defs.SetWeaponItem,DisableWeaponItem=defs.DisableWeaponItem,RemoveWeaponItem=defs.RemoveWeaponItem,HasWeaponItem=defs.HasWeaponItem}}),
  transport=part({config=config})
 }
 return {parts=parts,library=lib,database=v.Database.Database,platform=platform}
end
