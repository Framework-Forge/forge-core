-- PR streaming/audio captured before57; existing58 owns registration and domain teardown.
local createWorker=require 'kernel.client.worker_context'
local createShutdown=require 'kernel.client.shutdown_sequence'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(state,ports)
    assert(state.ClientMediaContext==nil and state.ClientWorkerContext==nil,'fresh client media context required')
    local api={OperationalReady=false};state.ClientMediaContext=api
    local phase,worker,graph,sequence='constructing'
    local function current()
        if phase=='closed'or phase=='failed'or state.ClientMediaContext~=api then return false end
        return not worker or(state.ClientWorkerContext==worker and graph.IsCanonical()and(not sequence or state.ShutdownSequence==sequence))
    end
    local m=copy(ports.media);m.isCurrent=current
    local media=assert(ports.createMedia,'explicit PR client media factory required')(m);api.Media=media
    local p=copy(ports.worker);p.central=copy(p.central);p.central.native=copy(p.central.native)
    for name,fn in pairs(media.Native)do p.central.native[name]=fn end
    p.central.helpers=copy(p.central.helpers);p.central.helpers.audio=media.Audio
    p.central.character=copy(p.central.character);p.central.character.streaming=media.Streaming
    p.domains=copy(p.domains);p.domains.domains=copy(p.domains.domains)
    for _,name in ipairs({'Objects','Npcs','Starterpack','Vehicles'})do
        local d=copy(p.domains.domains[name]);d.library=copy(d.library);d.library.fivem=copy(d.library.fivem or{})
        d.library.fivem.streaming=media.Streaming;p.domains.domains[name]=d
    end
    local function finish(...)
        if sequence then local status=sequence.Progress()
            if status.phase=='cleaned'or status.phase=='cleanup-failed'then media.Close();phase='closed'end
        end
        return ...
    end
    local function cleanup(fn,...)
        if media.Progress().phase=='closed'then return fn(...)end
        phase='stopping';media.CloseIngress()
        return finish(media.DuringCleanup(fn,...))
    end
    local report=p.onError;p.onError=function(...)
        if sequence and current()then cleanup(sequence.Stop)else media.Close();if worker then worker.Close()end;phase='failed'end
        return report(...)
    end
    local ok,value=pcall(createWorker,state,p)
    if not ok then phase='failed';media.Close();error(value,0)end
    worker=value;graph=worker.Graph;api.Worker,api.Graph=worker,graph
    local progress=worker.Progress;worker.Progress=function()
        local out=progress();if media.Progress().pending>0 then out.quiescent=false end;return out
    end
    local function guard(fn)return function(...)
        if phase=='stopping'or not current()then return end;return fn(...)
    end end
    local function properties(v,seen)
        if type(v)=='function'then return guard(v)end;if type(v)~='table'then return v end
        seen=seen or{};if seen[v]then return seen[v]end;local out={};seen[v]=out;for k,x in pairs(v)do out[k]=properties(x,seen)end;return out
    end
    local s=copy(ports.shutdown);s.events=copy(s.events);local listen=s.events.listen
    s.events.listen=function(name,fn)return listen(name,function(resource,...)
        if name=='onResourceStop'and resource==s.resource then return cleanup(fn,resource,...)end
        return guard(fn)(resource,...)
    end)end
    s.callbacks=copy(s.callbacks)
    for _,kind in ipairs({'native','ox'})do local b=copy(s.callbacks[kind]);local bind=b.Bind;b.Bind=function(lease,fn)return bind(lease,guard(fn))end;s.callbacks[kind]=b end
    s.public=copy(s.public);local pub=s.public;local publish=pub.publishExport
    pub.publishExport=function(name,fn)return publish(name,guard(fn))end
    for _,kind in ipairs({'prCommand','oxCommand'})do local bind=pub[kind];pub[kind]=function(name,options,fn)return bind(name,properties(options),guard(fn))end end
    local bind=pub.nativeCommand;pub.nativeCommand=function(name,fn,restricted)return bind(name,guard(fn),restricted)end
    s.input=copy(s.input);s.input.resolveEntity=graph.Central.Parts.Helpers.Lib.getEntityAndNetIdFromBagName
    local bag=s.input.addBag;s.input.addBag=function(key,filter,fn)return bag(key,filter,guard(fn))end
    local provider=s.input.keybind;local call=assert(getmetatable(provider).__call);local proxy=copy(provider)
    setmetatable(proxy,{__call=function(_,data)for k,v in pairs(data)do if type(v)=='function'then data[k]=guard(v)end end;return call(provider,data)end});s.input.keybind=proxy
    ok,value=pcall(createShutdown,worker,s)
    if not ok then phase='failed';worker.Close();media.Close();error(value,0)end
    sequence=value;api.Sequence=sequence;phase='prepared'
    function api.Install()
        if phase~='prepared'or not current()then return false,'client_media_not_prepared'end
        assert(media.Open(),'media scope unavailable');local result=table.pack(pcall(sequence.Install))
        if result[1]and result[2]and current()then phase='installed';return table.unpack(result,2,result.n)end
        cleanup(sequence.Stop);if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Start()
        if phase~='installed'or not current()then return false,'client_media_not_installed'end
        phase='starting';local result=table.pack(pcall(sequence.Start))
        if result[1]and result[2]and current()then phase='running';return table.unpack(result,2,result.n)end
        cleanup(sequence.Stop);if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Stop()
        if media.Progress().phase=='closed'then return sequence.Stop()end
        if not current()then media.Close();worker.Close();phase='failed';return false,'stale_context'end
        return cleanup(sequence.Stop)
    end
    function api.Poll()
        if media.Progress().phase=='closed'then return sequence.Poll()end
        if phase~='stopping'then return false,'not_stopping'end
        return cleanup(sequence.Poll)
    end
    function api.GetPhase()return phase end
    function api.Progress()local s,m=sequence.Progress(),media.Progress();return{phase=phase,sequence=s,media=m,complete=s.complete and m.complete}end
    return api
end
