local M=dofile('tests/kernel_native_bootstrap_harness.lua');local count=0
local function check(fn)fn();count=count+1 end
check(function()local r=M.server();r.prepareBootstrap();r.nativeReady=false;assert(not r.installBootstrap());assert(r.active()==0)
    r.nativeReady=true;r.startBootstrap();assert(r.drain())end)
check(function()local r=M.server();r.allocateBootstrap();r.locales.readHook=function()coroutine.yield()end
    local co=coroutine.create(function()assert(not r.api.Prepare('en'))end);assert(coroutine.resume(co));assert(not r.api.Stop())
    r.locales.readHook=nil;assert(coroutine.resume(co));assert(r.api.Poll()and r.api.Progress().complete and r.api.Graph==nil)
end)
check(function()local r=M.server();r.prepareBootstrap();r.surface.exports.getLocale=function()return'foreign100'end
    assert(not r.installBootstrap());assert(r.surface.exports.getLocale()=='foreign100');r.drain();assert(r.active()==0)
end)
check(function()local r=M.server();r.prepareBootstrap();r.onListen=function(t)if t.name=='ox_lib:setLocale'then r.api.Stop()end end
    assert(not r.installBootstrap());r.onListen=nil;assert(r.drain());assert(r.active()==0)
end)
check(function()local r=M.server();r.prepareBootstrap();r.startBootstrap();r.locales.readHook=function()coroutine.yield()end
    local co=coroutine.create(function()r.emit('ox_lib:setLocale','pt-br')end);assert(coroutine.resume(co));assert(not r.api.Stop())
    assert(r.api.Progress().transport.pending==1);r.locales.readHook=nil;assert(coroutine.resume(co));assert(r.drain())
end)
check(function()local r=M.server();r.prepareBootstrap();r.startBootstrap();local foreign={calls=0,Stop=function()error('foreign teardown')end}
    r.fixture.base.ServerNativeBootstrap=foreign;assert(not r.api.IsCurrent());r.drain();assert(foreign.calls==0)
end)
check(function()local r=M.server();r.prepareBootstrap();r.startBootstrap();r.emit('onResourceStop','forge-core');r.clock.advance(1200000)
    assert(r.api.Poll());assert(r.api.Progress().complete and r.active()==0)
end)
assert(count==7);print('PASS lot100 scope:7 actual server74 cases;readiness retry,Close during Prepare/listen/locale await,foreign export/owner and native stop;no second core or real runtime effects')
