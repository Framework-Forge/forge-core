local F=dofile('tests/kernel_character_flow_harness.lua')
local R=dofile('tests/kernel_character_renderer_harness.lua')
local T=dofile('tests/kernel_session_harness.lua')
local C=dofile('tests/kernel_character_harness.lua')
local H=F.H
local r,world,delivery,server=F.new(true),R.new(true),T.new(true,'client'),C.character(true)
local state=r.core
local originalPlayer=state.PlayerData
local n={}
for _,source in ipairs({delivery.native,r.native,world.native}) do for name,fn in pairs(source) do n[name]=fn end end
n.GetGameTimer=function() return r.now end
n.Wait=r.native.Wait
n.GetEntityCoords=function(ped) return world.entities[ped].coords end
r.cache=world.cache
local writer=H.load('kernel/shared/bridge_cache.lua',H.environment())(delivery.delivery,'qbx_core:client:cacheChanged')
local cacheModule=H.load('kernel/client/bridge_cache.lua',H.environment())({core=state,native=n,writer=writer})
state.BridgeCache=cacheModule.Producer
local originalCache=state.BridgeCache
local config=H.load('kernel/config/client.lua',H.environment())({
    getResourceState=n.GetResourceState,getVehicleNumberPlateText=function() return 'TEST' end,
    vec4=function(x,y,z,w) return {x=x,y=y,z=z,w=w} end,joaat=n.joaat,vehicleKeys={}})
local membership=H.load('kernel/shared/functions.lua',H.environment())({tableType=H.tableType,warn=function() error('Unexpected warning') end})
local notifications={}
local functions=H.load('kernel/client/functions.lua',H.environment())({core=state,membership=membership,
    notify=function(data) notifications[#notifications+1]=data end,notifyPosition='center-left'})
local env=H.environment()
local allowed={['kernel.client.character']=true,['kernel.client.character_renderer_core']=true,
    ['kernel.client.character_renderer']=true,['kernel.data.nationalities']=true}
local loaded={}
env.require=function(name)
    assert(allowed[name],'External import '..tostring(name))
    if not loaded[name] then loaded[name]=H.load(name:gsub('%.','/')..'.lua',env) end
    return loaded[name]
end
local nationalities=env.require('kernel.data.nationalities')
H.same(nationalities,H.load(H.qbx..'data/nationalities.lua',H.environment()),'Complete installed nationality data')
assert(#nationalities>200)
local compose=H.load('kernel/client/character_core.lua',env)
server.state.characters={F.character(1,'A')};server.state.blocked={};server.settings.requireItem=true
world.decoded={['skin data']={model=42}}
local transport={}
transport.await=function(name,delay,...)
    if name=='qbx_core:server:getCharacters' then assert(delay==nil);return server.callbacks[name](1) end
    assert(delay==false)
    if name=='qbx_core:server:deleteCharacter' then return server.bindings.deleteCharacter(1,...) end
    return assert(server.callbacks[name],'Unknown own-core callback')(1,...)
end
local bindings={config=config,defaultSpawn=r.defaultSpawn,native=n,cache=r.cache,ui=r.ui,
    callbacks=transport,integrations=r.integrations,functions=functions,locale=r.locale,
    groupdigits=r.groupdigits,strsplit=F.split,random=r.random,streaming=world.bindings.streaming,
    json=world.bindings.json,setPedAppearance=world.bindings.setPedAppearance}
r.clearTrace()
local api=compose(state,bindings)
assert(api.State==state and state.CharacterCore==api and state.CharacterRenderer.Renderer==api.Renderer)
assert(state.PlayerData==originalPlayer and state.BridgeCache==originalCache)
assert(#r.trace==0 and #world.trace==0 and #delivery.trace==0 and #server.trace==0)
assert(not pcall(compose,state,bindings),'Duplicate authority/renderer refused')
assert(#api.Flow.Events==3 and #api.Flow.Threads==2 and #world.threads==0)
assert(api.Flow.Initialize() and not api.Flow.Initialize())
r.events=api.Flow.Events;r.threads=api.Flow.Threads;r.fillNationalities()
api.Flow.characterDialog(server.settings)
assert(#r.lastDialog[2][3].options==#nationalities)
api.Flow.chooseCharacter()
assert(r.shown=='qbx_core_multichar_characters')
assert(world.entities[101].coords.x==1 and world.entities[101].coords.z==3 and world.entities[101].heading==45)
assert(world.entities[101].model==42 and world.cameras[501])
assert(api.Renderer.IsConfigured())
assert(api.Flow.GetFallbackLocation()==config.characters.locations[1])
-- Cache is passive with bridge stopped, no hydration. Flush only on availability.
assert(delivery.cache.ped==nil)
delivery.bridge='started';writer.flush('available',true)
assert(delivery.cache.ped==10)
-- Existing-character callback uses the private server flow and then external spawn ports.
r.menus.qbx_core_multichar_character_1.options[1].onSelect()
assert(not world.entities[101] and next(world.cameras)==nil)
world.run(1)
local login=0;for _,e in ipairs(server.trace) do if e.kind=='Login' then login=login+1 end end
assert(login==1)
assert(state.PlayerData==originalPlayer and state.BridgeCache==originalCache and functions.GetPlayerData()==originalPlayer)
-- Form feeds the private server create callback, strips termsAccepted before Login and delivers kit once.
r.dialogIndex=0;r.dialogs={{'First','Last','American','info.char_male','1990-01-01'}}
assert(api.Flow.createCharacter(1,{})==true)
local kit=0
for _,e in ipairs(server.trace) do if e.kind=='AddItem' then kit=kit+1;assert(e.args[2]=='water') end end
assert(kit==1,'No duplicate starter kit or legacy documents')
api.Flow.chooseCharacter()
server.deleteResult=false
r.menus.qbx_core_multichar_character_1.options[2].onSelect()
assert(notifications[#notifications].description=='error.character_delete_failed')
assert(notifications[#notifications].type=='error' and notifications[#notifications].position=='center-left')
local owned=0;for _,e in ipairs(server.trace) do if e.kind=='ownedDelete' then owned=owned+1 end end
assert(owned==1,'Owned callback route, not administrative force export')
for i=1,#world.threads do
    if coroutine.status(world.threads[i])~='dead' then api.Renderer.destroyPreviewCam();world.run(i) end
end
-- Disabled external character mode creates neither renderer nor platform startup.
local disabled={PlayerData={},BridgeCache=originalCache}
local inactive=compose(disabled,{config={characters={useExternalCharacters=true}}})
assert(not inactive.Flow.Enabled and not inactive.Flow.Initialize() and disabled.CharacterRenderer==nil)
assert(#inactive.Flow.Events==0 and #inactive.Flow.Threads==0)
assert(not pcall(env.require,'pr_lib.framework'))
for _,name in ipairs({'QBX','exports','RegisterNetEvent','CreateThread','MySQL','GlobalState'}) do
    assert(rawget(env,name)==nil,'No ambient '..name)
end
print('PASS character flow composition: real private renderer/config/Notify/cache and server character callbacks, normalized first scene/nationalities, play/create/kit/owned-delete transport and canonical identities; PR/UI/SQL/resources simulated, no startup')
