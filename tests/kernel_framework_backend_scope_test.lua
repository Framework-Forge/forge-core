local T=dofile('tests/kernel_framework_backend_harness.lua');local r=T.new();r.backendReady=true
r.readyHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(not pcall(r.backend.Core.GetPlayer,2))end)
assert(coroutine.resume(co));assert(r.backend.Progress().pending==1);r.backend.Close();assert(not r.backend.Progress().complete)
assert(coroutine.resume(co));assert(r.backend.Progress().complete,'readiness await included;no lookup after Close');r.close()
for _,change in ipairs({'function','container','core','owner'})do
    local x=T.new();local held=x.backend.Core.GetPlayer;x.backendReady=true
    if change=='function'then x.graph.PlayerCore.Lookup.GetPlayer=function()return'foreign'end
    elseif change=='container'then local old=x.graph.PlayerCore.Lookup;local new={};for k,v in pairs(old)do new[k]=v end;x.graph.PlayerCore.Lookup=new
    elseif change=='core'then x.graph.PlayerCore={}
    else x.current=false end
    assert(not x.backend.IsCurrent()and not pcall(held,1),'foreign dependency refuses '..change);x.backend.Close();x.adapter.Close()
end
local late=T.new();late.backendReady=true;late.readyHook=function()error('ready unavailable',0)end
assert(not pcall(late.backend.Core.GetMoney,2,'cash')and late.backend.Progress().pending==0);late.close()
print('PASS lot82 scope:readiness await drain/Close prevents body,function/container/core/owner replacement refuses old handles,readiness exception unwinds;no live backend publication')
