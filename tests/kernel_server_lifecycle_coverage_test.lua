local T=dofile('tests/kernel_server_lifecycle_harness.lua');local r=T.new();local before=r.fixture.snapshot()
r.prepareLifecycle();T.H.same(r.fixture.snapshot(),before,'lifecycle construction inert');assert(r.active()==0 and #r.clock.queue==0)
local found={onResourceStart={},onResourceStop={}};local visited={}
local function walk(t)
    if type(t)~='table'or visited[t]then return end;visited[t]=true
    for _,d in ipairs(t.Events or{})do if found[d.name]then found[d.name][d.handler]=true end end
    for key,value in pairs(t)do if key~='Base'and key~='State'and key~='Config'then walk(value)end end
end
walk(r.graph);local descriptions=r.api.Describe()
for key,event in pairs({starts='onResourceStart',stops='onResourceStop'})do
    local seen={};for _,d in ipairs(descriptions[key])do assert(found[event][d.handler],'invented lifecycle body');assert(not seen[d.handler],'duplicate lifecycle alias');seen[d.handler]=true end
    local n=0;for fn in pairs(found[event])do assert(seen[fn],'omitted lifecycle body');n=n+1 end;assert(n==(key=='starts'and 8 or 5))
end
assert(not pcall(r.lifeFactory,r.fixture.base,r.lifePorts),'cannot adopt lifecycle owner')
assert(r.install());assert(r.active('onResourceStop')==1 and r.active('onResourceStart')==1,'one physical listener per resource lifecycle event')
local events=r.fixture.base.EventRegistration.Describe();assert(#events==73)
assert(r.marked['QBCore:Server:OnPlayerLoaded']and r.active('playerJoining')==2,'supplemental bootstrap events installed alongside original counter handler')
assert(#r.schema==0 and r.api.Worker.Progress().context=='prepared','Install performs no schema or service startup')
r.api.Stop();assert(r.api.Progress().complete)
print('PASS lot60 independent5-stop/8-start coverage,73+2 event descriptors, one resource listener each, inert construction/install, no alias replay')
