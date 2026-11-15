local T=dofile('tests/kernel_subscription_harness.lua');local r=T.new();r.prepare()
local function coverage(graph,entries)
    local seen,expected,actual={},{},{}
    local function walk(v)
        if type(v)~='table'or seen[v]then return end;seen[v]=true
        for _,d in ipairs(v.Subscriptions or{})do expected[d.key]=expected[d.key]or{};expected[d.key][d.handler]=true end
        for key,child in pairs(v)do if key~='Config'and key~='State'and key~='Base'then walk(child)end end
    end
    walk(graph)
    for _,d in ipairs(entries)do actual[d.key]=actual[d.key]or{};assert(not actual[d.key][d.handler],'duplicate subscribed alias');actual[d.key][d.handler]=true end
    local count=0
    for key,handlers in pairs(expected)do for fn in pairs(handlers)do assert(actual[key]and actual[key][fn],'omitted/foreign reachable subscription '..key);count=count+1 end end
    for key,handlers in pairs(actual)do for fn in pairs(handlers)do assert(expected[key]and expected[key][fn],'invented subscription '..key)end end
    return count
end
assert(coverage(r.graph,r.api.Describe())==8,'all eight actual descriptors')
for i,key in ipairs({'objects','npcs','spotlights','billboards','stores','farms','starterpack','vinewood'})do assert(r.api.Describe()[i].key==key,'installed relative manifest order')end
local server=r.fixture.server.mount();assert(coverage(server,{})==0,'no invented server subscription registration')
local snapshot=r.fixture.snapshot();r.api.Install();T.H.same(r.fixture.snapshot(),snapshot,'binding is not hydration/replay/worker start')
local existing=r.world.onChange;r.world.onChange=function()error('replacement must invalidate')end
assert(r.api.Dispose()and not r.api.Install());r.world.onChange=existing
print('PASS lot55 independent coverage: eight unique real client50 key/function subscriptions, aggregate aliases not doubled, original relative order; zero reachable server subscriptions; install inert')
