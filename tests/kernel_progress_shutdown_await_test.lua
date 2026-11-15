local P=dofile('tests/kernel_progress_shutdown_harness.lua');local H=P.H
local lease=H.load('../pr_bridge/bridge/delivery/forge_progress_streaming_lease.lua',H.environment())
for _,kind in ipairs({'model','anim'})do for _,fenced in ipairs({false,true})do
    local r=P.P.new(false);local method=kind=='model'and'requestModel'or'requestAnimDict'
    local original=r.streaming[method];r.streaming[method]=function(...)coroutine.yield('request');return original(...)end
    local api
    if fenced then r.ports.streaming=lease(r.streaming,function()return api and api.Progress().phase=='open'end)end
    api=H.load('../pr_bridge/bridge/delivery/forge_client_progress_shutdown.lua',H.environment())(r.ports)
    assert(api.Open());r.api=api;r.lib=api.Library
    r.begin('progressBar',{duration=99999,prop={model='prop'},anim=kind=='anim'and{dict='d',clip='c'}or nil})
    assert(r.api.Progress().pending==1);assert(r.api.CloseIngress()and r.state.invBusy=='before')
    local beforeProps=P.count(r,'serverEvent','pr_bridge:progressProps');local beforeAnim=P.count(r,'anim')
    r.step(1);assert(r.api.Close())
    if fenced then
        assert(not r.result[1]and tostring(r.result[2]):find('scope closed'))
        assert(P.count(r,'serverEvent','pr_bridge:progressProps')==beforeProps and P.count(r,'anim')==beforeAnim)
    elseif kind=='model'then assert(P.count(r,'serverEvent','pr_bridge:progressProps')==beforeProps+1)
    else assert(P.count(r,'anim')==beforeAnim+1)end
end end
print('PASS160 model/animation await late effects reproduced on unfenced156 and prevented by lease;request completion/error explicit')
