local T=dofile('tests/kernel_shutdown_harness.lua');local r=T.new();local before=r.fixture.snapshot()
r.prepareShutdown();T.H.same(r.fixture.snapshot(),before,'shutdown constructor inert');assert(r.active()==0 and #r.clock.queue==0)
local found,visited={},{}
local function walk(t,path)
    if type(t)~='table'or visited[t]then return end;visited[t]=true
    for i,d in ipairs(t.Events or{})do if d.name=='onResourceStop'then found[d.handler]=path..'.Events.'..i end end
    for k,v in pairs(t)do if k~='Core'and k~='State'and k~='Config'then walk(v,path..'.'..tostring(k))end end
end
walk(r.graph,'graph')
local n,seen=0,{}
for _,d in ipairs(r.api.Describe())do
    local value=r.graph;for key in d.name:gmatch('[^.]+')do value=assert(value[tonumber(key)or key])end
    assert(found[value.handler],'invented teardown');assert(not seen[value.handler],'duplicate teardown alias');seen[value.handler]=true;n=n+1
end
for fn,path in pairs(found)do assert(seen[fn],'omitted teardown '..path)end
assert(n==16,'independent16 cleanup coverage')
assert(r.install());assert(r.active('onResourceStop')==1,'single domain-stop listener')
assert(r.active()==76,'91 original descriptors minus16 virtual stops plus one native root')
local names=r.api.Describe();assert(names[1].name:find('Producers.Status',1,true)and names[16].name:find('Vinewood',1,true),'original relative teardown order')
assert(not pcall(r.factory,r.worker,r.ports),'cannot adopt existing binders')
print('PASS lot58 independent16 cleanup coverage, original aliases/order, same graph and inert construction;91 Events51 descriptors/one domain-stop listener')
