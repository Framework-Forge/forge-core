local T=dofile('tests/kernel_client_domains_harness.lua');local r=T.new();r.config.NotifyPos='bottom-left';local a=r.mount()
r.server.central.m.seed(r.config.CharacterSlots.previewStorage,{{x=12,y=23,z=34,heading=0,animation='stand'}})
local s=r.connect()
s.Parts.CharacterAdmin.Exports.GetCharacterPreviews() -- Explicit selector request, not constructor hydration.
local menu,c,ui=a.Menu,r.context.api,r.fixtures.Work
a.Shared.notify({description='bound config',type='inform'})
assert(ui.trace[#ui.trace].args[1].position=='bottom-left','global NotifyPos reaches shared menu helper')
local function current()return c.GetOpenContextMenu()end
local function select(index)c.HandleSelect(current(),index)end
s.Central.Parts.Finance.Payments.load();s.Central.Parts.Finance.Vip.Initialize()
menu.openMain();assert(current()=='forge_core_main')
select(4);assert(current()=='forge_core_server_settings','main invokes real settings parent')
c.HandleBack();assert(current()=='forge_core_main','settings back reaches actual main')
a.SettingsParent();assert(current()=='forge_core_server_settings','owned forward parent delegates real settings34')
select(6);assert(current()=='forge_core_density');c.HandleBack();assert(current()=='forge_core_server_settings')
menu.openPlayersManagement();assert(current()=='forge_core_players_management')
select(1);assert(current()=='forge_core_character_creation_settings','same management45 slots46')
c.HandleBack();assert(current()=='forge_core_players_management')
select(2);assert(current()=='forge_core_vip_classes','same canonical VIP')
c.HandleBack();c.HandleBack();assert(current()=='forge_core_main')
menu.openMain();select(8)
local panel;for _,e in ipairs(ui.trace)do if e.kind=='external-client'then panel=e.args end end
T.H.same(panel,table.pack('forge-loadscreen:client:openAdminMenu','forge_core_main','forge-core'),'loadscreen parent and owner unchanged')
menu.openMain();select(9);panel=ui.trace[#ui.trace].args
T.H.same(panel,table.pack('forge-pause:client:openAdminMenu','forge_core_main','forge-core'),'pause parent and owner unchanged')
local ok,data=r.rpc('Afk','saveSettings',{enabled=true,minutes=17});assert(ok and s.Parts.Access.Afk.Service.getSettings().minutes==17)
ok,data=r.rpc('CharacterSlots','savePreview',1,{x=45,y=56,z=67,heading=180,animation='stand'});assert(ok)
local _,_,scene=s.PlayerCore.Characters.Character.Callbacks['qbx_core:server:getCharacters'](1)
assert(scene.previews[1].x==45,'same Character11 reads admin preview46')
r.wire.playerSource=1
ok,data=r.rpc('Afk','saveSettings',{enabled=false,minutes=2});assert(not ok and data=='no_permission','real server48 Security denies write')
ok,data=r.rpc('Vip','get',1);assert(not ok and data=='no_permission','same server denies VIP read')
assert(a.IsCanonical()and s.Base==r.server.base,'client graph and server graph retain own canonical state')
assert(next(r.wire.client.api.getPending())==nil and next(r.wire.server.api.getPending())==nil,'no pending real PR wire requests')
print('PASS lot50 menus: actual client50/server48 factories and installed PR RPC/context; main/settings/density/management/slots/VIP/back, owned forward parent, external loadscreen/pause parent-owner, local preview and protected denial; IO/NUI/providers virtual')
