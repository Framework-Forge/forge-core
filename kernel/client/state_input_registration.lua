local create=require 'kernel.shared.state_input_registration'
return function(graph,ports)
    local state,central=assert(graph.Core),assert(graph.Central)
    assert(graph.State=='prepared-inactive'and state.ClientDomainAssembly==graph and graph.IsCanonical(),'canonical client50 required')
    local refs={}
    local function resolve(path)local v=graph;for k in path:gmatch('[^.]+')do v=assert(v[k],path)end;return v end
    local function remember(path)local v=resolve(path);refs[#refs+1]={path=path,value=v};return v end
    local bags,keys={},{}
    -- Descriptor identity/value checks are independent of registration copies.
    local snapshots={}
    local function copy(value)
        if type(value)~='table'then return value end
        local out={};for k,v in pairs(value)do out[k]=copy(v)end;return out
    end
    local function equal(a,b)
        if type(a)~='table'or type(b)~='table'then return a==b end
        for k,v in pairs(a)do if not equal(v,b[k])then return false end end
        for k in pairs(b)do if a[k]==nil then return false end end;return true
    end
    local function capture(list)
        local entries={};for i,d in ipairs(list)do entries[i]={value=d,fields=copy(d)}end;return entries
    end
    local function snapshot(list)
        local s={list=list,entries=capture(list)};snapshots[#snapshots+1]=s;return s
    end
    local function collect(path,field,entity,target)
        remember(path)
        local list=remember(path..'.'..field);snapshot(list)
        for _,d in ipairs(list)do
            local out={};for k,v in pairs(d)do out[k]=v end
            if entity then out.entity=true end;out.owner=path;target[#target+1]=out
        end
    end
    collect('Central.Parts.Runtime.Events','StateBags',false,bags)
    collect('Central.Parts.Runtime.Events','EntityStateHandlers',true,bags)
    collect('Central.Parts.Runtime.Discord','StateBags',false,bags)
    collect('Central.Parts.Consumption','Keybinds',false,keys)
    collect('Parts.Work','Keybinds',false,keys)
    local hospital=remember('Parts.AutoMedic.Hospital')
    local initialize=remember('Parts.AutoMedic.Hospital.Initialize')
    local late=remember('Parts.AutoMedic.Hospital.Keybinds')
    local lateSnapshot=snapshot(late)
    local lib=remember('Central.Parts.Helpers.Lib')
    local entityResolver=remember('Central.Parts.Helpers.Lib.getEntityAndNetIdFromBagName')
    assert(ports.resolveEntity==entityResolver,'same canonical Lib resolver required')
    local function canonical()
        if state.ClientDomainAssembly~=graph or state.ClientAssembly~=central or not graph.IsCanonical()then return false end
        for _,ref in ipairs(refs)do local ok,v=pcall(resolve,ref.path);if not ok or v~=ref.value then return false end end
        for _,s in ipairs(snapshots)do
            if #s.list~=#s.entries then return false end
            for i,d in ipairs(s.entries)do if s.list[i]~=d.value or not equal(d.value,d.fields)then return false end end
        end
        return true
    end
    local function prepare()
        assert(canonical(),'client replaced before hospital descriptor preparation')
        initialize() -- Audited description-only initializer; never the parent AutoMedic/Session initializer.
        assert(hospital.Keybinds==late and lib.getEntityAndNetIdFromBagName==entityResolver,'late descriptor owner replaced')
        lateSnapshot.entries=capture(late)
        local result={};for _,d in ipairs(late)do
            local out={};for k,v in pairs(d)do out[k]=v end;out.owner='Parts.AutoMedic.Hospital';result[#result+1]=out
        end
        return result
    end
    return create({owner=state,bags=bags,keys=keys,prepare=prepare,isCurrent=canonical},ports)
end
