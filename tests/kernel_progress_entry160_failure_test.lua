local T=dofile('tests/kernel_progress_entry160_harness.lua')
do
    local r=T.client();local emit=r.env160.TriggerEvent
    r.env160.TriggerEvent=function(name,action,...)if name=='pr_bridge:ui:send'and action=='progress:hide'then error('cleanup UI failure')end;return emit(name,action,...)end
    local e=r.allocate160();assert(e.Prepare('pt-br'));r.surface.Open();assert(e.Install());r.runtimeImports.pollNative();assert(e.Start())
    local result;local co=coroutine.create(function()result=table.pack(pcall(e.Profile.ProgressScope.Library.progressBar,{duration=999999}))end)
    assert(coroutine.resume(co));r.stopListeners160[1]('forge-core')
    assert(e.Profile.StopBoundary.Progress().failures>=1 and e.Profile.ProgressScope.Progress().uncertain)
    assert(not e.Poll()and r.env160.PRCore.forgeNativeSeed~=nil)
    assert(coroutine.resume(co));r.clock.advance(120000);assert(not e.Poll()and not e.Progress().complete)
    assert(r.env160.PRCore.forgeNativeSeed~=nil and r.env160.PRCore.forgeProgressScope~=nil)
end
do
    local r=T.client();local refuse=false;local remove=r.options160.bootstrap.registration.native.RemoveEventHandler
    r.options160.bootstrap.registration.native.RemoveEventHandler=function(...)if refuse then return false end;return remove(...)end
    local e=r.allocate160();assert(e.Prepare('pt-br'));r.surface.Open();assert(e.Install());r.runtimeImports.pollNative();assert(e.Start())
    local result;local co=coroutine.create(function()result=table.pack(pcall(e.Profile.ProgressScope.Library.progressBar,{duration=999999}))end)
    assert(coroutine.resume(co));refuse=true
    assert(not e.Stop());assert(e.Profile.ProgressScope.Progress().listeners==1)
    assert(r.progressFixture.state.invBusy=='before'and r.env160.PRCore.forgeNativeSeed~=nil)
    refuse=false
    assert(coroutine.resume(co));r.clock.advance(120000);local done=e.Poll()
    assert(not done and e.Profile.ProgressScope.Progress().listeners==0 and e.Profile.ProgressScope.Progress().pending==0)
    assert(r.env160.PRCore.forgeNativeSeed~=nil and not e.Progress().complete)
end
print('PASS160 physical cleanup/removal failure retains ownership/no false success;progress listener retry succeeds without claiming full graph recovery')
