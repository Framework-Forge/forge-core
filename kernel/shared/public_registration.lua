-- Inactive exports/commands surface. Native/public names have no removal token in this contract.
local function copy(value,seen)
    if type(value)~='table'then return value end
    seen=seen or{};if seen[value]then return seen[value]end
    local out={};seen[value]=out;for k,v in pairs(value)do out[k]=copy(v,seen)end;return out
end
return function(spec,ports)
    local owner,current=assert(spec.owner),assert(spec.isCurrent)
    assert(spec.side=='server'or spec.side=='client','explicit public side required')
    assert(type(current)=='function'and current(),'canonical public graph required')
    assert(owner.PublicRegistration==nil,'public surface already owned')
    local delivery={}
    for _,key in ipairs({'available','publishExport','prCommand','oxCommand','nativeCommand'})do
        assert(type(ports[key])=='function','explicit public port required: '..key);delivery[key]=ports[key]
    end
    local entries,seen,counts={}, {}, {exports=0,commands=0,callbacks=0}
    for _,d in ipairs(assert(spec.entries))do
        assert(type(d.owner)=='string'and type(d.name)=='string'and d.name~=''and type(d.handler)=='function','invalid public descriptor')
        assert(d.kind=='export'or d.kind=='command','invalid public descriptor kind')
        if d.kind=='command'then assert(d.mode=='native'or d.mode=='pr'or d.mode=='ox','explicit command mode required')end
        if d.isEnabled~=nil then
            assert(d.kind=='command'and type(d.isEnabled)=='function'and type(d.externalOwner)=='string'and d.externalOwner~='',
                'explicit external command owner and selection required')
        end
        local key=d.kind..':'..(d.kind=='command'and d.name:lower()or d.name)
        assert(not seen[key],'public name collision: '..key);seen[key]=true
        local entry=copy(d);entries[#entries+1]=entry
        counts[d.kind=='export'and'exports'or'commands']=counts[d.kind=='export'and'exports'or'commands']+1
    end
    local rpc,callbacks=ports.rpc,{}
    for _,d in ipairs(spec.callbacks or{})do
        assert(type(d.name)=='string'and type(d.handler)=='function'and not seen['callback:'..d.name],'invalid/duplicate supplemental callback')
        seen['callback:'..d.name]=true;callbacks[#callbacks+1]={name=d.name,handler=d.handler,owner=d.owner}
    end
    if #callbacks>0 then
        assert(rpc and rpc.Protocol=='ox'and rpc.Side==spec.side,'owned ox callback provider required')
        local p={};for _,key in ipairs({'IsReady','Reserve','Bind','Release'})do assert(type(rpc[key])=='function','complete ox provider required');p[key]=rpc[key]end;rpc=p
    end
    counts.callbacks=#callbacks
    local api={State='prepared-inactive',Side=spec.side,Counts=copy(counts),PhysicalUnregistration=false}
    owner.PublicRegistration=api
    local phase,attempted,leases='prepared-inactive',false,{}
    local delegated={}
    function api.GetDelegatedCommands()return copy(delegated)end
    local function setState(value)phase=value;api.State=value end
    local function canonical()
        if owner.PublicRegistration~=api then return false end
        local ok,value=pcall(current);return ok and value==true
    end
    local function wrap(fn)
        return function(...)
            if phase~='installed'or not canonical()then return end
            return fn(...)
        end
    end
    local function guardedProperties(value,seen)
        if type(value)=='function'then return wrap(value)end
        if type(value)~='table'then return value end
        seen=seen or{};if seen[value]then return seen[value]end
        local out={};seen[value]=out
        for key,item in pairs(value)do out[key]=guardedProperties(item,seen)end
        return out
    end
    local function release()
        local failures={}
        for i=#leases,1,-1 do
            local item=leases[i]
            if not item.released then
                local ok,value=pcall(rpc.Release,item.lease)
                if ok and value==true then item.released=true else failures[#failures+1]={name=item.name,error=ok and'release_rejected'or value}end
            end
        end
        return failures
    end
    function api.Describe()
        local out={}
        for _,d in ipairs(entries)do out[#out+1]={name=d.name,kind=d.kind,mode=d.mode,owner=d.owner,properties=copy(d.properties),restricted=d.restricted}end
        for _,d in ipairs(callbacks)do out[#out+1]={name=d.name,kind='callback',mode='ox',owner=d.owner}end
        return out
    end
    function api.Dispose()
        if phase=='installing'or phase=='revoking'then return false,'operation_in_progress'end
        if phase=='revoked'then return false,'already_revoked'end
        setState('revoking');local failures=release();setState(#failures==0 and'revoked'or'revoke-failed')
        return #failures==0,failures
    end
    function api.Install()
        if attempted or phase~='prepared-inactive'then return false,'installation_not_repeatable'end
        if not canonical()then return false,'canonical_graph_replaced'end
        if #callbacks>0 and not rpc.IsReady()then return false,'transport_not_opened'end
        attempted=true;setState('installing')
        local ok,problem=pcall(function()
            -- Complete namespace preflight before publishing anything or compiling a command.
            local selected,external={},{}
            for _,d in ipairs(entries)do
                local enabled=true
                if d.isEnabled then
                    enabled=d.isEnabled()
                    assert(type(enabled)=='boolean','command selection must return a boolean: '..d.name)
                end
                assert(canonical(),'public graph changed during command selection')
                if enabled then
                    assert(delivery.available(d.kind,d.name)==true,'foreign public name: '..d.name)
                    selected[#selected+1]=d
                else external[#external+1]={name=d.name,owner=d.owner,externalOwner=d.externalOwner}end
            end
            for _,d in ipairs(callbacks)do leases[#leases+1]={name=d.name,lease=rpc.Reserve(d.name),descriptor=d}end
            for _,item in ipairs(leases)do
                assert(canonical(),'public graph changed during callback binding')
                assert(rpc.Bind(item.lease,wrap(item.descriptor.handler))==true,'supplemental callback bind rejected')
            end
            for _,d in ipairs(selected)do
                assert(canonical(),'public graph changed during installation')
                assert(delivery.available(d.kind,d.name)==true,'public namespace changed during installation: '..d.name)
                local fn,result=wrap(d.handler)
                if d.kind=='export'then result=delivery.publishExport(d.name,fn)
                elseif d.mode=='native'then result=delivery.nativeCommand(d.name,fn,d.restricted)
                else result=delivery[d.mode..'Command'](d.name,guardedProperties(d.properties),fn)end
                assert(result~=false,'public registration rejected: '..d.name)
            end
            assert(canonical(),'public graph changed before commit')
            delegated=external
        end)
        if not ok then
            setState('revoking');local failures=release();setState(#failures==0 and'install-failed-revoked'or'revoke-failed')
            return false,problem,failures
        end
        setState('installed');return true
    end
    return api
end
