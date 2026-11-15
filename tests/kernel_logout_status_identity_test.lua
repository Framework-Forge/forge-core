local T=dofile('tests/kernel_runtime_import_harness.lua')
local r=T.context();r.prepareImports();assert(r.installImports())
local before=r.fixture.state.Status
before.health=35;before.oxygen=19;before.transient=true
local status=r.graph.Central.Parts.Producers.Status
local handler
for _,entry in ipairs(status.Events)do
 if entry.name=='QBCore:Client:OnPlayerUnload'then handler=entry.handler end
end
assert(handler);handler()
assert(r.fixture.state.Status==before,'logout must preserve status identity')
assert(before.health==100 and before.oxygen==100 and before.transient==nil)
assert(r.api.IsCurrent(),'logout must not revoke framework imports')
local producer=r.graph.Central.Parts.Producers.Cache.Producer
producer.session(false)
producer.player({citizenid='NEXT',metadata={health=200}},'next-character')
assert(r.api.IsCurrent(),'next character can publish through the same scope')
assert(r.api.Stop())
print('PASS logout status reset preserves imports/cache and next-character publication')
