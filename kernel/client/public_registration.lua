local create=require 'kernel.shared.public_registration'
return function(graph,ports)
    local state,central=assert(graph.Core),assert(graph.Central)
    assert(graph.State=='prepared-inactive'and state.ClientDomainAssembly==graph and graph.IsCanonical(),'canonical client50 required')
    local entries,refs={},{}
    local function resolve(path)local value=graph;for key in path:gmatch('[^.]+')do value=assert(value[key],path)end;return value end
    local function module(path)local value=resolve(path);refs[#refs+1]={path=path,value=value};return value end
    local session=module('Central.Parts.Producers.Session').Exports.GetCachedState
    local world=module('Parts.World.World').Exports.GetCachedState
    for _,path in ipairs({'Central.Parts.Runtime.Main','Central.Parts.Producers.Cache','Central.Parts.Producers.Session','Central.Parts.Producers.Status',
        'Central.Parts.Legacy.Groups','Central.Parts.Legacy.Functions','Parts.Skills','Parts.AutoMedic.Runtime','Parts.Work'})do
        local list=assert(module(path).Exports);local names={};for name in pairs(list)do names[#names+1]=name end;table.sort(names)
        for _,name in ipairs(names)do if name~='GetCachedState'then entries[#entries+1]={kind='export',name=name,owner=path,handler=list[name]}end end
    end
    entries[#entries+1]={kind='export',name='GetCachedState',owner='Session+World',handler=function(domain,...)
        if domain=='session'then return session(domain,...)end;return world(domain,...)
    end}
    for _,path in ipairs({'Parts.SkillMenus','Parts.Vinewood','Parts.Objects','Parts.Npcs'})do
        for _,d in ipairs(module(path).Commands)do
            local mode=d.mode or d.transport;if mode=='library'then mode='pr'end
            local names=type(d.name)=='table'and d.name or{d.name}
            for _,name in ipairs(names)do entries[#entries+1]={kind='command',name=name,owner=path,handler=d.handler,mode=mode,
                properties=d.options or d.properties,restricted=d.restricted}end
        end
    end
    for _,name in ipairs(graph.Order)do module('Parts.'..name)end
    local function canonical()
        if state.ClientDomainAssembly~=graph or state.ClientAssembly~=central or not graph.IsCanonical()then return false end
        for _,ref in ipairs(refs)do local ok,value=pcall(resolve,ref.path);if not ok or value~=ref.value then return false end end
        return true
    end
    return create({owner=state,side='client',entries=entries,isCurrent=canonical},ports)
end
