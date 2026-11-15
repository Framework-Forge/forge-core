local E=dofile('tests/kernel_native_execution_harness.lua');local H=E.H;local T={E=E,H=H,path='../pr_bridge/bridge/delivery/forge_native_platform.lua'}
function T.new(side)
    local r=E.new(side);r.effects={};local n=r.native
    for _,name in ipairs({'GetInvokingResource','GetPlayerName','GetPlayerIdentifierByType','DropPlayer','TriggerClientEvent','TriggerServerEvent','TriggerEvent',
        'GetPlayerPed','SetPedArmour','Player','DoesEntityExist','GetEntityCoords','GetEntityHeading','vec4','SetPlayerRoutingBucket','SetEntityRoutingBucket','GetResourceMetadata','ExecuteCommand'})do
        n[name]=function(...)r.effects[#r.effects+1]={name,...};return name,nil,false,7 end
    end
    r.events.listen=function(...)r.effects[#r.effects+1]={'owned-listen',...};return'token'end
    r.allocate();r.ports137={execution=r.api,side=r.side,events=r.events,isCurrent=function()return r.current end,time=function()return 101 end,locale=function(...)return ... end}
    r.factory137=H.load(T.path,H.environment());function r.mount()r.platform=r.factory137(r.ports137);return r.platform end
    function r.finish()if r.platform then r.platform.Close()end;r.api.Close()end;return r
end
return T
