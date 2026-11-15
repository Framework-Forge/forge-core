-- Additional local endpoint;uses the already installed QB95 binding and no new QB event handlers.
return function(side,bridge,binding,origin,ports)
    local invoke,current,ready=assert(ports.getInvokingResource),assert(ports.isCurrent),assert(ports.isReady)
    local generation=assert(ports.generation);assert(type(generation)=='string'and generation~='','QB runtime generation required')
    local enabled=side=='server'and bridge.Enabled==true
    local handler=enabled and assert(bridge.ResourceExports.SetField)or nil
    local aliases={}
    if ports.publicAliases and bridge.Enabled then
        for name,fn in pairs(assert(bridge.Exports))do aliases[name]=fn end
    end
    local phase,pending='open',0;local api={OperationalReady=false}
    local function valid()
        local ok,value=pcall(current);if phase~='open'or not ok or value~=true then return false end
        if enabled then return binding.IsCurrent()and binding.Progress().phase=='installed'and bridge.ResourceExports.SetField==handler end
        return bridge.Enabled~=true or side=='client'
    end
    local function check()
        assert(invoke()==(ports.transportResource or'qbx_core'),'QB transport denied');assert(valid(),'QB compatibility unavailable')
        local ok,value=pcall(ready);assert(ok and value==true and valid(),'QB compatibility not ready')
    end
    function api.Describe()
        check();local names={};for name in pairs(aliases)do names[#names+1]=name end;table.sort(names)
        return{protocol='forge-qbx-qb/1',side=side,generation=generation,setField=enabled,names=names}
    end
    function api.Call(epoch,name,caller,...)
        check();assert(epoch==generation,'stale QB generation')
        local fn=name=='SetField'and handler or aliases[name]
        assert(type(fn)=='function','unsupported QB resource export')
        if aliases[name]then assert(bridge.Exports[name]==fn,'QB export target replaced')end
        assert(type(caller)=='string'and caller~=''and caller~='qbx_core','identified original caller required')
        pending=pending+1;local out=table.pack(pcall(origin.Run,caller,fn,...));pending=pending-1
        if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
    end
    function api.Close()phase='closed';return pending==0 end
    function api.Progress()return{phase=phase,pending=pending,complete=phase=='closed'and pending==0}end
    return api
end
