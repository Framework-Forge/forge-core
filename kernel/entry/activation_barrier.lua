-- Local bootstrap admission policy; probes report readiness, never perform startup or infer it from resource state.
return function(ports)
    local current=assert(ports.isCurrent);local generation=assert(ports.generation)
    assert(type(generation)=='string'and generation~='','explicit activation generation required')
    local requirements={{'allocations'},{'rawProviders'},{'bootstrap'},{'nativeAPI','compatIdentity'},{'consumerBindings'},
        {'oxHooks','catalogs','banking','keys','decisions','environment'}}
    local probes={};for _,list in ipairs(requirements)do for _,key in ipairs(list)do
        probes[key]=assert(ports.probes[key],'readiness probe required: '..key);assert(type(probes[key])=='function')
    end end
    local consumers={};for _,name in ipairs(assert(ports.consumers))do
        assert(type(name)=='string'and name~=''and name~='forge-core'and name~='qbx_core'and not consumers[name],'explicit external consumer required')
        consumers[name]='declared'
    end
    assert(next(consumers),'consumer set required')
    local cleanups={};for i,entry in ipairs(ports.ownedCleanup or{})do
        assert(type(entry.name)=='string'and type(entry.close)=='function');cleanups[i]={name=entry.name,close=entry.close,complete=false}
    end
    local phase,closed,busy,pending=0,false,false,0;local failures={};local api={OperationalReady=false}
    local function valid()local ok,value=pcall(current);return not closed and ok and value==true end
    function api.ConsumerState(epoch,name,state)
        if epoch~=generation or not valid()or not consumers[name]then return false end
        local prior=consumers[name]
        if prior=='declared'and state=='prepared'and phase==0 or prior=='prepared'and state=='attaching'and phase==4
            or prior=='attaching'and state=='committed'and phase==4 then consumers[name]=state;return true end
        return false
    end
    function api.CanServe()return valid()and phase>=4 end
    function api.IsConsumerAllowed(name,mode)
        if not api.CanServe()then return false end
        local s=consumers[name]
        return mode=='describe'and(s=='prepared'or s=='attaching'or s=='committed')or mode=='call'and(s=='attaching'or s=='committed')or false
    end
    function api.IsIngressOpen()return valid()and phase==6 end
    function api.Advance(stage)
        if busy or not valid()or stage~=phase+1 or stage>6 then return false,'activation_stage_unavailable'end
        busy=true;pending=pending+1;local expected=phase;local missing={}
        local ok,problem=pcall(function()
            for _,key in ipairs(requirements[stage])do if probes[key](generation)~=true then missing[#missing+1]=key end end
            if stage==1 or stage>=5 then for name,s in pairs(consumers)do
                if stage==1 and s~='prepared'or stage>=5 and s~='committed'then missing[#missing+1]='consumer:'..name end
            end end
        end)
        pending=pending-1;busy=false
        if not ok then failures[#failures+1]=tostring(problem);api.Close();return false,problem end
        if not valid()or phase~=expected then return false,'activation_changed_during_probe'end
        if #missing>0 then return false,missing end
        phase=stage;return true
    end
    function api.WrapIngress(fn)
        assert(type(fn)=='function')
        return function(...)
            if not api.IsIngressOpen()then return end
            pending=pending+1;local out=table.pack(pcall(fn,...));pending=pending-1
            if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
        end
    end
    function api.Close()
        closed=true -- All new admissions are revoked before any cleanup may yield.
        if busy then return false end
        busy=true
        for i=#cleanups,1,-1 do local e=cleanups[i];if not e.complete then
            local ok,value=pcall(e.close);e.complete=ok and value==true
            if not e.complete then failures[#failures+1]=e.name..':'..(ok and'cleanup_pending'or tostring(value))end
        end end
        busy=false;return api.Progress().complete
    end
    function api.Progress()
        local remaining={};for _,e in ipairs(cleanups)do if not e.complete then remaining[#remaining+1]=e.name end end
        local states={};for k,v in pairs(consumers)do states[k]=v end;local errors={};for i,v in ipairs(failures)do errors[i]=v end
        return{generation=generation,stage=phase,closed=closed,pending=pending,busy=busy,ingressOpen=api.IsIngressOpen(),
            consumers=states,remaining=remaining,errors=errors,complete=closed and not busy and pending==0 and #remaining==0,operationalReady=false}
    end
    return api
end
