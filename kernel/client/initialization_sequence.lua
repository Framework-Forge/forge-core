local create=require 'kernel.shared.initialization_sequence'
return function(graph,ports)
    local state,central=assert(graph.Core),assert(graph.Central)
    assert(state.ClientDomainAssembly==graph and graph.State=='prepared-inactive'and graph.IsCanonical(),'canonical client50 required')
    local refs,entries={},{}
    local function resolve(path)
        local value=graph;for k in path:gmatch('[^.]+')do value=assert(value[tonumber(k)or k],path)end;return value
    end
    local function remember(path)local value=resolve(path);refs[#refs+1]={path=path,value=value};return value end
    local stages={'Parts.World.World.Initialize','Central.Parts.Producers.Initialize','Central.Parts.Legacy.Initialize',
        'Central.Parts.Runtime.Initialize','Central.Parts.Character.Flow.Initialize','Parts.AutoMedic.Initialize','Parts.Starterpack.Initializers.1'}
    for _,path in ipairs(stages)do
        local parent=path:match('(.+)%.[^.]+$');remember(parent)
        entries[#entries+1]={name=path,owner=parent,handler=remember(path)}
    end
    -- Parents invoke these exact leaves. Do not initialize them a second time.
    for _,path in ipairs({'Central.Parts.Producers.Cache.Initialize','Central.Parts.Producers.Session.Initialize',
        'Central.Parts.Legacy.Utils.Initialize','Central.Parts.Legacy.Groups.Initialize','Central.Parts.Runtime.Main.Initialize',
        'Central.Parts.Runtime.Discord.Initialize','Parts.AutoMedic.Hospital.Initialize','Parts.AutoMedic.Session.Initialize'})do remember(path)end
    local world=remember('Parts.World.World')
    local view=remember('Parts.World.WorldState')
    local getRecord=remember('Parts.World.WorldState.getRecord')
    assert(world.State==view and graph.Client.WorldState==view,'canonical World35 required')
    assert(remember('Parts.Starterpack.Runtime.Initializers')==graph.Parts.Starterpack.Initializers,'canonical Starterpack initializer alias required')
    for _,name in ipairs(graph.Order)do remember('Parts.'..name)end
    local function canonical()
        if state.ClientDomainAssembly~=graph or state.ClientAssembly~=central or not graph.IsCanonical()or graph.Client.WorldState~=view or world.State~=view then return false end
        for _,ref in ipairs(refs)do local ok,value=pcall(resolve,ref.path);if not ok or value~=ref.value then return false end end
        return true
    end
    local function preflight()
        for _,key in ipairs({'stores','objects','npcs','density','vinewood','starterpack','farms','billboards','characterPreviews','spotlights'})do
            assert(getRecord(key)==nil,'late initialization would clear hydrated World: '..key)
        end
    end
    return create({owner=state,isCurrent=canonical,entries=entries,preflight=preflight},ports)
end
