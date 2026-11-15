-- Explicit publication of borrowed gateways over the existing public registry.
local createPublic=require 'kernel.shared.public_registration'
return function(gateway,qb,ports)
    assert(ports.side=='server'or ports.side=='client','explicit gateway side required')
    local owner,ready=assert(ports.isCurrent),assert(ports.isReady)
    local phase,pending='allocated',0;local api={OperationalReady=false};local holder={}
    local refs={Describe=assert(gateway.Describe),Call=assert(gateway.Call),QBDescribe=assert(qb.Describe),QBCall=assert(qb.Call)}
    local function valid()
        if phase=='closed'or phase=='failed'then return false end
        local ok,value=pcall(owner)
        return ok and value==true and gateway.Describe==refs.Describe and gateway.Call==refs.Call and qb.Describe==refs.QBDescribe and qb.Call==refs.QBCall
    end
    local function check()
        assert(phase=='installed'and valid(),'compatibility endpoints unavailable')
        local ok,value=pcall(ready);assert(ok and value==true and phase=='installed'and valid(),'compatibility endpoints not ready')
    end
    local function call(fn,...)
        check();pending=pending+1;local out=table.pack(pcall(fn,...));pending=pending-1
        if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
    end
    local descriptors={}
    for _,pair in ipairs({{'ForgeQbxCompatDescribe','Describe'},{'ForgeQbxCompatCall','Call'},
        {'ForgeQbxCompatQBDescribe','QBDescribe'},{'ForgeQbxCompatQBCall','QBCall'}})do
        local fn=refs[pair[2]];descriptors[#descriptors+1]={kind='export',owner='Forge.QbxCompatibility',name=pair[1],handler=function(...)return call(fn,...)end}
    end
    local registration=createPublic({owner=holder,side=ports.side,entries=descriptors,isCurrent=valid},assert(ports.public))
    function api.Install()
        if phase~='allocated'then return false,'endpoint installation not repeatable'end
        local ok,value=pcall(ready);if not ok or value~=true or phase~='allocated'or not valid()then return false,'endpoint provider not ready'end
        phase='installing';pending=pending+1
        local out=table.pack(pcall(registration.Install));pending=pending-1
        if not out[1]or out[2]~=true or phase~='installing'or not valid()then
            api.Close();return false,out[1]and out[3]or out[2]
        end
        phase='installed';return true
    end
    function api.Close()
        phase='closed';local ok,value,why=pcall(registration.Dispose)
        return ok and(value==true or why=='already_revoked')and pending==0
    end
    function api.Progress()
        return{phase=phase,pending=pending,publication=registration.State,physicalRemoval=false,
            complete=phase=='closed'and pending==0 and registration.State=='revoked'}
    end
    function api.Describe()return registration.Describe()end
    return api
end
