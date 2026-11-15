-- Private callback/token ownership. Missing removal ports leave explicitly revoked shells.
return function(ports)
    local current=assert(ports.isCurrent)
    local phase,entered,publishing='prepared',0,0
    local records,bindings={},{}
    local api={PhysicalRemoval=false}
    local function live()
        if phase~='open'then return false end
        local ok,value=pcall(current);return ok and value==true
    end
    local function remove(r,exact)
        if r.removed then
            if exact and r.removeResult then return table.unpack(r.removeResult,2,r.removeResult.n)end
            return true
        end
        if not r.binding.remove or not r.token then return true end
        local result=table.pack(pcall(r.binding.remove,r.token))
        if not result[1]or result[2]==false then
            r.error=tostring(result[1]and result[3]or result[2])
            if exact then if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)end
            return false
        end
        r.removed=true;r.error=nil;r.removeResult=result
        if exact then return table.unpack(result,2,result.n)end;return true
    end
    function api.Wrap(register,removePort,options)
        assert(phase=='prepared'and type(register)=='function','wrap ingress before Install')
        options=options or{};local index,closedValue=options.callback or 2,options.closedValue
        local b={remove=removePort};bindings[#bindings+1]=b
        local function unregister(token)
            for i=#records,1,-1 do local r=records[i]
                if r.binding==b and r.token==token then r.fn=nil;return remove(r,true)end
            end
            return false,'foreign_ingress_token'
        end
        return function(...)
            if not live()then return nil,'ingress_closed'end
            local args=table.pack(...);assert(type(args[index])=='function','ingress callback required')
            local r={binding=b,fn=args[index]};records[#records+1]=r
            args[index]=function(...)
                local fn=r.fn
                if not fn or not live()then return closedValue end
                entered=entered+1;local result=table.pack(pcall(fn,...));entered=entered-1
                if not result[1]then error(result[2],0)end
                return table.unpack(result,2,result.n)
            end
            publishing=publishing+1
            local result=table.pack(pcall(register,table.unpack(args,1,args.n)));publishing=publishing-1
            if not result[1]then
                r.fn=nil;r.unknown=true;r.error=tostring(result[2]);error(result[2],0)
            end
            r.token=result[2]
            if r.token==false then r.fn=nil;r.refused=true
            elseif r.token==nil then r.unknown=true end
            if not live()then r.fn=nil;remove(r)end -- Close during publication: retire the late token.
            return table.unpack(result,2,result.n)
        end,unregister
    end
    function api.Install()
        if phase~='prepared'then return false,'ingress_not_repeatable'end
        phase='open';if not live()then phase='closed';return false,'stale_ingress_owner'end;return true
    end
    function api.Dispose()
        phase='closed'
        for _,r in ipairs(records)do r.fn=nil end
        local ok=true;for i=#records,1,-1 do if not remove(records[i])then ok=false end end
        return ok
    end
    function api.Pending()return entered+publishing end
    function api.Progress()
        local out={phase=phase,entered=entered,publishing=publishing,records=#records,residual=0,removeFailed=0}
        for _,r in ipairs(records)do
            if not r.removed and not r.refused then out.residual=out.residual+1 end
            if r.error then out.removeFailed=out.removeFailed+1 end
        end
        return out
    end
    return api
end
