-- Critical dependency checks only; no registration, version HTTP, shutdown or schema writes.
return function(ports)
    local current=assert(ports.isCurrent)
    local state,dependency=assert(ports.resourceState),assert(ports.checkDependency)
    local convar,convarInt=assert(ports.getConvar),assert(ports.getConvarInt)
    local databaseReady,ping=assert(ports.databaseReady),assert(ports.ping)
    local entries={}
    for _,name in ipairs({'pr_bridge','oxmysql','ox_inventory'})do
        entries[#entries+1]={name='resource:'..name,run=function()return state(name)=='started'end}
    end
    for _,d in ipairs({{'ox_lib','3.20.0'},{'ox_inventory','2.42.1'}})do
        entries[#entries+1]={name='contract:'..d[1],run=function()return dependency(d[1],d[2],false)==true end}
    end
    entries[#entries+1]={name='inventory:framework',run=function()return convar('inventory:framework','')=='qbx'end}
    entries[#entries+1]={name='onesync',run=function()return convarInt('onesync_enableInfinity',0)==1 end}
    entries[#entries+1]={name='database:provider',run=function()return databaseReady()==true end}
    entries[#entries+1]={name='database:ping',run=function()return ping()==true end}
    local api={OperationalReady=false,Writes=false}
    function api.Describe()local out={};for i,d in ipairs(entries)do out[i]=d.name end;return out end
    function api.Check()
        local report={ready=true,checks={}}
        for _,d in ipairs(entries)do
            if not current()then report.ready=false;report.cancelled=true;break end
            if d.name=='database:ping'and not report.ready then
                report.checks[#report.checks+1]={name=d.name,ready=false,skipped=true}
            else
                local ok,value=pcall(d.run)
                if not current()then report.ready=false;report.cancelled=true;break end
                local valid=ok and value==true
                report.checks[#report.checks+1]={name=d.name,ready=valid,error=not ok and tostring(value)or nil}
                if not valid then report.ready=false end
            end
        end
        return report.ready,report
    end
    return api
end
