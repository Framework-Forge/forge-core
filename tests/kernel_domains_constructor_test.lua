local D=dofile('tests/kernel_domains_harness.lua');local H,n=D.H,0
local function check(value,label)n=n+1;assert(value,label)end
local r=D.new();local before=r.snapshot();local api=r.mount();H.same(r.snapshot(),before,'construction has no effects except pure translation')
check(api.State=='prepared-inactive'and api.Unbound==true,'prepared, not installed')
local order={'Helpers','MultiJob','Staff','Skills','AutoMedic','Access','Settings','World','Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','PlayerAdmin','CharacterAdmin'}
H.same(api.Order,order,'dependency order');check(#api.Order+#api.Central.Order==32,'thirteen plus nineteen actual stages')
check(#api.Callbacks==196 and next(r.central.handlers)==nil,'196 descriptors, no RPC installation')
check(api.RawCallbacks.Character==api.PlayerCore.Characters.Character.Callbacks and api.RawCallbacks.World==api.Parts.World.RawCallbacks,'distinct raw transports preserved')
for name,value in pairs(r.config)do if type(value)=='table'then check(api.Config[name]==value,'canonical config before Security '..name)end end
local pc=api.PlayerCore;local deps=r.base.JobCatalog.Dependencies
for _,key in ipairs({'Staff','Skills','AutoMedic','Access','Settings','World','Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','PlayerAdmin','CharacterAdmin','MultiJob'})do
 local a=api.Parts[key];check(a.PlayerCore==pc and a.Security==api.Security,'one Player/Security '..key)
end
check(api.Parts.PlayerAdmin.Services.WeaponService==r.base.WeaponCore.Service,'plugins now include actual Weapon21 in same graph')
check(api.Parts.PlayerAdmin.Services.StaffService==r.base.StaffCore.Service and api.Parts.PlayerAdmin.Services.SkillService==r.base.SkillCore.Service,'same staff/skills for plugins')
check(api.Parts.CharacterAdmin.Usable==r.base.InventoryCore.Consumption.Usable and api.Parts.CharacterAdmin.SlotPolicy==api.Central.Slots.Service,'one usable/slot authority')
check(api.Parts.Vehicles.Helpers==r.base.Helpers and api.Parts.Farms.Runtime==pc.Runtime,'same helpers/runtime/vehicle catalog')
for _,name in ipairs({'Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack'})do check(api.Parts[name].State==deps.State,'same public State '..name)end
check(api.Parts.Access.Session==r.base.ForgeSession and api.Parts.AutoMedic.Session==r.base.ForgeSession,'one Forge Session view')
check(api.Parts.CharacterAdmin.State==api.Parts.World.State,'character previews on same public State')
check(r.ports.central.runtime.helpers~=r.base.Helpers.Lib and r.ports.central.session.player.utils==r.central.p.bindings.utils,'input ports not overwritten')
for _,p in pairs(r.ports.domains)do check(p.config==nil and p.coreState==nil and p.isReady==nil and p.slotPolicy==nil,'caller domain inputs unchanged')end
check(not pcall(r.mount),'repeated assembly refused')
check(api.IsReady(),'explicit readiness and canonical identity')
r.operational=false;check(not api.IsReady(),'prepared does not override operational readiness');r.operational=true
local a=D.new()
for name,value in pairs(a.config)do if type(value)=='table'then
 a.config[name]=nil;check(not pcall(a.mount),'missing config '..name);check(a.base.DomainAssembly==nil and a.base.PlayerCore==nil,'config preflight before mutation');a.config[name]=value
end end
for name,value in pairs(a.ports.domains)do
 a.ports.domains[name]=nil;check(not pcall(a.mount),'missing domain '..name);check(a.base.DomainAssembly==nil,'domain preflight before mutation');a.ports.domains[name]=value
end
for _,name in ipairs({'Skills','Vehicles','Farms','CharacterAdmin'})do
 a.ports.domains[name].isReady=function()return true end;check(not pcall(a.mount),'foreign core readiness '..name);a.ports.domains[name].isReady=nil
end
a.ports.domains.Staff.config={};check(not pcall(a.mount),'foreign domain config refused');a.ports.domains.Staff.config=nil
a.ports.central.transport.config.Staff={};check(not pcall(a.mount),'foreign classification config refused');a.ports.central.transport.config.Staff=nil
-- Deliberate config collision must be reported before any public handler is installed.
local b=D.new();b.config.Weapons.Callbacks.getAll=b.config.Inventory.Callbacks.getAll
check(not pcall(b.mount),'duplicate protected callback refused')
check(b.base.DomainAssembly.State=='construction-failed'and next(b.central.handlers)==nil,'failed aggregate never installs partial RPC')
check(not pcall(b.mount),'failed holder not reusable')
check(not pcall(b.base.PlayerCore.Players.AddMoney,1,'cash',1)or next(b.base.PlayerCore.State.Players)==nil,'failure cannot fabricate an online player')
for _,name in ipairs({'forge-core:cache:snapshot','qbx_core:server:getCharacters'})do
 local collision=D.new();collision.config.Inventory.Callbacks.getAll=name
 check(not pcall(collision.mount),'cross-transport callback collision refused '..name)
 check(collision.base.DomainAssembly.State=='construction-failed'and next(collision.central.handlers)==nil,'no partial transport installation')
end
local saved=r.base.Helpers;r.base.Helpers={};check(not api.IsReady(),'helper replacement is not another service');r.base.Helpers=saved
check(api.IsReady(),'same helper restored')
print('PASS lot48 constructors: '..n..' checks, 32 real stages/26 shared configs/196 protected descriptors; no install/start/IO, wrong/duplicate/partial holders refused')
