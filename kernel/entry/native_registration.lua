-- Native registration boundary only. Caller supplies resource-local natives and PR command delegates.
return function(spec,ports)
    local side=assert(spec.side);assert(side=='client'or side=='server','explicit side required')
    local current,ready=assert(spec.isCurrent),assert(spec.isReady)
    local n=assert(ports.native)
    for _,key in ipairs({'GetCurrentResourceName','IsDuplicityVersion','AddEventHandler','RemoveEventHandler','RegisterNetEvent','RegisterCommand','source','publishExport'})do
        assert(type(n[key])=='function','native binding required: '..key)
    end
    assert(n.GetCurrentResourceName()=='forge-core','existing physical resource required')
    assert((not not n.IsDuplicityVersion())==(side=='server'),'native side mismatch')
    local available=assert(ports.available)
    local prCommand,oxCommand=assert(ports.prCommand),assert(ports.oxCommand)
    local running=assert(ports.running)
    local phase,pending='allocated',0;local tokens,names={},{};local origins=setmetatable({},{__mode='k'})
    local api={OperationalReady=false,PhysicalPublicRemoval=false,Side=side}
    local function valid()local ok,value=pcall(current);return ok and value==true end
    local function active()return phase=='open'and valid()end
    local function invoke(fn,...)
        pending=pending+1;local result=table.pack(pcall(fn,...));pending=pending-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    local function dispatch(fn,...)
        local origin=n.source();local thread=running();local prior=origins[thread]
        origins[thread]={value=origin};local result=table.pack(pcall(function(...)
            if not active()then return end;return invoke(fn,...)
        end,...));origins[thread]=prior
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    local function guard(fn)return function(...)if active()then return invoke(fn,...)end end end
    local function properties(value,seen)
        if type(value)=='function'then return guard(value)end;if type(value)~='table'then return value end
        seen=seen or{};if seen[value]then return seen[value]end;local out={};seen[value]=out
        for key,item in pairs(value)do out[key]=properties(item,seen)end;return out
    end
    local function retire(token)
        if not token.active then return true end
        if token.removing then return false end;token.removing=true
        local ok,result=pcall(invoke,n.RemoveEventHandler,token.native)
        token.removing=false
        if ok and result~=false then token.active=false;token.error=nil;return true end
        token.error=ok and'removal_rejected'or tostring(result);return false
    end
    local function complete()
        if phase=='closing'and pending==0 then
            for _,t in ipairs(tokens)do if t.active or t.uncertain then return false end end
            phase='closed';return true
        end
        return phase=='closed'
    end
    function api.Open()
        if phase~='allocated'then return false,'scope_not_allocated'end
        if not valid()then return false,'stale_scope'end
        local ok,value=pcall(ready)
        if phase~='allocated'or not valid()then return false,'scope_closed_during_readiness'end
        if not ok or value~=true then return false,'registration_not_ready'end
        phase='open';return true
    end
    function api.Close()
        if phase=='closed'then return true end
        phase='closing';for i=#tokens,1,-1 do retire(tokens[i])end;return complete()
    end
    function api.Poll()if phase=='closing'then return api.Close()end;return complete()end
    function api.Progress()
        local remaining,unknown,errors=0,0,{};for _,t in ipairs(tokens)do
            if t.active then remaining=remaining+1 end;if t.uncertain then unknown=unknown+1 end;if t.error then errors[#errors+1]=t.error end
        end
        return{phase=phase,pending=pending,listenerRemaining=remaining,uncertainRegistrations=unknown,errors=errors,complete=phase=='closed'and pending==0 and remaining==0 and unknown==0,
            publicWrappersRetained=next(names)~=nil,physicalPublicRemoval=false}
    end
    local function key(kind,name)return kind..':'..(kind=='command'and name:lower()or name)end
    local function free(kind,name)
        if not active()or names[key(kind,name)]then return false end
        local value=invoke(available,kind,name);return active()and value==true
    end
    local function publish(kind,name,fn,perform,...)
        assert(type(name)=='string'and name~=''and type(fn)=='function','valid public binding required')
        if not free(kind,name)then return false end
        names[key(kind,name)]=true -- Reserve before a yielding native/provider call; uncertain publication is not retried.
        return invoke(perform,name,guard(fn),...)
    end
    api.Events={
        source=function()local entry=origins[running()];if entry then return entry.value end;return n.source()end,
        markNetwork=function(name)if not active()then return false end;return invoke(n.RegisterNetEvent,name)end,
        listen=function(name,fn)
            assert(type(name)=='string'and type(fn)=='function','valid listener required')
            if not active()then return nil end
            local token={active=true};tokens[#tokens+1]=token
            -- A token exists in our ledger before registration yields, but has no native handle yet.
            token.active=false
            local result=table.pack(pcall(invoke,n.AddEventHandler,name,function(...)return dispatch(fn,...)end))
            if not result[1]or result[2]==nil or result[2]==false then
                token.uncertain=true;token.error='native_registration_uncertain';error(result[1]and'native listener token required'or result[2],0)
            end
            token.native=result[2];token.active=true
            if not active()then retire(token);complete()end
            return token
        end,
        remove=function(token)
            local owned=false;for _,t in ipairs(tokens)do if t==token then owned=true;break end end
            if not owned then return false end;local ok=retire(token);complete();return ok
        end,
    }
    api.Public={available=free,
        publishExport=function(name,fn)return publish('export',name,fn,n.publishExport)end,
        nativeCommand=function(name,fn,restricted)return publish('command',name,fn,n.RegisterCommand,restricted)end,
        prCommand=function(name,options,fn)return publish('command',name,fn,function(k,handler)return prCommand(k,properties(options),handler)end)end,
        oxCommand=function(name,options,fn)return publish('command',name,fn,function(k,handler)return oxCommand(k,properties(options),handler)end)end,
    }
    return api
end
