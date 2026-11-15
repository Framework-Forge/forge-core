-- Same canonical World35/Farms43/Player/Session/Menu graph; PR RPC/context/ACE/recovery execute, IO/providers virtual.
local R=dofile('tests/kernel_player_admin_harness.lua');local H=R.H
local file=assert(io.open('tests/kernel_starterpack_composition_test.lua','r'));local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('\nlocal fixture=R.new(true)',1,true))
local g=assert(load(source:sub(1,cut-1)..'\nreturn g\n','@canonical-world35-farms43-player-admin','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
local fixture=R.new(true)
-- Attach actual prepared Staff27/Skills28 to THIS base, not a second Player authority.
local Q=dofile('tests/kernel_staff_harness.lua');local staffFixture=Q.new(true)
staffFixture.library.command=function()error('no command installation')end
local ace=Q.aceProvider(staffFixture,base.PlayerCore.Lookup);staffFixture.forbidLookup=true
local staff=H.load('kernel/server/staff/staff_core.lua',R.env())(base,{config=staffFixture.config,library=staffFixture.library,
 native=staffFixture.native,aceIntegration=ace,translate=staffFixture.translate,adminAce='forge-core.admin',notifyPosition='top-right'})
for _,d in ipairs(staff.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
local K=dofile('tests/kernel_skill_harness.lua');local skillFixture=K.new(true)
local skill=H.load('kernel/server/skill/skill_core.lua',R.env())(base,{config=skillFixture.config,library=skillFixture.library,
 native=skillFixture.native,integrations=skillFixture.integrations,json=skillFixture.m.codec,progression=skillFixture.progression,
 translate=skillFixture.translate,isReady=function()return base.PlayerCore.Lookup~=nil end})
for _,d in ipairs(skill.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
config.Staff,config.Skills=staff.Config,skill.Config
config.Player,config.PlayerManagement=fixture.config.Player,fixture.config.PlayerManagement
local slotConfig=H.environment({PR={}});H.load('shared/character_slots.lua',slotConfig);config.CharacterSlots=slotConfig.PR.CharacterSlots
fixture.config.Staff=staff.Config;fixture.config.Weather=base.WorldCore.Config.Weather
local count=#fixture.registrations
local server=H.load('kernel/server/player_admin_core.lua',R.env())(base,{config=fixture.config,native=fixture.native,clock=fixture.clock,
 translate=fixture.translate,managementIntegration=fixture.managementIntegration,print=fixture.print})
assert(#fixture.registrations==count and #fixture.timerQueue==0,'no automatic plugin registration/timer')
assert(server.Lookup==base.PlayerCore.Lookup and server.Services.JobService==base.JobCatalog.Service)
assert(server.Services.VipService==base.JobCatalog.Finance.Vip and server.Services.PrisonService==base.MultiJobCore.PrisonService)
assert(server.Services.StaffService==staff.Service and server.Services.SkillService==skill.Service)
assert(not pcall(H.load('kernel/server/player_admin_core.lua',R.env()),base,{}),'duplicate server refused')
for _,d in ipairs(server.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
-- Weapon21 requires attachment BEFORE Security18; this inherited partial graph lacks it.
-- Do not clear/replace Security to bypass that guard. Its plugin branch is differential-tested, not fully composed here.
assert(not base.WeaponCore and server.Services.WeaponService==nil,'partial graph not activation-ready')
local state,client=graph.state,graph.client
assert(not client.Menu.openPlayerMenu and not client.Menu.openPlayersManagement)
local data,session,world=state.PlayerData,client.ForgeSession,client.WorldState
local menus=H.load('kernel/client/menu/player_admin_core.lua',R.env())(state,{client=client,config=config,native=r.native,library=r.library})
assert(menus.Menu==g.farmsClient.Menu and menus.Shared==g.farmsClient.Shared and menus.Session==session)
assert(not pcall(H.load('kernel/client/menu/player_admin_core.lua',R.env()),state,{}),'duplicate menus refused')
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
local function manage(key,...)return rpc(config.PlayerManagement.Callbacks[key],...)end
wire.playerSource=1
for _,key in ipairs({'list','details','whitelist','prisonSentence','prisonRelease'})do local ok,e=manage(key,1,true);assert(not ok and e=='no_permission','admin refusal '..key)end
local ok,e=rpc('forge-core:server:plugin:load','job');assert(not ok and e=='no_permission')
ok,e=rpc('forge-core:server:plugin:action','job','forcePayment',{});assert(not ok and e=='no_permission')
local player=assert(base.PlayerCore.Lookup.GetPlayer(1));player.PlayerData.charinfo.firstname='Canonical';player.PlayerData.charinfo.lastname='Player';player.PlayerData.charinfo.birthdate='2000-10-22'
ok,e=rpc(config.Player.Callbacks.getInfo);assert(ok and e.firstname=='Canonical'and e.age=='26','personal info uses own canonical identity')
wire.playerSource=2
ok,e=manage('list');assert(ok and #e==2 and e[1].name=='Canonical Player','native online list with canonical Lookup')
ok,e=manage('details','1');assert(ok and e.citizenid==player.PlayerData.citizenid and e.prison==nil and e.availableJobs,'canonical profile with optional prison provider stopped')
local context=graph.context.api;context.RegisterContext({id='forge_core_main',title='Root',options={}})
menus.Menu.openPlayersManagement();assert(context.GetOpenContextMenu()=='forge_core_players_management')
context.HandleSelect('forge_core_players_management',3);assert(context.GetOpenContextMenu()=='forge_core_managed_player','list to canonical profile')
context.HandleBack();context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_main','management back to main')
menus.Menu.openPlayerStaffAdmin(1);assert(context.GetOpenContextMenu()=='forge_core_player_staff','effective multi-permission menu')
local pluginLoad='forge-core:server:plugin:load';local pluginAction='forge-core:server:plugin:action'
for _,name in ipairs({'job','afk','density','password','staff','skill'})do
 ok,e=rpc(pluginLoad,name);assert(ok and type(e)=='table','canonical plugin load '..name)
end
ok,e=rpc(pluginLoad,'password');assert(ok and e.password=='********','password remains masked')
ok,e=rpc(pluginAction,'afk','save',{settings={enabled=false,minutes=11}});assert(ok and base.AccessCore.Afk.Service.getSettings().minutes==11,'plugin mutates same local AFK service')
ok,e=rpc(pluginAction,'density','save',{settings={enabled=false}});assert(ok and not base.WorldCore.Density.Service.getSettings().enabled,'same local Density')
ok,e=rpc(pluginAction,'password','save',{settings={enabled=false,password='fixture-new'}});assert(ok,'same local Password save')
ok,e=rpc(pluginAction,'bad','save',{});assert(not ok and e=='invalid_action')
-- Registration remains an explicit external PR contract; no provider export is installed.
for _,d in ipairs(server.Events)do if d.name=='forge-management:server:pluginsReady'then d.handler()end end
assert(#fixture.registrations==9 and fixture.pluginDescriptors['forge-weather'],'explicit plugin registration descriptor protocol')
for _,d in ipairs(server.Events)do if d.name=='onResourceStop'then d.handler('forge-core')end end
assert(next(fixture.pluginDescriptors)==nil,'explicit plugin stop path')
wire.playerSource=1;menus.Menu.openPlayerMenu();assert(context.GetOpenContextMenu()=='forge_core_player_menu')
assert(state.PlayerData==data and client.ForgeSession==session and client.WorldState==world and base.Callbacks==server.Security)
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending player/plugin RPC')
print('PASS player/plugin composition: canonical Player/Lookup/Job/Finance/MultiJob/Prison/Access/World/Staff/Skill/Security/Menu/Session; actual PR RPC/context/recovery/ACE with virtual IO/providers. Weapon plugin branch only isolated; full bootstrap/provider/disposal/FiveM unverified')
