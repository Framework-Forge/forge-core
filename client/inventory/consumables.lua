local alcoholCount = 0
local effectToken = 0
local persistentInteraction

local defaults = {
    food = { label = 'Comendo...', dict = 'mp_player_inteat@burger', anim = 'mp_player_int_eat_burger', model = 'prop_cs_burger_01', bone = 18905, pos = { x = 0.13, y = 0.05, z = 0.02 }, rot = { x = -50.0, y = 16.0, z = 60.0 } },
    drink = { label = 'Bebendo...', dict = 'mp_player_intdrink', anim = 'loop_bottle', model = 'prop_ld_flow_bottle', bone = 18905, pos = { x = 0.12, y = 0.008, z = 0.03 }, rot = { x = 240.0, y = -60.0, z = 0.0 } },
    alcohol = { label = 'Bebendo...', dict = 'mp_player_intdrink', anim = 'loop_bottle', model = 'prop_amb_beer_bottle', bone = 18905, pos = { x = 0.12, y = 0.008, z = 0.03 }, rot = { x = 240.0, y = -60.0, z = 0.0 } },
    narco = { label = 'Usando...', dict = 'mp_suicide', anim = 'pill' },
}

local function normalizeProps(props)
    local output = {}
    for index = 1, #(type(props) == 'table' and props or {}) do
        local prop = props[index]
        output[#output + 1] = {
            model = prop.model,
            bone = tonumber(prop.bone) or 57005,
            pos = prop.pos or {},
            rot = prop.rot or {},
            rotOrder = tonumber(prop.rotationOrder or prop.rotOrder) or 2,
        }
    end
    return output
end

local function resolveInteraction(interaction)
    local fallback = defaults[interaction.category] or defaults.food
    local animation = type(interaction.animation) == 'table' and interaction.animation or {}
    local props = normalizeProps(animation.props)
    if #props == 0 and fallback.model then
        props[1] = { model = fallback.model, bone = fallback.bone, pos = fallback.pos, rot = fallback.rot, rotOrder = 2 }
    end

    return {
        label = type(interaction.label) == 'string' and interaction.label ~= '' and interaction.label or fallback.label,
        dict = type(animation.dict) == 'string' and animation.dict ~= '' and animation.dict or fallback.dict,
        anim = type(animation.anim) == 'string' and animation.anim ~= '' and animation.anim or fallback.anim,
        flags = tonumber(animation.flags) or (animation.mode == 'full' and 1 or 49),
        props = props,
    }
end

local function removePersistentProps(props)
    for index = 1, #(props or {}) do
        local entity = props[index]
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            DetachEntity(entity, true, true)
            SetEntityAsMissionEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end
end

local function stopPersistentInteraction()
    local state = persistentInteraction
    if not state then return false end
    persistentInteraction = nil

    if state.ped and state.ped ~= 0 and DoesEntityExist(state.ped) and state.dict and state.anim then
        StopAnimTask(state.ped, state.dict, state.anim, 2.0)
    end
    removePersistentProps(state.entities)
    return true
end

local function playPersistentAnimation(state)
    if not state or not state.ped or state.ped == 0 or not DoesEntityExist(state.ped) then return false end
    if not state.dict or state.dict == '' or not state.anim or state.anim == '' then return false end

    local ok = pr_lib.playAnim({
        ped = state.ped,
        anim = {
            dict = state.dict,
            clip = state.anim,
            duration = -1,
            flags = state.flags,
            blendIn = 8.0,
            blendOut = -8.0,
            wait = false,
        },
    })
    return ok == true
end

local function createPersistentProps(ped, props)
    local entities = {}
    local coords = GetEntityCoords(ped)

    for index = 1, #props do
        local prop = props[index]
        if prop.model and prop.model ~= '' then
            local loaded, model = pr_lib.requestModel(prop.model, 5000)
            if loaded and model then
                local entity = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
                if entity and entity ~= 0 and DoesEntityExist(entity) then
                    local pos = prop.pos or {}
                    local rot = prop.rot or {}
                    SetEntityAsMissionEntity(entity, true, true)
                    AttachEntityToEntity(
                        entity,
                        ped,
                        GetPedBoneIndex(ped, tonumber(prop.bone) or 57005),
                        tonumber(pos.x or pos[1]) or 0.0,
                        tonumber(pos.y or pos[2]) or 0.0,
                        tonumber(pos.z or pos[3]) or 0.0,
                        tonumber(rot.x or rot[1]) or 0.0,
                        tonumber(rot.y or rot[2]) or 0.0,
                        tonumber(rot.z or rot[3]) or 0.0,
                        true,
                        true,
                        false,
                        true,
                        tonumber(prop.rotOrder) or 2,
                        true
                    )
                    entities[#entities + 1] = entity
                end
                SetModelAsNoLongerNeeded(model)
            end
        end
    end

    return entities
end

local function togglePersistentInteraction(itemName, interaction)
    itemName = tostring(itemName or ''):lower()
    if persistentInteraction and persistentInteraction.itemName == itemName then
        stopPersistentInteraction()
        return true, 'stopped'
    end

    stopPersistentInteraction()
    local resolved = resolveInteraction(interaction)
    local ped = PlayerPedId()
    if not ped or ped == 0 or IsEntityDead(ped) then return false, 'invalid_ped' end

    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
    local state = {
        itemName = itemName,
        ped = ped,
        dict = resolved.dict,
        anim = resolved.anim,
        flags = resolved.flags,
        canCancel = interaction.canCancel ~= false,
        entities = {},
    }
    if not playPersistentAnimation(state) then return false, 'animation_failed' end

    state.entities = createPersistentProps(ped, resolved.props)
    persistentInteraction = state
    return true, 'started'
end

pr_lib.callback.register('forge-core:client:inventory:useInteraction', function(itemName, interaction)
    if type(interaction) ~= 'table' or interaction.enabled ~= true then return false end
    local duration = tonumber(interaction.duration)
    if duration == nil then duration = 5000 end

    if duration <= 0 then
        local completed, action = togglePersistentInteraction(itemName, interaction)
        return { completed = completed == true, action = action }
    end

    stopPersistentInteraction()
    local resolved = resolveInteraction(interaction)
    local completed = pr_lib.progressBar({
        duration = duration,
        label = resolved.label,
        useWhileDead = false,
        canCancel = interaction.canCancel ~= false,
        disable = { combat = true },
        anim = {
            dict = resolved.dict,
            clip = resolved.anim,
            flag = resolved.flags,
        },
        prop = resolved.props,
    })
    if not completed and pr_lib.Notify then
        pr_lib.Notify({ title = 'Inventario', description = 'Uso cancelado.', type = 'error' })
    end
    return completed == true
end)

local persistentConfig = PR.Inventory.PersistentInteraction or {}
if pr_lib and pr_lib.addKeybind then
    pr_lib.addKeybind({
        name = 'forge_core_cancel_persistent_item',
        description = persistentConfig.cancelDescription or 'Cancelar interacao persistente de item',
        key = persistentConfig.cancelKey or 'H',
        keys = persistentConfig.cancelKey or 'H',
        defaultKey = persistentConfig.cancelKey or 'H',
        onPressed = function()
            if persistentInteraction and persistentInteraction.canCancel ~= false then
                stopPersistentInteraction()
            end
        end,
    })
end

CreateThread(function()
    while true do
        local state = persistentInteraction
        if not state then
            Wait(750)
        else
            Wait(math.max(100, tonumber(persistentConfig.reapplyInterval) or 500))
            if persistentInteraction == state then
                local ped = PlayerPedId()
                if ped ~= state.ped or not DoesEntityExist(ped) or IsEntityDead(ped) then
                    stopPersistentInteraction()
                elseif not IsEntityPlayingAnim(ped, state.dict, state.anim, 3) then
                    playPersistentAnimation(state)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then stopPersistentInteraction() end
end)
local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

local function stopEffectVisuals()
    AnimpostfxStop('DrugsTrevorClownsFightIn')
    AnimpostfxStop('DrugsMichaelAliensFightIn')
    AnimpostfxStop('DrugsDrivingIn')
end

local function startSpecialEffect(effect, durationMs, strength)
    effectToken = effectToken + 1
    local token = effectToken

    CreateThread(function()
        local player = PlayerId()
        local ped = PlayerPedId()
        local duration = math.floor(clamp(durationMs, 1000, 300000))
        local sprintMultiplier = 1.0

        SetRunSprintMultiplierForPlayer(player, 1.0)
        stopEffectVisuals()

        if effect == 'adrenaline' then
            sprintMultiplier = clamp(strength, 1.0, 1.49)
        elseif effect == 'meth' then
            AnimpostfxPlay('DrugsTrevorClownsFightIn', 3.0, false)
            sprintMultiplier = 1.35
        elseif effect == 'coke' or effect == 'crack' then
            AnimpostfxPlay('DrugsMichaelAliensFightIn', 3.0, false)
            sprintMultiplier = effect == 'crack' and 1.25 or 1.1
        elseif effect == 'ecstasy' then
            SetFlash(0, 0, 500, math.min(duration, 30000), 500)
        elseif effect == 'weed' then
            AnimpostfxPlay('DrugsDrivingIn', 3.0, false)
        else
            return
        end

        if sprintMultiplier > 1.0 then
            SetRunSprintMultiplierForPlayer(player, sprintMultiplier)
        end

        local expiresAt = GetGameTimer() + duration
        local nextCrackCheck = GetGameTimer() + 1000
        while token == effectToken and GetGameTimer() < expiresAt do
            Wait(250)
            RestorePlayerStamina(player, 1.0)

            if effect == 'crack' and GetGameTimer() >= nextCrackCheck then
                nextCrackCheck = GetGameTimer() + 1000
                if math.random(1, 100) <= 12 and IsPedRunning(ped) then
                    SetPedToRagdoll(ped, 1200, 1200, 3, false, false, false)
                end
            end
        end

        if token ~= effectToken then return end
        SetRunSprintMultiplierForPlayer(player, 1.0)
        stopEffectVisuals()
    end)
end

RegisterNetEvent('forge-core:client:inventory:applyInteractionEffects', function(data)
    data = type(data) == 'table' and data or {}
    if type(data.statuses) == 'table' then
        local ok = pcall(function() exports.qbx_core:AddStatuses(data.statuses) end)
        if not ok then TriggerEvent('qbx_core:client:applyStatusEffects', data.statuses) end
    end
    if (tonumber(data.alcohol) or 0) > 0 then
        alcoholCount = alcoholCount + tonumber(data.alcohol)
        TriggerEvent('evidence:client:SetStatus', alcoholCount >= 4 and 'heavyalcohol' or 'alcohol', 200)
    end
    local effect = tostring(data.effect or ''):lower()
    if effect == 'oxy' then
        ClearPedBloodDamage(PlayerPedId())
    elseif effect ~= '' then
        if effect ~= 'adrenaline' then
            TriggerEvent('evidence:client:SetStatus', effect == 'weed' and 'weedsmell' or 'widepupils', 300)
        end
        startSpecialEffect(effect, data.effectDuration, data.effectStrength)
    end
end)

CreateThread(function()
    while true do
        if alcoholCount > 0 then
            Wait(15 * 60 * 1000)
            alcoholCount = math.max(0, alcoholCount - 1)
        else
            Wait(5000)
        end
    end
end)
