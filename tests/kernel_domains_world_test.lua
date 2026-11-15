local D=dofile('tests/kernel_domains_harness.lua');local r=D.new();local api=r.mount();r.register()
local world=api.Parts.World;local snapshot=world.RawCallbacks[1].handler
assert(not snapshot(1).ready,'construction is not hydrated/public ready')
world.World.Initialize()
for _,name in ipairs({'Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack'})do
 local service=api.Parts[name].Service;if service.Initialize then service.Initialize()end;service.start()
end
if world.Density.Service.Initialize then world.Density.Service.Initialize()end;world.Density.Service.start()
local admin=api.Parts.CharacterAdmin;local config=api.Config
r.central.m.seed(config.CharacterSlots.previewStorage,{{x=12,y=23,z=34,heading=-90,animation='phone'}})
admin.Exports.GetCharacterPreviews()
assert(snapshot(1)==nil,'existing 500ms same-source snapshot throttle preserved')
assert(snapshot(2).ready,'all ten actual public domain producers ready on one State')
local pc=api.PlayerCore
local list,max,scene=pc.Characters.Character.Callbacks['qbx_core:server:getCharacters'](1)
assert(scene.previews[1].x==12 and scene.previews[1].heading==270 and scene.previews[1].scenario=='WORLD_HUMAN_STAND_MOBILE','first payload contains canonical normalized preview')
local ok,data=r.rpc('CharacterSlots','getSettings',2);assert(ok and data.previews[1].x==12)
ok,data=r.rpc('CharacterSlots','savePreview',2,1,{x=45,y=56,z=67,heading=180,animation='stand'});assert(ok)
list,max,scene=pc.Characters.Character.Callbacks['qbx_core:server:getCharacters'](1)
assert(scene.previews[1].x==45 and world.State.get('characterPreviews')[1].x==45,'admin updates same selection scene')
ok,data=r.rpc('Objects','getAll',1);assert(ok and type(data)=='table','player gets public objects from same Service')
ok,data=r.rpc('Stores','getAll',1);assert(ok and type(data)=='table','player gets public stores')
ok,data=r.rpc('Farms','getAll',1);assert(ok and type(data)=='table','player gets public farms')
-- Failed recovery write must not publish a preview change to world or selector.
local old=world.State.getRecord('characterPreviews');r.central.m.onWrite=function()return false end
ok,data=r.rpc('CharacterSlots','savePreview',2,1,{x=90,y=91,z=92,heading=0,animation='stand'});assert(not ok)
D.H.same(world.State.getRecord('characterPreviews'),old,'failed preview save no publication');r.central.m.onWrite=nil
assert(admin.Usable==api.Central.Parts.Consumption.Usable and api.Parts.Vehicles.Helpers==r.base.Helpers,'same usable/helpers')
r.operational=false;assert(not api.IsReady(),'explicit runtime readiness is distinct from ten published domains')
assert(snapshot(3).ready and api.Unbound,'public hydration alone does not install the framework')
print('PASS lot48 world: ten actual producers share State35; first/updated normalized Character11 scene, public Objects/Stores/Farms and failed-write preservation; native/IO/SQL virtual, no real boot')
