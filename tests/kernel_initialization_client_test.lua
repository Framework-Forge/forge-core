local T=dofile('tests/kernel_initialization_harness.lua');local r=T.new();local g=r.graph
local before=r.fixture.snapshot();r.prepare();T.H.same(r.fixture.snapshot(),before,'initialization constructor inert')
local data=r.fixture.state.PlayerData;local shared=r.fixture.state.Shared
assert(r.api.Initialize(),'actual client50 initializer sequence')
assert(not r.api.Initialize()and r.readyCalls==1,'same coordinator never initializes twice')
local p=r.api.Progress();assert(p.phase=='initialized'and p.inFlight==nil and #p.ledger==7)
for _,state in ipairs(p.ledger)do assert(state=='completed')end
assert(r.fixture.state.PlayerData==data and r.fixture.state.Shared==shared,'no second PlayerData/Shared authority')
assert(r.fixture.central.groupPulls==1,'actual Groups initializer called once through original port')
assert(#g.Parts.AutoMedic.Hospital.Keybinds==1 and not g.Parts.AutoMedic.Hospital.Initialize(),'actual Hospital descriptor initialized once')
assert(not g.Central.Parts.Producers.Initialize()and not g.Central.Parts.Legacy.Initialize()and not g.Central.Parts.Runtime.Initialize(),'original parent flags preserved')
assert(g.Central.Parts.Character.Flow.GetFallbackLocation(),'actual character fallback initialized')
assert(g.IsCanonical()and r.world==g.Client.WorldState,'same canonical World and graph after sequence')
assert(not r.api.StartsWorkers and not r.api.ReversesEffects,'initialization is not worker launch/teardown')
-- Actual subscription registration can precede initialization without replaying a packet or changing ownership.
local second=T.new();local subs=T.S.H.load('kernel/client/subscription_registration.lua',T.S.D.A.E.env())(second.graph)
subs.Install();second.prepare();assert(second.api.Initialize());second.apply('stores',{settings={enabled=false},stores={},marker=56});second.drain()
assert(second.graph.Parts.Stores.Stores.payload.marker==56,'first payload after initialization reaches same consumer')
assert(second.fixture.state.PlayerData~=second.graph.Parts.Stores.Stores.payload,'world does not become player authority')
-- Binder54 may already have prepared the Hospital descriptor; the parent must not register it twice.
local K=dofile('tests/kernel_state_input_harness.lua');local prior=T.new();local keyPort=K.ports()
keyPort.ports.resolveEntity=prior.graph.Central.Parts.Helpers.Lib.getEntityAndNetIdFromBagName
local bind=T.H.load('kernel/client/state_input_registration.lua',T.S.D.A.E.env())(prior.graph,keyPort.ports)
assert(bind.Install()and #prior.graph.Parts.AutoMedic.Hospital.Keybinds==1)
prior.prepare();assert(prior.api.Initialize()and #prior.graph.Parts.AutoMedic.Hospital.Keybinds==1,'parent reuses Hospital already prepared by54')
print('PASS lot56 client50: actual seven-stage initialization, original parent flags/Groups/Hospital/character fallback, same PlayerData/Shared/World; subscriptions before first packet; native/cache/groups/timers virtual, no static workers or real boot')
