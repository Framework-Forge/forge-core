local M=dofile('tests/kernel_client_media_harness.lua');local H=M.H;local T={M=M,H=H,path='../pr_bridge/bridge/delivery/forge_native_utilities.lua'}
function T.new()
    local r=M.provider();r.current=true;r.pools={};r.players={1,2,3};r.positions[1]=M.V.vector(0,0,0);r.positions[2]=M.V.vector(2,0,0);r.positions[3]=M.V.vector(1,0,0)
    r.native.GetActivePlayers=function()return r.players end;r.native.PlayerId=function()return 1 end;r.native.GetPlayerPed=function(id)return id end
    r.native.GetGamePool=function(name)return r.pools[name]or{}end;r.native.GetEntityModel=function()return 123 end
    r.native.FindFirstVehicle=function()r.vehicleIndex=1;return 100,(r.pools.CVehicle or{})[1]or 0 end
    r.native.FindNextVehicle=function()r.vehicleIndex=r.vehicleIndex+1;local id=(r.pools.CVehicle or{})[r.vehicleIndex];return id~=nil,id end
    r.native.EndFindVehicle=function()end
    r.native.GetVehicleNumberPlateText=function()return'V138'end
    local env=M.T.env(r.native);env.coroutine=coroutine;r.environment=env;r.loads={}
    r.ports138={environment=env,isCurrent=function()return r.current end,
        load=function(path,target)r.loads[#r.loads+1]=path;return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end}
    r.factory138=H.load(T.path,H.environment());function r.allocate()r.api138=r.factory138(r.ports138);return r.api138 end
    function r.original()
        local f=assert(io.open('../pr_bridge/init.lua','rb'));local source=f:read('*a');f:close()
        local first=assert(source:find('    public.getClosestVehicle = function',1,true));local last=assert(source:find('    if public.raycast then',first,true))
        local objects=H.load('../pr_bridge/bridge/fivem/objects/client.lua',env);env.public={fivem={objects=objects}}
        assert(load(source:sub(first,last-1),'@@queries-original138','t',env))();return env.public
    end
    return r
end
return T
