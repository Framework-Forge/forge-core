local T=dofile('tests/kernel_client_domains_harness.lua');local r=T.new();local a=r.mount()
local sf,packet=r.server.fixtures.World
sf.native.TriggerClientEvent=function(name,target,value)assert(name=='forge-core:cache:world'and target==-1);packet=value end
local s=r.connect()
local world=s.Parts.World;local view=a.Parts.World
local function start(service)if service.Initialize then service.Initialize()end;service.start()end
world.World.Initialize();view.World.Initialize()
assert(not r.wire.client.api.request('forge-core:cache:snapshot',nil,nil,10000).ready,'constructor is not global hydration')
for _,name in ipairs({'Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack'})do start(s.Parts[name].Service)end
start(world.Density.Service);s.Parts.CharacterAdmin.Exports.GetCharacterPreviews()
-- Different source avoids inherited 500ms snapshot throttle. Transport is actual PR, provider/clock/network virtual.
r.wire.playerSource=3
assert(view.WorldState.refresh(),'all ten actual producers hydrate one public client view')
for _,name in ipairs({'stores','objects','npcs','density','vinewood','starterpack','farms','billboards','characterPreviews','spotlights'})do
 assert(view.WorldState.getRecord(name),'same public view '..name)
end
assert(view.WorldState~=r.state.PlayerData and view.WorldState~=r.state.Session,'public state not player authority')
local old=view.WorldState.getRecord('density')
r.wire.playerSource=2
local ok,data=r.rpc('Density','saveSettings',{enabled=false});assert(ok)
sf.advance(0);assert(packet)
local event;for _,e in ipairs(view.Events)do if e.name=='forge-core:cache:world'then event=e.handler end end
-- Native was copied into the composition; its original source port reads the fixture environment.
local env=r.fixtures.World.env
env.source=65535;event(packet)
assert(view.WorldState.getRecord('density').revision>old.revision and view.WorldState.get('density').enabled==false,'public delta reaches same canonical WorldState')
env.source=2;local forged=T.H.copy(packet);for _,v in pairs(forged.states)do v.revision=v.revision+1000;v.data.enabled=true end;event(forged)
assert(view.WorldState.get('density').enabled==false,'spoofed delta refused')
local record=world.State.getRecord('density');sf.m.onWrite=function()return false end
ok,data=r.rpc('Density','saveSettings',{enabled=true});assert(not ok and data=='save_failed')
T.H.same(world.State.getRecord('density'),record,'failed write has no public publication');sf.m.onWrite=nil
local before=r.state.PlayerData;env.source=nil
for _,e in ipairs(view.Events)do if e.name=='onResourceStop'then e.handler('forge-core')end end
assert(view.WorldState.get('density')==nil and r.state.PlayerData==before,'public stop clears no PlayerData')
assert(a.IsCanonical()and a.Parts.Starterpack.WorldState==view.WorldState,'cleanup keeps same domain ownership')
print('PASS lot50 world: actual client50/server48 plus installed PR wire/cache; ten producers hydrate one view, same domain ownership, delta/spoof/refused persistence/stop; source, JSON, native effects and clocks virtual')
