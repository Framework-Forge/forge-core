local create=require 'kernel.shared.event_registration'
return function(graph,ports)
    local base,pc,central,security=assert(graph.Base),assert(graph.PlayerCore),assert(graph.Central),assert(graph.Security)
    assert(graph.State=='prepared-inactive'and base.DomainAssembly==graph and base.PlayerCore==pc,'canonical server48 required')
    local entries,refs={},{}
    local function resolve(path)local value=graph;for key in path:gmatch('[^.]+')do value=value[key];assert(value~=nil,path)end;return value end
    local function include(path,first,field,net)
        local module=resolve(path)
        if module==false then assert(path=='PlayerCore.Lifecycle.Queue','only queue may be disabled');refs[#refs+1]={path=path,module=false};return end
        assert(type(module)=='table','event owner required: '..path);refs[#refs+1]={path=path,module=module}
        for _,d in ipairs(module[field or'Events']or{})do
            local network=d.network;if net~=nil then network=net end
            local sourceFirst=d.sourceFirst;if sourceFirst==nil then sourceFirst=first==true end
            entries[#entries+1]={owner=path,name=d.name,handler=d.handler,network=network==true,sourceFirst=sourceFirst}
        end
    end
    for _,path in ipairs({'PlayerCore.State','PlayerCore.Players','PlayerCore.Lookup','PlayerCore.Storage','PlayerCore.Shared','PlayerCore.Groups',
        'PlayerCore.State.Players','PlayerCore.State.Status','PlayerCore.State.Session','PlayerCore.State.BridgeCache'})do
        refs[#refs+1]={path=path,module=resolve(path)}
    end
    -- Preserve installed QBX then Forge manifest-relative event order, not construction order.
    for _,path in ipairs({'PlayerCore.Runtime.Main','PlayerCore.Runtime.Weapons','PlayerCore.Producers.Cache',
        'PlayerCore.Producers.Session','PlayerCore.Producers.Status','PlayerCore.Lifecycle.Queue','PlayerCore.Lifecycle.Events',
        'PlayerCore.Characters.Character'})do include(path,true)end
    for _,path in ipairs({'Parts.World.World','Parts.AutoMedic.Session','Central.Parts.Transport.Security','Central.Parts.Jobs',
        'Central.Parts.Finance.Vip','Central.Parts.Weapons.Service','Central.Parts.Inventory.Service'})do include(path,false)end
    include('Central.Parts.Consumption.Service',true);include('Parts.CharacterAdmin',false);include('Parts.Vehicles',false)
    include('Parts.Skills.Boundary',false,'NetEvents',true);include('Parts.Skills.Boundary',false,'Listeners',false)
    for _,path in ipairs({'Parts.Access.Afk','Parts.Settings.Password','Parts.World.Density','Parts.Stores','Parts.Farms',
        'Parts.AutoMedic.Boundary','Parts.PlayerAdmin','Central.Parts.Transport.Compat'})do include(path,false)end
    -- Track canonical owners without collecting their aliases a second time.
    for _,name in ipairs({'MultiJob','Staff','Skills','AutoMedic','Access','Settings','World','Vehicles','Vinewood','Objects','Npcs',
        'Spotlights','Billboards','Stores','Farms','Starterpack','PlayerAdmin','CharacterAdmin'})do
        local path='Parts.'..name;refs[#refs+1]={path=path,module=resolve(path)}
    end
    local function canonical()
        if graph.State~='prepared-inactive'or central.State~='prepared-inactive'or base.DomainAssembly~=graph
            or base.ServerAssembly~=central or base.PlayerCore~=pc or base.Callbacks~=security or graph.Security~=security
            or pc.Groups~=base.Groups or pc.Shared~=base.Shared then return false end
        for _,ref in ipairs(refs)do local ok,value=pcall(resolve,ref.path);if not ok or value~=ref.module then return false end end
        return true
    end
    return create({owner=base,side='server',entries=entries,isCurrent=canonical},ports)
end
