-- Inactive installed-QBX port; see NOTICE-11.md and LICENSE-QBX.
return function(ports)
    assert(type(ports) == 'table', 'explicit character ports required')
    local config = assert(ports.config, 'local server configuration required')
    local logger = assert(ports.logger, 'local logger required')
    local storage = assert(ports.storage, 'internal storage required')
    local starterItems = assert(ports.starterItems, 'local starter metadata definitions required')
    local documentItems = assert(ports.documentItems, 'document classifier required')
    local slots = assert(ports.slots, 'canonical slot policy required')
    local inventory = assert(ports.inventory, 'PR inventory integration required')
    local native = assert(ports.native, 'platform ports required')
    local library = assert(ports.library, 'library print ports required')
    local previewsReady = assert(ports.previewsReady, 'local preview readiness required')
    local getPreviews = assert(ports.getPreviews, 'normalized internal preview scene required')
    local login = assert(ports.login, 'internal Login required')
    local deleteCharacter = assert(ports.deleteCharacter, 'ownership checked delete required')
    local notify = assert(ports.notify, 'internal Notify required')
    local locale = assert(ports.locale, 'local translator required')
    local api = {Callbacks = {}, Events = {}}
    local function callback(name, handler) api.Callbacks[name] = handler end
    local function network(name, handler) api.Events[#api.Events + 1] = {name = name, handler = handler, network = true} end

---@param source Source
local function giveStarterItems(source)
    if native.GetResourceState('ox_inventory') == 'missing' then return end
    while not inventory.GetInventory(source) do
        native.Wait(100)
    end
    local configured = slots.getSettings().starterItems
    local documents = documentItems.get()
    local metadataByName = {}
    for _, item in ipairs(starterItems) do metadataByName[item.name] = item.metadata end
    for i = 1, #configured do
        local entry = configured[i]
        if not documents[entry.name] then
            local item = { name = entry.name, amount = entry.amount, metadata = metadataByName[entry.name] }
            if item.metadata and type(item.metadata) == 'function' then
                inventory.AddItem(source, item.name, item.amount, item.metadata(source))
            else
                inventory.AddItem(source, item.name, item.amount, item.metadata)
            end
        end
    end
end

local function characterPreviews()
    if not previewsReady() then return {} end
    local ok, locations = pcall(function() return getPreviews() end)
    if ok and type(locations) == 'table' then return locations end
    library.print.error(('Unable to load Forge character previews: %s'):format(tostring(locations)))
    return nil
end

callback('qbx_core:server:getCharacters', function(source)
    -- Deliver the Forge-owned scene with the selection response. A client no
    -- longer races world-cache hydration or polls an unpublished cache key.
    local previews = characterPreviews()
    local state, errorCode = slots.getState(source)
    if not state then
        library.print.error(('Unable to load character slots for source %s: %s'):format(source, errorCode))
        return {}, 1, { settings = slots.getSettings(), unlocked = { [1] = true }, previews = previews }
    end
    return state.characters, state.displaySlots, {
        settings = state.settings,
        unlocked = state.unlocked,
        blocked = state.blocked,
        previews = previews,
    }
end)

callback('qbx_core:server:getPreviewPedData', function(_, citizenId)
    local ped = storage.fetchPlayerSkin(citizenId)
    if not ped then return end

    return ped.skin, ped.model and native.joaat(ped.model)
end)

callback('qbx_core:server:loadCharacter', function(source, citizenId)
    local success, reason = login(source, citizenId)
    if not success then return false, reason or 'character_load_failed' end

    logger.log({
        source = 'qbx_core',
        webhook = config.logging.webhook['joinleave'],
        event = 'Loaded',
        color = 'green',
        message = ('**%s** (%s |  ||%s|| | %s | %s | %s) loaded'):format(native.GetPlayerName(source), native.GetPlayerIdentifierByType(source, 'discord') or 'undefined', native.GetPlayerIdentifierByType(source, 'ip') or 'undefined', native.GetPlayerIdentifierByType(source, 'license2') or native.GetPlayerIdentifierByType(source, 'license') or 'undefined', citizenId, source)
    })
    library.print.info(('%s (Citizen ID: %s ID: %s) has successfully loaded!'):format(native.GetPlayerName(source), citizenId, source))
    return true
end)

---@param data unknown
---@return table? newData
callback('qbx_core:server:createCharacter', function(source, data)
    if type(data) ~= 'table' then return nil, 'invalid_character_data' end
    local allowed, errorCode = slots.canCreate(source, data.cid, data)
    if not allowed then return nil, errorCode end

    local newData = { charinfo = {} }
    for key, value in pairs(data) do
        if key ~= 'termsAccepted' then newData.charinfo[key] = value end
    end

    local success = login(source, nil, newData)
    if not success then return nil, 'character_creation_failed' end

    slots.recordTermsAcceptance(source)
    giveStarterItems(source)

    library.print.info(('%s has created a character'):format(native.GetPlayerName(source)))
    return newData
end)

--- Deprecated. This event is kept for backward compatibility only and is no longer used internally.
network('qbx_core:server:deleteCharacter', function(source, citizenId)
    local src = source
    local deleted = deleteCharacter(src --[[@as number]], citizenId)
    notify(src, locale(deleted and 'success.character_deleted' or 'error.character_delete_failed'), deleted and 'success' or 'error')
end)

    return api
end

