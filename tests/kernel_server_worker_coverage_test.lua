local T=dofile('tests/kernel_server_worker_harness.lua');local r=T.new();local before=r.fixture.snapshot()
r.prepare();T.H.same(r.fixture.snapshot(),before,'server context construction inert');assert(#r.clock.queue==0)
local found,seen,visited={}, {}, {}
local excluded=r.graph.PlayerCore.Producers.Status.Status.Initialize -- Per-player API, not zero-argument bootstrap.
local function walk(t,path)
    if type(t)~='table'or visited[t]then return end;visited[t]=true
    for key,value in pairs(t)do
        if type(value)=='function'and(key=='Initialize'or key=='start'or key=='Bootstrap')and value~=excluded then found[value]=path..'.'..key end
    end
    for key,value in pairs(t)do if key~='Base'and key~='State'and key~='Config'then walk(value,path..'.'..tostring(key))end end
end
walk(r.graph,'graph')
local total=0
for _,entry in ipairs(r.api.Initialization.Describe())do
    if entry.name~='Bootstrap.Begin'then assert(found[entry.handler],'invented server startup '..entry.name);seen[entry.handler]=true;total=total+1 end
end
-- Runtime parent invokes these children itself; they must not be run as extra stages.
seen[r.graph.PlayerCore.Runtime.Main.Initialize]=true;seen[r.graph.PlayerCore.Runtime.Commands.Initialize]=true
local methods=0;for fn,path in pairs(found)do assert(seen[fn],'omitted server startup '..path);methods=methods+1 end
assert(methods==31 and total==29,'31 startup methods/29 roots plus Begin')
local threads,walked={},{ }
local function workers(t)
    if type(t)~='table'or walked[t]then return end;walked[t]=true
    for _,fn in ipairs(t.Threads or{})do threads[fn]=true end
    for key,value in pairs(t)do if key~='Base'and key~='State'and key~='Config'then workers(value)end end
end
workers(r.graph);local selected={}
for _,d in ipairs(r.api.Describe())do local v=r.graph;for key in d.name:gmatch('[^.]+')do v=v[tonumber(key)or key]end;assert(threads[v]);selected[v]=true end
local n=0;for fn in pairs(threads)do assert(selected[fn],'omitted static server worker');n=n+1 end;assert(n==2)
assert(not pcall(r.factory,r.fixture.base,r.ports),'cannot adopt old server graph')
assert(#r.api.Bootstrap.Events==2,'supplemental events remain described not installed')
print('PASS lot59 independent31-method/two-static-worker coverage,30 ordered roots including prelude;no per-player Status.Initialize or duplicate Runtime children;constructor inert')
