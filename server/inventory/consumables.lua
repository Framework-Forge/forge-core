ForgeCore = ForgeCore or {}

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

    TriggerClientEvent('forge-core:client:inventory:applyInteractionEffects', source, {
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
    local item = ForgeCore.InventoryService.getItem(itemData.name)
    local interaction = item and item.interaction
    if not item or item.active == false or type(interaction) ~= 'table' or interaction.enabled ~= true then return false end

    Service.busy[source] = true
    local duration = tonumber(interaction.duration)
    if duration == nil then duration = 5000 end
    local timeout = duration > 0 and math.max(5000, math.floor(duration + 5000)) or 5000
    local ok, response = pcall(function()
        return pr_lib.callback.awaitClient(source, 'forge-core:client:inventory:useInteraction', timeout, item.name, interaction)
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
            local removed = pr_lib.inventory.RemoveItem(source, item.name, removeCount, nil, itemData.slot)
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
    local item = ForgeCore.InventoryService.getItem(name)
    if not item or type(item.interaction) ~= 'table' then return end
    if pr_lib.inventory.RegisterUsableItem(name, itemUse, { cancelUse = true }) then
        Service.registered[name] = true
    end
end

function Service.refreshAll()
    local payload = ForgeCore.InventoryService.getPayload()
    for index = 1, #(payload.items or {}) do Service.refreshItem(payload.items[index].name) end
end

local function setStatus(source, key, value)
    source = tonumber(source)
    if not source then return false end
    TriggerClientEvent('qbx_core:client:setStatus', source, key, clamp(value, 0, 100))
    return true
end

local function addStatus(source, key, value)
    source = tonumber(source)
    if not source then return false end
    TriggerClientEvent('qbx_core:client:addStatus', source, key, tonumber(value) or 0)
    return true
end

RegisterNetEvent('consumables:server:setHunger', function(value)
    if not GetInvokingResource() then setStatus(source, 'hunger', value) end
end)
RegisterNetEvent('consumables:server:addHunger', function(value)
    local invoker = GetInvokingResource()
    if invoker == 'ox_inventory' then setStatus(source, 'hunger', value)
    elseif not invoker then addStatus(source, 'hunger', value) end
end)
RegisterNetEvent('consumables:server:setThirst', function(value)
    if not GetInvokingResource() then setStatus(source, 'thirst', value) end
end)
RegisterNetEvent('consumables:server:addThirst', function(value)
    local invoker = GetInvokingResource()
    if invoker == 'ox_inventory' then setStatus(source, 'thirst', value)
    elseif not invoker then addStatus(source, 'thirst', value) end
end)

exports('SetHunger', function(source, value) return setStatus(source, 'hunger', value) end)
exports('AddHunger', function(source, value) return addStatus(source, 'hunger', value) end)
exports('SetThirst', function(source, value) return setStatus(source, 'thirst', value) end)
exports('AddThirst', function(source, value) return addStatus(source, 'thirst', value) end)
exports('setHunger', function(source, value) return setStatus(source, 'hunger', value) end)
exports('addHunger', function(source, value) return addStatus(source, 'hunger', value) end)
exports('setThirst', function(source, value) return setStatus(source, 'thirst', value) end)
exports('addThirst', function(source, value) return addStatus(source, 'thirst', value) end)

local function registerSpecial(name, advanced)
    if not ForgeCore.InventoryService.getItem(name) then return end
    pr_lib.inventory.RegisterUsableItem(name, function(source)
        TriggerClientEvent('lockpicks:UseLockpick', source, advanced)
        TriggerEvent('lockpicks:UseLockpick', source, advanced)
        return false
    end, { cancelUse = true })
end

AddEventHandler('forge-core:server:inventory:reloaded', function() SetTimeout(0, Service.refreshAll) end)
AddEventHandler('playerDropped', function() Service.busy[source] = nil end)

ForgeCore.ConsumableService = Service
SetTimeout(0, function()
    Service.refreshAll()
    registerSpecial('lockpick', false)
    registerSpecial('advancedlockpick', true)
end)
