local T=dofile('tests/kernel_consumer_delivery_harness.lua')
for _,stage in ipairs({'read','compile'})do
    local r=T.new();r.mount();local once=false
    r[stage..'Hook']=function()if not once then once=true;coroutine.yield()end end
    local co=coroutine.create(function()assert(not pcall(r.api.Prepare))end)
    assert(coroutine.resume(co));r.api.Close();assert(not r.api.Progress().complete)
    assert(coroutine.resume(co));assert(r.api.Progress().complete and r.api.Binding==nil and r.gets==0 and r.active()==0)
end
for _,source in ipairs({false,'this is not Lua','return {}'})do
    local r=T.new();r.mount();r.overrides['kernel/imports/require_binding.lua']=source
    assert(not pcall(r.api.Prepare)and r.active()==0 and r.target.qbx.foreign)
    assert(not r.api.Prepare());r.api.Close();assert(r.api.Progress().complete)
end
local r=T.new();r.mount();r.api.Prepare();r.api.Install();r.getHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(not pcall(r.api.ExecuteEntry,'modules.playerdata'))end)
assert(coroutine.resume(co));r.api.Close();assert(not r.api.Progress().complete)
assert(coroutine.resume(co));assert(r.api.Progress().complete and r.active()==0 and r.target.QBX==r.oldQBX)
local stale=T.new();stale.mount();stale.api.Prepare();stale.current=false
assert(not pcall(stale.api.Install));stale.api.Close();assert(stale.api.Progress().complete)
print('PASS lot79 scope:Close during source IO/compile/entry getter,missing/corrupt/wrong factory,no replay,stale owner,drain without namespace/listener reopening;no real delivery')
