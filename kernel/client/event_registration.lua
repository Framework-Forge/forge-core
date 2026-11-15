local create=require 'kernel.shared.event_registration'
return function(graph,ports)
    local state,central=assert(graph.Core),assert(graph.Central)
    assert(graph.State=='prepared-inactive'and state.ClientDomainAssembly==graph and graph.IsCanonical(),'canonical client50 required')
    local entries,refs={},{}
    local function resolve(path)local value=graph;for key in path:gmatch('[^.]+')do value=assert(value[key],path)end;return value end
    local function include(path)
        local module=resolve(path);assert(type(module)=='table','event owner required: '..path);refs[#refs+1]={path=path,module=module}
        for _,d in ipairs(module.Events or{})do
            entries[#entries+1]={owner=path,name=d.name,handler=d.handler,network=d.network==true,sourceFirst=false}
        end
    end
    -- Original relative manifest order. Do not collect aggregated aliases from World/AutoMedic again.
    for _,path in ipairs({'Central.Parts.Runtime.Main','Central.Parts.Producers.Cache','Central.Parts.Producers.Session',
        'Central.Parts.Producers.Status','Central.Parts.Legacy.Groups','Central.Parts.Runtime.Loops','Central.Parts.Runtime.Events',
        'Central.Parts.Character.Flow','Central.Parts.Runtime.Discord','Parts.World.World','Parts.AutoMedic.Session','Parts.Jobs.Replica',
        'Parts.Zones','Parts.Objects','Parts.Npcs','Parts.Spotlights','Parts.Billboards','Parts.Stores','Parts.Farms','Parts.Starterpack',
        'Parts.AutoMedic.Hospital','Parts.AutoMedic.Runtime','Central.Parts.Consumption','Parts.Work','Parts.Skills','Parts.Access','Parts.Vinewood'})do include(path)end
    for _,name in ipairs(graph.Order)do local path='Parts.'..name;refs[#refs+1]={path=path,module=resolve(path)}end
    local function canonical()
        if state.ClientDomainAssembly~=graph or state.ClientAssembly~=central or not graph.IsCanonical()then return false end
        for _,ref in ipairs(refs)do local ok,value=pcall(resolve,ref.path);if not ok or value~=ref.module then return false end end
        return true
    end
    return create({owner=state,side='client',entries=entries,isCurrent=canonical},ports)
end
