-- Bind only the documented platform/utility subsets. Other caller ports remain explicit.
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
local function branch(root,path)local out=root;for _,key in ipairs(path)do out[key]=copy(out[key]);out=out[key]end;return out end
local clientNames={'GetGameTimer','GetCurrentResourceName','GetEntityCoords','GetEntityHeading','PlayerPedId','PlayerId','GetPlayerServerId','GetResourceState',
    'joaat','Wait','CreateThread','SetTimeout','TriggerServerEvent','TriggerEvent','DoScreenFadeIn','DoScreenFadeOut','FreezeEntityPosition',
    'SetEntityCoords','SetEntityHeading','RequestCollisionAtCoord','ShutdownLoadingScreen','ShutdownLoadingScreenNui'}
local api={OperationalReady=false}
function api.Server(input,platform)
    assert(platform.Side=='server','server platform required');local root=copy(input)
    local life=branch(root,{'deliveryContext','mediaContext','supportContext','configurationContext','vehicleContext','bankingContext','operationsContext','inventoryContext','startup','lifecycle'})
    life.worker=copy(life.worker);life.worker.graph=copy(life.worker.graph);local g=life.worker.graph
    g.central=copy(g.central);g.central.session=copy(g.central.session);g.central.session.player=copy(g.central.session.player)
    local player=platform.Player();player.getIdentifiers=platform.Select({'GetPlayerIdentifiers'}).GetPlayerIdentifiers
    g.central.session.player.platform=player;return root
end
function api.Client(input,platform,utilities)
    assert(platform.Side=='client'and utilities.Library,'client platform/utilities required');local root=copy(input)
    local m=branch(root,{'runtimeContext','deliveryContext','configurationContext','mediaContext'})
    m.worker=copy(m.worker);local w=m.worker;w.central=copy(w.central);w.central.native=copy(w.central.native)
    local selected=platform.Select(clientNames);for key,value in pairs(selected)do w.central.native[key]=value end
    local function library(source)local out=copy(source);for key,value in pairs(utilities.Library)do out[key]=value end;return out end
    w.central.library=library(w.central.library);w.domains=copy(w.domains);w.domains.domains=copy(w.domains.domains)
    for name,part in pairs(w.domains.domains)do
        local out=copy(part)
        if out.library then out.library=library(out.library)end
        if out.native then out.native=copy(out.native);for key,value in pairs(selected)do if out.native[key]~=nil then out.native[key]=value end end end
        w.domains.domains[name]=out
    end
    return root
end
function api.DescribeClientNatives()local out={};for i,name in ipairs(clientNames)do out[i]=name end;return out end
return api
