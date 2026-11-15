-- Explicit18-domain input for187/48. State/services remain owned by the assemblies.
local names={'MultiJob','Staff','Skills','AutoMedic','Access','Settings','World','Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','PlayerAdmin','CharacterAdmin'}
return function(f,s,v,library,integrations,ports)
 assert(f.Side=='server'and f.IsCurrent(),'current server domain foundation required')
 local raw,config=assert(ports.services),assert(ports.config);local clock=v.Clock;local codec=f.Seed.IO.Codec
 local out,libraries={},{};local trans=assert(ports.translate);local nativePrint=assert(ports.environment.print)
 local function input(extra)
  local p={library=library,native={},translate=trans,json=codec,time=clock.time,resource='forge-core',
   adminAce=config.AdminAce,notifyPosition=config.NotifyPos}
  for k,x in pairs(extra or{})do p[k]=x end;return p
 end
 local op,defs=raw.Operations,raw.Inventory
 out.MultiJob=input({prisonProvider=integrations.Prison})
 out.Staff=input({aceIntegration=integrations.Ace})
 out.Skills=input({integrations=integrations.Skill,progression=integrations.Progression})
 out.AutoMedic=input({inventoryIntegration={isReady=op.IsReady,clearInventoryRaw=op.Raw.ClearInventory}})
 out.Access=input({webhookIntegration=integrations.Webhook})
 out.Settings=input();out.World=input()
 out.Vehicles=input({catalogFile=integrations.CatalogFile,compile=v.Compile,vehicleIntegration=raw.Keys.Integration})
 for _,name in ipairs({'Vinewood','Objects','Npcs','Spotlights','Billboards'})do out[name]=input()end
 out.Stores=input({clock=clock,inventoryIntegration={resourceState=op.ResourceState,readShopFile=op.ReadShopFile,
  addItemRaw=op.Raw.AddItem,removeItemRaw=op.Raw.RemoveItem,searchCountRaw=op.Raw.searchCountRaw,itemsRaw=op.Raw.Items,
  onPurchaseResult=integrations.Purchases.onPurchaseResult,removePurchaseResult=integrations.Purchases.removePurchaseResult}})
 out.Farms=input({clock=clock,math=assert(library.math),inventoryIntegration={resourceState=op.ResourceState,addItemRaw=op.Raw.AddItem,
  searchSlotsRaw=op.Raw.searchSlotsRaw,setDurabilityRaw=op.Raw.SetDurability,itemsRaw=op.Raw.Items}})
 out.Starterpack=input({clock=clock,print=nativePrint,inventoryIntegration={resourceState=op.ResourceState,canCarryRaw=op.Raw.CanCarryItem,addItemRaw=op.Raw.AddItem}})
 out.PlayerAdmin=input({clock=clock,print=nativePrint,managementIntegration=integrations.Management})
 out.CharacterAdmin=input({clock=clock,print=nativePrint})
 for _,name in ipairs(names)do assert(out[name]);libraries[name]=library end
 return {domains=out,libraries=libraries}
end
