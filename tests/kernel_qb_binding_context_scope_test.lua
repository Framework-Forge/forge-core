local T=dofile('tests/kernel_qb_binding_context_harness.lua');local H=T.H;local n=0
local r=T.unit();r.prepare();r.ready=false
assert(not r.binding.Install()and r.binding.Progress().complete and r.core.State=='installed'and r.bus.active()==2);n=n+1
local r=T.unit();r.prepare();local foreign=function()end;r.surface.exports.Existing=foreign
r.aliasForeign['__cfx_export_qb-core_GetCoreObject']=true
assert(not r.binding.Install()and r.binding.Progress().complete and r.surface.exports.Existing==foreign);n=n+1
local r=T.unit();r.prepare();r.aliasHook=function()coroutine.yield('preflight')end
local co=coroutine.create(r.binding.Install);assert(coroutine.resume(co));assert(not r.binding.Close())
r.aliasHook=nil;assert(coroutine.resume(co)and r.binding.Progress().complete and r.bus.active()==2);n=n+1
local r=T.unit();r.prepare();assert(r.binding.Install());local get=r.lookup('GetCoreObject')
r.bridge.readyHook=function()coroutine.yield('getter')end
local co=coroutine.create(get);assert(coroutine.resume(co));assert(not r.binding.Close())
r.bridge.readyHook=nil;assert(not coroutine.resume(co));assert(r.binding.Progress().complete and r.bus.active()==2);n=n+1
local r=T.unit();r.prepare();assert(r.binding.Install())
local key=r.lookup('KeyPressed');key();assert(r.binding.Progress().bridge.tasks==1)
assert(not r.binding.Close());r.bridge.runTask();assert(r.binding.Poll()and r.core.State=='installed');n=n+1
local r=T.unit();r.prepare();assert(r.binding.Install())
local token;for t,d in pairs(r.bus.records)do if d.name=='qb-core:client:DrawText'then token=t end end
r.bus.failRemove=token.id;assert(not r.binding.Close()and not r.binding.Progress().complete)
r.bus.failRemove=nil;assert(r.binding.Poll()and r.bus.active()==2);n=n+1
local r=T.unit();local other=T.unit()
assert(not pcall(r.factory,r.graph,r.qb,other.backend,r.bindingPorts));n=n+1
local r=T.unit();local other=T.unit()
-- Correct backend but a different bridge must fail the pre-publication identity proof.
local context=r.factory(r.graph,other.qb,r.backend,r.bindingPorts)
assert(not context.Install()and context.Progress().complete and r.bus.active()==2);n=n+1
local r=T.unit();r.prepare();assert(r.binding.Install())
r.graph.Core.EventRegistration={Side='client',State='installed'}
assert(not r.binding.IsCurrent());assert(r.lookup('GetCoreObject')==nil);r.binding.Close();n=n+1
local r=T.unit(true);r.prepare()
local accepted,why=r.binding.Install();assert(not accepted and why=='core_events_not_installed'and r.bus.active()==0)
r.installCore();assert(r.binding.Install());assert(r.binding.Close()and r.core.State=='installed');n=n+1
local r=T.unit();r.qb.Enabled=false;r.prepare()
local accepted,why=r.binding.Install();assert(not accepted and why=='qb_bridge_disabled'and r.bus.active()==2)
assert(r.binding.Close()and r.binding.Progress().complete and r.core.State=='installed');n=n+1
local r=T.unit();r.prepare();local partialCommit=0
r.bus.onListen=function(token,handler)
    if r.bus.records[token].name=='QBCore:Command:CallCommand'then
        r.bus.emit('__cfx_export_qb-core_GetCoreObject',0,function()partialCommit=partialCommit+1 end)
        handler('partial_commit95')
    end
end
assert(r.binding.Install()and partialCommit==0)
local getter=r.lookup('GetCoreObject');assert(type(getter)=='function'and getter()==r.bridge.object)
r.binding.Close();n=n+1
print('PASS lot95 scope:'..n..' checks;unready/foreign names,Close during install/getter/timer/removal retry,mixed backend/bridge refused,core registry replacement,late core install/disabled bridge,ingress waits for both commits;no core shutdown')
