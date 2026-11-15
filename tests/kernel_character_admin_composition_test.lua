-- Focused canonical Character11 -> admin46 -> public State35/VIP16; virtual SQL/IO/providers.
local R=dofile('tests/kernel_character_admin_harness.lua');local H=R.H
local f=assert(io.open('tests/kernel_character_composition_test.lua','r'));local source=f:read('*a'):gsub('\r\n','\n');f:close()
local cut=assert(source:find('local api=compose(base,core,ports)',1,true))
local g=assert(load(source:sub(1,cut-1)..'\nreturn{base=base,core=core,ports=ports,compose=compose,p=p,slots=slotFixture,character=character}\n',
 '@canonical-character11-admin46','t',_ENV))()
local base,pc,p=g.base,g.core,g.p
local fixture=R.new(true)
local W=dofile('tests/kernel_world_harness.lua');local world=W.world(true,true)
-- Character's preview dependency is late-bound to this public State, not another holder or self-export.
g.ports.previewsReady=function()return base.CharacterAdminCore~=nil end
g.ports.getPreviews=function()return base.CharacterAdminCore.Exports.GetCharacterPreviews()end
local characters=g.compose(base,pc,g.ports)
local groups=H.load('kernel/server/groups.lua',R.env())({jobs=p.groupData.jobs,gangs=p.groupData.gangs,emitServer=p.platform.emitServer,
 emitClient=p.platform.emitClient,saveGroups=function()error('No legacy writes')end,logError=function()end})
base.Groups,pc.Groups=groups,groups
local S=dofile('tests/kernel_job_service_harness.lua');local F=R.F
local native=fixture.vip.native
native.isAceAllowed=function(src)return src==2 end;native.getPlayerPing=function()return 50 end
native.isPlayerAceAllowed=function(src)return src==2 end;native.getGameTimer=function()return 1000000 end
native.getPlayerName=function()return 'Player'end;native.getInvokingResource=function()return'pr_bridge'end
native.isPrincipalAceAllowed=function()return false end
local library=fixture.vip.library;library.database={query=function()return{}end,transaction=function()return true end}
library.inventory=fixture.library.inventory;library.command=function()error('No command installation')end
local catalog=F.J.composition(base,{config=F.J.config(true).config,library=library,translate=fixture.vip.translate})
local service=S.compose(base,{library=library,translate=fixture.vip.translate,dependencies={},native=native,time=function()return fixture.vip.now end})
local finance=F.compose(base,{library=library,translate=fixture.vip.translate,native=native,integrations=fixture.vip.integrations,
 time=function()return fixture.vip.now end,resource='forge-core'})
catalog.Dependencies.State=world.state
local config={CharacterSlots=R.config(true),Vip=finance.VipConfig,Job=catalog.Config,AdminAce='forge-core.admin',NotifyPos='top-right'}
local handlers={};library.callback={register=function(name,fn)assert(not handlers[name],'duplicate RPC');handlers[name]=fn end}
local security=H.load('kernel/server/callback_security.lua',R.env())({services={JobService=service},config=config,library=library,
 json=fixture.m.codec,native=native})
base.Callbacks=security;catalog.Transport={Security=security}
local bindings={config=config,library=library,native=fixture.native,clock=fixture.clock,print=fixture.print,
 slotPolicy=g.slots.service,isReady=function()return base.PlayerCore==pc and pc.Characters==characters end}
local factory=H.load('kernel/server/character_admin_core.lua',R.env())
local wrong={};for k,v in pairs(bindings)do wrong[k]=v end;wrong.slotPolicy={}
assert(not pcall(factory,base,wrong),'shadow slot policy refused before attachment')
wrong={};for k,v in pairs(bindings)do wrong[k]=v end;wrong.config={CharacterSlots=config.CharacterSlots,Vip={}}
assert(not pcall(factory,base,wrong),'shadow VIP configuration refused before attachment')
local before=#fixture.trace;local api=factory(base,bindings)
assert(#fixture.trace==before and not api.Service.loaded and not api.Service.registered,'inert focused composition')
assert(api.PlayerCore==pc and api.SlotPolicy==g.slots.service and api.State==world.state and api.Vip==finance.Vip)
assert(catalog.Dependencies.CharacterSlotService==api.Service and api.Slots==characters.Slots)
assert(#api.Callbacks==14 and #api.Events==2 and api.Exports.GetCharacterPreviews,'complete consumer descriptors')
assert(not pcall(factory,base,bindings),'duplicate attachment refused')
for _,d in ipairs(api.Callbacks)do security.register(d.name,d.handler,d.options)end
for _,name in pairs(config.CharacterSlots.callbacks)do local ok,e=handlers[name](1);assert(not ok and e=='no_permission','admin slot denial')end
for _,name in pairs(config.Vip.Callbacks)do local ok,e=handlers[name](1);assert(not ok and e=='no_permission','admin VIP denial')end
local function rpc(key,...)return handlers[config.CharacterSlots.callbacks[key]](2,...)end
local ok,value=rpc('saveSettings',{maxSlots=5,minimumAgeEnabled=false,starterItems={{name='water',amount=2}}})
assert(ok and g.slots.service.getSettings().maxSlots==5,'same slot policy mutated')
ok,value=rpc('savePreview',nil,{x=21,y=22,z=23,heading=-90,animation='phone'});assert(ok)
local public=assert(world.state.get('characterPreviews'));assert(public[1].heading==270 and public[1].scenario=='WORLD_HUMAN_STAND_MOBILE')
local _,_,scene=characters.Character.Callbacks['qbx_core:server:getCharacters'](1)
assert(scene.previews[1].x==21 and scene.previews[1].scenario==public[1].scenario,'initial character payload gets same normalized scene')
-- Renderer12 consumes exactly that first payload; native entities remain virtual.
local V=dofile('tests/kernel_character_renderer_harness.lua');local renderer=V.new(true)
local locations=renderer.api.configuredPreviewLocations(scene);assert(locations==scene.previews)
renderer.api.buildConfiguredPreviews({},1,locations);assert(renderer.entities[101].coords.x==21 and renderer.entities[101].heading==270)
ok,value=rpc('getSettings');assert(ok and value.previewAnimations[1].id=='stand'and #value.previews==1)
assert(handlers[config.CharacterSlots.playerCallbacks.getCharacters](1),'own list allowed by player gate')
g.slots.characters={{citizenid='A',charinfo={cid=2,firstname='John',lastname='Doe'}}}
ok,value=rpc('getPlayer',1);assert(ok and value.occupied[2]=='John Doe')
assert(rpc('setPlayerSlot',1,2,false));assert(g.slots.blocked[101][2],'canonical account policy suspension')
ok,value=handlers[config.CharacterSlots.playerCallbacks.getCharacters](1);assert(ok and #value==0,'blocked character filtered')
assert(rpc('setPlayerSlot',1,2,true))
local player=pc.Players.CheckPlayerData(1,{citizenid='SLOT-VIP',license='license:test',userId=101})
assert(pc.Lookup.GetPlayer(1),'canonical Player online')
finance.Vip.Initialize()
ok,value=handlers[config.Vip.Callbacks.grant](2,1,'gold',2);assert(ok and pc.Lookup.GetPlayer(1).PlayerData.metadata.vip.tier=='gold')
ok,value=handlers[config.Vip.Callbacks.get](2,1);assert(ok and value.tier=='gold')
assert(handlers[config.Vip.Callbacks.revoke](2,1));assert(pc.Lookup.GetPlayer(1).PlayerData.metadata.vip==nil)
-- Actual installed PR OX adapter for external catalog/remove/refund/hooks; core registration stays local20.
local external=library.inventory;local hooks={};local proxy={}
for _,name in ipairs({'Items','RemoveItem','AddItem'})do proxy[name]=function(_,...)return external[name](...)end end
proxy.registerHook=function(_,event,fn,options)assert(options.itemFilter.new_slot);hooks[event]=fn;return 1 end
library.inventory=H.load('../pr_bridge/bridge/inventories/ox/server.lua',H.environment({ActiveBridges={inventory='ox'},exports={ox_inventory=proxy},
 Debug=function()end,Lang={t=function(_,key)return key end},Bridge={framework=setmetatable({},{__index=function()error('forbidden PR framework registration cycle')end})}}))
api.Service.start();assert(hooks.useItem and hooks.usingItem and api.Service.registered,'PR hooks with local fallback')
local localUse=assert(pc.Lifecycle.Functions.Exports.CanUseItem('new_slot'))
local stock=fixture.stock;assert(localUse(1,{slot=8})==false and fixture.stock==stock-1,'canonical usable consumes via PR once')
assert(hooks.usingItem({source=1,item='new_slot',slot=8})==false and fixture.stock==stock-1,'750ms dedupe across local registry and OX hook')
ok,value=rpc('getSettings');assert(ok and #value.itemOptions==4,'catalog through actual PR OX adapter includes provider-only definitions')
assert(api.State==world.state and not world.api.Callbacks[1].handler(1).ready,'only one world domain: not activation-ready')
print('PASS lot46 focused composition: canonical slots11/Player/Lookup/Logout/VIP16/Security18/State35 and initial preview payload -> renderer12; native/SQL/provider virtual, not full bootstrap')
