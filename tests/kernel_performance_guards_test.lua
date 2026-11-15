local T=dofile('tests/kernel_native_execution_harness.lua')
local r=T.new('client')
local env=T.H.environment({load=load})
r.factory=T.H.load(T.path,env)
local names={}
for i=1,300 do local name='native'..i;names[i]=name;r.native[name]=function()return nil,false,7 end end
r.allocate();local bound=r.api.Bind(names)
local values=table.pack(bound.native1())
assert(values.n==3 and values[1]==nil and values[2]==false and values[3]==7)
-- Replacing any bound port must invalidate even an unrelated function.
for i=1,300 do
    local name=names[i];local old=r.native[name];r.native[name]=function()end
    assert(not r.api.IsCurrent()and not pcall(bound.native1),'missed replacement '..name)
    r.native[name]=old;assert(r.api.IsCurrent())
end
r.native.later=function()return 19 end
local later=r.api.Bind({'later'}).later;assert(later()==19)
r.native.later=function()return 20 end;assert(not pcall(bound.native1))
r.api.Close();assert(not pcall(later))
-- Every descriptor, array size and parent replacement remains checked.
local W=dofile('tests/kernel_worker_harness.lua');local w=W.new();w.prepare()
local check
for i=1,30 do local k,v=debug.getupvalue(w.api.Start,i);if k=='canonical'then check=v end end
assert(check and check())
for _,item in ipairs(w.api.Describe())do
    local value=w.graph;local keys={};for key in item.name:gmatch('[^.]+')do keys[#keys+1]=tonumber(key)or key end
    for i=1,#keys-1 do value=value[keys[i]]end
    local key=keys[#keys];local original=value[key]
    value[key]=function()end;assert(not check(),item.name);value[key]=original;assert(check())
    value[#value+1]=function()end;assert(not check());value[#value]=nil;assert(check())
end
w.api.Close();assert(not check())
print('PASS performance guards: compiled 300-reference validation, late binding, tuples, revocation, all 27 worker replacements and array lengths')
