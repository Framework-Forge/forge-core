-- Private port/composition of installed QBX bridge/qb/client/main.lua; see NOTICE-92.md.
local createShared=require 'kernel.compat.qb.shared'
local createFunctions=require 'kernel.compat.qb.client_functions'
local createDrawtext=require 'kernel.compat.qb.client_drawtext'
local createEvents=require 'kernel.compat.qb.client_events'
return function(backend,ports)
    local phase,pending,tasks='open',0,0
    local uncertain=false
    local api={OperationalReady=false,Enabled=false,Events={},Exports={}}
    local function current()
        if phase~='open'then return false end
        local ok,value=pcall(ports.isCurrent);if not ok or value~=true then return false end
        return backend.IsCurrent()
    end
    local function invoke(fn,...)
        assert(current(),'qb_client_bridge_replaced')
        pending=pending+1;local args=table.pack(...)
        local result=table.pack(pcall(function()
            assert(ports.isReady()==true,'qb_client_bridge_unready');assert(current(),'qb_client_bridge_replaced')
            return fn(table.unpack(args,1,args.n))
        end));pending=pending-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    local function createExport(name,fn)
        assert(api.Exports[name]==nil,'duplicate QB client export: '..name)
        api.Exports[name]=function(...)return invoke(fn,...)end
    end
    local function network(name,fn)api.Events[#api.Events+1]={name=name,network=true,handler=function(...)return invoke(fn,...)end}end
    local scheduler={}
    function scheduler.createThread(fn)
        assert(current(),'qb_client_bridge_replaced');tasks=tasks+1
        local complete=false
        local result=table.pack(pcall(ports.scheduler.createThread,function(...)
            if complete then return end
            local returned=table.pack(pcall(fn,...));complete=true;tasks=tasks-1
            if not returned[1]then error(returned[2],0)end;return table.unpack(returned,2,returned.n)
        end))
        if not result[1]then
            -- A provider may enqueue then throw; without a receipt we cannot claim the task was never published.
            if not complete then uncertain=true end
            error(result[2],0)
        end
        return table.unpack(result,2,result.n)
    end
    function api.IsCurrent()return current()end
    function api.Close()phase='closed';backend.Close();return true end
    function api.Progress()
        local b=backend.Progress()
        return{phase=phase,pending=pending,tasks=tasks,uncertainPublication=uncertain,
            complete=phase=='closed'and pending==0 and tasks==0 and b.complete}
    end
    assert(current(),'qb_client_bridge_replaced')
    if ports.native.GetConvar('qbx:enablebridge','true')=='false'then return api end
    assert(current(),'qb_client_bridge_replaced')
    api.Enabled=true
    scheduler.wait=ports.scheduler.wait
    local p={core=backend.Core,helpers=backend.Helpers,cache=backend.NativeCache,library=ports.library,native=ports.native,
        inventory=ports.inventory,scheduler=scheduler,config=backend.Config.Client}
    local ui=createDrawtext(p)
    for name,fn in pairs(ui.Exports)do createExport(name,fn)end
    for _,d in ipairs(ui.Events)do network(d.name,d.handler)end
    for _,d in ipairs(createEvents(p))do network(d.name,d.handler)end
    local qbCoreCompat={}
    qbCoreCompat.PlayerData=backend.Core.GetPlayerData()
    qbCoreCompat.Config=ports.library.table.merge(backend.Config.Client,backend.Config.Shared)
    qbCoreCompat.Shared=createShared({shared=backend.Shared,config=backend.Config.Shared,lib=ports.library,helpers=backend.Helpers})
    qbCoreCompat.Shared.Jobs=backend.Core.GetJobs()
    qbCoreCompat.Shared.Gangs=backend.Core.GetGangs()
    qbCoreCompat.Functions=createFunctions(p)
    qbCoreCompat.ClientCallbacks={}
    qbCoreCompat.ServerCallbacks={}

-- Callback Events --

-- Client Callback
---@deprecated call a function instead
network('QBCore:Client:TriggerClientCallback', function(name, ...)
    qbCoreCompat.Functions.TriggerClientCallback(name, function(...)
        ports.native.TriggerServerEvent('QBCore:Server:TriggerClientCallback', name, ...)
    end, ...)
end)

-- Server Callback
---@deprecated use https://coxdocs.dev/ox_lib/Modules/Callback/Lua/Client instead
network('QBCore:Client:TriggerCallback', function(name, ...)
    if qbCoreCompat.ServerCallbacks[name] then
        qbCoreCompat.ServerCallbacks[name](...)
        qbCoreCompat.ServerCallbacks[name] = nil
    end
end)

-- Callback Functions --

-- Client Callback
---@deprecated use https://coxdocs.dev/ox_lib/Modules/Callback/Lua/Client instead
function qbCoreCompat.Functions.CreateClientCallback(name, cb)
    qbCoreCompat.ClientCallbacks[name] = cb
end

---@deprecated call a function instead
function qbCoreCompat.Functions.TriggerClientCallback(name, cb, ...)
    if not qbCoreCompat.ClientCallbacks[name] then return end
    qbCoreCompat.ClientCallbacks[name](cb, ...)
end

-- Server Callback
---@deprecated use https://coxdocs.dev/ox_lib/Modules/Callback/Lua/Client instead
function qbCoreCompat.Functions.TriggerCallback(name, cb, ...)
    qbCoreCompat.ServerCallbacks[name] = cb
    ports.native.TriggerServerEvent('QBCore:Server:TriggerCallback', name, ...)
end

---@deprecated Use ports.library.print.debug()
---@param obj any
function qbCoreCompat.Debug(_, obj)
    ports.library.print.debug(obj)
end

local createQbExport = createExport

createQbExport('GetCoreObject', function()
    return qbCoreCompat
end)

network('qbx_core:client:onJobUpdate', function(jobName, job)
    qbCoreCompat.Shared.Jobs[jobName] = job
end)

network('qbx_core:client:onGangUpdate', function(gangName, gang)
    qbCoreCompat.Shared.Gangs[gangName] = gang
end)

api.GetCoreObject=api.Exports.GetCoreObject
return api
end
