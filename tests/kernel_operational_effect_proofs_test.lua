local H=dofile('tests/kernel_native_foundation_harness.lua').H
local create=H.load('../pr_bridge/bridge/frameworks/forge/operational_effect_proofs.lua',H.environment())
local g='proofs278';local b={generation=g,phase='ready',query=true,transaction=true};local k={generation=g,resource='pr_carkeys',ready=true,contractOnly=true}
local h={generation=g,owner='forge-core',count=2,duplicates=0};local item={disabled=true};local weapon={disabled=false}
local e={IsDuplicityVersion=function()return true end,exports={
 ['Renewed-Banking']={ForgeBankingReadiness=function()return b end},pr_carkeys={ForgeKeysReadiness=function()return k end},
 ox_inventory={ForgeOwnedHookSnapshot=function()return h end}}}
local p={environment=e,profile={Generation=g},isCurrent=function()return true end,
 decisions={sameBase=true,qbxShim=true,preserveData=true,legacyConversion='disabled-for-initial-test'}}
local a=create(p)
local raw={Services={Banking={Progress=function()return{phase='open'}end},Keys={Progress=function()return{phase='open'}end},
 Inventory={Progress=function()return{residual=2,unknown=0,removeFailed=0}end,
 HasItemDefinition=function(name)return true,item end,HasWeaponItem=function()return true,weapon end}}}
local graph={Central={Parts={Inventory={Service={items={hamburger={active=false}},weaponInventory={ammo={},components={}}}},
 Weapons={Registry={getWeapons=function()return{weapon_test={active=true}}end}}}}}
assert(a.environment(g,graph,raw)and a.banking(g,graph,raw)and a.keys(g,graph,raw)and a.decisions(g))
assert(a.oxHooks(g,graph,raw)and a.catalogs(g,graph,raw))
h.duplicates=1;assert(not a.oxHooks(g,graph,raw));h.duplicates=0
item.disabled=false;assert(not a.catalogs(g,graph,raw));item.disabled=true
b.phase='loading';assert(not a.environment(g,graph,raw));b.phase='ready'
weapon.disabled=true;assert(not a.catalogs(g,graph,raw));weapon.disabled=false
e.IsDuplicityVersion=function()return false end;e.GlobalState={forgeCoreActivation={generation=g,ingressOpen=false}}
a=create(p);assert(not a.environment(g));e.GlobalState.forgeCoreActivation.ingressOpen=true;assert(a.environment(g))
e.GlobalState.forgeCoreActivation.generation='stale';assert(not a.environment(g))
print('PASS278 PR effect proofs reject duplicate hooks,wrong item/weapon disabled flags,bank loading and stale server epoch;external effects virtual')
