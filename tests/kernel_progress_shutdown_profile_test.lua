local T=dofile('tests/kernel_progress_shutdown_profile_harness.lua')
for _,native in ipairs({false,true})do
    local r=T.new('client');local p=r.open158(true);local result
    local co=coroutine.create(function()result=table.pack(pcall(p.ProgressScope.Library.progressBar,{duration=999999,canCancel=false,anim={dict='d',clip='c'}}))end)
    assert(coroutine.resume(co));assert(r.progressFixture.state.invBusy==true)
    if native then
        r.fireStop158('foreign');assert(r.progressFixture.state.invBusy==true)
        -- First domain handler runs before the progress engine's own listener.
        r.fireStop158('forge-core');assert(p.StopBoundary.Progress().signals>=1)
    else assert(not p.Stop())end
    assert(r.progressFixture.state.invBusy=='before'and coroutine.status(co)=='suspended')
    assert(p.ProgressScope.Progress().listeners==0 and p.ProgressScope.Progress().pending==1)
    assert(not p.Poll()and r.seed.IsCurrent())
    assert(coroutine.resume(co));assert(result[1]and result[2]==false)
    r.clock.advance(120000);assert(p.Poll()and p.Progress().complete)
    assert(#r.fixture.state.ClientMediaContext.Sequence.Progress().ledger==16 and r.seed.IsCurrent())
    r.platform.Close();r.utilities.Close();r.finishProfile()
end
local r=T.new('server');local p=r.open158(false);assert(p.ProgressScope==nil and p.StopBoundary==nil);p.Stop();r.finishProfile()
print('PASS158 manual/native-first stop cleanup while suspended;pending/drain retained;16 domain cleanup;server149 preserved')
