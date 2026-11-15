-- Decorate the existing registration boundary;no extra native listener or lifecycle owner.
return function(input,side,beforeStop)
    assert(side=='client'or side=='server','stop port side required')
    assert(type(beforeStop)=='function','stop prelude required')
    local function copy(t)local o={};for k,v in pairs(assert(t))do o[k]=v end;return o end
    local bootstrap=copy(input);bootstrap.registration=copy(input.registration)
    local original=assert(input.registration.native);local native=copy(original);bootstrap.registration.native=native
    assert(original.GetCurrentResourceName()=='forge-core','Forge resource stop boundary required')
    local stopEvent=side=='client'and'onClientResourceStop'or'onResourceStop'
    local signals,pending,failures,inBefore=0,0,0,false;local errors={};local api={Bootstrap=bootstrap,OperationalReady=false}
    native.AddEventHandler=function(name,handler)
        assert(type(handler)=='function','stop handler required')
        if name~=stopEvent then return original.AddEventHandler(name,handler)end
        return original.AddEventHandler(name,function(resource,...)
            if resource=='forge-core'and not inBefore then
                signals=signals+1;pending=pending+1;inBefore=true
                local out=table.pack(pcall(beforeStop,resource));inBefore=false;pending=pending-1
                if not out[1]or out[2]~=true then
                    failures=failures+1;errors[#errors+1]=out[1]and'stop prelude incomplete'or tostring(out[2])
                end
            end
            -- Even failed cleanup must not suppress the domain's installed stop handler.
            return handler(resource,...)
        end)
    end
    function api.Progress()
        local snapshot={};for i,e in ipairs(errors)do snapshot[i]=e end
        return{signals=signals,pending=pending,failures=failures,errors=snapshot,operationalReady=false}
    end
    return api
end
