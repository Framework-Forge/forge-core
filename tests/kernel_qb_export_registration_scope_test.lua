local T=dofile('tests/kernel_qb_export_registration_harness.lua');local n=0
local r=T.new('server');r.aliasForeign.__cfx_export_qb_core_fake=true
r.aliasForeign['__cfx_export_qb-core_GetCoreObject']=true
assert(not r.api.Install()and r.bus.active()==0 and next(r.surface.exports)==nil)
r.aliasForeign={};assert(r.api.Install());r.api.Dispose();n=n+1
local r=T.new('server');r.surface.exports.SetField=function()end
assert(not r.api.Install()and r.bus.active()==0);r.api.Dispose();n=n+1
local r=T.new('server');r.surface.onPublish=function()r.aliasForeign['__cfx_export_qb-core_GetCoreObject']=true end
assert(not r.api.Install()and r.bus.active()==0);assert(r.surface.exports.SetField('x',1)==nil);assert(r.api.Progress().complete);n=n+1
local r=T.new('client');r.aliasHook=function()r.current=false end
assert(not r.api.Install()and r.bus.active()==0);r.api.Dispose();n=n+1
local r=T.new('client');r.aliasHook=function()coroutine.yield('alias preflight')end
local co=coroutine.create(r.api.Install);assert(coroutine.resume(co));assert(not r.api.Dispose())
r.aliasHook=nil;assert(coroutine.resume(co));assert(r.bus.active()==0 and r.api.Progress().complete);n=n+1
local r=T.new('client');r.install();local retained=r.lookup('GetCoreObject')
r.bridge.readyHook=function()coroutine.yield('getter')end
local co=coroutine.create(retained);assert(coroutine.resume(co));assert(r.api.Progress().pending==1)
assert(r.api.Dispose());assert(not r.api.Progress().complete)
r.bridge.readyHook=nil;local ok,obj=coroutine.resume(co);assert(ok and obj==r.bridge.object and r.api.Progress().complete);n=n+1
local r=T.new('client');r.install()
local token;for t,d in pairs(r.bus.records)do if d.active then token=t;break end end
r.bus.failRemove=token.id;assert(not r.api.Dispose());assert(r.api.Progress().phase=='close-failed')
assert(r.lookup('GetCoreObject')==nil);r.bus.failRemove=nil;assert(r.api.Dispose()and r.bus.active()==0);n=n+1
local r=T.new('client');r.install();local ref=r.lookup('GetCoreObject')
r.bridge.api.Exports.GetCoreObject=function()return'foreign'end
assert(ref()==nil);assert(r.api.Dispose());n=n+1
local r=T.new('client');r.bus.failAt=2
assert(not r.api.Install()and r.bus.active()==0);assert(r.api.Progress().complete);n=n+1
print('PASS lot93 scope:'..n..' checks;foreign aliases/resource names,post-publication race,await/Close/getter drain,failed removal retry,changed callback,partial installation;all effects virtual')
