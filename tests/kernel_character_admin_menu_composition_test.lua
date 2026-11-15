-- Existing graph45 extended in place. Full graph's Character11 slot policy is NOT yet reconciled.
local R=dofile('tests/kernel_character_admin_harness.lua');local H=R.H
local f=assert(io.open('tests/kernel_player_admin_composition_test.lua','r'));local src=f:read('*a'):gsub('\r\n','\n');f:close()
local cut=assert(src:find('local function rpc(name,...)',1,true))
local g=assert(load(src:sub(1,cut-1)..'\nreturn{graph=graph,base=base,r=r,wire=wire,config=config,menus=menus}\n','@canonical-management45-admin46','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
config.CharacterSlots=R.config(true);config.Vip=base.JobCatalog.Finance.VipConfig
local before=#r.trace
local factory=H.load('kernel/client/menu/character_admin_core.lua',R.env())
assert(not pcall(factory,graph.state,{client={},config=config}),'shadow client refused')
local api=factory(graph.state,{client=graph.client,config=config,library=r.library,native=r.native})
assert(api.Menu==g.menus.Menu and api.Shared==g.menus.Shared and api.Session==graph.client.ForgeSession)
assert(#r.trace==before,'no constructor menu/RPC/timer effects')
assert(not pcall(factory,graph.state,{}),'duplicate menu attachment refused')
for _,d in ipairs(H.load('kernel/server/vip/callbacks.lua',R.env())({config=config,service=base.JobCatalog.Finance.Vip,clock={date=os.date}}))do base.Callbacks.register(d.name,d.handler,d.options)end
local context=graph.context.api;wire.playerSource=2
base.JobCatalog.Finance.Vip.Initialize()
context.RegisterContext({id='forge_core_main',title='Main',options={}})
api.Menu.openPlayersManagement();context.HandleSelect('forge_core_players_management',1)
assert(context.GetOpenContextMenu()=='forge_core_character_creation_settings','management45 -> creation46')
assert(base.Callbacks.registrations[config.CharacterSlots.callbacks.getSettings]==nil,'full graph slot RPC absent, not fabricated')
-- Do not launch an unbound RPC (which awaits a network timeout); focused test above exercises the real service.
context.HandleBack();api.Menu.openPlayersManagement();context.HandleSelect('forge_core_players_management',2)
assert(context.GetOpenContextMenu()=='forge_core_vip_classes','management45 -> canonical VIP16 callback46')
context.HandleBack();context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_main','back to same main')
api.Menu.openManagedPlayer(1)
local managed=assert(context.GetOpenContextMenu());assert(managed=='forge_core_managed_player')
api.Menu.openPlayerVipAdmin(1);assert(context.GetOpenContextMenu()=='forge_core_player_vip');context.HandleBack()
assert(context.GetOpenContextMenu()=='forge_core_managed_player','VIP parent is existing profile45')
wire.playerSource=1
local ok,e=r.library.callback.await(config.Vip.Callbacks.get,10000,1);assert(not ok and e=='no_permission','canonical server Security denies VIP read')
assert(not base.PlayerCore.Characters and not base.CharacterAdminCore,'partial full graph explicitly not activation-ready')
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending menu RPC')
print('PASS lot46 menu composition: same management45/Menu/Shared/Session/World, canonical VIP16/Security and PR context/back/RPC; full graph Character11 reconciliation still pending')
