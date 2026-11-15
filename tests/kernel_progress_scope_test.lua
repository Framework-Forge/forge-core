local T=dofile('tests/kernel_progress_harness.lua');local r=T.new(true);assert(not pcall(r.factory,r.ports));r.invokeOwner='other-resource'
r.begin('progressBar',{duration=90000,canCancel=false});assert(r.api.Progress().pending==1);assert(not r.api.Close());assert(next(r.handlers)==nil)
r.step(1);assert(r.result[1]and r.result[2]==false and r.state.invBusy=='before');assert(r.api.Close()and r.core.forgeProgressScope==nil)
assert(not pcall(r.lib.progressActive));local q=T.new(true);q.current=false;assert(not pcall(q.lib.progressActive));assert(q.api.Close())
local s=T.new(true);s.refuseRemove=true;assert(not s.api.Close());s.refuseRemove=false;assert(s.api.Close())
local x=T.new(true);x.environment.GetCurrentResourceName=function()return'other'end -- existing engine closure still uses the supplied function from Open
x.api.Close();local p=T.new(true);assert(p.lib.progress==p.lib.progressbar);p.api.Close()
print('PASS151 six duplicate/foreign-owner-close/closed/stale/removal-retry/alias checks;pending accepted work drains without releasing borrowed state')
