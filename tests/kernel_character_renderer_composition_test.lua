local R=dofile('tests/kernel_character_renderer_harness.lua')
local T=dofile('tests/kernel_session_harness.lua')
local H=R.H
local r,delivery=R.new(true),T.new(true,'client')
local env=H.environment()
env.require=function(name)
    assert(name=='kernel.client.character_renderer','External import refused')
    return H.load('kernel/client/character_renderer.lua',H.environment())
end
local compose=H.load('kernel/client/character_renderer_core.lua',env)
local state=delivery.core
local originalPlayer=state.PlayerData
local native={}
for key,value in pairs(delivery.native) do native[key]=value end
for key,value in pairs(r.native) do native[key]=value end
native.GetEntityCoords=function(ped) return r.entities[ped].coords end
local writer=H.load('kernel/shared/bridge_cache.lua',H.environment())(delivery.delivery,'qbx_core:client:cacheChanged')
local cacheModule=H.load('kernel/client/bridge_cache.lua',H.environment())({core=state,native=native,writer=writer})
state.BridgeCache=cacheModule.Producer
local originalCache=state.BridgeCache
local api=compose(state,r.bindings)
assert(api.State==state and state.CharacterRenderer==api)
assert(state.PlayerData==originalPlayer and state.BridgeCache==originalCache)
assert(#r.trace==0 and #delivery.trace==0 and #r.threads==0)
assert(not pcall(compose,state,r.bindings),'Duplicate attachment refused')
assert(not pcall(compose,{PlayerData={}},r.bindings),'Cannot create another canonical cache')
-- Real local producer stages passive context while PR delivery is stopped.
r.swapPed=20
api.Renderer.randomPed()
assert(r.cache.ped==20 and delivery.cache.ped==nil and state.PlayerData==originalPlayer)
delivery.bridge='started'
writer.flush('bridge-ready',true)
assert(delivery.cache.ped==20 and delivery.cache.playerId==7 and delivery.cache.serverId==1)
-- Same state is refreshed when another saved model replaces the actual player ped.
r.swapPed=30;r.skins.A={'saved',42};r.decoded={saved={model=42}}
api.Renderer.previewPed('A')
assert(delivery.cache.ped==30 and state.PlayerData==originalPlayer and state.BridgeCache==originalCache)
-- Preview scene is received directly, without another config request or read-through.
local scene={previews={{x=21,y=22,z=23,heading=24,scenario='WORLD_HUMAN_STAND_IMPATIENT'}}}
assert(api.Renderer.configuredPreviewLocations(scene)==scene.previews)
api.Renderer.buildConfiguredPreviews({},1,scene.previews)
assert(r.entities[101].coords.z==23 and r.entities[101].heading==24)
api.Renderer.setupPreviewCam(api.Renderer.configuredOverview())
api.Renderer.destroyPreviewCam();r.run(1)
assert(not r.entities[101] and r.entities[30])
assert(state.PlayerData==originalPlayer and state.BridgeCache==originalCache)
-- Separate attachment has separate camera/ped/revision maps, not shared global state.
local other=R.new(true)
local state2={PlayerData={},BridgeCache=other.bridgeCache}
local api2=compose(state2,other.bindings)
api2.Renderer.buildConfiguredPreviews({},1,scene.previews)
assert(other.entities[101] and not r.entities[101] and not api.Renderer.IsConfigured())
api2.Renderer.clearConfiguredPreviews()
assert(not pcall(env.require,'pr_lib.framework'))
for _,name in ipairs({'QBX','ForgeCore','exports','RegisterNetEvent','CreateThread','GlobalState','MySQL'}) do
    assert(rawget(env,name)==nil,'No ambient runtime '..name)
end
print('PASS character renderer composition: same canonical PlayerData and real passive cache producer, model refresh while PR stopped/started, normalized scenes and isolated attachments; no startup/loading/public bindings')
