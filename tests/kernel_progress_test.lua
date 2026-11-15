local T=dofile('tests/kernel_progress_harness.lua')
for _,case in ipairs({{duration=20,label='plain',canCancel=true},{duration=20,label='anim',anim={dict='dict',clip='clip'},prop={model='prop'},disable={move=true,combat=true}},
    {duration=20,label='scenario',anim={scenario='scenario'}},{duration=0},{duration=20,useWhileDead=false}})do
    local a,b=T.new(false),T.new(true);a.dead=case.useWhileDead==false;b.dead=a.dead
    a.begin('progressBar',case);b.begin('progressBar',case);a.step(10);b.step(10);a.step(20);b.step(20)
    T.H.same(a.result,b.result,'result');T.H.same(a.trace,b.trace,'trace');assert(a.state.invBusy=='before'and b.state.invBusy=='before');assert(b.api.Close())
end
local c=T.new(true);c.begin('progressCircle',{duration=20,label='circle',canCancel=true});assert(c.lib.progressActive());assert(c.lib.progressBar({duration=1})==false)
c.lib.cancelProgress();c.step(1);assert(c.result[1]and c.result[2]==false and not c.lib.progressActive());c.api.Close()
print('PASS151 five installed-engine parity traces/results plus circle/concurrency/cancel;anim/props/control/state restoration unchanged')
