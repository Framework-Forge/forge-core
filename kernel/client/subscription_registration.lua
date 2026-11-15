local create=require 'kernel.shared.subscription_registration'
return function(graph)
    local state,central=assert(graph.Core),assert(graph.Central)
    assert(graph.State=='prepared-inactive'and state.ClientDomainAssembly==graph and graph.IsCanonical(),'canonical client50 required')
    local refs,snapshots,entries={},{},{}
    local function resolve(path)local v=graph;for key in path:gmatch('[^.]+')do v=assert(v[key],path)end;return v end
    local function remember(path)local value=resolve(path);refs[#refs+1]={path=path,value=value};return value end
    local world=remember('Parts.World')
    local view=remember('Parts.World.WorldState')
    assert(view==world.World.State and view==graph.Client.WorldState,'same canonical World35 required')
    local subscribe=remember('Parts.World.WorldState.onChange')
    -- Installed client manifest order; aggregate aliases are checked, never registered twice.
    for _,name in ipairs({'Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','Vinewood'})do
        local path='Parts.'..name
        local part,runtime=remember(path),remember(path..'.Runtime')
        local list=remember(path..'.Runtime.Subscriptions')
        assert(remember(path..'.Subscriptions')==list and part.Runtime==runtime,'same subscription alias required: '..name)
        assert(part.WorldState==view and part.World==world,'same world owner required: '..name)
        local snapshot={list=list,entries={}};snapshots[#snapshots+1]=snapshot
        for i,d in ipairs(list)do
            snapshot.entries[i]={value=d,key=d.key,handler=d.handler}
            entries[#entries+1]={key=d.key,handler=d.handler,owner=path..'.Runtime'}
        end
    end
    for _,name in ipairs(graph.Order)do remember('Parts.'..name)end
    local function canonical()
        if state.ClientDomainAssembly~=graph or state.ClientAssembly~=central or not graph.IsCanonical()then return false end
        if graph.Client.WorldState~=view or world.World.State~=view then return false end
        for _,ref in ipairs(refs)do local ok,value=pcall(resolve,ref.path);if not ok or value~=ref.value then return false end end
        for _,s in ipairs(snapshots)do
            if #s.list~=#s.entries then return false end
            for i,d in ipairs(s.entries)do
                if s.list[i]~=d.value or d.value.key~=d.key or d.value.handler~=d.handler then return false end
            end
        end
        return true
    end
    return create({owner=state,isCurrent=canonical,subscribe=subscribe,entries=entries})
end
