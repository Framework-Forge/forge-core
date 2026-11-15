local X=dofile('tests/kernel_qb_export_registration_harness.lua');local H=X.H;local T={X=X,H=H,E=X.E,C=X.C,S=X.S}
function T.new(side)
    local r=X.new(side)
    r.coreJobs=r.bridge.jobs;r.coreGangs=r.bridge.gangs
    local prefix=side=='server'and'qbx_core:server:'or'qbx_core:client:'
    r.jobEvent=prefix..'onJobUpdate';r.gangEvent=prefix..'onGangUpdate'
    local coreEntries={
        {owner='Groups',name=r.jobEvent,network=side=='client',sourceFirst=false,handler=function(name,job)
            r.coreJobs[name]=job;r.coreJobCalls=(r.coreJobCalls or 0)+1
        end},
        {owner='Groups',name=r.gangEvent,network=side=='client',sourceFirst=false,handler=function(name,gang)r.coreGangs[name]=gang end},
    }
    r.core=H.load('kernel/shared/event_registration.lua',H.environment())({owner={},side=side,entries=coreEntries,isCurrent=function()return r.current end},r.bus.ports)
    r.eventPorts={side=side,events=r.bus.ports,isCurrent=function()return r.current end}
    r.factory=H.load('kernel/compat/qb/event_registration.lua',X.C.environment())
    function r.prepare()r.events=r.factory(r.bridge.api,r.core,r.eventPorts);return r.events end
    function r.installCore()assert(r.core.Install())end
    function r.install()assert(r.events.Install())end
    return r
end
return T
