-- Shared seed for explicit server100/client101 contexts. Context/domain ports are supplied separately.
return function(ports)
    local pr,rpc=assert(ports.prCore),assert(ports.rpc)
    assert(pr.forgeOwnedCallbacks==rpc,'seed must borrow this PRCore callback owner')
    assert(pr.forgeNativeSeed==nil,'native seed already owned')
    local phase='allocated';local api={OperationalReady=false};pr.forgeNativeSeed=api
    local function current()local ok,value=pcall(ports.isCurrent);return phase~='closed'and pr.forgeNativeSeed==api and pr.forgeOwnedCallbacks==rpc and ok and value==true end
    local io,execution,library,registry
    function api.Close()
        phase='closed'
        if registry then registry.Close()end;if library then library.Close()end
        if execution then execution.Close()end;if io then io.Close()end
        if pr.forgeNativeSeed==api then pr.forgeNativeSeed=nil end
        return api.Progress().complete
    end
    function api.Progress()
        local i=io and io.Progress();local e=execution and execution.Progress();local r=registry and registry.Progress()
        return{phase=phase,io=i,execution=e,registry=r,complete=phase=='closed'and(not i or i.complete)and(not e or e.complete)and(not r or r.complete),operationalReady=false}
    end
    local ok,problem=pcall(function()
        local loadPR=assert(ports.loadPR);local native=assert(ports.native)
        io=loadPR('@pr_bridge/bridge/delivery/forge_native_io')({native=native,core=pr,json=ports.json,isCurrent=current});api.IO=io
        execution=loadPR('@pr_bridge/bridge/delivery/forge_native_execution')({native=native,side=rpc.Side,isCurrent=current,compile=ports.compile,
            events=ports.events,running=ports.running,getSource=ports.getSource});api.Execution=execution
        library=loadPR('@pr_bridge/bridge/delivery/forge_native_library')({native=native,prCore=pr,public=ports.public,rpc=rpc,
            environment=ports.environment,nativeCache=ports.nativeCache,isCurrent=current,load=loadPR});api.Library=library
        registry=assert(ports.createRegistry)({readFile=io.Files.LoadResourceFile,compile=ports.compile,environment=ports.environment,
            inventoryBridgeProbe=ports.inventoryBridgeProbe,isCurrent=current});api.Registry=registry
    end)
    if not ok then api.Close();error(problem,0)end
    function api.Prepare()
        if phase~='allocated'or not current()then return false end
        local prepared,reason=library.Prepare();if not prepared or not current()then api.Close();return false,reason end
        phase='prepared';return true
    end
    function api.IsCurrent()return current()and registry.IsCurrent()and execution.IsCurrent()and library.IsCurrent()end
    return api
end
