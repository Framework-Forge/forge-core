-- Shared lifecycle for an explicitly supplied prepared client/server context; never an operational entrypoint.
local createNative=require 'kernel.entry.native_registration'
return function(holder,side,createContext,bind,ports)
    local key=side=='server'and'ServerNativeBootstrap'or'ClientNativeBootstrap'
    assert(side=='server'or side=='client','explicit bootstrap side required');assert(holder[key]==nil,'fresh native bootstrap required')
    local owner,ready=assert(ports.isCurrent),assert(ports.isReady)
    local api={OperationalReady=false,Side=side};holder[key]=api
    local phase,pending,busy,draining,stopped='allocated',0,false,false,false
    local context,transport;local errors={}
    local function canonical()
        if holder[key]~=api or(context and api.Context~=context)or(transport and api.Transport~=transport)then return false end
        local ok,value=pcall(owner);return ok and value==true
    end
    local function current()return phase~='closed'and phase~='failed'and canonical()end
    transport=createNative({side=side,isCurrent=current,isReady=ready},assert(ports.registration));api.Transport=transport
    local function attempt(fn)
        local result=table.pack(pcall(fn));if not result[1]then errors[#errors+1]=tostring(result[2])end;return result
    end
    local function finish()
        local c=context and context.Progress()or{complete=true};local n=transport.Progress()
        if phase=='closing'and pending==0 and c.complete and n.complete then phase='closed';return true end
        return phase=='closed'
    end
    function api.Stop()
        if phase=='closed'then return true end
        if draining then return false,'cleanup_in_progress'end
        phase='closing';draining=true
        attempt(transport.Close) -- Revoke physical ingress before any yielding domain cleanup.
        if context then
            if stopped then attempt(context.Poll)else stopped=true;attempt(context.Stop)end
        end
        draining=false;return finish()
    end
    function api.Poll()
        if phase=='closed'then return true end
        if phase~='closing'then
            if context and context.Progress().complete then return api.Stop()end
            return false,'not_stopping'
        end
        return api.Stop()
    end
    local ok,result=pcall(function()return createContext(holder,bind(assert(ports.context),transport))end)
    if not ok then transport.Close();phase='failed';error(result,0)end
    context=result;api.Context=context
    local function operation(method,expected,working,nextPhase,...)
        if busy then return false,'bootstrap_operation_in_progress'end
        if phase~=expected or not canonical()then return false,'bootstrap_'..method:lower()..'_unavailable'end
        if method=='Install'then
            local opened,reason=transport.Open();if not opened then return false,reason end
            if phase~=expected or not canonical()then api.Stop();return false,'bootstrap_install_cancelled'end
        end
        busy=true;pending=pending+1;phase=working
        local out=table.pack(pcall(context[method],...));pending=pending-1;busy=false
        if phase~=working or not canonical()then api.Stop();return false,'bootstrap_operation_cancelled'end
        if not out[1]then api.Stop();error(out[2],0)end
        if out[2]~=true then api.Stop();return table.unpack(out,2,out.n)end
        phase=nextPhase;if method=='Prepare'then api.Graph=context.Graph end
        return table.unpack(out,2,out.n)
    end
    function api.Prepare(...)return operation('Prepare','allocated','preparing','prepared',...)end
    function api.Install()return operation('Install','prepared','installing','installed')end
    function api.Start()return operation('Start','installed','starting','running')end
    function api.IsCurrent()return current()and context.IsCurrent()end
    function api.Progress()
        local c=context.Progress();local n=transport.Progress();local out={};for i,e in ipairs(errors)do out[i]=e end
        return{phase=phase,pending=pending,busy=busy,context=c,transport=n,errors=out,operationalReady=false,
            complete=phase=='closed'and pending==0 and c.complete and n.complete}
    end
    return api
end
