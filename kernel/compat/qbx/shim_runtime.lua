-- Physical-shim runtime factory. Registers only relay exports and one owned stop listener.
return function(createRelay,ports)
    local resource,side=assert(ports.getCurrentResourceName)(),assert(ports.side)
    assert(resource=='qbx_core','qbx_core compatibility directory required')
    local state=assert(ports.resourceState);local listen,remove=assert(ports.listen),assert(ports.remove)
    local current=true;local token;local pending=0;local phase='allocated';local registrationUncertain=false
    local api={OperationalReady=false};local relay
    local function valid()return current and state('forge-core')=='started'end
    local function tracked(fn,...)
        pending=pending+1;local out=table.pack(pcall(fn,...));pending=pending-1
        if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
    end
    relay=createRelay(side,{getCurrentResourceName=ports.getCurrentResourceName,getInvokingResource=assert(ports.getInvokingResource),isCurrent=valid,
        describe=assert(ports.describe),call=assert(ports.call),available=assert(ports.available),publishExport=assert(ports.publishExport)})
    api.Relay=relay
    function api.Close()
        current=false;phase='closed';relay.Close()
        if token then local ok,value=pcall(tracked,remove,token);if ok and value~=false then token=nil end end
        return api.Progress().complete
    end
    function api.Progress()
        local child=relay.Progress();return{phase=phase,pending=pending+child.pending,relay=child,listenerRemaining=token~=nil,
            registrationUncertain=registrationUncertain,complete=phase=='closed'and pending==0 and child.complete and token==nil and not registrationUncertain}
    end
    function api.Start()
        if phase~='allocated'or not valid()then return false,'forge_compatibility_not_ready'end
        phase='starting';local ok,problem=pcall(function()
            assert(relay.Prepare());assert(current,'shim closed during preparation')
            local accepted,value=pcall(tracked,listen,'onResourceStop',function(stopped)if stopped==resource then api.Close()end end)
            if not accepted or value==nil or value==false then registrationUncertain=true;error(accepted and'stop listener handle required'or value,0)end
            token=value;assert(current,'shim closed during listener registration')
            local installed,why=relay.Install();assert(installed,why);assert(current and valid(),'shim closed before commit')
        end)
        if not ok then api.Close();return false,problem end
        phase='running';return true
    end
    return api
end
