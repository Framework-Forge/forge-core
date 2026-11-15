-- Factory intended for an explicit qbx_core compatibility resource. No core state,services,timers or fallback.
return function(side,ports)
    assert(side=='server'or side=='client','explicit relay side required')
    local resource,invoking,current=assert(ports.getCurrentResourceName),assert(ports.getInvokingResource),assert(ports.isCurrent)
    assert(resource()=='qbx_core','explicit QBX compatibility resource required')
    local describe,call,available,publish=assert(ports.describe),assert(ports.call),assert(ports.available),assert(ports.publishExport)
    local phase,pending='allocated',0;local generation;local names,published={},0
    local api={OperationalReady=false,Authority='forge-core',Side=side}
    local function valid()local ok,value=pcall(current);return phase~='closed'and ok and value==true end
    local function tracked(fn,...)
        pending=pending+1;local result=table.pack(pcall(fn,...));pending=pending-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Prepare()
        if phase~='allocated'or not valid()then return false,'qbx_relay_not_allocated'end
        phase='preparing';local ok,data=pcall(tracked,describe)
        if not ok then if phase~='closed'then phase='failed'end;error(data,0)end
        if phase~='preparing'or not valid()then return false,'qbx_relay_cancelled'end
        assert(data.protocol=='forge-qbx-compat/1'and data.authority=='forge-core'and data.side==side,'QBX gateway contract mismatch')
        assert(type(data.generation)=='string'and data.generation~='','gateway generation required');generation=data.generation
        local seen={};for i,name in ipairs(assert(data.names))do
            assert(type(name)=='string'and name:match('^[%a_][%w_]*$')and not seen[name],'invalid/duplicate QBX export')
            seen[name]=true;names[i]=name
        end
        assert(#names==(side=='server'and 105 or 24),'complete native QBX export surface required');phase='prepared';return true
    end
    function api.Install()
        if phase~='prepared'or not valid()then return false,'qbx_relay_not_prepared'end
        phase='installing'
        local ok,problem=pcall(function()
            for _,name in ipairs(names)do assert(tracked(available,name)==true,'foreign QBX export '..name);assert(phase=='installing'and valid(),'relay installation cancelled')end
            for _,name in ipairs(names)do
                assert(phase=='installing'and valid(),'relay installation cancelled')
                assert(tracked(available,name)==true,'QBX export namespace changed');assert(phase=='installing'and valid(),'relay installation cancelled')
                local function forward(...)
                    assert(phase=='installed'and valid(),'qbx_relay_unavailable')
                    local caller=invoking();assert(type(caller)=='string'and caller~=''and caller~='qbx_core','local invoking resource required')
                    return tracked(call,generation,name,caller,...)
                end
                published=published+1 -- Native publication may be irreversible/uncertain;never retry it.
                assert(tracked(publish,name,forward)~=false,'QBX export publication rejected')
            end
            assert(phase=='installing'and valid(),'relay installation cancelled')
        end)
        if not ok then if phase~='closed'then phase='failed'end;return false,problem end
        phase='installed';return true
    end
    function api.Close()phase='closed';return pending==0 end
    function api.Progress()return{phase=phase,pending=pending,published=published,physicalRemoval=false,complete=phase=='closed'and pending==0}end
    function api.Describe()local out={};for i,name in ipairs(names)do out[i]=name end;return{names=out,generation=generation,authority='forge-core'}end
    return api
end
