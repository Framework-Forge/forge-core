-- Private composition of installed QBX bridge/qb/server/main.lua. See NOTICE-89.md.
local createShared=require 'kernel.compat.qb.shared'
local createPlayer=require 'kernel.compat.qb.server_player'
local createFunctions=require 'kernel.compat.qb.server_functions'
local createCommands=require 'kernel.compat.qb.server_commands'
local createEvents=require 'kernel.compat.qb.server_events'
return function(backend,ports)
    local phase,pending='open',0
    local api={OperationalReady=false,Enabled=false,Events={},Exports={},ResourceExports={}}
    local function current()
        if phase~='open' then return false end
        local ok,value=pcall(ports.isCurrent);if not ok or value~=true then return false end
        return backend.IsCurrent()
    end
    local function invoke(fn,...)
        assert(current(),'qb_bridge_replaced')
        pending=pending+1;local args=table.pack(...)
        local result=table.pack(pcall(function()
            assert(ports.isReady()==true,'qb_bridge_unready')
            assert(current(),'qb_bridge_replaced')
            return fn(table.unpack(args,1,args.n))
        end));pending=pending-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    local function createExport(name,fn)
        assert(api.Exports[name]==nil,'duplicate QB descriptor: '..name)
        api.Exports[name]=function(...)return invoke(fn,...)end
    end
    local function resourceExport(name,fn)
        assert(api.ResourceExports[name]==nil,'duplicate resource descriptor: '..name)
        api.ResourceExports[name]=function(...)return invoke(fn,...)end
    end
    local function descriptor(name,fn,network,sourceFirst)
        api.Events[#api.Events+1]={name=name,network=network,sourceFirst=sourceFirst,handler=function(...)return invoke(fn,...)end}
    end
    local function network(name,fn)descriptor(name,fn,true,true)end
    local function listen(name,fn)descriptor(name,fn,false,false)end
    function api.IsCurrent()return current()end
    function api.Close()phase='closed';backend.Close();return true end
    function api.Progress()return{phase=phase,pending=pending,complete=phase=='closed'and pending==0}end
    assert(current(),'qb_bridge_replaced')
    if ports.native.GetConvar('qbx:enablebridge','true')=='false' then return api end
    assert(current(),'qb_bridge_replaced')
    api.Enabled=true
    local qbCoreCompat={}
    local p={core=backend.Core,state=backend.State,object=qbCoreCompat,lib=ports.lib,native=ports.native,
        helpers=backend.Helpers,inventory=ports.inventory,createExport=createExport,createResourceExport=resourceExport}
    qbCoreCompat.Config=ports.lib.table.merge(backend.Config.Server,backend.Config.Shared)
    qbCoreCompat.Shared=createShared({shared=backend.Shared,config=backend.Config.Shared,lib=ports.lib,helpers=backend.Helpers})
    qbCoreCompat.Shared.Jobs=backend.Core.GetJobs()
    qbCoreCompat.Shared.Gangs=backend.Core.GetGangs()
    qbCoreCompat.Players=backend.State.Players
    local player=createPlayer(p);qbCoreCompat.Player=player.Player;p.decorate=player.Decorate
    qbCoreCompat.Player_Buckets=backend.State.Player_Buckets
    qbCoreCompat.Entity_Buckets=backend.State.Entity_Buckets
    qbCoreCompat.UsableItems=backend.State.UsableItems
    qbCoreCompat.Functions=createFunctions(p)
    qbCoreCompat.Commands=createCommands(p)
    qbCoreCompat.Debug=ports.lib.print.debug
    qbCoreCompat.ShowError=ports.lib.print.error
    qbCoreCompat.ShowSuccess=ports.lib.print.info
    qbCoreCompat.ClientCallbacks={}
    qbCoreCompat.ServerCallbacks={}
    for _,d in ipairs(createEvents(p))do descriptor(d.name,d.handler,d.network,d.sourceFirst)end

-- Callback Events --

-- Client Callback
---@deprecated use https://coxdocs.dev/ox_lib/Modules/Callback/Lua/Server instead
network('QBCore:Server:TriggerClientCallback', function(source, name, ...)
    if qbCoreCompat.ClientCallbacks[name] then
        qbCoreCompat.ClientCallbacks[name](...)
        qbCoreCompat.ClientCallbacks[name] = nil
    end
end)

-- Server Callback
---@deprecated use https://coxdocs.dev/ox_lib/Modules/Callback/Lua/Server instead
network('QBCore:Server:TriggerCallback', function(source, name, ...)
    local src = source
    qbCoreCompat.Functions.TriggerCallback(name, src, function(...)
        ports.native.TriggerClientEvent('QBCore:Client:TriggerCallback', src, name, ...)
    end, ...)
end)

--- @deprecated
network('QBCore:CallCommand', function(source, command, args)
    local src = source --[[@as Source]]
    local player = backend.Core.GetPlayer(src)
    if not player then return end
    if ports.native.IsPlayerAceAllowed(src --[[@as string]], ('command.%s'):format(command)) then
        local commandString = command
        for _, value in pairs(args) do
            commandString = ('%s %s'):format(commandString, value)
        end
        ports.native.TriggerClientEvent('QBCore:Command:CallCommand', src, commandString)
    end
end)

-- Callback Functions --

-- Client Callback
---@deprecated use https://coxdocs.dev/ox_lib/Modules/Callback/Lua/Server instead
function qbCoreCompat.Functions.TriggerClientCallback(name, source, cb, ...)
    qbCoreCompat.ClientCallbacks[name] = cb
    ports.native.TriggerClientEvent('QBCore:Client:TriggerClientCallback', source, name, ...)
end

-- Server Callback
---@deprecated use https://coxdocs.dev/ox_lib/Modules/Callback/Lua/Server instead
function qbCoreCompat.Functions.CreateCallback(name, cb)
    qbCoreCompat.ServerCallbacks[name] = cb
end

---@deprecated call a function instead
function qbCoreCompat.Functions.TriggerCallback(name, source, cb, ...)
    if not qbCoreCompat.ServerCallbacks[name] then return end
    qbCoreCompat.ServerCallbacks[name](source, cb, ...)
end

---@deprecated call server function qbx.spawnVehicle from modules/lib.lua
qbCoreCompat.Functions.CreateCallback('QBCore:Server:SpawnVehicle', function(source, cb, model, coords, warp)
    local vehId = qbCoreCompat.Functions.SpawnVehicle(source, model, coords, warp)

    if vehId then cb(ports.native.NetworkGetNetworkIdFromEntity(vehId)) end
end)

---@deprecated call server function qbx.spawnVehicle from modules/lib.lua
qbCoreCompat.Functions.CreateCallback('QBCore:Server:CreateVehicle', function(source, cb, model, coords, warp)
    local vehId = qbCoreCompat.Functions.CreateVehicle(source, model, nil, coords, warp)

    if vehId then cb(ports.native.NetworkGetNetworkIdFromEntity(vehId)) end
end)

listen('qbx_core:server:onJobUpdate', function(jobName, job)
    qbCoreCompat.Shared.Jobs[jobName] = job
end)

listen('qbx_core:server:onGangUpdate', function(gangName, gang)
    qbCoreCompat.Shared.Gangs[gangName] = gang
end)

local createQbExport = createExport

createQbExport('GetCoreObject', function()
    return qbCoreCompat
end)


    api.GetCoreObject=api.Exports.GetCoreObject
    function api.InitializeLegacyItems()
        return invoke(function()return ports.convertItems(ports.inventoryItems,ports.legacyItems)end)
    end
    return api
end
