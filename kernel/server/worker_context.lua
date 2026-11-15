local createGraph=require 'kernel.server.domain_assembly'
local createBootstrap=require 'kernel.server.bootstrap'
local createInitialization=require 'kernel.server.initialization_sequence'
local function copy(t)local o={};for k,v in pairs(t)do o[k]=v end;return o end
return function(base,ports)
    assert(base.ServerWorkerContext==nil and base.ServerAssembly==nil and base.DomainAssembly==nil,'fresh server worker state required')
    local phase,graph,initial,bootstrap='constructing'
    local refs,workers={},{}
    local api={Base=base,ReversesEffects=false,PhysicalRemoval=false}
    base.ServerWorkerContext=api
    local function resolve(path)local value=graph;for key in path:gmatch('[^.]+')do value=assert(value[tonumber(key)or key],path)end;return value end
    local function current()
        if phase=='closed'or phase=='failed'or not graph or base.ServerWorkerContext~=api or base.DomainAssembly~=graph
            or base.ServerAssembly~=graph.Central or base.PlayerCore~=graph.PlayerCore or base.Callbacks~=graph.Security then return false end
        for _,d in ipairs(refs)do local ok,value=pcall(resolve,d.path);if not ok or value~=d.value or(d.count and #value~=d.count)then return false end end
        return true
    end
    local report=assert(ports.onError)
    local tasks=assert(ports.createTasks)({running=assert(ports.running),isCurrent=current,onError=function(...)
        if phase~='closed'then phase='failed'end;if initial then initial.Cancel()end;return report(...)
    end})
    local function wrap(native)
        local out=tasks.WrapNative(assert(native))
        if native.spawn then out.spawn=tasks.WrapNative({createThread=native.spawn}).createThread end
        return out
    end
    local scheduler
    local ok,err=pcall(function()
        local p=copy(assert(ports.graph));p.central=copy(p.central);p.helpers=copy(p.helpers);p.helpers.native=wrap(p.helpers.native)
        p.domains={};for name,value in pairs(ports.graph.domains)do local d=copy(value);d.native=wrap(d.native);p.domains[name]=d end
        for name,value in pairs(ports.graph.central)do
            local d=copy(value);if d.native then d.native=wrap(d.native)end;p.central[name]=d
        end
        p.central.session.player=copy(p.central.session.player)
        p.central.session.player.platform=wrap(p.central.session.player.platform)
        local native=wrap(assert(ports.bootstrap.native))
        scheduler=tasks.WrapNative({CreateThread=ports.bootstrap.native.spawn or ports.bootstrap.native.CreateThread})
        graph=createGraph(base,p)
        for _,name in ipairs(graph.Order)do refs[#refs+1]={path='Parts.'..name,value=graph.Parts[name]}end
        for _,path in ipairs({'PlayerCore.State','PlayerCore.State.Players','PlayerCore.State.Status','PlayerCore.Shared','PlayerCore.Groups',
            'PlayerCore.Producers.Status','Central.Parts.Finance.Vip'})do refs[#refs+1]={path=path,value=resolve(path)}end
        for _,path in ipairs({'PlayerCore.Producers.Status.Threads','Central.Parts.Finance.Vip.Threads'})do
            local list=resolve(path);assert(#list==1,'server static worker coverage changed')
            refs[#refs+1]={path=path,value=list,count=1};refs[#refs+1]={path=path..'.1',value=list[1]}
            workers[#workers+1]={name=path..'.1',handler=list[1]}
        end
        local services=copy(base.JobCatalog.Dependencies);services.JobService=base.JobCatalog.Service
        bootstrap=createBootstrap({services=services,library=ports.bootstrap.library,native=native,debugEnabled=graph.Config.Debug})
        initial=createInitialization(graph,bootstrap,{isReady=assert(ports.isReady)})
        api.Graph,api.Bootstrap,api.Initialization=graph,bootstrap,initial;phase='prepared'
    end)
    if not ok then phase='failed';tasks.Close();error(err,0)end
    function api.Start()
        if phase~='prepared'then return false,'server_context_not_repeatable'end
        phase='starting'
        local done,problem=pcall(function()
            assert(current()and tasks.Open(),'server task scope unavailable')
            local initialized,why=initial.Initialize();assert(initialized,why or'server initialization refused')
            for _,d in ipairs(workers)do assert(current()and phase=='starting','server context revoked');assert(tasks.Launch(scheduler,d.handler))end
            assert(current()and phase=='starting','server context revoked');phase='running'
        end)
        if not done then if phase~='closed'then phase='failed'end;tasks.Close();initial.Cancel();error(problem,0)end
        return true
    end
    function api.Close()if phase=='closed'then return false end;phase='closed';tasks.Close();initial.Cancel();return true end
    function api.Progress()local out=tasks.Snapshot();out.context=phase;out.initialization=initial.Progress();return out end
    function api.Describe()local out={};for i,d in ipairs(workers)do out[i]={name=d.name}end;return out end
    return api
end
