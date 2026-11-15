local T=dofile('tests/kernel_state_input_harness.lua')
local function coverage(graph,described)
    local seen,expected,actual={},{},{}
    local function add(kind,key,filter,handler)
        local id=kind..':'..key..':'..tostring(filter)
        assert(not expected[id]or expected[id]==handler,'reachable descriptor collision '..id);expected[id]=handler
    end
    local function walk(v)
        if type(v)~='table'or seen[v]then return end;seen[v]=true
        for _,d in ipairs(v.StateBags or{})do add('bag',d.key,d.filter,d.handler)end
        for _,d in ipairs(v.EntityStateHandlers or{})do add('entity',d.key,'',d.handler)end
        for _,d in ipairs(v.Keybinds or{})do add('key',d.name,nil,d.onPressed)end
        for key,child in pairs(v)do if key~='Config'and key~='State'and key~='Base'then walk(child)end end
    end
    walk(graph)
    for _,d in ipairs(described.bags)do
        local id=(d.entity and'entity:'or'bag:')..d.key..':'..tostring(d.entity and''or d.filter)
        assert(not actual[id],'duplicate selection '..id);actual[id]=d.handler
    end
    for _,d in ipairs(described.keys)do local id='key:'..d.name..':nil';assert(not actual[id]);actual[id]=d.onPressed end
    local count=0;for id,handler in pairs(expected)do assert(actual[id]==handler,'omitted/foreign descriptor '..id);count=count+1 end
    for id in pairs(actual)do assert(expected[id],'invented descriptor '..id)end
    return count
end
local r=T.new();r.prepare();assert(coverage(r.graph,r.api.Describe())==5,'all early descriptors')
r.api.Install();assert(coverage(r.graph,r.api.Describe())==6,'late hospital descriptor covered by name/function')
local hospital=r.graph.Parts.AutoMedic.Hospital;assert(not hospital.Initialize()and #hospital.Keybinds==1,'no duplicate late key')
assert(r.graph.Central.Parts.Consumption.Keybinds[1].combos==nil,'provider never mutates canonical descriptor')
local disabled=T.new('no-discord');disabled.prepare();disabled.api.Install();assert(coverage(disabled.graph,disabled.api.Describe())==5,'disabled Discord does not invent PlayerCount')
local pre=T.new();pre.graph.Parts.AutoMedic.Hospital.Initialize();pre.prepare();pre.api.Install();assert(coverage(pre.graph,pre.api.Describe())==6,'already prepared hospital key only once')
-- Same hospital initializer legitimately skips the descriptor when its original library port is absent.
local absent=T.new();absent.graphFixture.fixtures.AutoMedic.library.addKeybind=nil;absent.prepare();absent.api.Install()
assert(#absent.api.Describe().keys==1 and coverage(absent.graph,absent.api.Describe())==5,'absent hospital key port respected')
-- Core constructors described no server statebags/keys: verify this independently, not with an empty server binder.
local server=absent.graphFixture.server.mount();assert(coverage(server,{bags={},keys={}})==0)
print('PASS lot54 independent coverage: six reachable descriptors by name/function; five early, Discord-disabled/late/already-prepared/absent-key variants; zero server state/input descriptors')
