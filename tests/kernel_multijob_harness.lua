-- Test-only whole installed sources vs private modules. No live SQL, NUI or resource mutation.
local S=dofile('tests/kernel_job_service_harness.lua')
local A=dofile('tests/kernel_work_menu_harness.lua')
local H,P,J=S.H,S.P,S.J
local N={H=H,P=P,J=J,A=A,count=0}
function N.env()
    local e=H.environment()
    e.require=function(name)assert(name:match('^kernel%.'));return H.load(name:gsub('%.','/')..'.lua',e)end
    return e
end
function N.config(ported)
    if ported then return H.load('kernel/config/forge_multijob.lua',H.environment())()end
    local e=H.environment({PR={}});H.load('shared/multijob.lua',e);return e.PR.MultiJob
end
function N.provider(r)
    local e=H.environment({GetResourceState=function(name)assert(name=='xt-prison');r.record('prison-state');return r.prisonState end})
    local p={}
    for _,name in ipairs({'GetPrisonStatus','JailPlayer','ReleasePlayer'})do
        p[name]=function(_,src,data)
            r.record('prison-'..name,src,data)
            if r.providerError then error('provider-error',0)end
            if name=='GetPrisonStatus'then return r.prisonStatus end
            return table.unpack(r.prisonResult,1,r.prisonResult.n)
        end
    end
    e.exports={['xt-prison']=p}
    return H.load('../pr_bridge/bridge/prison/server.lua',e)
end
function N.new(ported,options)
    local r={trace={},callbacks={},settings={},players={},jobs={},blocked=false,metadataResult=nil,
        now=1792320000,prisonState='stopped',prisonStatus={jailed=false,status='free'},prisonResult=table.pack(true,'done'),
        setResult=table.pack(true),dutyResult=table.pack(nil)}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    r.config=N.config(ported)
    r.jobs={taxi={label='Taxi',defaultDuty=true,grades={[0]={name='Driver',payment=10},[2]={name='Boss',payment=50}},
        stashes={{enabled=true,duty={enabled=true}}}},
        police={label='Police',defaultDuty=false,grades={[0]={name='Cadet'},[4]={name='Chief',payment=100}}},
        unemployed={label='Civilian',grades={[0]={name='Citizen',payment=1}}}}
    r.registryJobs=H.copy(r.jobs)
    r.players[1]={PlayerData={source=1,citizenid='ONE',metadata={multijob={}},jobs={police=0},job={name='police',label='Police',grade={level=0},onduty=true}}}
    r.players[2]={PlayerData={source=2,citizenid='TWO',metadata={multijob={}},jobs={taxi=0},job={name='taxi',label='Taxi',grade={level=0},onduty=false}}}
    for src,p in pairs(r.players)do
        p.Functions={SetMetaData=function(key,value)
            r.record('metadata-write',src,key,value)
            if r.metadataHook then r.metadataHook(src,key,value)end
            if r.metadataError then error('metadata-error',0)end
            if not r.skipMetadata then p.PlayerData.metadata[key]=value end
            return r.metadataResult
        end}
    end
    r.memory=J.persistence();r.memory.seed(r.config.Storage.file,{maxJobs=3,enabled=true})
    local library={};for k,v in pairs(r.memory.api)do library[k]=v end
    r.library=library
    local wrap=library.wrapJsonMutations
    library.wrapJsonMutations=function(path,obj,names)r.record('wrap',path,names);return wrap(path,obj,names)end
    local save=library.saveJsonRecovery
    library.saveJsonRecovery=function(path,data)
        r.record('save',path,data);if r.saveHook then r.saveHook()end
        if r.saveError then error('save-error',0)end
        if r.failSave then return false end
        return save(path,data)
    end
    library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    library.debug={success=function(...)r.record('debug',...)end}
    r.translate=function(key,args)r.record('translate',key,args);return key end
    r.native={emitClient=function(...)r.record('client',...)end}
    r.lookup={GetPlayer=function(src)r.record('player',src);return r.players[tonumber(src)or src]end}
    r.groups={GetJob=function(name)
        r.record('job',name);if r.jobError then error('job-error',0)end
        if r.jobHook then r.jobHook(name)end
        return r.jobs[name]
    end}
    r.registry={getJobs=function()r.record('registry');return r.registryJobs end}
    r.jobService={canManage=function(src)r.record('permission',src);return src==0 or src==2 and not r.revoke end}
    r.playerApi={
        SetJob=function(src,name,grade)
            r.record('set-job',src,name,grade);if r.setHook then r.setHook()end
            if r.setError then error('set-error',0)end
            if r.setResult[1]and r.players[src]then
                local p=r.players[src].PlayerData
                p.job={name=name,label=(r.jobs[name]or{}).label,grade={level=grade},onduty=true}
                p.jobs[name]=grade
            end
            return table.unpack(r.setResult,1,r.setResult.n)
        end,
        SetJobDuty=function(src,duty)
            r.record('set-duty',src,duty);if r.dutyError then error('duty-error',0)end
            if not r.skipDuty and r.players[src]then r.players[src].PlayerData.job.onduty=duty end
            return table.unpack(r.dutyResult,1,r.dutyResult.n)
        end,
    }
    if options then options(r)end
    r.provider=r.providerNil and nil or N.provider(r)
    if r.providerNil then r.provider=nil end
    if ported then
        local deps={}
        r.base={Groups=r.groups,PlayerCore={Groups=r.groups,Lookup=r.lookup,Players=r.playerApi},
            Callbacks={},JobCatalog={Groups=r.groups,Registry=r.registry,Service=r.jobService,Dependencies=deps}}
        r.base.JobCatalog.Transport={Security=r.base.Callbacks}
        r.core=H.load('kernel/server/multijob/multijob_core.lua',N.env())(r.base,{
            config=r.config,library=library,native=r.native,translate=r.translate,time=function()return r.now end,
            prisonProvider=r.provider,notifyPosition='top-right'})
        r.api,r.prison=r.core.Service,r.core.PrisonService
        assert(#r.trace==0,'constructors must not query/read/register/wrap')
        r.api.Initialize()
        for _,d in ipairs(r.core.Callbacks)do r.callbacks[d.name]=d.handler end
    else
        local e=H.environment({PR={MultiJob=r.config,NotifyPos='top-right'},pr_lib=library,
            GetCurrentResourceName=function()return'forge-core'end,TriggerClientEvent=r.native.emitClient,os={time=function()return r.now end}})
        local qbx={}
        for name,fn in pairs({GetPlayer=r.lookup.GetPlayer,GetJob=r.groups.GetJob,SetJob=r.playerApi.SetJob,SetJobDuty=r.playerApi.SetJobDuty})do
            qbx[name]=function(_,...)return fn(...)end
        end
        local fe=H.environment({ActiveBridges={frameworks='qbx'},exports={qbx_core=qbx},
            Debug=function()end,Lang={t=function()return''end}})
        local framework=H.load('../pr_bridge/bridge/frameworks/qbx/server.lua',fe)
        e.exports={qbx_core=qbx}
        framework.GetPlayerMetadata,framework.SetPlayerMetadata=framework.getPlayerMetadata,framework.setPlayerMetadata
        library.framework=framework
        library.load=function(name)assert(name=='@pr_bridge/bridge/prison/server');return r.provider end
        e.ForgeCore={t=r.translate,JobRegistry=r.registry,JobService=r.jobService,Callbacks={register=function(name,fn)r.callbacks[name]=fn end}}
        H.load('server/player/prison.lua',e);H.load('server/multijob/service.lua',e);H.load('server/multijob/callbacks.lua',e)
        r.api,r.prison=e.ForgeCore.MultiJobService,e.ForgeCore.PrisonService
    end
    return r
end
local function outcome(fn,r)
    local result=table.pack(pcall(fn,r))
    if not result[1]then result[2]=tostring(result[2]):gsub('\nstack traceback:.*',''):gsub('^.-:%d+: ','')end
    return P.snapshot(result)
end
function N.case(label,fn,options)
    local a,b=N.new(false,options),N.new(true,options)
    H.same(outcome(fn,b),outcome(fn,a),label..': return/error')
    H.same(b.trace,a.trace,label..': complete effects')
    local function snapshot(r)
        return P.snapshot({settings=r.api.settings,players=r.players,jobs=r.jobs,files=r.memory.files,io=r.memory.trace})
    end
    H.same(snapshot(b),snapshot(a),label..': state/metadata/files')
    N.count=N.count+1
end
function N.ui(ported,options)
    local r=A.new(ported,function(r)
        r.config.MultiJob=N.config(ported)
        if options then options(r)end
    end)
    r.menu.openMultiJobAdminMenu=nil
    if ported then
        H.load('kernel/client/menu/multijob.lua',H.environment())({menu=r.menu,shared=r.shared,config=r.config,native=r.native})
    else
        local e=H.environment({ForgeCore={Client={Menu=r.menu,MenuShared=r.shared}},PR=r.config,SetTimeout=r.native.setTimeout})
        H.load('client/menu/menu_multijob.lua',e)
    end
    return r
end
function N.uiCase(label,fn,options)
    local a,b=N.ui(false,options),N.ui(true,options)
    H.same(outcome(fn,b),outcome(fn,a),label..': return/error')
    H.same(b.trace,a.trace,label..': complete UI/RPC/timer effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),label..': retained contexts')
    N.count=N.count+1
end
return N

