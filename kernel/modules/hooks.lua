-- Private QBX port; not loaded by the live manifest. See kernel/NOTICE-06.md.
return function(ports)
    assert(type(ports) == 'table', 'explicit support ports required')
    local GetInvokingResource = assert(ports.getInvokingResource, 'invoking-resource port required')
    local warn = assert(ports.warn, 'hook-warning port required')
    local checkDependency = assert(ports.checkDependency, 'dependency-check port required')
    local resource = assert(ports.resource, 'current resource required')
    assert(type(ports.microtime) == 'function', 'microtime port required')
-- Modified from original source https://github.com/overextended/ox_inventory/blob/main/modules/hooks/server.lua
-- Copyright (C) 2021  Linden <https://github.com/thelindat>, Dunak <https://github.com/dunak-debug>, Luke <https://github.com/LukeWasTakenn>

-- Legacy dependency check is explicit; never query another resource at construction.
local function checkDependencies()
    return assert(checkDependency('ox_lib', '3.8.0', true))
end

local eventHooks = {}
-- luacheck: ignore
local microtime = ports.microtime

local function triggerEventHooks(event, payload)
    local hooks = eventHooks[event]
    if not hooks then return true end

    for i = 1, #hooks do
        local hook = hooks[i]

        local start = microtime()
        local _, response = pcall(hooks[i], payload)
        local executionTime = microtime() - start

        if executionTime >= 100000 then
            warn(('Execution of event hook "%s:%s:%s" took %.2fms.'):format(hook.resource, event, i, executionTime / 1e3))
        end

        if response == false then
            return false
        end
    end

    return true
end

local hookId = 0

---Registers a callback function to be triggered by a resource. Returning false from the callback function cancels the event
---@param event string
---@param cb any
---@return integer hookId
local function registerHook(event, cb)
    if not eventHooks[event] then
        eventHooks[event] = {}
    end

    local mt = getmetatable(cb)
    mt.__index = nil
    mt.__newindex = nil
    cb.resource = GetInvokingResource()
    hookId = hookId + 1
    cb.hookId = hookId

    eventHooks[event][#eventHooks[event] + 1] = cb
    return hookId
end

local function removeResourceHooks(resource, id)
    for _, hooks in pairs(eventHooks) do
        for i = #hooks, 1, -1 do
            local hook = hooks[i]

            if hook.resource == resource and (not id or hook.hookId == id) then
                table.remove(hooks, i)
            end
        end
    end
end

local events = {{name = 'onResourceStop', handler = removeResourceHooks}}

---Remove a previously registered hook by its id
---@param id number hookId
local function removeHooks(id)
    removeResourceHooks(GetInvokingResource() or resource, id)
end

return {
    trigger = triggerEventHooks,
    registerHook = registerHook,
    removeHooks = removeHooks,
    CheckDependencies = checkDependencies,
    Events = events,
    Exports = {registerHook = registerHook, removeHooks = removeHooks},
}
end
