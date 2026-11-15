local T=dofile('tests/kernel_progress_shutdown_harness.lua')
for _,anim in ipairs({{dict='dict',clip='clip'},{scenario='WORLD_HUMAN_STAND_IMPATIENT'}})do
    local r=T.new();r.invokeOwner='another_resource'
    r.begin('progressBar',{duration=999999,canCancel=false,prop={model='prop'},anim=anim})
    assert(r.state.invBusy==true and r.api.Progress().pending==1)
    assert(r.api.CloseIngress());assert(r.state.invBusy=='before'and coroutine.status(r.co)=='suspended')
    assert(T.count(r,'event','pr_bridge:ui:send')==2 and T.count(r,'serverEvent','pr_bridge:progressProps')==2)
    assert(T.count(r,anim.dict and'stopAnim'or'clearTasks')==1)
    assert(not r.api.Close()and r.api.Progress().cleanupAttempted and not r.api.Progress().complete)
    assert(not pcall(r.lib.progressActive));local count=#r.trace
    r.step(1);assert(r.result[1]and r.result[2]==false and #r.trace==count)
    assert(r.api.Close()and r.api.Progress().complete and r.core.forgeProgressScope==nil)
end
local a=T.P.new(false);local b=T.new();local d={duration=9000,anim={dict='d',clip='c'},prop={model='p'}}
a.begin('progressCircle',d);b.begin('progressCircle',d)
a.handlers[1][2]('forge-core');b.api.CloseIngress()
assert(#a.trace==#b.trace);for i,e in ipairs(a.trace)do assert(e[1]==b.trace[i][1]and e[2]==b.trace[i][2])end
a.step(1);b.step(1);assert(a.result[2]==false and b.result[2]==false and b.api.Close())
print('PASS156 installed self-stop cleanup without coroutine resume;animation/scenario/props/state parity;drain retained/idempotent')
