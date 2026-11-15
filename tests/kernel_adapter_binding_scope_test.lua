local T=dofile('tests/kernel_adapter_binding_harness.lua')
for _,stage in ipairs({'listen','mark'})do
    local r=T.new();r.mount();local once=false;r[stage..'Hook']=function()if not once then once=true;coroutine.yield()end end
    local co=coroutine.create(function()assert(not pcall(r.api.Install))end)
    assert(coroutine.resume(co));r.api.Close();assert(not r.api.Progress().complete)
    assert(coroutine.resume(co));r.api.Close();assert(r.api.Progress().complete and r.active()==0 and r.target.framework==nil)
end
local refused=T.new();refused.mount();refused.api.Install();local held=refused.target.framework
refused.refuseRemove=true;assert(not refused.api.Close()and not refused.api.Progress().complete)
refused.emit('QBCore:Player:SetPlayerData',T.C.data());assert(held.GetPlayerData()==nil and next(refused.source.view.PlayerData)==nil)
refused.refuseRemove=false;assert(refused.api.Close()and refused.api.Progress().complete)
local server=T.new('server');local base=server.ports.callbacks;local bind=base.Bind
server.ports.callbacks={Protocol='native',Side='server',IsReady=base.IsReady,Reserve=base.Reserve,Release=base.Release,
    Bind=function(...)coroutine.yield();return bind(...)end}
server.mount();server.api.Install();local before=server.wire.server.active()
local cb=coroutine.create(function()assert(not pcall(server.target.framework.RegisterCallback,'forge83:late',function()return'x'end))end)
assert(coroutine.resume(cb));assert(not server.api.Close()and not server.api.Progress().complete,'in-flight Bind defers lease Release')
assert(coroutine.resume(cb));assert(server.api.Close()and server.api.Progress().complete and server.wire.server.active()==before,'late callback removed after Bind returns')
local read=T.new('server');local raw=read.ports.callbacks
read.ports.callbacks={Protocol='native',Side='server',IsReady=function()coroutine.yield();return true end,Reserve=raw.Reserve,Bind=raw.Bind,Release=raw.Release}
read.mount();read.api.Install();local cr=coroutine.create(function()assert(not pcall(read.target.framework.RegisterCallback,'forge83:no-reserve',function()end))end)
assert(coroutine.resume(cr));read.api.Close();assert(coroutine.resume(cr));assert(read.api.Progress().complete and not read.wire.server.find('forge83:no-reserve'))
local active=T.new('server');active.mount();active.api.Install()
active.target.framework.RegisterCallback('forge83:inflight',function(source,...)coroutine.yield();return source,... end)
local ca=coroutine.create(function()return active.wire.client.api.native.await('forge83:inflight',5000,false,nil,83)end)
assert(coroutine.resume(ca));active.api.Close();assert(not active.api.Progress().complete)
T.H.same(table.pack(coroutine.resume(ca)),table.pack(true,2,false,nil,83));assert(active.api.Progress().complete)
local leaseFail=T.new('server');leaseFail.mount();leaseFail.api.Install()
leaseFail.target.framework.RegisterCallback('forge83:retry',function()return'live'end)
leaseFail.wire.server.failRemove=leaseFail.wire.server.find('forge83:retry')
assert(not leaseFail.api.Close()and leaseFail.api.Progress().callbackLeasesRemaining==1)
leaseFail.wire.server.failRemove=nil;assert(leaseFail.api.Close()and leaseFail.api.Progress().complete)
print('PASS lot83 scope:Close during listener/network mark,late token retirement,remove failure/retry,callback Bind/readiness/in-flight wire await and exact lease drain,no Reserve after Close;virtual only')
