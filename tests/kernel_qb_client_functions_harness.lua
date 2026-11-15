local V=dofile('tests/kernel_legacy_harness.lua');local H,P=V.H,V.P;local T={V=V,H=H,P=P,vector=V.vector}
function T.dialect(text)return P.lua54(text:gsub('([%w_]+)%?%.([%w_]+)','(%1 and %1.%2)'))end
function T.new(ported,build)
    local r=V.new(true,'client');r.state={PlayerData={citizenid='QB90',job={name='taxi'},money={cash=4}}}
    r.build=build or 3258;r.cache.playerId=17;r.trace={};r.progress=true;r.networked=true;r.cdImage=true
    local native=r.native
    -- Setters emit trace only; getters below supply explicit stateful fixture values.
    for _,name in ipairs(dofile('tests/kernel_qb_client_natives.lua'))do
        if not native[name]then native[name]=function(...)r.record(name,...);return nil end end
    end
    native.GetGameBuildNumber=function()r.record('build');return r.build end
    native.GetVehicleColours=function(...)r.record('colours',...);return 1,2 end
    native.GetVehicleExtraColours=function(...)r.record('extraColours',...);return 3,4 end
    native.GetVehicleWheelHealth=function(v,i)r.record('wheelHealth',v,i);return 100-i end
    native.IsVehicleWindowIntact=function(v,i)r.record('window',v,i);return i%2==0 end
    native.IsVehicleDoorDamaged=function(v,i)r.record('door',v,i);return r.doorBool and true or i%2 end
    native.GetVehicleHeadlightsColour=function(...)r.record('headlight',...);return 7 end
    native.NetworkGetEntityIsNetworked=function(...)r.record('networked',...);return r.networked end
    native.IsModelInCdimage=function(...)r.record('cdImage',...);return r.cdImage end
    native.SetVehicleHasBeenOwnedByPlayer=function(...)r.record('owned',...)end
    native.TaskWarpPedIntoVehicle=function(...)r.record('warp',...)end
    r.library.requestAnimDict=function(...)r.record('requestAnimDict',...);return true,'dict'end
    r.library.requestAnimSet=function(...)r.record('requestAnimSet',...);return true,'set'end
    r.library.progressBar=function(data)r.record('progressBar',data);if r.progressHook then r.progressHook()end;return r.progress end
    r.library.getVehicleProperties=function(vehicle)r.record('getProperties',vehicle);return r.props end
    r.library.print.verbose=function(...)r.record('verbose',...)end
    r.library.requestModel=function(...)r.record('requestModel',...);return true,'model'end
    local core={GetPlayerData=function()return r.state.PlayerData end,Notify=function(...)r.record('notify',...);return false,'ignored'end}
    r.ports={core=core,inventory={search=function(...)r.record('search',...);return r.searchResult end},native=native,
        library=r.library,cache=r.cache,helpers=r.helpers}
    local env=V.T.env();r.env=env
    if ported then r.api=H.load('kernel/compat/qb/client_functions.lua',env)(r.ports)
    else
        for name,fn in pairs(native)do env[name]=fn end
        env.QBX=r.state;env.qbx=r.helpers;env.lib=r.library;env.cache=r.cache
        env.exports={ox_inventory={Search=function(_,...)return r.ports.inventory.search(...)end},qbx_core={Notify=function(_,...)return core.Notify(...)end}}
        env.require=function(name)assert(name=='client.functions');return true end
        r.api=assert(load(T.dialect(P.source('bridge/qb/client/functions.lua')),'@installed_qb_client','t',env))()
    end
    assert(#r.trace==1 and r.trace[1].kind=='build','constructor must only read game-build metadata')
    r.trace={}
    function r.capture(fn,...)
        local result=table.pack(pcall(fn,...));if not result[1]then result[2]=tostring(result[2]):gsub('^.-:%d+: ','')end
        return P.snapshot(result)
    end
    return r
end
function T.compare(name,fn,build)
    local a,b=T.new(false,build),T.new(true,build)
    H.same(a.capture(fn,a),b.capture(fn,b),name..' returns/errors')
    H.same(a.trace,b.trace,name..' effects');H.same(P.snapshot(a.state),P.snapshot(b.state),name..' state')
    return a,b
end
return T
