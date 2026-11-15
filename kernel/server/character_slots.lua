-- Inactive installed-QBX port; see NOTICE-11.md and LICENSE-QBX.
return function(ports)
    assert(type(ports) == 'table', 'explicit slot ports required')
    local config = assert(ports.config, 'local server configuration required')
    local storage = assert(ports.storage, 'internal storage required')
    local Service = assert(ports.service, 'stable slot policy service required')
    local starterItems = assert(ports.starterItems, 'local starter items required')
    local db = assert(ports.db, 'explicit database ports required')
    local json = assert(ports.json, 'codec port required')
    local calendar = assert(ports.calendar, 'calendar ports required')
    local native = assert(ports.native, 'platform ports required')
    local getPlayer = assert(ports.getPlayer, 'internal player lookup required')
    local logout = assert(ports.logout, 'internal logout required')
    local api = {Service = Service, Exports = {}, Ready = {}}
    local function describeExport(name, handler) api.Exports[name] = handler end
local initialized, settingsCache = false, nil
local accountLocks = {}

local defaults = {
    maxSlots = math.max(1, math.floor(tonumber(config.characters.defaultNumberOfCharacters) or 1)),
    requireItem = true,
    slotsPerItem = 1,
    loseSlotOnDelete = true,
    firstNamePlaceholder = 'Hank',
    lastNamePlaceholder = 'Jordan',
    minimumAgeEnabled = true,
    minimumAge = 18,
    termsEnabled = true,
    termsTitle = 'Termos de uso e responsabilidade',
    termsText = 'Declaro que tenho a idade minima exigida e aceito os termos de uso e responsabilidade do servidor.',
    termsVersion = '1.0',
}

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end
    value = tostring(value):lower()
    return value == 'true' or value == '1' or value == 'yes' or value == 'sim'
end

local function trim(value)
    return (tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function normalizeStarterItems(items)
    if type(items) ~= 'table' then items = starterItems end
    local result, seen = {}, {}
    for _, item in ipairs(items) do
        if type(item) == 'table' and type(item.name) == 'string' and not seen[item.name] then
            local amount = tonumber(item.amount)
            if amount and amount == amount and amount >= 1 and amount < math.huge then
                seen[item.name] = true
                result[#result + 1] = { name = item.name, amount = math.min(1000000, math.floor(amount)) }
            end
        end
    end
    return result
end

local function normalizeSettings(value)
    value = type(value) == 'table' and value or {}
    local maxSlots = math.max(1, math.min(50, math.floor(tonumber(value.maxSlots) or defaults.maxSlots)))
    return {
        maxSlots = maxSlots,
        starterItems = normalizeStarterItems(value.starterItems),
        requireItem = boolValue(value.requireItem, defaults.requireItem),
        slotsPerItem = math.max(1, math.min(maxSlots, math.floor(tonumber(value.slotsPerItem) or defaults.slotsPerItem))),
        loseSlotOnDelete = boolValue(value.loseSlotOnDelete, defaults.loseSlotOnDelete),
        firstNamePlaceholder = trim(value.firstNamePlaceholder) ~= '' and trim(value.firstNamePlaceholder):sub(1, 50) or defaults.firstNamePlaceholder,
        lastNamePlaceholder = trim(value.lastNamePlaceholder) ~= '' and trim(value.lastNamePlaceholder):sub(1, 50) or defaults.lastNamePlaceholder,
        minimumAgeEnabled = boolValue(value.minimumAgeEnabled, defaults.minimumAgeEnabled),
        minimumAge = math.max(1, math.min(100, math.floor(tonumber(value.minimumAge) or defaults.minimumAge))),
        termsEnabled = boolValue(value.termsEnabled, defaults.termsEnabled),
        termsTitle = trim(value.termsTitle) ~= '' and trim(value.termsTitle):sub(1, 120) or defaults.termsTitle,
        termsText = trim(value.termsText) ~= '' and trim(value.termsText):sub(1, 8000) or defaults.termsText,
        termsVersion = trim(value.termsVersion) ~= '' and trim(value.termsVersion):sub(1, 40) or defaults.termsVersion,
    }
end

local function ensureTables()
    if initialized then return true end
    db.query.await([[CREATE TABLE IF NOT EXISTS `qbx_character_slot_settings` (
        `id` tinyint UNSIGNED NOT NULL DEFAULT 1, `settings` longtext NOT NULL,
        `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
    db.query.await([[CREATE TABLE IF NOT EXISTS `qbx_character_slots` (
        `user_id` int UNSIGNED NOT NULL, `slot_id` tinyint UNSIGNED NOT NULL,
        `acquired_at` timestamp NOT NULL DEFAULT current_timestamp(),
        PRIMARY KEY (`user_id`, `slot_id`), KEY `idx_qbx_character_slots_user` (`user_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
    db.query.await([[CREATE TABLE IF NOT EXISTS `qbx_character_slot_blocks` (
        `user_id` int UNSIGNED NOT NULL, `slot_id` tinyint UNSIGNED NOT NULL,
        `blocked_at` timestamp NOT NULL DEFAULT current_timestamp(),
        PRIMARY KEY (`user_id`, `slot_id`), KEY `idx_qbx_character_slot_blocks_user` (`user_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
    db.query.await([[CREATE TABLE IF NOT EXISTS `qbx_character_terms_acceptance` (
        `user_id` int UNSIGNED NOT NULL, `terms_version` varchar(40) NOT NULL,
        `accepted_at` timestamp NOT NULL DEFAULT current_timestamp(),
        PRIMARY KEY (`user_id`, `terms_version`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
    initialized = true
    return true
end

local function getSettings()
    ensureTables()
    if settingsCache then return settingsCache end
    local encoded = db.scalar.await('SELECT settings FROM qbx_character_slot_settings WHERE id = 1')
    local decoded
    if type(encoded) == 'string' and encoded ~= '' then
        local ok, value = pcall(json.decode, encoded)
        if ok then decoded = value end
    end
    settingsCache = normalizeSettings(decoded or defaults)
    return settingsCache
end

local function getUserId(source)
    local license2 = native.GetPlayerIdentifierByType(source, 'license2')
    local license = native.GetPlayerIdentifierByType(source, 'license')
    return license2 and storage.fetchUserByIdentifier(license2) or license and storage.fetchUserByIdentifier(license)
end

local function getCharacters(source)
    return storage.fetchAllPlayerEntities(
        native.GetPlayerIdentifierByType(source, 'license2'),
        native.GetPlayerIdentifierByType(source, 'license')
    )
end

local function purchasedSlots(userId)
    local rows = db.query.await('SELECT slot_id FROM qbx_character_slots WHERE user_id = ?', { userId }) or {}
    local unlocked = { [1] = true }
    for i = 1, #rows do unlocked[tonumber(rows[i].slot_id)] = true end
    return unlocked
end

local function blockedSlots(userId)
    local rows = db.query.await('SELECT slot_id FROM qbx_character_slot_blocks WHERE user_id = ?', { userId }) or {}
    local blocked = {}
    for i = 1, #rows do blocked[tonumber(rows[i].slot_id)] = true end
    return blocked
end

local function highestCharacterSlot(characters)
    local highest = 1
    for index = 1, #(characters or {}) do
        local cid = tonumber(characters[index].charinfo and characters[index].charinfo.cid) or index
        if cid > highest then highest = cid end
    end
    return highest
end

local function validDate(year, month, day)
    if not year or not month or not day or month < 1 or month > 12 or day < 1 or day > 31 then return false end
    local stamp = calendar.time({ year = year, month = month, day = day, hour = 12 })
    if not stamp then return false end
    local normalized = calendar.date('*t', stamp)
    return normalized.year == year and normalized.month == month and normalized.day == day
end

function Service.getSettings()
    return normalizeSettings(getSettings())
end

function Service.saveSettings(value)
    local settings = normalizeSettings(value)
    ensureTables()
    local result = db.update.await([[INSERT INTO qbx_character_slot_settings (id, settings) VALUES (1, ?)
        ON DUPLICATE KEY UPDATE settings = VALUES(settings)]], { json.encode(settings) })
    if result == nil then return false, 'save_failed' end
    settingsCache = settings
    return true, Service.getSettings()
end

function Service.getState(source)
    source = tonumber(source)
    if not source then return nil, 'invalid_player' end
    local userId = getUserId(source)
    if not userId then return nil, 'account_not_found' end
    local settings, characters = getSettings(), getCharacters(source)
    local unlocked = settings.requireItem and purchasedSlots(userId) or {}
    if settings.requireItem then
        for index = 1, #(characters or {}) do
            local occupiedSlot = tonumber(characters[index].charinfo and characters[index].charinfo.cid) or index
            if occupiedSlot > 1 and unlocked[occupiedSlot] ~= true then
                db.insert.await('INSERT IGNORE INTO qbx_character_slots (user_id, slot_id) VALUES (?, ?)', { userId, occupiedSlot })
                unlocked[occupiedSlot] = true
            end
        end
    end
    if not settings.requireItem then
        for slot = 1, settings.maxSlots do unlocked[slot] = true end
    end
    local blocked = blockedSlots(userId)
    -- Entitlement and administrative suspension are independent.
    unlocked[1] = true
    local publicSettings = Service.getSettings()
    if publicSettings.minimumAgeEnabled then
        local cutoff = calendar.date('*t')
        cutoff.year = cutoff.year - publicSettings.minimumAge
        publicSettings.birthdateMax = calendar.date('%Y-%m-%d', calendar.time(cutoff))
    end
    return {
        userId = userId,
        settings = publicSettings,
        unlocked = unlocked,
        blocked = blocked,
        displaySlots = math.max(settings.maxSlots, highestCharacterSlot(characters)),
        characters = characters,
    }
end

function Service.validateAge(birthdate)
    local settings = getSettings()
    if not settings.minimumAgeEnabled then return true end
    local a, b, c = tostring(birthdate or ''):match('^(%d+)%D(%d+)%D(%d+)$')
    a, b, c = tonumber(a), tonumber(b), tonumber(c)
    local year, month, day
    if a and a >= 1000 then year, month, day = a, b, c else day, month, year = a, b, c end
    if not validDate(year, month, day) then return false, 'invalid_birthdate' end
    local now = calendar.date('*t')
    local age = now.year - year
    if now.month < month or (now.month == month and now.day < day) then age = age - 1 end
    if age < settings.minimumAge then return false, 'minimum_age_required' end
    return true
end

function Service.canCreate(source, cid, data)
    cid = tonumber(cid)
    if not cid or cid % 1 ~= 0 then return false, 'invalid_character_slot' end
    local state, errorCode = Service.getState(source)
    if not state then return false, errorCode end
    if cid < 1 or cid > state.settings.maxSlots then return false, 'character_slot_unavailable' end
    if state.blocked[cid] == true then return false, 'character_slot_locked' end
    if state.settings.requireItem and cid > 1 and state.unlocked[cid] ~= true then return false, 'character_slot_locked' end
    for index = 1, #state.characters do
        local occupied = tonumber(state.characters[index].charinfo and state.characters[index].charinfo.cid) or index
        if occupied == cid then return false, 'character_slot_occupied' end
    end
    if state.settings.termsEnabled and (type(data) ~= 'table' or data.termsAccepted ~= true) then
        return false, 'character_terms_required'
    end
    return Service.validateAge(data and data.birthdate)
end

function Service.recordTermsAcceptance(source)
    local settings = getSettings()
    if not settings.termsEnabled then return true end
    local userId = getUserId(source)
    if not userId then return false end
    db.insert.await('INSERT IGNORE INTO qbx_character_terms_acceptance (user_id, terms_version) VALUES (?, ?)', { userId, settings.termsVersion })
    return true
end

function Service.unlock(source, requested)
    source = tonumber(source)
    requested = math.max(1, math.floor(tonumber(requested) or 1))
    local state, errorCode = Service.getState(source)
    if not state then return false, errorCode end
    if not state.settings.requireItem then return false, 'slot_item_disabled' end
    if accountLocks[state.userId] then return false, 'operation_in_progress' end
    accountLocks[state.userId] = true
    local slots = {}
    for slot = 2, state.settings.maxSlots do
        if state.unlocked[slot] ~= true and state.blocked[slot] ~= true then
            slots[#slots + 1] = slot
            if #slots >= requested then break end
        end
    end
    if #slots == 0 then accountLocks[state.userId] = nil return false, 'maximum_slots_reached' end
    local queries = {}
    for i = 1, #slots do
        queries[#queries + 1] = {
            query = 'INSERT IGNORE INTO qbx_character_slots (user_id, slot_id) VALUES (?, ?)',
            values = { state.userId, slots[i] },
        }
    end
    local ok, success = pcall(db.transaction.await, queries)
    accountLocks[state.userId] = nil
    if not ok or not success then return false, 'save_failed' end
    return true, { count = #slots, slots = slots }
end

function Service.hasAvailableSlot(source)
    local state, errorCode = Service.getState(source)
    if not state then return false, errorCode end
    if not state.settings.requireItem then return false, 'slot_item_disabled' end
    for slot = 2, state.settings.maxSlots do
        if state.unlocked[slot] ~= true and state.blocked[slot] ~= true then return true end
    end
    return false, 'maximum_slots_reached'
end

-- A suspension never deletes the entitlement or the character.
function Service.setSpecificSlot(source, slot, unlocked)
    source, slot = tonumber(source), tonumber(slot)
    if not source or not slot or slot % 1 ~= 0 then return false, 'invalid_character_slot' end
    local state, errorCode = Service.getState(source)
    if not state then return false, errorCode end
    if slot < 1 or slot > state.displaySlots then return false, 'character_slot_unavailable' end
    local success
    if unlocked == true then
        -- Lifting a suspension restores the previous entitlement, without granting a new one.
        local queries = {{ query = 'DELETE FROM qbx_character_slot_blocks WHERE user_id = ? AND slot_id = ?', values = { state.userId, slot } }}
        if not state.blocked[slot] and state.settings.requireItem and slot > 1 then
            queries[#queries + 1] = { query = 'INSERT IGNORE INTO qbx_character_slots (user_id, slot_id) VALUES (?, ?)', values = { state.userId, slot } }
        end
        success = db.transaction.await(queries)
    else
        success = db.transaction.await({{ query = 'INSERT IGNORE INTO qbx_character_slot_blocks (user_id, slot_id) VALUES (?, ?)', values = { state.userId, slot } }})
    end
    if not success then return false, 'save_failed' end
    local player = getPlayer(source)
    local currentSlot = player and tonumber(player.PlayerData.charinfo and player.PlayerData.charinfo.cid)
    if unlocked ~= true and currentSlot == slot then
        if not logout(source) then
            native.DropPlayer(tostring(source), 'Seu personagem foi suspenso pela administração.')
        end
    end
    return true, Service.getState(source)
end

function Service.canLoad(source, character)
    local userId = getUserId(source)
    if not userId then return false, 'account_not_found' end
    ensureTables()
    local slot = tonumber(character.charinfo and character.charinfo.cid or character.cid)
    if not slot then return false, 'invalid_character_slot' end
    if blockedSlots(userId)[slot] then return false, 'character_slot_locked' end
    return true
end

function Service.handleCharacterDeleted(playerEntity)
    if type(playerEntity) ~= 'table' then return end
    local settings = getSettings()
    local cid = tonumber(playerEntity.charinfo and playerEntity.charinfo.cid or playerEntity.cid)
    local userId = tonumber(playerEntity.userId)
    if not settings.loseSlotOnDelete or not userId or not cid or cid <= 1 then return end
    db.update.await('DELETE FROM qbx_character_slots WHERE user_id = ? AND slot_id = ?', { userId, cid })
end

describeExport('GetCharacterSlotSettings', function() return Service.getSettings() end)
describeExport('SetCharacterSlotSettings', function(value) return Service.saveSettings(value) end)
describeExport('GetCharacterSlotState', function(source) return Service.getState(source) end)
describeExport('CanUnlockCharacterSlots', function(source) return Service.hasAvailableSlot(source) end)
describeExport('UnlockCharacterSlots', function(source, amount) return Service.unlock(source, amount) end)
describeExport('SetCharacterSlotUnlocked', function(source, slot, unlocked) return Service.setSpecificSlot(source, slot, unlocked) end)

api.Ready[1] = ensureTables

    return api
end

