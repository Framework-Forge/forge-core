--278: physical read-only checks behind PR;no test purchase/key grant/balance mutation.
return function(p)
 local e,profile=assert(p.environment),assert(p.profile);local current=assert(p.isCurrent)
 local generation=profile.Generation;local server=e.IsDuplicityVersion();local decisions=assert(p.decisions)
 local function module(path)return e.PRCore.load('@pr_bridge/'..path,e)end
 local inventory=module('bridge/inventories/ox/forge_control')(e)
 local banking=module('bridge/banking/renewed/forge_control')(e)
 local keys=module('bridge/vehicle_key/pr_carkeys/forge_control')(e)
 local queries={ForgeOwnedHookSnapshot=inventory.GetOwnedHookSnapshot,ForgeBankingReadiness=banking.Readiness,ForgeKeysReadiness=keys.Readiness}
 local function remote(resource,method)
  local ok,value=pcall(assert(queries[method],'unknown readiness query'))
  if ok and type(value)=='table'and value.generation==generation then return value end
 end
 local function serverCommitted()
  -- Forge: sem statebag. Le a convar replicada publicada em boot_runtime_entry.
  local raw=e.GetConvar('forge:coreActivation','')
  if raw==''then return false end
  local ok,s=pcall(e.json.decode,raw)
  return ok and type(s)=='table'and s.generation==generation and s.ingressOpen==true
 end
 local function owner(g)return current()and g==generation end
 local proofs={}
 function proofs.decisions(g)
  return owner(g)and decisions.sameBase==true and decisions.legacyCompat=='pr_bridge' and decisions.preserveData==true
   and decisions.legacyConversion=='disabled-for-initial-test'
 end
 function proofs.environment(g,graph,raw,entry)
  if not owner(g)then return false end
  if not server then return serverCommitted()end
  local bank=remote('Renewed-Banking','ForgeBankingReadiness')
  local keys=remote('pr_carkeys','ForgeKeysReadiness')
  return bank and bank.phase=='ready'and bank.query==true and bank.transaction==true
   and keys and keys.resource=='pr_carkeys'and keys.ready==true and keys.contractOnly==true or false
 end
 function proofs.oxHooks(g,graph,raw)
  if not owner(g)then return false end
  if not server then return serverCommitted()end
  local s=remote('ox_inventory','ForgeOwnedHookSnapshot')
  local r=raw.Services.Inventory.Progress()
  return s and s.owner=='forge-core'and s.duplicates==0 and s.count==r.residual and r.unknown==0 and r.removeFailed==0 or false
 end
 function proofs.catalogs(g,graph,raw)
  if not owner(g)then return false end
  if not server then return serverCommitted()end
  local part=graph.Central and graph.Central.Parts and graph.Central.Parts.Inventory
  local inventory=part and part.Service
  if not inventory or type(inventory.items)~='table'then return false end
  local provider=raw.Services.Inventory
  for name,item in pairs(inventory.items)do
   local exists,actual=provider.HasItemDefinition(name)
   if not exists or type(actual)~='table'or (actual.disabled==true)~=(item.active==false)then return false end
  end
  for _,group in ipairs({'ammo','components'})do for name,item in pairs(inventory.weaponInventory[group])do
   local exists=provider.HasItemDefinition(name)
   if (exists==true)~=(item.active~=false)then return false end
  end end
  local weapons=graph.Central.Parts.Weapons
  if not weapons or not weapons.Registry then return false end
  for name,item in pairs(weapons.Registry.getWeapons())do
   local exists,actual=provider.HasWeaponItem(name)
   if not exists or type(actual)~='table'or (actual.disabled==true)~=(item.active==false)then return false end
  end
  return true
 end
 function proofs.banking(g,graph,raw)
  if not owner(g)then return false end
  if not server then return serverCommitted()end
  local s=remote('Renewed-Banking','ForgeBankingReadiness')
  return s and s.phase=='ready'and raw.Services.Banking.Progress().phase=='open'or false
 end
 function proofs.keys(g,graph,raw)
  if not owner(g)then return false end
  if not server then return serverCommitted()end
  local s=remote('pr_carkeys','ForgeKeysReadiness')
  return s and s.ready==true and s.contractOnly==true and raw.Services.Keys.Progress().phase=='open'or false
 end
 return proofs
end
