local T=dofile('tests/kernel_subscription_harness.lua');local r=T.new();local g=r.graph
local before=r.fixture.snapshot();r.prepare();T.H.same(r.fixture.snapshot(),before,'subscription constructor inert')
assert(r.api.Install());T.H.same(r.fixture.snapshot(),before,'subscription binding does not start any initializer or worker')
local foreign={};r.world.onChange('stores',function(value)foreign[#foreign+1]=value end)
local payloads={
    objects={objects={{id=11,model='object55',coords={x=1,y=2,z=3}}}},
    npcs={npcs={{id=12,model='npc55',name='NPC55',coords={x=3,y=4,z=5}}}},
    spotlights={enabled=true,revision=1,lights={{id=13,groupId=1,coords={x=1,y=2,z=3}}}},
    billboards={enabled=true,billboards={{id=14,enabled=true,url='about:blank'}}},
    stores={settings={enabled=false},stores={},marker=55},farms={settings={enabled=false},farms={},marker=55},
    starterpack={enabled=false,prologue={enabled=false},marker=55},vinewood={enabled=false,revision=1,text='test55'}}
for _,key in ipairs({'objects','npcs','spotlights','billboards','stores','farms','starterpack','vinewood'})do r.apply(key,payloads[key])end
r.drain()
assert(g.Parts.Objects.Objects.entries[11].model=='object55','same Objects consumer')
assert(g.Parts.Npcs.Npcs.entries[12].name=='NPC55','same NPC consumer')
assert(g.Parts.Spotlights.Spotlights.lights[1].id==13 and g.Parts.Spotlights.Spotlights.enabled,'same Spotlights consumer')
assert(g.Parts.Billboards.Billboards.entries[1].id==14,'same Billboards consumer')
assert(g.Parts.Stores.Stores.payload.marker==55 and g.Parts.Farms.Farms.payload.marker==55,'same store/farm payload consumers')
assert(g.Parts.Starterpack.Starterpack.payload.marker==55,'same Starterpack consumer')
assert(#r.fixture.fixtures.Vinewood.trace>0,'same Vinewood renderer without static worker')
assert(#foreign==1 and foreign[1].marker==55)
assert(g.Parts.Stores.Stores.payload~=r.world.peek('stores'),'World emitter still isolates consumer copies')
g.Parts.Stores.Stores.payload.marker='consumer mutation';assert(r.world.peek('stores').marker==55,'consumer does not mutate authoritative public record')
local stable=g.Parts.Stores.Stores.payload
-- A queued callback is invalidated before dispatch, while unrelated consumers keep working.
r.apply('stores',{settings={enabled=false},stores={},marker=56},1,2)
assert(r.api.Dispose());r.api.State='installed';r.drain()
assert(g.Parts.Stores.Stores.payload==stable and #foreign==2 and foreign[2].marker==56,'queued own callback revoked without touching foreign listener')
local queue=#r.clock.queue;r.apply('stores',{settings={enabled=false},stores={},marker=57},1,3)
assert(#r.clock.queue>queue,'installed World retains inert subscription shells, not physical removal');r.drain()
assert(g.Parts.Stores.Stores.payload==stable and foreign[3].marker==57 and r.world.peek('stores').marker==57)
assert(g.IsCanonical()and not r.api.Install()and not r.api.PhysicalUnregistration,'same canonical public view after logical disposal')
print('PASS lot55 world: all eight actual consumers on canonical World35/cache; copy isolation, queued revocation, foreign listener retained, inert shells explicit; no static worker/service start or real platform')
