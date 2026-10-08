ForgeCore = ForgeCore or {}

local Service = { busy = {}, registered = false, loaded = false, previews = {} }
local ITEM_NAME = (PR.CharacterSlots and PR.CharacterSlots.item) or 'new_slot'
local PREVIEW_FILE = (PR.CharacterSlots and PR.CharacterSlots.previewStorage) or 'data/character_previews.json'

local function finiteNumber(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end

local function animationCatalog()
    local catalog = {}
    for _, animation in ipairs(PR.CharacterSlots.previewAnimations or {}) do
        if type(animation) == 'table' and type(animation.id) == 'string' then catalog[animation.id] = animation end
    end
    return catalog
end

local function normalizePreview(data)
    if type(data) ~= 'table' then return nil end
    local x, y, z = finiteNumber(data.x), finiteNumber(data.y), finiteNumber(data.z)
    local heading = finiteNumber(data.heading or data.w)
    local animation = tostring(data.animation or 'stand')
    if not x or not y or not z or not heading or not animationCatalog()[animation] then return nil end
    return { x = x, y = y, z = z, heading = heading % 360.0, animation = animation }
end

local function publishPreviews()
    local catalog, public = animationCatalog(), {}
    for index, preview in ipairs(Service.previews) do
        local animation = catalog[preview.animation] or catalog.stand or {}
        public[index] = {
            x = preview.x, y = preview.y, z = preview.z, heading = preview.heading,
            animation = preview.animation,
            scenario = animation.scenario,
            animDict = animation.animDict,
            animName = animation.animName,
            animFlag = animation.flag,
        }
    end
    ForgeCore.State.publish('characterPreviews',public)
end

local function savePreviews(draft)
    local ok, result = pr_lib.saveJsonRecovery(PREVIEW_FILE, draft, { indent = true })
    if not ok then return false, result or 'save_failed' end
    Service.previews = draft
    publishPreviews()
    return true, Service.previews
end

local function loadPreviews()
    local loaded = pr_lib.loadJsonRecovery(PREVIEW_FILE, true)
    Service.previews = {}
    if type(loaded) == 'table' then
        for _, data in ipairs(loaded) do
            local preview = normalizePreview(data)
            if preview and #Service.previews < 50 then Service.previews[#Service.previews + 1] = preview end
        end
    end
    Service.loaded = true
    publishPreviews()
end

local function notify(source, description, kind)
    if source == 0 or not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end
    pr_lib.notify.NotifyPlayer(source, {
        title = 'Slots de personagem',
        description = description,
        type = kind or 'inform',
        position = PR.NotifyPos,
    })
end

local function qbxExport(name, ...)
    if GetResourceState('qbx_core') ~= 'started' then return false, 'qbx_unavailable' end
    local args = table.pack(...)
    local result = table.pack(pcall(function()
        local api = exports.qbx_core
        return api[name](api, table.unpack(args, 1, args.n))
    end))
    if not result[1] then
        print(('[forge-core:character-slots] qbx export %s failed: %s'):format(name, tostring(result[2])))
        return false, 'qbx_export_failed'
    end
    return table.unpack(result, 2, result.n)
end

local function ensureItem()
    if not ForgeCore.InventoryService or ForgeCore.InventoryService.getItem(ITEM_NAME) then return true end
    local ok, errorCode = ForgeCore.InventoryService.upsertItem(0, {
        name = ITEM_NAME,
        label = 'Novo slot de personagem',
        description = 'Libera um ou mais slots adicionais de personagem.',
        weight = 0,
        stack = true,
        close = true,
        active = true,
        access = { mode = 'free' },
    })
    if not ok then
        print(('[forge-core:character-slots] unable to create %s: %s'):format(ITEM_NAME, tostring(errorCode)))
    end
    return ok
end

local messages = {
    slot_item_disabled = 'A liberação de slots por item está desativada.',
    maximum_slots_reached = 'Você já atingiu o limite máximo de slots.',
    operation_in_progress = 'Aguarde: já existe uma liberação em andamento.',
    account_not_found = 'Não foi possível localizar sua conta.',
    item_remove_failed = 'Não foi possível consumir o item.',
    save_failed = 'Não foi possível gravar o novo slot.',
}

local function useItem(source, itemData)
    source = tonumber(source)
    if not source or Service.busy[source] then return false end
    Service.busy[source] = true

    local available, errorCode = qbxExport('CanUnlockCharacterSlots', source)
    if available ~= true then
        Service.busy[source] = nil
        notify(source, messages[errorCode] or ('Não foi possível liberar o slot: %s'):format(tostring(errorCode)), 'error')
        return false
    end

    local removed = pr_lib.inventory.RemoveItem(source, ITEM_NAME, 1, nil, itemData and itemData.slot)
    if not removed then
        Service.busy[source] = nil
        notify(source, messages.item_remove_failed, 'error')
        return false
    end

    local settings = Service.getSettings()
    local success, payload = qbxExport('UnlockCharacterSlots', source, settings and settings.slotsPerItem or 1)
    if success ~= true then
        local refunded = pr_lib.inventory.AddItem(source, ITEM_NAME, 1, nil, itemData and itemData.slot)
        Service.busy[source] = nil
        notify(source, (messages[payload] or messages.save_failed) .. (refunded and ' O item foi devolvido.' or ' Procure a administração para recuperar o item.'), 'error')
        return false
    end

    Service.busy[source] = nil
    local count = type(payload) == 'table' and tonumber(payload.count) or 1
    notify(source, ('%s slot(s) liberado(s) com sucesso.'):format(count or 1), 'success')
    return false
end

function Service.getSettings()
    local settings, errorCode = qbxExport('GetCharacterSlotSettings')
    if type(settings) ~= 'table' then return nil, errorCode or 'settings_unavailable' end
    return settings
end

function Service.getPreviews()
    return Service.previews
end

function Service.savePreview(index, data)
    local draft = pr_lib.jsonDraft(Service.previews, {})
    local preview = normalizePreview(data)
    if not preview then return false, 'invalid_preview' end
    index = tonumber(index)
    if index then
        index = math.floor(index)
        if not draft[index] then return false, 'preview_not_found' end
        draft[index] = preview
    else
        if #draft >= 50 then return false, 'preview_limit_reached' end
        draft[#draft + 1] = preview
    end
    return savePreviews(draft)
end

function Service.deletePreview(index)
    local draft = pr_lib.jsonDraft(Service.previews, {})
    index = math.floor(tonumber(index) or 0)
    if index < 1 or not draft[index] then return false, 'preview_not_found' end
    table.remove(draft, index)
    return savePreviews(draft)
end

function Service.saveSettings(settings)
    return qbxExport('SetCharacterSlotSettings', settings)
end

function Service.getPlayer(target)
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return false, 'invalid_player' end
    local state, errorCode = qbxExport('GetCharacterSlotState', target)
    if type(state) ~= 'table' then return false, errorCode or 'state_unavailable' end
    local occupied = {}
    for index = 1, #(state.characters or {}) do
        local character = state.characters[index]
        local slot = tonumber(character.charinfo and character.charinfo.cid) or index
        occupied[slot] = ('%s %s'):format(character.charinfo.firstname or '', character.charinfo.lastname or '')
    end
    local unlockedCount = 0
    for slot = 1, state.settings.maxSlots do
        if state.settings.requireItem ~= true or state.unlocked[slot] == true or state.unlocked[tostring(slot)] == true then
            unlockedCount = unlockedCount + 1
        end
    end
    return true, {
        settings = state.settings,
        unlocked = state.unlocked,
        occupied = occupied,
        blocked = state.blocked or {},
        unlockedCount = unlockedCount,
        maxSlots = state.displaySlots or state.settings.maxSlots,
    }
end

function Service.setPlayerSlot(target, slot, unlocked)
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return false, 'invalid_player' end
    return qbxExport('SetCharacterSlotUnlocked', target, slot, unlocked == true)
end

function Service.getOwnCharacters(source)
    local state, errorCode = qbxExport('GetCharacterSlotState', source)
    if type(state) ~= 'table' then return false, errorCode or 'state_unavailable' end
    local characters = {}
    for _, character in ipairs(state.characters or {}) do
        local slot = tonumber(character.charinfo and character.charinfo.cid)
        if slot and not state.blocked[slot] and not state.blocked[tostring(slot)] then
            characters[#characters + 1] = { citizenid = character.citizenid, slot = slot }
        end
    end
    return true, characters
end

local switching = {}
function Service.logout(source)
    if switching[source] then return false, 'operation_in_progress' end
    switching[source] = true
    local ok, success, reason = pcall(function()
        if not GetPlayerName(source) then return false, 'invalid_player' end
        local player = qbxExport('GetPlayer', source)
        if player == nil then
            TriggerClientEvent('qbx_core:client:playerLoggedOut', source)
            return true
        end
        if qbxExport('Logout', source) ~= true then return false, 'logout_failed' end
        return true
    end)
    switching[source] = nil
    if not ok then return false, 'logout_failed' end
    return success, reason
end

function Service.start()
    if not Service.loaded then loadPreviews() end
    ensureItem()
    if Service.registered then return end
    local registered = pr_lib.inventory.RegisterUsableItem(ITEM_NAME, useItem, { cancelUse = true })
    Service.registered = registered == true or registered == 1
    if not Service.registered then print(('[forge-core:character-slots] unable to register usable item %s'):format(ITEM_NAME)) end
end

AddEventHandler('forge-core:server:inventory:reloaded', function()
    SetTimeout(0, function()
        ensureItem()
        if not Service.registered then Service.start() end
    end)
end)
AddEventHandler('playerDropped', function() Service.busy[source] = nil end)

pr_lib.wrapJsonMutations(PREVIEW_FILE, Service, {
    'savePreview', 'deletePreview',
})

ForgeCore.CharacterSlotService = Service
