-- Inactive complete consumption port; see NOTICE-20.md. No runtime installation on construction.
return function(ports)
    local services, library = assert(ports.services), assert(ports.library)
    local native, usable = assert(ports.native), assert(ports.usable)
    local integrations = assert(ports.integrations)
    local events, exported = {}, {}
    local function listen(name, handler) events[#events+1]={name=name,handler=handler,network=false} end
    local function network(name, handler) events[#events+1]={name=name,handler=handler,network=true} end
    local function describeExport(name, handler) exported[name]=handler end
local Service = { registered = {}, busy = {} }
local allowedEffects = { adrenaline = true, weed = true, coke = true, crack = true, ecstasy = true, oxy = true, meth = true }

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or 0))
end

local function randomRange(range)
    range = type(range) == 'table' and range or {}
    local minimum = math.floor(tonumber(range.min or range[1]) or 0)
    local maximum = math.floor(tonumber(range.max or range[2]) or minimum)
    if minimum > maximum then minimum, maximum = maximum, minimum end
    return math.random(minimum, maximum)
end

local function applyVitals(source, interaction)
    local effects = type(interaction.effects) == 'table' and interaction.effects or {}
    local statuses = {
        health = randomRange(effects.health),
        armor = randomRange(effects.armor),
        hunger = randomRange(effects.hunger),
        thirst = randomRange(effects.thirst),
        stress = randomRange(effects.stress),
        oxygen = randomRange(effects.oxygen),
    }

    native.emitClient('forge-core:client:inventory:applyInteractionEffects', source, {
        statuses = statuses,
        alcohol = tonumber(interaction.alcohol) or 0,
        effect = allowedEffects[interaction.effect] and interaction.effect or nil,
        effectDuration = math.floor(clamp(interaction.effectDuration or 12000, 1000, 300000)),
        effectStrength = clamp(interaction.effectStrength or 1.15, 1.0, 1.49),
    })
end

local function itemUse(source, itemData)
    source = tonumber(source)
    if not source or Service.busy[source] or type(itemData) ~= 'table' then return false end
    local item = services.InventoryService.getItem(itemData.name)
    local interaction = item and item.interaction
    if not item or item.active == false or type(interaction) ~= 'table' or interaction.enabled ~= true then return false end

    Service.busy[source] = true
    local duration = tonumber(interaction.duration)
    if duration == nil then duration = 5000 end
    local timeout = duration > 0 and math.max(5000, math.floor(duration + 5000)) or 5000
    local ok, response = pcall(function()
        return library.callback.awaitClient(source, 'forge-core:client:inventory:useInteraction', timeout, item.name, interaction)
    end)
    local completed = response == true or (type(response) == 'table' and response.completed == true)
    if not ok or not completed then
        Service.busy[source] = nil
        return false
    end

    local action = type(response) == 'table' and response.action or 'completed'
    if action == 'stopped' then
        Service.busy[source] = nil
        return false
    end

    local succeeded = pcall(function()
        local removeCount = math.max(0, math.floor(tonumber(interaction.remove) or 1))
        if removeCount > 0 then
            local removed = library.inventory.RemoveItem(source, item.name, removeCount, nil, itemData.slot)
            if not removed then error('item_remove_failed') end
        end

        applyVitals(source, interaction)
    end)
    Service.busy[source] = nil
    if not succeeded then return false end
    return false
end

function Service.refreshItem(name)
    name = tostring(name or ''):lower()
    if name == '' or Service.registered[name] then return end
    local item = services.InventoryService.getItem(name)
    if not item or type(item.interaction) ~= 'table' then return end
    if usable.RegisterUsableItem(name, itemUse, { cancelUse = true }) then
        Service.registered[name] = true
    end
end

function Service.refreshAll()
    local payload = services.InventoryService.getPayload()
    for index = 1, #(payload.items or {}) do Service.refreshItem(payload.items[index].name) end
end

local function setStatus(source, key, value)
    source = tonumber(source)
    if not source then return false end
    native.emitClient('qbx_core:client:setStatus', source, key, clamp(value, 0, 100))
    return true
end

local function addStatus(source, key, value)
    source = tonumber(source)
    if not source then return false end
    native.emitClient('qbx_core:client:addStatus', source, key, tonumber(value) or 0)
    return true
end

network('consumables:server:setHunger', function(eventSource, value)
    if not native.getInvokingResource() then setStatus(eventSource, 'hunger', value) end
end)
network('consumables:server:addHunger', function(eventSource, value)
    local invoker = native.getInvokingResource()
    if invoker == 'ox_inventory' then setStatus(eventSource, 'hunger', value)
    elseif not invoker then addStatus(eventSource, 'hunger', value) end
end)
network('consumables:server:setThirst', function(eventSource, value)
    if not native.getInvokingResource() then setStatus(eventSource, 'thirst', value) end
end)
network('consumables:server:addThirst', function(eventSource, value)
    local invoker = native.getInvokingResource()
    if invoker == 'ox_inventory' then setStatus(eventSource, 'thirst', value)
    elseif not invoker then addStatus(eventSource, 'thirst', value) end
end)

describeExport('SetHunger', function(source, value) return setStatus(source, 'hunger', value) end)
describeExport('AddHunger', function(source, value) return addStatus(source, 'hunger', value) end)
describeExport('SetThirst', function(source, value) return setStatus(source, 'thirst', value) end)
describeExport('AddThirst', function(source, value) return addStatus(source, 'thirst', value) end)
describeExport('setHunger', function(source, value) return setStatus(source, 'hunger', value) end)
describeExport('addHunger', function(source, value) return addStatus(source, 'hunger', value) end)
describeExport('setThirst', function(source, value) return setStatus(source, 'thirst', value) end)
describeExport('addThirst', function(source, value) return addStatus(source, 'thirst', value) end)

local function registerSpecial(name, advanced)
    if not services.InventoryService.getItem(name) then return end
    usable.RegisterUsableItem(name, function(source)
        integrations.useLockpick(source, advanced)
        return false
    end, { cancelUse = true })
end

listen('forge-core:server:inventory:reloaded', function() native.setTimeout(0, Service.refreshAll) end)
listen('playerDropped', function(eventSource) Service.busy[eventSource] = nil end)

    Service.Events, Service.Exports = events, exported
    local initialized = false
    function Service.Initialize()
        if initialized then return false end
        initialized = true
native.setTimeout(0, function()
    Service.refreshAll()
    registerSpecial('lockpick', false)
    registerSpecial('advancedlockpick', true)
end)
        return true
    end
    return Service
end
