local M=dofile('tests/kernel_native_profile_harness.lua');local C=dofile('tests/kernel_native_client_rpc_harness.lua')
local P=dofile('tests/kernel_native_platform_harness.lua');local U=dofile('tests/kernel_native_utilities_harness.lua');local H=M.H
local T={M=M,C=C,P=P,U=U,H=H};T.bind=H.load('kernel/entry/native_graph_ports.lua',H.environment())
function T.server()
    local r=M.server();local c=r.profilePorts.bootstrap.context.deliveryContext.mediaContext.supportContext.configurationContext.vehicleContext.bankingContext.operationsContext.inventoryContext.startup.lifecycle.worker.graph.central
    local old=c.session.player.platform;local n=r.seedPorts.native
    n.GetPlayerIdentifiers=old.getIdentifiers
    for alias,name in pairs({getInvokingResource='GetInvokingResource',getPlayerName='GetPlayerName',getIdentifier='GetPlayerIdentifierByType',dropPlayer='DropPlayer',
        emitClient='TriggerClientEvent',emitServer='TriggerEvent',getPed='GetPlayerPed',setArmour='SetPedArmour',player='Player',entityExists='DoesEntityExist',getCoords='GetEntityCoords',getHeading='GetEntityHeading',vec4='vec4'})do
        if n[name]==nil then n[name]=old[alias]end
    end
    r.platform=H.load(P.path,H.environment())({execution=r.seed.Execution,side='server',events=r.events,isCurrent=function()return r.nativeCurrent end,time=old.time,locale=old.locale})
    r.original139=r.profilePorts.bootstrap.context;r.profilePorts.bootstrap.context=T.bind.Server(r.original139,r.platform)
    return r
end
function T.client()
    local r=C.new();local context=r.profilePorts.bootstrap.context;local c=context.runtimeContext.deliveryContext.configurationContext.mediaContext.worker.central
    local n=r.seedUnit.seedPorts.native
    for _,name in ipairs(T.bind.DescribeClientNatives())do if n[name]==nil then n[name]=assert(c.native[name],name)end end
    r.platform=H.load(P.path,H.environment())({execution=r.seed.Execution,side='client',events=r.events,isCurrent=function()return r.nativeCurrent end,time=function()return 101 end,locale=function(...)return ... end})
    local u=U.new();local load=u.ports138.load
    u.ports138.load=function(path,env)
        if path=='@pr_bridge/bridge/utils/tables'then return H.load('../pr_bridge/bridge/delivery/forge_native_tables.lua',env or u.environment)end
        return load(path,env)
    end
    r.utilityFixture=u;r.utilities=u.allocate()
    r.original139=context;r.profilePorts.bootstrap.context=T.bind.Client(context,r.platform,r.utilities)
    return r
end
return T
