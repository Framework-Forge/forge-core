local R=dofile('tests/kernel_assembly_harness.lua');local H,n=R.H,0
local function check(value,message)n=n+1;assert(value,message)end
local expected={'Slots','Player','Lifecycle','Runtime','Characters','Catalog','Jobs','Finance','Business','Inventory','Consumption','Weapons','Transport'}
local r=R.new();local base,ports=r.base,r.ports
local before={trace=#r.trace,p=#r.p.trace,l=#r.l.trace,n=#r.n.trace,slot=#r.c.trace,character=#r.character.trace,doc=#r.documents.trace,m=#r.m.trace,ox=#r.ox.events}
local api=r.mount();check(api.State=='prepared-inactive','prepared only');H.same(api.Order,expected,'explicit dependency order')
for key,value in pairs(before)do
 local t=key=='trace'and r.trace or key=='p'and r.p.trace or key=='l'and r.l.trace or key=='n'and r.n.trace or key=='slot'and r.c.trace or key=='character'and r.character.trace or key=='doc'and r.documents.trace or key=='ox'and r.ox.events or r.m.trace
 check(#t==value,'no constructor effect '..key)
end
check(#r.workers==0 and #r.timers==0 and next(r.handlers)==nil and r.hookCount==0 and #r.ox.events==before.ox,'no worker/timer/RPC/hook/publication')
check(base.PlayerCore==api.PlayerCore and api.PlayerCore.Groups==base.Groups and api.PlayerCore.Shared==base.Shared,'one Player/Groups/Shared')
check(api.Parts.Characters.Slots==api.Slots and api.Parts.Characters.State==api.PlayerCore.State,'canonical character policy')
check(api.Parts.Business.Points==base.JobCatalog.Dependencies.JobPoints and api.Parts.Business.Business==base.JobCatalog.Dependencies.JobBusiness,'real Points/Business, no sentinel')
check(api.Parts.Consumption==base.InventoryCore.Consumption and api.Parts.Weapons==base.WeaponCore,'canonical consumption/weapons')
check(api.Security==base.Callbacks and api.Config.Inventory==base.InventoryCore.Config and api.Config.Weapons==base.WeaponCore.Config,'Security built last with canonical configs')
check(ports.session.player.characterSlots==nil and ports.slots.service==nil and ports.slots.storage==nil,'caller ports not overwritten')
check(ports.transport.config.Job==nil and ports.transport.config.Inventory==nil and ports.character.slots==nil,'caller config and character ports untouched')
check(not pcall(r.factory,base,ports),'duplicate construction refused')
for _,key in ipairs({'session','slots','lifecycle','runtime','character','catalog','jobs','finance','business','inventory','consumption','weapons','transport'})do
 local a=R.new();a.ports[key]=nil;check(not pcall(a.mount),'missing required ports '..key);check(a.base.ServerAssembly==nil and a.base.PlayerCore==nil,'preflight before holder mutation')
end
for _,key in ipairs({'service','storage','getPlayer','logout'})do
 local a=R.new();a.ports.slots[key]={};check(not pcall(a.mount),'foreign slot dependency '..key)
end
for _,key in ipairs({'slots','slotPolicy','previewsReady','getPreviews'})do
 local a=R.new();a.ports.character[key]={};check(not pcall(a.mount),'foreign character dependency '..key)
end
for _,key in ipairs({'VipService','InventoryService','WeaponService','State','CharacterSlotService'})do
 local a=R.new();a.ports.jobs.dependencies[key]={};check(not pcall(a.mount),'prepopulated service authority '..key)
end
local a=R.new();a.ports.session.player.characterSlots={};check(not pcall(a.mount),'foreign Player policy rejected')
a=R.new();a.ports.character.config={};check(not pcall(a.mount),'foreign character config rejected')
a=R.new();a.ports.transport.config.Inventory={};check(not pcall(a.mount),'mismatched Security config rejected')
check(a.base.ServerAssembly.State=='construction-failed'and a.base.Callbacks==nil,'failed assembly not reported prepared')
check(not pcall(a.base.ServerAssembly.Parts.Slots.Service.getState,1),'late dependencies refuse a partial failed assembly')
check(not pcall(a.mount),'partial holder cannot be replayed')
check(next(a.handlers)==nil and a.hookCount==0 and #a.workers==0 and #a.timers==0,'failure does not install partial runtime')
local b=R.new();check(b.mount().State=='prepared-inactive','fresh holder after separate failure works')
check(b.api.PlayerCore.State.Players~=api.PlayerCore.State.Players and b.api.Slots.Service~=api.Slots.Service,'separate test instances never share state')
print('PASS lot47 constructors: '..n..' checks; thirteen stages/one authority, all effects deferred, wrong/duplicate/partial holders refused')
