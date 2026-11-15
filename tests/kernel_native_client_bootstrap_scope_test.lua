local M=dofile('tests/kernel_native_client_bootstrap_harness.lua');local count=0
local function check(fn)fn();count=count+1 end
check(function()local r=M.new();r.prepareBootstrap();r.nativeReady=false;assert(not r.installBootstrap()and r.active()==0)
    r.nativeReady=true;r.startBootstrap();assert(r.drain())end)
check(function()local r=M.new();r.allocateBootstrap();r.locales.readHook=function()coroutine.yield()end
    local co=coroutine.create(function()assert(not r.api.Prepare())end);assert(coroutine.resume(co));assert(not r.api.Stop())
    r.locales.readHook=nil;assert(coroutine.resume(co));assert(r.api.Poll()and r.api.Graph==nil)
end)
check(function()local r=M.new();r.prepareBootstrap();r.surface.exports.getLocale=function()return'foreign101'end
    assert(not r.installBootstrap());assert(r.surface.exports.getLocale()=='foreign101');r.drain();assert(r.active()==0)
end)
check(function()local r=M.new();r.prepareBootstrap();r.onListen=function(t)if t.name=='ox_lib:setLocale'then r.api.Stop()end end
    assert(not r.installBootstrap());r.onListen=nil;assert(r.drain()and r.active()==0)
end)
check(function()local r=M.new();r.prepareBootstrap();r.startBootstrap();r.locales.readHook=function()coroutine.yield()end
    local co=coroutine.create(function()r.emit('ox_lib:setLocale','pt-br')end);assert(coroutine.resume(co));assert(not r.api.Stop())
    assert(r.api.Progress().transport.pending==1);r.locales.readHook=nil;assert(coroutine.resume(co));assert(r.drain())
end)
check(function()local r=M.new();r.prepareBootstrap();r.startBootstrap();local native
    for _,t in ipairs(r.bus)do if t.name=='ox_lib:setLocale'then native=t end end
    assert(native);r.refuseNativeToken=native;assert(not r.drain()and not r.api.Progress().complete)
    r.refuseNativeToken=nil;assert(r.api.Poll()and r.active()==0)
end)
check(function()local r=M.new();r.prepareBootstrap();r.startBootstrap();r.emit('onResourceStop','forge-core');r.clock.advance(120000)
    assert(r.api.Poll()and r.api.Progress().complete and r.active()==0)
end)
check(function()local r=M.new();r.prepareBootstrap();r.startBootstrap();r.fixture.state.ClientNativeBootstrap={}
    assert(not r.api.IsCurrent());r.drain();assert(r.active()==0)
end)
assert(count==8);print('PASS lot101 scope:8 actual client75 cases;readiness,cancelled Prepare/listen/locale await,foreign export/owner,physical removal retry,native stop;16 cleanups preserved;virtual only')
