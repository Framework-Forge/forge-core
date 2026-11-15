-- Forge-local authenticated endpoint. It is not registered here and accepts no network event.
return function(catalog,origin,ports)
    local current,ready,invoking=assert(ports.isCurrent),assert(ports.isReady),assert(ports.getInvokingResource)
    local generation=assert(ports.generation);assert(type(generation)=='string'and generation~='','unique runtime generation required')
    local phase,pending='closed-ingress',0;local api={OperationalReady=false}
    local function valid()
        local ok,value=pcall(current);return phase~='retired'and ok and value==true and catalog.IsCurrent()and origin.IsCurrent()
    end
    local function check()
        assert(phase=='open'and valid(),'qbx_gateway_unavailable')
        assert(invoking()==(ports.transportResource or'qbx_core'),'qbx_gateway_transport_denied')
        local ok,value=pcall(ready);assert(ok and value==true and phase=='open'and valid(),'qbx_gateway_not_ready')
    end
    function api.Open()
        if phase~='closed-ingress'or not valid()then return false end
        local ok,value=pcall(ready);if not ok or value~=true or phase~='closed-ingress'or not valid()then return false end
        phase='open';return true
    end
    function api.Describe()
        check();local names={};for i,e in ipairs(catalog.Describe())do names[i]=e.name end
        return{protocol='forge-qbx-compat/1',side=catalog.Side,generation=generation,names=names,authority='forge-core'}
    end
    function api.Call(epoch,name,caller,...)
        check();assert(epoch==generation,'qbx_gateway_stale_generation')
        assert(type(caller)=='string'and caller~=''and caller~='qbx_core','identified original local caller required')
        local fn=catalog.Resolve(name);assert(valid(),'qbx_gateway_graph_changed');pending=pending+1
        local result=table.pack(pcall(origin.Run,caller,fn,...));pending=pending-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Close()phase='retired';return pending==0 end
    function api.IsCurrent()return valid()end
    function api.Progress()return{phase=phase,pending=pending,complete=phase=='retired'and pending==0}end
    return api
end
