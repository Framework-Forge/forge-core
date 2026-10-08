ForgeCore = ForgeCore or {}

local resourceName = GetCurrentResourceName()
local Vip = {
    sessions = {},
    tiers = {},
    inventoryRevision = {},
    pendingInventoryReset = {},
}

local function now()
    return os.time()
end

local function clone(value)
    if type(value) ~= 'table' then return value end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = clone(child)
    end

    return copy
end

local function trim(value)
    return (tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function normalizeId(value)
    return trim(value):lower():gsub('%s+', '_'):gsub('[^%w_%-]', '')
end

local function player(source)
    return exports.qbx_core:GetPlayer(tonumber(source) or 0)
end

local function canManage(source)
    return source == 0 or (ForgeCore.JobService and ForgeCore.JobService.canManage(source))
end

local function metadata(source)
    local currentPlayer = player(source)
    return currentPlayer and currentPlayer.PlayerData and currentPlayer.PlayerData.metadata or {}
end

local function principal(source)
    local license = GetPlayerIdentifierByType(source, 'license')
    return license and ('identifier.%s'):format(license) or nil
end

local function normalizeTier(data, fallback)
    data = type(data) == 'table' and data or {}
    local id = normalizeId(data.id or fallback)
    if id == '' then return nil, 'missing_id' end

    local salary = type(data.salary) == 'table' and data.salary or {}

    return {
        id = id,
        label = trim(data.label) ~= '' and trim(data.label) or id,
        color = trim(data.color) ~= '' and trim(data.color) or '#ffffff',
        principal = trim(data.principal) ~= '' and trim(data.principal) or ('vip.%s'):format(id),
        slots = math.max(0, math.floor(tonumber(data.slots) or 0)),
        weight = math.max(0, math.floor(tonumber(data.weight) or 0)),
        xpMultiplier = math.max(1, tonumber(data.xpMultiplier) or 1),
        salary = {
            enabled = salary.enabled == true,
            account = trim(salary.account) ~= '' and trim(salary.account) or 'bank',
            amount = math.max(0, math.floor(tonumber(salary.amount) or 0)),
        },
    }
end

local function save(draft)
    draft = draft or Vip.tiers
    if not pr_lib.saveJsonRecovery(PR.Vip.storageFile, draft) then return false end
    Vip.tiers = draft
    PR.Vip.tiers = draft
    return true
end

function Vip.load()
    Vip.tiers = {}

    local decoded = pr_lib.loadJsonRecovery(PR.Vip.storageFile)

    local source = type(decoded) == 'table' and decoded or PR.Vip.tiers or {}
    for id, data in pairs(source) do
        local normalized = normalizeTier(data, id)
        if normalized then Vip.tiers[normalized.id] = normalized end
    end

    PR.Vip.tiers = Vip.tiers
    if not decoded then save() end
end

function Vip.getTiers()
    local result = {}
    for _, data in pairs(Vip.tiers) do
        result[#result + 1] = clone(data)
    end

    table.sort(result, function(a, b) return a.label < b.label end)
    return result
end

local function tier(id)
    return Vip.tiers[normalizeId(id)]
end

local function updateInventory(source, config)
    if GetResourceState('ox_inventory') ~= 'started' then
        return false, 'inventory_unavailable'
    end

    local extraSlots = math.max(0, math.floor(tonumber(config and config.slots) or 0))
    local extraWeight = math.max(0, math.floor(tonumber(config and config.weight) or 0))
    local called, success, response, details = pcall(function()
        return exports.ox_inventory:ApplyPlayerInventoryBonus(source, extraSlots, extraWeight)
    end)

    if not called then
        return false, 'inventory_export_failed', success
    end

    return success == true, response, details
end

local function queueInventoryUpdate(source, config)
    source = tonumber(source)
    if not source then return end

    Vip.inventoryRevision[source] = (Vip.inventoryRevision[source] or 0) + 1
    local revision = Vip.inventoryRevision[source]
    local resetting = config == nil
    local appliedConfig = config and clone(config) or nil

    if not resetting then Vip.pendingInventoryReset[source] = nil end

    CreateThread(function()
        local attempts = math.max(1, math.floor(tonumber(PR.Vip.inventoryRetryAttempts) or 40))
        local retryDelay = math.max(50, math.floor(tonumber(PR.Vip.inventoryRetryDelay) or 250))
        local lastReason

        for _ = 1, attempts do
            if Vip.inventoryRevision[source] ~= revision then return end
            if not player(source) then
                Vip.pendingInventoryReset[source] = nil
                return
            end

            local success, reason = updateInventory(source, appliedConfig)
            if success then
                Vip.pendingInventoryReset[source] = nil
                return
            end

            lastReason = reason
            if reason == 'slot_limit_below_item_count' then
                if resetting then Vip.pendingInventoryReset[source] = true end
                print(('[forge-core][vip] Inventario de %s possui mais itens que os slots padrao; nova tentativa sera feita automaticamente.'):format(source))
                return
            end

            Wait(retryDelay)
        end

        if resetting then Vip.pendingInventoryReset[source] = true end
        print(('[forge-core][vip] Nao foi possivel atualizar os limites do inventario de %s: %s'):format(source, tostring(lastReason or 'timeout')))
    end)
end

function Vip.get(source)
    if PR.Vip.enabled == false then return nil end

    local data = metadata(source)[PR.Vip.metadataKey]
    if type(data) ~= 'table' then return nil end

    local config = tier(data.tier)
    local expiresAt = tonumber(data.expiresAt) or 0
    if not config or expiresAt <= now() then return nil end

    return {
        tier = config.id,
        assignedAt = tonumber(data.assignedAt) or 0,
        expiresAt = expiresAt,
        config = config,
    }
end

local function removeSession(source)
    source = tonumber(source)
    if not source then return end

    local active = Vip.sessions[source]
    local identifier = principal(source)

    if active and identifier and active.config.principal ~= '' then
        ExecuteCommand(('remove_principal %s %s'):format(identifier, active.config.principal))
    end

    Vip.sessions[source] = nil
end

function Vip.clearSession(source, resetInventory)
    source = tonumber(source)
    if not source then return end

    removeSession(source)
    if resetInventory ~= false then queueInventoryUpdate(source, nil) end
end

function Vip.apply(source)
    source = tonumber(source)
    if not source or not player(source) then return false, 'invalid_player' end

    removeSession(source)
    local active = Vip.get(source)

    if not active then
        local old = metadata(source)[PR.Vip.metadataKey]
        if type(old) == 'table' and (not tier(old.tier) or (tonumber(old.expiresAt) or 0) <= now()) then
            exports.qbx_core:SetMetadata(source, PR.Vip.metadataKey, nil)
        end

        queueInventoryUpdate(source, nil)
        return false, 'not_active'
    end

    local identifier = principal(source)
    if identifier and active.config.principal ~= '' then
        ExecuteCommand(('add_principal %s %s'):format(identifier, active.config.principal))
    end

    Vip.sessions[source] = active
    queueInventoryUpdate(source, active.config)

    return true, active
end

function Vip.grant(actor, target, tierId, durationDays)
    if not canManage(actor) then return false, 'no_permission' end

    target = tonumber(target)
    durationDays = tonumber(durationDays)
    local config = tier(tierId)

    if not target or not player(target) or not config or not durationDays or durationDays < 1 then
        return false, 'invalid_data'
    end

    exports.qbx_core:SetMetadata(target, PR.Vip.metadataKey, {
        tier = config.id,
        assignedAt = now(),
        expiresAt = now() + math.floor(durationDays * 86400),
    })

    Vip.apply(target)
    return true, Vip.get(target)
end

function Vip.revoke(actor, target)
    if not canManage(actor) then return false, 'no_permission' end

    target = tonumber(target)
    if not target or not player(target) then return false, 'invalid_player' end

    Vip.clearSession(target, true)
    exports.qbx_core:SetMetadata(target, PR.Vip.metadataKey, nil)

    return true
end

function Vip.upsertTier(source, data)
    if not canManage(source) then return false, 'no_permission' end

    local normalized, errorCode = normalizeTier(data)
    if not normalized then return false, errorCode end

    local draft = pr_lib.jsonDraft(Vip.tiers, {})
    draft[normalized.id] = normalized
    if not save(draft) then return false, 'save_failed' end

    for playerSource, active in pairs(Vip.sessions) do
        if active.tier == normalized.id then Vip.apply(playerSource) end
    end

    return true, normalized
end

function Vip.deleteTier(source, id)
    if not canManage(source) then return false, 'no_permission' end

    id = normalizeId(id)
    if not Vip.tiers[id] then return false, 'not_found' end

    for _, active in pairs(Vip.sessions) do
        if active.tier == id then return false, 'tier_in_use' end
    end

    local draft = pr_lib.jsonDraft(Vip.tiers, {})
    draft[id] = nil
    if not save(draft) then return false, 'save_failed' end

    return true
end

local function applyOnlinePlayers()
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then Vip.apply(source) end
    end
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local source = source
    SetTimeout(250, function()
        if player(source) then Vip.apply(source) end
    end)
end)

AddEventHandler('playerDropped', function()
    local source = source
    removeSession(source)
    Vip.inventoryRevision[source] = (Vip.inventoryRevision[source] or 0) + 1
    Vip.pendingInventoryReset[source] = nil
end)

AddEventHandler('onResourceStart', function(startedResource)
    if startedResource ~= resourceName and startedResource ~= 'ox_inventory' then return end

    SetTimeout(startedResource == 'ox_inventory' and 1500 or 750, function()
        applyOnlinePlayers()
    end)
end)

CreateThread(function()
    local interval = math.max(1000, math.floor(tonumber(PR.Vip.expirationCheckInterval) or 15000))

    while true do
        Wait(interval)

        local currentTime = now()
        local expired = {}
        for source, active in pairs(Vip.sessions) do
            if active.expiresAt <= currentTime then expired[#expired + 1] = source end
        end

        for index = 1, #expired do
            Vip.apply(expired[index])
        end

        local pending = {}
        for source in pairs(Vip.pendingInventoryReset) do
            pending[#pending + 1] = source
        end

        for index = 1, #pending do
            local source = pending[index]
            if player(source) and not Vip.sessions[source] then
                queueInventoryUpdate(source, nil)
            else
                Vip.pendingInventoryReset[source] = nil
            end
        end
    end
end)

Vip.load()
pr_lib.wrapJsonMutations(PR.Vip.storageFile, Vip, { 'upsertTier', 'deleteTier' })

ForgeCore.VipService = Vip

exports('GetVip', function(source)
    return Vip.get(source)
end)

exports('GetVipXpMultiplier', function(source)
    local active = Vip.get(source)
    return active and active.config.xpMultiplier or 1
end)
