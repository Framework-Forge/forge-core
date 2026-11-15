local T=dofile('tests/kernel_progress_shutdown_harness.lua');local cases=0
do local r=T.new();assert(not pcall(r.factory,r.ports));assert(r.api.Close());cases=cases+1 end
do local r=T.new();r.refuseRemove=true;r.begin('progressBar',{duration=99999});assert(not r.api.CloseIngress())
assert(r.state.invBusy=='before'and r.api.Progress().listeners==1);r.refuseRemove=false;r.step(1);assert(r.api.Close());cases=cases+1 end
do local r=T.new();r.begin('progressBar',{duration=99999})
r.environment.TriggerEvent=function()error('unused copied environment')end
assert(r.api.CloseIngress());r.step(1);assert(r.api.Close());cases=cases+1 end
do local r=T.P.new(false);local original=r.environment.TriggerEvent
r.environment.TriggerEvent=function(action,data)if data=='progress:hide'then error('hide failed')end;return original(action,data)end
r.api=T.H.load('../pr_bridge/bridge/delivery/forge_client_progress_shutdown.lua',T.H.environment())(r.ports)
assert(r.api.Open());r.lib=r.api.Library;r.begin('progressBar',{duration=99999});assert(not r.api.CloseIngress())
assert(r.api.Progress().uncertain and not r.api.Close()and r.core.forgeProgressScope==r.api)
r.step(1);assert(not r.api.Close()and #r.api.Progress().errors>0);cases=cases+1 end
do local r=T.new();r.current=false;assert(not pcall(r.lib.progressActive));assert(r.api.Close());cases=cases+1 end
assert(cases==5);print('PASS156 five scope checks:collision,removal retry,copied environment,cleanup error retained,stale')
