local T=dofile('tests/kernel_qb_client_functions_harness.lua');local H,P=T.H,T.P;local D={T=T,H=H,P=P}
function D.new(ported)
    local r=T.new(true);r.events={};r.exported={};r.tasks={};r.trace={};r.hasKeys=true
    r.library.showTextUI=function(...)r.record('show',...);if r.showHook then r.showHook()end end
    r.library.hideTextUI=function(...)r.record('hide',...)end
    r.native.ExecuteCommand=function(...)r.record('execute',...);if r.executeError then error('fixture_command_failure',0)end;return 'ignored'end
    r.native.NetworkGetEntityFromNetworkId=function(id)r.record('entityFromNet',id);return id+100 end
    r.native.GetPedInVehicleSeat=function(...)r.record('seat',...);return 10 end
    r.native.TriggerEvent=function(...)r.record('event',...)end
    r.config={hasKeys=function(...)r.record('hasKeys',...);if r.keyHook then r.keyHook()end;if r.keyError then error('fixture_key_failure',0)end;return r.hasKeys end}
    r.scheduler={createThread=function(fn)r.record('thread');r.tasks[#r.tasks+1]=coroutine.create(fn)end,
        wait=function(ms)r.record('wait',ms);if r.yielding then coroutine.yield(ms)end end}
    r.ports={native=r.native,library=r.library,helpers=r.helpers,config=r.config,scheduler=r.scheduler}
    local env=H.environment();r.env=env
    if ported then
        r.ui=H.load('kernel/compat/qb/client_drawtext.lua',env)(r.ports)
        r.eventList=H.load('kernel/compat/qb/client_events.lua',env)(r.ports)
        for _,d in ipairs(r.ui.Events)do r.events[d.name]=d end
        for _,d in ipairs(r.eventList)do r.events[d.name]=d end
        r.exported=r.ui.Exports
    else
        for name,fn in pairs(r.native)do env[name]=fn end
        env.CreateThread=r.scheduler.createThread;env.Wait=r.scheduler.wait
        env.lib=r.library;env.qbx=r.helpers
        env.RegisterNetEvent=function(name,fn)assert(not r.events[name],name);r.events[name]={name=name,handler=fn,network=true}end
        env.require=function(name)
            if name=='config.client'then return r.config end
            if name=='bridge.qb.shared.export-function'then return function(name,fn)assert(not r.exported[name]);r.exported[name]=fn end end
            error(name)
        end
        P.loadOrigin('bridge/qb/client/drawtext.lua',env)
        P.loadOrigin('bridge/qb/client/events.lua',env)
    end
    assert(#r.trace==0 and #r.tasks==0,'UI/events constructor must be inert')
    function r.fire(name,...)return assert(r.events[name],name).handler(...)end
    function r.runTask(index)
        local co=assert(r.tasks[index or 1]);local ok,value=coroutine.resume(co);assert(ok,value);return coroutine.status(co),value
    end
    return r
end
return D
