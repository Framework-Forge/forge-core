local T=dofile('tests/kernel_initialization_harness.lua');local r=T.new();r.prepare()
local actual={};local seen={}
local function walk(v)
    if type(v)~='table'or seen[v]then return end;seen[v]=true
    if type(v.Initialize)=='function'then actual[v.Initialize]=true end
    for _,fn in ipairs(v.Initializers or{})do actual[fn]=true end
    for key,child in pairs(v)do if key~='Config'and key~='State'and key~='Base'and key~='InitializationSequence'then walk(child)end end
end
walk(r.graph)
local selected={};for _,d in ipairs(r.api.Describe())do selected[d.handler]=true end
local p=r.graph.Central.Parts;local a=r.graph.Parts.AutoMedic
for _,fn in ipairs({p.Producers.Cache.Initialize,p.Producers.Session.Initialize,p.Legacy.Utils.Initialize,p.Legacy.Groups.Initialize,
    p.Runtime.Main.Initialize,p.Runtime.Discord.Initialize,a.Hospital.Initialize,a.Session.Initialize})do selected[fn]=true end
local count=0;for fn in pairs(actual)do assert(selected[fn],'omitted reachable initializer');count=count+1 end
for fn in pairs(selected)do assert(actual[fn],'invented initializer')end
assert(count==15 and #r.api.Describe()==7,'seven stages/fifteen methods including parents/eleven leaves')
local descriptors=r.api.Describe();assert(descriptors[1].handler==r.graph.Parts.World.World.Initialize and descriptors[7].handler==r.graph.Parts.Starterpack.Initializers[1])
local old=r.graph.Central.Parts.Runtime.Main.Initialize;r.graph.Central.Parts.Runtime.Main.Initialize=function()end
assert(not r.api.Initialize()and r.readyCalls==0,'changed child initializer refused before work');r.graph.Central.Parts.Runtime.Main.Initialize=old
local late=T.new();late.apply('stores',{settings={enabled=false},stores={}});late.prepare();local before=late.fixture.snapshot()
local ok,err=late.api.Initialize();assert(not ok and tostring(err):find('late initialization would clear hydrated World:',1,true));T.H.same(late.fixture.snapshot(),before,'late cache not cleared')
assert(late.world.getRecord('stores')and late.api.Progress().ledger[1]=='pending','already hydrated World preserved before any initializer')
print('PASS lot56 independent coverage: all15 reachable initializer functions, seven stages/eleven unique leaves; World first/Starterpack last; changed child and late hydration refused')
