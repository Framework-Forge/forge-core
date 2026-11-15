-- Optional QB resource-export relay. Native QBX105/24 surface and lookup event ownership stay separate.
return function(side,ports)
    assert(side=='server'or side=='client','explicit QB relay side required')
    assert(ports.getCurrentResourceName()=='qbx_core','explicit QBX compatibility resource required')
    local current,invoke=assert(ports.isCurrent),assert(ports.getInvokingResource)
    local phase,pending='allocated',0;local generation,enabled;local api={OperationalReady=false}
    local function valid()local ok,value=pcall(current);return phase~='closed'and ok and value==true end
    local function tracked(fn,...)
        pending=pending+1;local out=table.pack(pcall(fn,...));pending=pending-1
        if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
    end
    function api.Prepare()
        if phase~='allocated'or not valid()then return false end;phase='preparing'
        local ok,data=pcall(tracked,ports.describe)
        if not ok then if phase~='closed'then phase='failed'end;error(data,0)end
        if phase~='preparing'or not valid()then return false end
        assert(data.protocol=='forge-qbx-qb/1'and data.side==side and type(data.generation)=='string'and data.generation~='','QB extension contract mismatch')
        assert(type(data.setField)=='boolean'and(side=='server'or data.setField==false),'invalid QB export capacity')
        generation,enabled=data.generation,data.setField;phase='prepared';return true
    end
    function api.Install()
        if phase~='prepared'or not valid()then return false end;phase='installing'
        local ok,problem=pcall(function()
            if enabled then
                assert(tracked(ports.available,'SetField')==true,'foreign SetField');assert(phase=='installing'and valid(),'QB extension closed')
                assert(tracked(ports.publishExport,'SetField',function(...)
                    assert(phase=='installed'and valid(),'QB relay unavailable');local caller=invoke()
                    assert(type(caller)=='string'and caller~=''and caller~='qbx_core','identified local caller required')
                    return tracked(ports.call,generation,'SetField',caller,...)
                end)~=false,'SetField publication rejected')
            end
            assert(phase=='installing'and valid(),'QB extension closed')
        end)
        if not ok then if phase~='closed'then phase='failed'end;return false,problem end;phase='installed';return true
    end
    function api.Close()phase='closed';return pending==0 end
    function api.Progress()return{phase=phase,pending=pending,setField=enabled==true,physicalRemoval=false,complete=phase=='closed'and pending==0}end
    return api
end
