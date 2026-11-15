local A=dofile('tests/kernel_client_assembly_harness.lua');local D=dofile('tests/kernel_domains_harness.lua')
local W=dofile('tests/kernel_client_jobs_harness.lua');local r=A.new();local server=D.new();local s=server.mount()
local c=server.central;local wire=W.wire();wire.playerSource=1
for name,handler in pairs(s.RawCallbacks.Character)do wire.server.api.register(name,handler)end
c.characterRow('CANONICAL49',1)
c.m.seed(s.Config.CharacterSlots.previewStorage,{{x=12,y=23,z=34,heading=-90,animation='phone'}})
local rawScene
r.ports.character.callbacks={await=function(name,delay,...)
 local values=table.pack(wire.client.api.request(name,nil,nil,5000,...))
 if name=='qbx_core:server:getCharacters'then rawScene=values[3]end
 return table.unpack(values,1,values.n)
end}
local api=r.mount();r.installEvents();local flow=api.Parts.Character.Flow
assert(flow.Initialize()and not flow.Initialize())
-- Actual installed loading controller: JSON-shaped config, same minimum-time contract, no remote media.
r.flow.now=12500;A.F.bindLoadingController(r.flow,{minimumLoadscreenSeconds=180})
local co=coroutine.create(flow.chooseCharacter)
for _=1,8 do local ok,value=coroutine.resume(co);assert(ok,value);assert(r.flow.shown==nil,'selector hidden while loadscreen minimum pending')end
assert(r.flow.now<180000,'virtual minimum still pending')
A.F.runCoroutine(co,400)
assert(r.flow.loadingClosedAt>=180000 and r.flow.shownAt>=r.flow.loadingClosedAt,'configured minimum respected before selector')
assert(rawScene.previews[1].x==12 and rawScene.previews[1].heading==270 and rawScene.previews[1].scenario=='WORLD_HUMAN_STAND_MOBILE')
assert(r.world.entities[101].coords.x==12 and r.world.entities[101].heading==270,'real renderer consumes server48 first scene')
assert(r.state.CharacterRenderer.Renderer==api.Parts.Character.Renderer and api.IsCanonical(),'one renderer/authority')
assert(server.base.CharacterAdminCore.State.get('characterPreviews')[1].x==12,'scene comes from canonical World35')
assert(next(wire.server.api.getPending())==nil and next(wire.client.api.getPending())==nil,'actual PR RPC wire released')
assert(next(r.producer.cache)==nil,'selector does not actively pull PR framework/cache')
-- Existing-character play traverses the same real server48 login and client13 cleanup/spawn boundary.
r.flow.menus.qbx_core_multichar_character_1.options[1].onSelect()
local player=s.PlayerCore.Lookup.GetPlayer(1)
assert(player and player.PlayerData.citizenid=='CANONICAL49','play reaches actual same private Player Login')
assert(r.world.entities[101]==nil and next(r.world.cameras)==nil,'same renderer cleans peds/cameras on play')
-- Explicit simulated snapshot delivery, not a claim of an installed FiveM event binder.
r.dispatch('QBCore:Player:SetPlayerData',player.PlayerData)
assert(api.Parts.Legacy.Functions.GetPlayerData()==player.PlayerData and r.state.Session.snapshot().data.character=='CANONICAL49')
assert(api.Unbound and s.Unbound,'no client/server installation or activation')
print('PASS lot49 characters: actual server48 raw Character11/State35/slots -> installed PR RPC -> real client13/renderer12; normalized first scene, installed loading controller waits180s, passive bridge; UI/natives/SQL/wire/time virtual')
