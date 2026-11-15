-- Local Forge API for external PR consumers; not a network transport or an internal framework shortcut.
local createPublic=require 'kernel.shared.public_registration'
local createBackend=require 'kernel.server.framework_backend'
local createCatalog=require 'kernel.compat.qbx.export_catalog'
return function(graph,side,origin,ports)
    assert(side=='server'or side=='client','explicit native API side required')
    local current,ready,invoke,allowed=assert(ports.isCurrent),assert(ports.isReady),assert(ports.getInvokingResource),assert(ports.isConsumerAllowed)
    local generation=assert(ports.generation);assert(type(generation)=='string'and generation~='','native generation required')
    local phase,pending='allocated',0;local holder={};local api={OperationalReady=false}
    local function valid()local ok,v=pcall(current);return phase~='closed'and ok and v==true end
    local catalog=createCatalog(graph,side,{isCurrent=valid})
    local backend=side=='server'and createBackend(graph,{isCurrent=valid,isReady=ready})or nil
    local groups={framework=backend and backend.Core or{},core={},inventory={},native={}}
    for _,name in ipairs(side=='server'and{'GetVehiclesByHash','GetJobs','GetGangs','EnablePersistence','DisablePersistence'}or{'GetVehiclesByHash','GetJobs','GetGangs'})do groups.core[name]=catalog.Resolve(name)end
    if side=='server'then for _,name in ipairs({'GetPlayer','GetPlayersData','CanUseItem','GetGroups','IsGradeBoss'})do groups.inventory[name]=catalog.Resolve(name)end end
    if ports.getCoreObject then assert(type(ports.getCoreObject)=='function');groups.native.GetCoreObject=ports.getCoreObject end
    local names={};for group,functions in pairs(groups)do names[group]={};for name,fn in pairs(functions)do assert(type(fn)=='function');names[group][#names[group]+1]=name end;table.sort(names[group])end
    local function entered(fn,...)
        pending=pending+1;local out=table.pack(pcall(fn,...));pending=pending-1
        if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
    end
    local function check(mode)
        assert(phase=='installed'and valid()and catalog.IsCurrent()and origin.IsCurrent(),'Forge PR API unavailable')
        local caller=invoke();assert(type(caller)=='string'and caller~=''and caller~='forge-core'and caller~='qbx_core','external local PR consumer required')
        assert(allowed(caller,mode)==true,'Forge PR consumer not admitted');assert(ready()==true and phase=='installed'and valid(),'Forge PR API not ready')
        return caller
    end
    function api.Describe()return entered(function()
        check('describe');local copy={};for group,list in pairs(names)do copy[group]={};for i,name in ipairs(list)do copy[group][i]=name end end
        return{protocol='forge-pr-native/1',authority='forge-core',side=side,generation=generation,groups=copy}
    end)end
    function api.Call(epoch,group,name,...)
        return entered(function(...)
            local caller=check('call');assert(epoch==generation,'stale Forge PR generation')
            local fn=assert(groups[group]and groups[group][name],'unsupported Forge PR method')
            return origin.Run(caller,fn,...)
        end,...)
    end
    local publication=createPublic({owner=holder,side=side,isCurrent=valid,entries={
        {kind='export',owner='Forge.PRNativeAPI',name='ForgePrDescribe',handler=api.Describe},
        {kind='export',owner='Forge.PRNativeAPI',name='ForgePrCall',handler=api.Call}}},assert(ports.public))
    function api.Install()
        if phase~='allocated'then return false end;phase='installing';pending=pending+1
        local ok,result,problem=pcall(publication.Install);pending=pending-1
        if not ok or result~=true or phase~='installing'or not valid()then api.Close();return false,ok and problem or result end
        phase='installed';return true
    end
    function api.Close()
        phase='closed';local a,b=publication.Dispose();if backend then backend.Close()end;catalog.Close()
        return(a or b=='already_revoked')and pending==0
    end
    function api.Progress()local b=backend and backend.Progress();return{phase=phase,pending=pending+(b and b.pending or 0),physicalRemoval=false,
        complete=phase=='closed'and pending==0 and(not b or b.complete)and publication.State=='revoked'}end
    return api
end
