local T=dofile('tests/kernel_worker_harness.lua');local r=T.new();local before=r.fixture.snapshot()
r.prepare();T.H.same(r.fixture.snapshot(),before,'fresh construction inert');assert(#r.clock.queue==0)
local found,visited={},{}
local function walk(value,path)
    if type(value)~='table'or visited[value]then return end;visited[value]=true
    for key,item in pairs(value)do
        if key=='Threads'and type(item)=='table'then
            for i,fn in ipairs(item)do assert(type(fn)=='function');found[fn]=path..'.Threads.'..i end
        elseif key~='Core'and key~='State'and key~='Config'then walk(item,path..'.'..tostring(key))end
    end
end
walk(r.graph,'graph')
local seen={};local total=0
for _,entry in ipairs(r.api.Describe())do
    local value=r.graph;for key in entry.name:gmatch('[^.]+')do value=assert(value[tonumber(key)or key],entry.name)end
    assert(found[value],'invented worker '..entry.name);assert(not seen[value],'duplicate worker alias '..entry.name)
    seen[value]=true;total=total+1
end
for fn,name in pairs(found)do assert(seen[fn],'omitted reachable worker '..name)end
assert(total==27,'independent 27-worker coverage')
local names=r.api.Describe();assert(names[1].name=='Central.Parts.Runtime.Main.Threads.1'and names[27].name=='Parts.Jobs.Bootstrap.Threads.1','relative manifest order')
assert(r.fixture.state.PlayerData==r.fixture.central.state.PlayerData and r.graph.Central.Core==r.fixture.state)
assert(not pcall(r.factory,r.fixture.state,r.ports),'cannot adopt already constructed graph')
assert(r.api.Close()and not r.api.Start()and not r.api.Close())
local drift=T.new();drift.prepare();table.insert(drift.graph.Parts.Stores.Threads,function()end)
assert(not pcall(drift.api.Start),'late descriptor insertion rejected')
print('PASS lot57 independent 27-worker coverage: aliases deduplicated, fresh construction inert, same canonical state, no old graph adoption')
