local create=require 'kernel.shared.callback_registration'
return function(graph,providers)
    local base,pc,central,security=assert(graph.Base),assert(graph.PlayerCore),assert(graph.Central),assert(graph.Security)
    assert(graph.State=='prepared-inactive'and base.DomainAssembly==graph and base.PlayerCore==pc,'canonical server48 required')
    local register,metadata=assert(security.register),assert(security.registrations)
    local capture=assert(providers.native.Capture,'native Security capture required')
    -- This must be the SAME explicit library port supplied to assembly48, before construction.
    local library=assert(providers.securityLibrary,'canonical Security library port required')
    local delivery=assert(library.callback)
    local captureRegister=assert(providers.native.CaptureRegister)
    assert(delivery.register==captureRegister,'owned delivery must be supplied before Security construction')
    local entries,refs={},{}
    local function resolve(path)local v=graph;for key in path:gmatch('[^.]+')do v=assert(v[key],path)end;return v end
    for _,path in ipairs({'PlayerCore.State','PlayerCore.Players','PlayerCore.Lookup','PlayerCore.Storage','PlayerCore.Shared','PlayerCore.Groups',
        'PlayerCore.State.Players','PlayerCore.State.Status','PlayerCore.State.Session','PlayerCore.State.BridgeCache',
        'Central.Parts.Transport','Central.Parts.Inventory','Central.Parts.Weapons','PlayerCore.Characters.Character'})do
        refs[#refs+1]={path=path,value=resolve(path)}
    end
    for _,name in ipairs(graph.Order)do local path='Parts.'..name;refs[#refs+1]={path=path,value=resolve(path)}end
    local function canonical()
        if graph.State~='prepared-inactive'or central.State~='prepared-inactive'or base.DomainAssembly~=graph
            or base.ServerAssembly~=central or base.PlayerCore~=pc or base.Callbacks~=security or graph.Security~=security
            or pc.Groups~=base.Groups or pc.Shared~=base.Shared or security.register~=register or security.registrations~=metadata
            or library.callback~=delivery or delivery.register~=captureRegister then return false end
        for _,ref in ipairs(refs)do local ok,v=pcall(resolve,ref.path);if not ok or v~=ref.value then return false end end
        return true
    end
    for _,d in ipairs(graph.Callbacks)do
        local name,handler,opts=d.name,d.handler,{}
        for key,value in pairs(d.options or{})do opts[key]=value end
        assert(metadata[name]==nil,'callback already compiled: '..name)
        entries[#entries+1]={name=name,owner='Security',handler=handler,protocol='native',prepare=function(fn)
            assert(metadata[name]==nil,'callback metadata collision: '..name)
            local ok,compiled=pcall(capture,name,function()register(name,fn,opts)end)
            local own=metadata[name]
            local function cleanup()if metadata[name]==own then metadata[name]=nil end end
            if not ok then cleanup();error(compiled,0)end
            return compiled,cleanup
        end}
    end
    local raw=assert(graph.RawCallbacks)
    local names={};for name in pairs(raw.Character)do names[#names+1]=name end;table.sort(names)
    for _,name in ipairs(names)do entries[#entries+1]={name=name,handler=raw.Character[name],owner='Character',protocol='ox'}end
    for _,d in ipairs(raw.World)do entries[#entries+1]={name=d.name,handler=d.handler,owner='World',protocol='native'}end
    return create({owner=base,side='server',entries=entries,isCurrent=canonical},providers)
end
