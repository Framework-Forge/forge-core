-- Fresh canonical client49/50 with owned native scheduling, before local captures.
local createCentral=require 'kernel.client.assembly_core'
local createDomains=require 'kernel.client.domain_assembly'
local createInitialization=require 'kernel.client.initialization_sequence'
local function copy(t)local o={};for k,v in pairs(t)do o[k]=v end;return o end
return function(state,ports)
    assert(state.ClientWorkerContext==nil and state.ClientAssembly==nil and state.ClientDomainAssembly==nil,'fresh client state required')
    local createTasks=assert(ports.createTasks,'explicit PR task factory required')
    local graph,refs,entries
    local phase='constructing'
    local api={Core=state,PhysicalRemoval=false,ReversesEffects=false}
    state.ClientWorkerContext=api
    local paths={}
    local function resolve(path)
        local keys=paths[path]
        if not keys then
            keys={};for key in path:gmatch('[^.]+')do keys[#keys+1]=tonumber(key)or key end
            paths[path]=keys
        end
        local value=graph;for i=1,#keys do value=assert(value[keys[i]],path)end;return value
    end
    local referenceTree={}
    local function checkTree(value,nodes)
        for i=1,#nodes do
            local node=nodes[i]
            local child=value[node.key]
            if not child then return false end
            if node.ref and(child~=node.ref.value or(node.ref.count and #child~=node.ref.count))then return false end
            if node.children and not checkTree(child,node.children)then return false end
        end
        return true
    end
    local function canonical()
        if phase=='closed'or phase=='failed'or not graph or state.ClientWorkerContext~=api or not graph.IsCanonical()then return false end
        -- Shared path prefixes are traversed once. This caches the structure of
        -- the check, never its result; replacement/cancellation remains immediate.
        local ok,value=pcall(checkTree,graph,referenceTree)
        return ok and value==true
    end
    local initial,centralPorts,domainPorts
    local reportError=assert(ports.onError)
    local tasks=createTasks({isCurrent=canonical,running=assert(ports.running),onError=function(...)
        if phase~='closed'then phase='failed'end
        if initial then initial.Cancel()end;return reportError(...)
    end})
    local ok,problem=pcall(function()
        centralPorts=copy(assert(ports.central));centralPorts.native=tasks.WrapNative(centralPorts.native)
        domainPorts=copy(assert(ports.domains));domainPorts.domains={}
        for key,value in pairs(ports.domains.domains)do
            local p=copy(value);p.native=tasks.WrapNative(p.native);domainPorts.domains[key]=p
            if key=='Jobs'then p.wait=tasks.WrapNative({wait=assert(p.wait)}).wait end
        end
        createCentral(state,centralPorts)
        graph=createDomains(state,domainPorts)
        refs,entries={},{}
        local function collect(path,native)
            local list=resolve(path);refs[#refs+1]={path=path,value=list,count=#list}
            for i,fn in ipairs(list)do
                assert(type(fn)=='function','invalid worker descriptor')
                local name=path..'.'..i;refs[#refs+1]={path=name,value=fn}
                entries[#entries+1]={name=name,handler=fn,native=native}
            end
        end
        -- Match original relative manifest order, not the order factories were constructed.
        for _,name in ipairs({'Runtime.Main','Producers.Status','Runtime.Loops','Character.Flow'})do
            collect('Central.Parts.'..name..'.Threads',centralPorts.native)
        end
        for _,item in ipairs({{'World','World'},{'Objects'},{'Npcs'},{'Spotlights'},{'Billboards'},{'Stores'},{'Farms'},{'AutoMedic','Runtime'}})do
            collect('Parts.'..item[1]..(item[2]and'.'..item[2]or'')..'.Threads',domainPorts.domains[item[1]].native)
        end
        collect('Central.Parts.Consumption.Threads',centralPorts.native)
        for _,item in ipairs({{'Skills','Runtime'},{'Access','Runtime'},{'World','Density'},{'Vinewood'},{'Jobs','Bootstrap'}})do
            collect('Parts.'..item[1]..(item[2]and'.'..item[2]or'')..'.Threads',domainPorts.domains[item[1]].native)
        end
        local seen={};for _,entry in ipairs(entries)do assert(not seen[entry.handler],'duplicate worker alias');seen[entry.handler]=true end
        for _,ref in ipairs(refs)do
            local list=referenceTree
            local keys=paths[ref.path]
            if not keys then keys={};for key in ref.path:gmatch('[^.]+')do keys[#keys+1]=tonumber(key)or key end end
            for i,key in ipairs(keys)do
                local node
                for _,candidate in ipairs(list)do if candidate.key==key then node=candidate;break end end
                if not node then node={key=key};list[#list+1]=node end
                if i==#keys then node.ref=ref
                else node.children=node.children or{};list=node.children end
            end
        end
        assert(#entries==27,'client worker coverage changed')
        initial=createInitialization(graph,{isReady=assert(ports.isReady)})
        api.Graph,api.Initialization=graph,initial
        phase='prepared'
    end)
    if not ok then phase='failed';tasks.Close();error(problem,0)end
    function api.Start()
        if phase~='prepared'then return false,'worker_context_not_repeatable'end
        phase='starting'
        local started,err=pcall(function()
            assert(canonical(),'stale worker context')
            assert(tasks.Open(),'task scope unavailable')
            local initialized,reason=initial.Initialize()
            assert(initialized,reason or'initialization refused')
            for _,entry in ipairs(entries)do
                assert(canonical()and phase=='starting','worker context revoked')
                assert(tasks.Launch(entry.native,entry.handler),'worker launch refused')
            end
            assert(canonical()and phase=='starting','worker context revoked')
            phase='running'
        end)
        if not started then
            if phase~='closed'then phase='failed'end
            tasks.Close();initial.Cancel();error(err,0)
        end
        return true
    end
    function api.Close()
        if phase=='closed'then return false end
        phase='closed';tasks.Close();initial.Cancel();return true
    end
    function api.Progress()local out=tasks.Snapshot();out.context=phase;out.initialization=initial.Progress();return out end
    function api.Describe()
        local out={};for i,entry in ipairs(entries)do out[i]={name=entry.name}end;return out
    end
    return api
end
