local create=require 'kernel.shared.initialization_sequence'
return function(graph,bootstrap,ports)
    local base,pc,central=assert(graph.Base),assert(graph.PlayerCore),assert(graph.Central)
    assert(base.DomainAssembly==graph and base.PlayerCore==pc and graph.State=='prepared-inactive','canonical server48 required')
    local refs,entries={},{}
    local function resolve(path)local value=graph;for key in path:gmatch('[^.]+')do value=assert(value[tonumber(key)or key],path)end;return value end
    local function remember(path)local value=resolve(path);refs[#refs+1]={path=path,value=value};return value end
    local function step(path)local parent=path:match('(.+)%.[^.]+$');remember(parent);entries[#entries+1]={name=path,owner=parent,handler=remember(path)}end
    -- World namespace must exist before any service publishes its first record.
    step('Parts.World.World.Initialize');step('PlayerCore.Runtime.Initialize')
    if pc.Lifecycle.Queue then step('PlayerCore.Lifecycle.Queue.Bootstrap')end
    for _,path in ipairs({'Central.Parts.Finance.Vip.Initialize','Central.Parts.Inventory.Service.Initialize',
        'Central.Parts.Consumption.Service.Initialize','Central.Parts.Weapons.Service.Initialize','Parts.MultiJob.Service.Initialize','Parts.Vehicles.Initialize'})do step(path)end
    remember('PlayerCore.Runtime.Main.Initialize');remember('PlayerCore.Runtime.Commands.Initialize')
    for _,name in ipairs(graph.Order)do remember('Parts.'..name)end
    local begin=assert(bootstrap.Begin);local services=assert(bootstrap.Services)
    entries[#entries+1]={name='Bootstrap.Begin',owner='Bootstrap',handler=begin}
    local dependencies=assert(base.JobCatalog.Dependencies);local serviceRefs={}
    local function service(name)if name=='JobService'then return base.JobCatalog.Service end;return dependencies[name]end
    for _,d in ipairs(services)do
        assert(service(d.name)and service(d.name).start==d.handler,'canonical bootstrap service required: '..d.name)
        serviceRefs[#serviceRefs+1]={descriptor=d,name=d.name,owner=service(d.name),handler=d.handler}
        entries[#entries+1]={name='Bootstrap.'..d.name..'.start',owner=d.name,handler=d.handler}
    end
    assert(#services==21,'complete Forge bootstrap required')
    local view=remember('Parts.World.State');local getRecord=remember('Parts.World.State.getRecord')
    local function canonical()
        if base.DomainAssembly~=graph or base.ServerAssembly~=central or base.PlayerCore~=pc or base.Callbacks~=graph.Security
            or base.JobCatalog.Dependencies~=dependencies or bootstrap.Begin~=begin or bootstrap.Services~=services or #services~=21 then return false end
        for _,d in ipairs(refs)do local ok,value=pcall(resolve,d.path);if not ok or value~=d.value then return false end end
        for i,d in ipairs(serviceRefs)do
            local item=services[i]
            if item~=d.descriptor or item.name~=d.name or service(d.name)~=d.owner
                or d.owner.start~=d.handler or item.handler~=d.handler then return false end
        end
        return true
    end
    local seq=create({owner=base,isCurrent=canonical,entries=entries,preflight=function()
        for _,key in ipairs({'stores','objects','npcs','density','vinewood','starterpack','farms','billboards','characterPreviews','spotlights'})do
            assert(getRecord(key)==nil,'late initialization would clear hydrated server World: '..key)
        end
        assert(view==graph.Parts.World.State,'canonical server World required')
    end},{isReady=assert(ports.isReady)})
    -- Service bodies can schedule work; do not expose generic56's no-launch metadata as a server promise.
    return{Initialize=seq.Initialize,Cancel=seq.Cancel,Progress=seq.Progress,Describe=seq.Describe,SchedulesServiceWork=true}
end
