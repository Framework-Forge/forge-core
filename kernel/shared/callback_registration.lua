-- Private callback installation; no protocol emulation or implicit initialization.
return function(spec,providers)
    local owner,current=assert(spec.owner),assert(spec.isCurrent)
    assert(type(current)=='function'and current(),'canonical callback graph required')
    assert(owner.CallbackRegistration==nil,'callback registration already owned')
    local ports={}
    for _,protocol in ipairs({'native','ox'})do
        local p=assert(providers[protocol],'explicit callback provider required: '..protocol)
        assert(p.Protocol==protocol and p.Side==spec.side,'callback provider identity mismatch')
        ports[protocol]={}
        for _,key in ipairs({'IsReady','EventName','Reserve','Bind','Release'})do
            assert(type(p[key])=='function','complete callback provider required: '..key);ports[protocol][key]=p[key]
        end
    end
    local list,seen={},{}
    for i,d in ipairs(assert(spec.entries))do
        assert(type(d.name)=='string'and d.name~=''and type(d.owner)=='string'and type(d.handler)=='function','invalid callback descriptor')
        assert(ports[d.protocol]and not seen[d.name],'invalid protocol/duplicate callback: '..d.name);seen[d.name]=true
        assert(d.prepare==nil or type(d.prepare)=='function','invalid callback compiler')
        list[i]={name=d.name,owner=d.owner,handler=d.handler,protocol=d.protocol,prepare=d.prepare}
    end
    local api={State='prepared-inactive',Side=spec.side,Count=#list}
    local phase,attempted,owned='prepared-inactive',false,{}
    owner.CallbackRegistration=api
    local function setState(value)phase=value;api.State=value end
    local function canonical()
        if owner.CallbackRegistration~=api then return false end
        local ok,value=pcall(current);return ok and value==true
    end
    local function cleanup()
        local failures={}
        for i=#owned,1,-1 do
            local item=owned[i]
            if not item.released then
                local ok,result=pcall(item.port.Release,item.lease)
                if ok and result==true then item.released=true else failures[#failures+1]={name=item.name,error=ok and'release_rejected'or result}end
            end
            if item.released and item.cleanup then
                local ok,result=pcall(item.cleanup)
                if ok and result~=false then item.cleanup=nil else failures[#failures+1]={name=item.name,error=ok and'metadata_cleanup_rejected'or result}end
            end
        end
        return failures
    end
    function api.Describe()
        local out={};for i,d in ipairs(list)do out[i]={name=d.name,owner=d.owner,protocol=d.protocol,protected=d.prepare~=nil}end;return out
    end
    function api.Dispose()
        if phase=='installing'or phase=='disposing'then return false,'operation_in_progress'end
        if phase=='disposed'then return false,'already_disposed'end
        setState('disposing');local failures=cleanup();setState(#failures==0 and'disposed'or'dispose-failed')
        return #failures==0,failures
    end
    function api.Install()
        if attempted or phase~='prepared-inactive'then return false,'installation_not_repeatable'end
        if not canonical()then return false,'canonical_graph_replaced'end
        for _,p in pairs(ports)do if not p.IsReady()then return false,'transport_not_opened'end end
        attempted=true;setState('installing')
        local ok,problem=pcall(function()
            local wires={}
            for _,d in ipairs(list)do
                local wire=ports[d.protocol].EventName(d.name);assert(not wires[wire],'wire event collision: '..wire);wires[wire]=true
            end
            for _,d in ipairs(list)do
                assert(canonical(),'callback graph changed during reservation')
                local p=ports[d.protocol];local lease=p.Reserve(d.name)
                assert(lease~=nil and lease~=false,'callback lease required')
                owned[#owned+1]={name=d.name,port=p,lease=lease,descriptor=d}
            end
            for _,item in ipairs(owned)do
                assert(canonical(),'callback graph changed during binding')
                local d=item.descriptor;local handler=d.handler
                if d.prepare then handler,item.cleanup=d.prepare(handler);assert(type(handler)=='function'and type(item.cleanup)=='function','owned compiler/cleanup required')end
                assert(item.port.Bind(item.lease,function(...)
                    if phase~='installed'or not canonical()then return end
                    return handler(...)
                end)==true,'callback bind rejected')
            end
            assert(canonical(),'callback graph changed before commit')
        end)
        if not ok then
            setState('disposing');local failures=cleanup();setState(#failures==0 and'install-failed'or'dispose-failed')
            return false,problem,failures
        end
        setState('installed');return true
    end
    return api
end
