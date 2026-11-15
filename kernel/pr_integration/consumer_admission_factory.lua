-- Local control plane. Native caller identity and effective consumer descriptors,never player payloads.
return function(barrier,ports)
    local generation,side=assert(ports.generation),assert(ports.side);assert(side=='server'or side=='client')
    local current,describe,invoker=assert(ports.isCurrent),assert(ports.describe),assert(ports.getInvokingResource)
    local state,allowed=assert(barrier.ConsumerState),assert(barrier.IsConsumerAllowed)
    local configured={};for _,name in ipairs(assert(ports.consumers))do
        assert(type(name)=='string'and name~=''and name~='forge-core'and name~='qbx_core'and not configured[name]);configured[name]=true
    end
    assert(next(configured),'explicit consumer set required')
    local closed,observed,pending=false,false,0;local instances={};local api={OperationalReady=false}
    local function valid()local ok,v=pcall(current);return not closed and ok and v==true end
    local function snapshot(name)
        local ok,d=pcall(describe,name)
        if not ok or type(d)~='table'or d.protocol~='forge-pr-consumer/1'or d.resource~=name or d.side~=side
            or d.current~=true or type(d.instance)~='string'or d.instance==''or d.phase=='closed'then return end
        if instances[name]and instances[name]~=d.instance then return end
        if not valid()then return end;return d
    end
    local function tracked(fn,...)
        pending=pending+1;local out=table.pack(pcall(fn,...));pending=pending-1
        if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
    end
    function api.ObservePrepared()return tracked(function()
        if observed or not valid()then return false end;local all={}
        for name in pairs(configured)do local d=snapshot(name);if not d or d.phase~='prepared'then return false,'consumer_not_prepared:'..name end;all[name]=d.instance end
        if not valid()then return false end
        for name,instance in pairs(all)do
            if not state(generation,name,'prepared')then closed=true;assert(ports.invalidate)('partial_prepared_admission');return false end
            instances[name]=instance
        end
        observed=true;return true
    end)end
    function api.Handle(epoch,instance,claim)return tracked(function()
        local caller=invoker();assert(type(caller)=='string'and configured[caller]and caller~='forge-core'and caller~='qbx_core','native configured PR consumer required')
        if not valid()or not observed or epoch~=generation or instances[caller]~=instance then return false,'consumer_epoch_mismatch'end
        local d=snapshot(caller);if not d or d.instance~=instance then return false,'consumer_description_changed'end
        if claim=='attaching'and d.phase=='prepared'and d.proxyReady==true or claim=='committed'and d.phase=='attached'and d.proxyReady==true then
            return state(generation,caller,claim)
        end
        return false,'consumer_claim_not_observed'
    end)end
    function api.IsAllowed(caller,mode)return tracked(function()
        if not valid()or not observed or not configured[caller]or not instances[caller]or not allowed(caller,mode)then return false end
        local d=snapshot(caller);if not d then return false end
        if mode=='describe'then return d.phase=='prepared'or d.phase=='attaching'or d.phase=='attached'end
        return mode=='call'and d.proxyReady==true and(d.phase=='prepared'or d.phase=='attaching'or d.phase=='attached')or false
    end)end
    function api.Close()closed=true;return pending==0 end
    function api.Progress()return{closed=closed,observed=observed,pending=pending,complete=closed and pending==0,operationalReady=false}end
    return api
end
