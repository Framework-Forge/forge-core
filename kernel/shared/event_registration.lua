-- Private owned event installation only. Does not start services, threads, RPC, exports or commands.
return function(spec,ports)
    local owner,entries,current=assert(spec.owner),assert(spec.entries),assert(spec.isCurrent)
    assert(type(current)=='function'and current(),'canonical graph required')
    assert(owner.EventRegistration==nil,'event registration already owned')
    assert(spec.side=='client'or spec.side=='server','explicit event side required')
    for _,key in ipairs({'listen','remove','markNetwork','source'})do assert(type(ports[key])=='function','explicit event port required: '..key)end
    local listen,remove,markNetwork,source=ports.listen,ports.remove,ports.markNetwork,ports.source
    local list,seen,networks={}, {}, {}
    for index,d in ipairs(entries)do
        assert(type(d.owner)=='string'and type(d.name)=='string'and d.name~=''and type(d.handler)=='function','invalid event descriptor')
        assert(type(d.network)=='boolean'and type(d.sourceFirst)=='boolean','explicit event policy required')
        seen[d.name]=seen[d.name]or{}
        assert(not seen[d.name][d.handler],'duplicate event handler alias: '..d.owner..':'..d.name);seen[d.name][d.handler]=true
        list[index]={owner=d.owner,name=d.name,handler=d.handler,network=d.network,sourceFirst=d.sourceFirst}
        if d.network then networks[d.name]=true end
    end
    local api={State='prepared-inactive',Side=spec.side,Count=#list,StartedServices=false}
    owner.EventRegistration=api
    local tokens,attempted,phase={},false,'prepared-inactive'
    local function setState(value)phase=value;api.State=value end
    local function canonical()
        if owner.EventRegistration~=api then return false end
        local ok,value=pcall(current);return ok and value==true
    end
    function api.Describe()
        local out={};for i,d in ipairs(list)do out[i]={owner=d.owner,name=d.name,network=d.network,sourceFirst=d.sourceFirst}end;return out
    end
    local function removeKnown()
        local failures={}
        for i=#tokens,1,-1 do
            local token=tokens[i]
            if token.active then
                local ok,result=pcall(remove,token.value)
                if ok and result~=false then token.active=false else failures[#failures+1]={index=i,error=ok and'remove_rejected'or result}end
            end
        end
        return failures
    end
    function api.Dispose()
        if phase=='installing'or phase=='disposing'then return false,'operation_in_progress'end
        if phase=='disposed'then return false,'already_disposed'end
        setState('disposing') -- Disable every wrapper before invoking an external removal port.
        local failures=removeKnown();setState(#failures==0 and'disposed'or'dispose-failed')
        return #failures==0,failures
    end
    function api.Install()
        if attempted or phase~='prepared-inactive'then return false,'installation_not_repeatable'end
        if not canonical()then return false,'canonical_graph_replaced'end
        attempted=true;setState('installing')
        local marked={}
        local ok,problem=pcall(function()
            for _,d in ipairs(list)do
                assert(canonical(),'canonical graph changed during installation')
                if networks[d.name]and not marked[d.name]then
                    assert(markNetwork(d.name)~=false,'network mark rejected');marked[d.name]=true
                end
                local function dispatch(...)
                    if phase~='installed'or not canonical()then return end
                    if d.sourceFirst then local origin=source();return d.handler(origin,...)end
                    return d.handler(...)
                end
                local token=listen(d.name,dispatch)
                assert(token~=nil and token~=false,'event listener token required')
                tokens[#tokens+1]={value=token,active=true}
            end
            assert(canonical(),'canonical graph changed before installation commit')
        end)
        if not ok then
            setState('disposing')
            local failures=removeKnown();setState(#failures==0 and'install-failed'or'dispose-failed')
            return false,problem,failures
        end
        setState('installed');return true
    end
    return api
end
