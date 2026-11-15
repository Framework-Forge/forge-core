-- Consumer-local import entry. It owns a namespace/searcher, never an authoritative core.
return function(createDelivery,ports)
    local env=assert(ports.environment);local key=assert(ports.namespace);local owner=assert(ports.isCurrent)
    local resource=assert(ports.resource);local phase,pending='allocated',0;local delivery,token;local registrationUncertain=false
    local api={Protocol='forge-qbx-consumer/1',OperationalReady=false}
    local function valid()
        local ok,value=pcall(owner)
        return phase~='closed'and phase~='failed'and rawget(env,key)==api and ok and value==true
    end
    local function check()assert(valid(),'consumer entry unavailable')end
    local function tracked(fn,...)
        pending=pending+1;local out=table.pack(pcall(fn,...));pending=pending-1
        if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
    end
    function api.Close()
        phase='closed';local clean=true
        if delivery then local ok,value=pcall(delivery.Close);clean=ok and value~=false end
        if token then
            local ok,value=pcall(ports.remove,token)
            if ok and value~=false then token=nil else clean=false end
        end
        local p=delivery and delivery.Progress()
        clean=clean and token==nil and pending==0 and not registrationUncertain and(not p or p.complete)
        if clean and rawget(env,key)==api then rawset(env,key,nil)end
        return clean
    end
    function api.Start()
        if phase~='allocated'then return false,'consumer entry not repeatable'end
        assert(rawget(env,key)==nil,'foreign consumer entry namespace')
        rawset(env,key,api);phase='preparing'
        local ok,problem=pcall(tracked,function()
            check();local p={};for k,v in pairs(assert(ports.delivery))do p[k]=v end
            local prior=assert(p.isCurrent);p.isCurrent=function()return valid()and prior()end
            delivery=createDelivery(p);check();assert(delivery.Prepare());check();assert(delivery.Install());check()
            local accepted,value=pcall(ports.listen,'onResourceStop',function(stopped)if stopped==resource then api.Close()end end)
            if not accepted or value==nil or value==false then registrationUncertain=true;error(accepted and'consumer stop token missing'or value,0)end
            token=value
            check()
        end)
        if not ok then api.Close();return false,problem end
        phase='installed';return true
    end
    function api.ExecuteEntry(name)
        check();assert(phase=='installed','consumer entry not installed')
        local out=table.pack(pcall(tracked,delivery.ExecuteEntry,name))
        if not out[1]then api.Close();error(out[2],0)end
        if not valid()then api.Close();error('consumer entry closed during execution',0)end
        return table.unpack(out,2,out.n)
    end
    function api.Progress()
        local p=delivery and delivery.Progress()
        return{phase=phase,pending=pending+(p and p.pending or 0),stopRemaining=token~=nil,registrationUncertain=registrationUncertain,delivery=p,
            complete=phase=='closed'and pending==0 and token==nil and not registrationUncertain and(not p or p.complete)}
    end
    return api
end
