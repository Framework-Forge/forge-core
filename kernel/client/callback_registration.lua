local create=require 'kernel.shared.callback_registration'
return function(graph,providers)
    local state,central=assert(graph.Core),assert(graph.Central)
    assert(graph.State=='prepared-inactive'and state.ClientDomainAssembly==graph and graph.IsCanonical(),'canonical client50 required')
    local oxOwners={['Central.Main']=true,['Central.Status']=true,['Central.Events']=true}
    local owners={['Central.Main']='Central.Parts.Runtime.Main',['Central.Status']='Central.Parts.Producers.Status',['Central.Events']='Central.Parts.Runtime.Events',
        ['Central.Consumption']='Central.Parts.Consumption',['Jobs.Main']='Parts.Jobs.Main',Work='Parts.Work',Staff='Parts.Staff',Access='Parts.Access',
        SkillMenus='Parts.SkillMenus',Vehicles='Parts.Vehicles'}
    local function resolve(path)local v=graph;for key in path:gmatch('[^.]+')do v=assert(v[key],path)end;return v end
    local entries,refs={},{}
    for _,name in ipairs(graph.Order)do local path='Parts.'..name;refs[#refs+1]={path=path,value=resolve(path)}end
    for _,d in ipairs(graph.Callbacks)do
        local path=assert(owners[d.owner],'unclassified callback owner: '..d.owner)
        refs[#refs+1]={path=path,value=resolve(path)}
        entries[#entries+1]={name=d.name,handler=d.handler,owner=d.owner,
            protocol=oxOwners[d.owner]and'ox'or'native'}
    end
    local function canonical()
        if state.ClientDomainAssembly~=graph or state.ClientAssembly~=central or not graph.IsCanonical()then return false end
        for _,ref in ipairs(refs)do local ok,v=pcall(resolve,ref.path);if not ok or v~=ref.value then return false end end
        return true
    end
    return create({owner=state,side='client',entries=entries,isCurrent=canonical},providers)
end
