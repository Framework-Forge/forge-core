local T=dofile('tests/kernel_progress_entry160_harness.lua')
for _,kind in ipairs({'model','anim'})do
    local r=T.client();local props,anims=0,0;local emit=r.env160.TriggerServerEvent;local play=r.env160.TaskPlayAnim
    r.env160.TriggerServerEvent=function(name,data,...)if name=='pr_bridge:progressProps'and data~=nil then props=props+1 end;return emit(name,data,...)end
    r.env160.TaskPlayAnim=function(...)anims=anims+1;return play(...)end
    local e=r.allocate160();assert(e.Prepare('pt-br'));r.surface.Open();assert(e.Install());r.runtimeImports.pollNative();assert(e.Start())
    local ui=e.Profile.Delegate.Delegate.Delegate.UI;local method=kind=='model'and'requestModel'or'requestAnimDict'
    ui.Streaming[method]=function()coroutine.yield('streaming');return true,123 end
    local result;local co=coroutine.create(function()result=table.pack(pcall(e.Profile.ProgressScope.Library.progressBar,
        {duration=999999,prop=kind=='model'and{model=123}or nil,anim=kind=='anim'and{dict='d',clip='c'}or nil}))end)
    assert(coroutine.resume(co));assert(e.Profile.ProgressScope.Progress().pending==1 and r.progressFixture.state.invBusy==true)
    assert(not e.Stop()and r.progressFixture.state.invBusy=='before'and r.env160.PRCore.forgeNativeSeed~=nil)
    assert(coroutine.resume(co));assert(not result[1]and tostring(result[2]):find('scope closed'))
    assert(props==0 and anims==0);r.clock.advance(120000);assert(e.Poll()and e.Progress().complete)
    assert(r.raw.Close());r.finish160()
end
print('PASS160 physical fenced profile rejects late model/animation result;no props/tasks after cleanup;pending then seed/raw drain')
