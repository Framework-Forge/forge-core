local createPublic=require 'kernel.shared.public_registration'
return function(admission,ports)
    local current=assert(ports.isCurrent);local holder={};local phase,pending='allocated',0
    local api={OperationalReady=false}
    local function valid()return phase~='closed'and current()==true end
    local public=createPublic({owner=holder,side=assert(ports.side),isCurrent=valid,entries={{kind='export',owner='Forge.PRAdmission',name='ForgePrConsumerState',
        handler=function(...)
            if phase~='installed'or not valid()then return end;pending=pending+1
            local out=table.pack(pcall(admission.Handle,...));pending=pending-1
            if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
        end}}},assert(ports.public))
    function api.Install()
        if phase~='allocated'or not valid()then return false end;phase='installing'
        local ok,value=pcall(public.Install)
        if not ok or value~=true or phase~='installing'or not valid()then api.Close();return false end
        phase='installed';return true
    end
    function api.Close()phase='closed';local ok,value=public.Dispose();return(ok or value=='already_revoked')and pending==0 end
    function api.Progress()return{phase=phase,pending=pending,complete=phase=='closed'and pending==0 and public.State=='revoked'}end
    return api
end
