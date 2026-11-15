local T=dofile('tests/kernel_client_domains_harness.lua');local H,n=T.H,0
local function check(ok,label)n=n+1;assert(ok,label)end
local r=T.new();local before=r.snapshot();local player,shared,central=r.state.PlayerData,r.state.Shared,r.central.api
local a=r.mount();H.same(r.snapshot(),before,'all client domain constructors inert')
H.same(a.Order,{'Jobs','Zones','Administration','Work','MultiJob','Staff','Skills','SkillMenus','AutoMedic','Access','Settings','World',
 'Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','PlayerAdmin','CharacterAdmin'},'23 actual attachments over seven central stages')
check(a.IsCanonical()and a.State=='prepared-inactive'and a.Unbound,'prepared is not installed')
check(r.state.PlayerData==player and r.state.Shared==shared and a.Central==central,'same central PlayerData/Shared')
check(a.Menu==r.client.Menu and a.Parts.Work.Menu==a.Parts.Settings.Menu,'one real controller')
check(a.Shared==a.Parts.Work.Shared and a.Shared==a.Parts.Administration.Shared,'one Shared menu helper')
check(a.Menu.openServerSettingsMenu~=a.SettingsParent and a.Menu.openServerSettingsMenu==a.SettingsMethod,'owned forward parent replaced by real method')
check(r.client.JobState==a.Parts.Jobs.JobState and a.Parts.Zones.Client==r.client,'same jobs replica/client')
check(r.client.ForgeSession==a.Parts.AutoMedic.Session.Session and a.Parts.Access.Session.Session==r.client.ForgeSession,'one canonical session view')
for _,key in ipairs({'Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack'})do
 check(a.Parts[key].WorldState==r.client.WorldState,'one WorldState '..key)
 check(a.Parts[key].Menu==a.Menu and a.Parts[key].Shared==a.Shared,'same controller '..key)
end
for name,cfg in pairs(r.config)do check(a.Config[name]==cfg,'local config identity '..name)end
local count=0;for _,fn in pairs(a.Menu)do if type(fn)=='function'then count=count+1 end end
check(count==196,'196 effective menu functions attached')
check(#a.Callbacks==13,'thirteen raw client callback descriptors')
local seen={};for _,d in ipairs(a.Callbacks)do
 check(type(d.handler)=='function'and type(d.owner)=='string'and not seen[d.name],'unique owned raw callback');seen[d.name]=true
end
for _,name in ipairs(a.Order)do
 local owned=r.ports.domains[name]
 check(owned.client==nil and owned.config==nil and owned.menu==nil,'caller ports untouched '..name)
 local old
 for key,value in pairs(r.state)do if value==a.Parts[name]then old=key;break end end
 check(old~=nil,'owned state slot '..name)
 r.state[old]={};check(not a.IsCanonical(),'foreign attached owner '..name);r.state[old]=a.Parts[name]
end
check(a.IsCanonical(),'identity restored')
for _,name in ipairs({'Menu','JobState','WorldState','ForgeSession'})do
 local old=r.client[name];r.client[name]={};check(not a.IsCanonical(),'foreign client view '..name);r.client[name]=old
end
local method=a.Menu.openServerSettingsMenu;a.Menu.openServerSettingsMenu=function()error('foreign parent must not run')end
check(not pcall(a.SettingsParent),'forward parent refuses replaced target');a.Menu.openServerSettingsMenu=method
check(not pcall(r.mount),'duplicate composition refused')
local q=T.new()
for _,name in ipairs(a.Order)do
 local value=q.ports.domains[name];q.ports.domains[name]=nil
 check(not pcall(q.mount),'missing domain '..name);check(q.state.ClientDomainAssembly==nil,'domain preflight before mutation');q.ports.domains[name]=value
 for _,key in ipairs({'client','menu','config','shared','world','session','playerAccess','groups','isReady','notifyPosition','debugEnabled'})do
  value[key]={};check(not pcall(q.mount),'foreign owned dependency '..name..'.'..key)
  check(q.state.ClientDomainAssembly==nil,'owned preflight before mutation');value[key]=nil
 end
end
for _,name in ipairs({'Job','Inventory','Weapons','Vip','MultiJob','Staff','Skills','AutoMedic','Whitelist','Afk','Password','DatabaseBackup',
 'Weather','Density','Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','Player','PlayerManagement','CharacterSlots'})do
 local v=q.config[name];q.config[name]=nil;check(not pcall(q.mount),'complete config '..name)
 check(q.state.ClientDomainAssembly==nil,'config preflight before mutation');q.config[name]=v
end
local inventory=q.config.Inventory;q.config.Inventory={};check(not pcall(q.mount),'foreign inventory49 config');q.config.Inventory=inventory
q.client.Menu={};check(not pcall(q.mount),'fresh holder required');q.client.Menu=nil
local owner=q.state.ClientAssembly;q.state.ClientAssembly=nil;check(not pcall(q.mount),'central49 required');q.state.ClientAssembly=owner
local broken=T.new();broken.ports.domains.CharacterAdmin.native.SetTimeout=nil
check(not pcall(broken.mount),'late failure retained');local failed=broken.state.ClientDomainAssembly
check(failed.State=='construction-failed'and #failed.Order>=20,'partial construction explicit no rollback')
check(not pcall(failed.SettingsParent),'forward parent refuses failed graph');check(not pcall(broken.mount),'failed holder not reusable')
local collision=T.new();collision.config.Vehicles.Callbacks.getCurrentVehicle=collision.config.Job.Callbacks.openMenu
check(not pcall(collision.mount),'raw callback collision refused before install')
check(collision.state.ClientDomainAssembly.State=='construction-failed','collision is failed not prepared')
local early=T.new();local env=T.A.E.env();local requireReal=env.require
env.require=function(name)
 local ctor=requireReal(name)
 if name=='kernel.client.menu.administration_core'then return function(state,ports)
  local value=ctor(state,ports);check(not pcall(ports.menu.openServerSettingsMenu),'owned forward parent refuses construction');return value
 end end
 return ctor
end
early.factory=H.load('kernel/client/domain_assembly.lua',env);check(early.mount().IsCanonical(),'real constructor completes after early parent refusal')
local tamper=T.new();local e=T.A.E.env();local real=e.require
e.require=function(name)
 local ctor=real(name)
 if name=='kernel.client.access_core'then return function(state,ports)
  local value=ctor(state,ports);ports.client.Menu.openServerSettingsMenu=function()error('foreign')end;return value
 end end
 return ctor
end
tamper.factory=H.load('kernel/client/domain_assembly.lua',e)
check(not pcall(tamper.mount),'forward parent ownership checked before release')
check(tamper.state.ServerSettingsMenus==nil and tamper.state.ClientDomainAssembly.State=='construction-failed','no foreign parent overwritten')
print('PASS lot50 construction: '..n..' checks; '..count..' menu functions/23 real attachments/13 raw callbacks; canonical identities, owned parent handoff, inert preflight, failure and collision')
