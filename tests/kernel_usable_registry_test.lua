local C=dofile('tests/kernel_consumables_harness.lua')
local total=0
local p=C.registryPair()
local cb=function(src,item)return src==1 and item.name=='burger'and false or true end
p.run('register with local fallback and both PR hooks',function(r)return r.api.RegisterUsableItem('burger',cb,{cancelUse=true})end)
p.run('local invocation',function(r)return r.items.burger(1,{slot=3})end)
p.run('cross-route duplicate',function(r)return r.hooks[1].handler({source=1,item='burger',slot=3})end)
p.run('independent slot',function(r)return r.hooks[2].handler({source=1,item={name='burger',slot=4}})end)
p.run('filter mismatch',function(r)return r.hooks[1].handler({source=1,item='water',slot=3})end)
p.run('expiry',function(r)for _,fn in ipairs(r.timers)do fn()end;r.timers={};return r.items.burger(1,'bad')end)
p.run('different source',function(r)return r.items.burger(2,{name='burger',slot=3})end)
total=total+p.count
for _,opts in ipairs({{}, {cancelUse=false}, {disableFrameworkFallback=true}, {disableInventoryHook=true},
    {disableFrameworkFallback=true,disableInventoryHook=true}, {debug=true}})do
    local x=C.registryPair()
    x.run('options register',function(r)return r.api.RegisterUsableItem('burger',function()return nil end,opts)end)
    x.run('nil return and normalized payload',function(r)
        if r.items.burger then return r.items.burger(1,{})end
        if r.hooks[1]then return r.hooks[1].handler({source=1,item='burger'})end
    end)
    x.run('duplicate cancel semantics',function(r)
        if r.items.burger then return r.items.burger(1,{})end
        if r.hooks[1]then return r.hooks[1].handler({source=1,item='burger'})end
    end)
    total=total+x.count
end
for _,case in ipairs({'local-false','local-error','hook-false','hook-error','both-error'})do
    local x=C.registryPair(function(r)
        if case=='local-false'then r.localResult=false end
        r.localError=case=='local-error'or case=='both-error'
        r.hookResult=case~='hook-false';r.hookError=case=='hook-error'or case=='both-error'
    end)
    x.run(case,function(r)return r.api.RegisterUsableItem('burger',function()error('use-error',0)end)end)
    x.run(case..' callback failure',function(r)if r.items.burger then return r.items.burger(1,{slot=2})end end)
    total=total+x.count
end
for _,name in ipairs({'',false,1})do
    local x=C.registryPair();x.run('invalid name',function(r)return r.api.RegisterUsableItem(name,cb)end);total=total+x.count
end
p=C.registryPair();p.run('invalid callback',function(r)return r.api.RegisterUsableItem('burger',false)end);total=total+p.count
print('PASS '..total..' usable-registry differential cases; local authority + PR hooks, shared dedup/timeout, payloads, cancel/nil/errors and inherited partial registration')
