ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    settings = {},
    deaths = {},
    treatments = {},
}

local resourceName = GetCurrentResourceName()

local function clone(value)
    if type(value) ~= 'table' then return value end
    local copy = {}
    for key, item in pairs(value) do copy[key] = clone(item) end
    return copy
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end
    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function normalizeSettings(settings)
    settings = type(settings) == 'table' and settings or {}
    local loss = type(settings.loseInventory) == 'table' and settings.loseInventory or {}
    local defaults = PR.AutoMedic.Defaults
    local cooldown = math.floor(tonumber(settings.cooldown) or defaults.cooldown)
    local treatmentPrice = math.floor(tonumber(settings.treatmentPrice) or defaults.treatmentPrice)
    local reviveHealthPercent = math.floor(tonumber(settings.reviveHealthPercent) or defaults.reviveHealthPercent)

    return {
        enabled = boolValue(settings.enabled, defaults.enabled),
        cooldown = math.max(0, math.min(cooldown, 3600)),
        bandageHealPercent = math.max(1, math.min(math.floor(tonumber(settings.bandageHealPercent) or defaults.bandageHealPercent), 100)),
        treatmentPrice = math.max(0, math.min(treatmentPrice, 1000000000)),
        reviveHealthPercent = math.max(1, math.min(reviveHealthPercent, 100)),
        loseInventory = {
            gunshot = boolValue(loss.gunshot, defaults.loseInventory.gunshot),
            other = boolValue(loss.other, defaults.loseInventory.other),
            collapse = boolValue(loss.collapse, defaults.loseInventory.collapse),
        },
    }
end

local function readSettings()
    local content = LoadResourceFile(resourceName, PR.AutoMedic.Storage.file)
    if type(content) == 'string' and content ~= '' then
        local ok, decoded = pcall(json.decode, content)
        if ok and type(decoded) == 'table' then return normalizeSettings(decoded) end
    end
    return normalizeSettings(PR.AutoMedic.Defaults)
end

local function writeSettings(settings)
    local ok, encoded = pcall(json.encode, settings)
    if not ok then return false end
    local saved = SaveResourceFile(resourceName, PR.AutoMedic.Storage.file, encoded, -1)
    return saved ~= false and saved ~= nil
end

local function canManage(source)
    if source == 0 then return true end
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        return ForgeCore.JobService.canManage(source)
    end
    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function isPedDead(source)
    local ped = GetPlayerPed(source)
    if ped == 0 or not DoesEntityExist(ped) then return false end

    -- Player peds use 100 as their base health. During a downed/death flow the
    -- server can still observe 100 before the final native death state syncs.
    return GetEntityHealth(ped) <= 100
end

local function isDead(source)
    if Service.deaths[source] then return true end

    local player = exports.qbx_core:GetPlayer(source)
    local metadata = player and player.PlayerData and player.PlayerData.metadata or {}
    if metadata.isdead == true or metadata.inlaststand == true then return true end

    if isPedDead(source) then
        Service.deaths[source] = { at = os.time() }
        return true
    end

    return false
end

local function hasBleeding(value)
    if type(value) ~= 'table' then return false end
    for key, item in pairs(value) do
        if key == 'bleeding' and tonumber(item) and tonumber(item) > 0 then return true end
        if type(item) == 'table' and hasBleeding(item) then return true end
    end
    return false
end

local function classify(source, requested)
    if requested == 'gunshot' then return 'gunshot' end

    local player = exports.qbx_core:GetPlayer(source)
    local metadata = player and player.PlayerData and player.PlayerData.metadata or {}

    if hasBleeding(metadata.injuries)
        or (tonumber(metadata.bleeding) or 0) > 0 then
        return 'collapse'
    end

    if requested == 'collapse' then return 'collapse' end
    return 'other'
end

local function deathAt(source)
    local record = Service.deaths[source]
    if record and record.at then return record.at end

    local player = exports.qbx_core:GetPlayer(source)
    local metadata = player and player.PlayerData and player.PlayerData.metadata or {}
    local cachedTime = tonumber(metadata.deathTimeStamp)
    local at = cachedTime and cachedTime > 0 and cachedTime or os.time()
    Service.deaths[source] = { at = at }
    return at
end

local function publicStatus(source)
    local dead = isDead(source)
    local at = dead and deathAt(source) or nil
    return {
        enabled = Service.settings.enabled,
        cooldown = Service.settings.cooldown,
        treatmentPrice = Service.settings.treatmentPrice,
        reviveHealthPercent = Service.settings.reviveHealthPercent,
        deathAt = at,
        remaining = dead and math.max(0, Service.settings.cooldown - (os.time() - at)) or 0,
        dead = dead,
    }
end

local function clearInventory(source)
    if GetResourceState('ox_inventory') ~= 'started' then return false, 'inventory_unavailable' end
    local ok, result = pcall(function()
        return exports.ox_inventory:ClearInventory(source)
    end)
    if not ok or result == false then return false, 'inventory_clear_failed' end
    return true
end


local function chargeTreatment(source, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount == 0 then return true, nil, 0 end

    local framework = pr_lib and pr_lib.framework
    if not framework or not framework.getPlayerMoney or not framework.removePlayerMoney then
        return false, 'payment_unavailable'
    end

    local cash = tonumber(framework.getPlayerMoney(source, 'cash')) or 0
    if cash >= amount and framework.removePlayerMoney(source, 'cash', amount, 'forge-core:automedic-treatment') ~= false then
        return true, 'cash', amount
    end

    -- O QBX permite saldo bancario negativo; quando o dinheiro em maos nao
    -- cobre tudo, o valor integral e debitado da conta bancaria.
    if framework.removePlayerMoney(source, 'bank', amount, 'forge-core:automedic-treatment') ~= false then
        return true, 'bank', amount
    end

    return false, 'payment_failed'
end

local function refundTreatment(source, account, amount)
    if not account or amount <= 0 then return end
    local framework = pr_lib and pr_lib.framework
    if framework and framework.addPlayerMoney then
        framework.addPlayerMoney(source, account, amount, 'forge-core:automedic-refund')
    end
end

local function ensureMinimumReviveNeeds(source)
    local minimum = 10

    for _, key in ipairs({ 'hunger', 'thirst' }) do
        local current = tonumber(exports.qbx_core:GetStatus(source, key))
        if current and current < minimum then
            exports.qbx_core:SetStatus(source, key, minimum)
        end
    end
end

local function revive(source)
    ensureMinimumReviveNeeds(source)
    exports.qbx_core:SetMetadata(source, 'isdead', false)
    exports.qbx_core:SetMetadata(source, 'inlaststand', false)
    exports.qbx_core:SetMetadata(source, 'deathTimeStamp', 0)
    TriggerClientEvent(PR.AutoMedic.Events.revive, source)
    return true
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getSettings()
    return clone(Service.settings)
end

function Service.save(source, settings)
    if not canManage(source) then return false, 'no_permission' end
    local normalized = normalizeSettings(settings)
    if not writeSettings(normalized) then return false, 'save_failed' end

    Service.settings = normalized
    TriggerClientEvent(PR.AutoMedic.Events.sync, -1, Service.getSettings())
    return true, Service.getSettings()
end

function Service.getStatus(source)
    return publicStatus(source)
end

function Service.reportDeath(source, info)
    info = type(info) == 'table' and info or {}

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false, 'player_unavailable' end

    local metadata = player.PlayerData and player.PlayerData.metadata or {}
    local nativeDead = isPedDead(source)
    if not nativeDead and metadata.isdead ~= true and metadata.inlaststand ~= true then
        return false, 'not_dead'
    end

    local now = os.time()
    local reportedAt = tonumber(info.timestamp)
    if not reportedAt or math.abs(now - reportedAt) > 30 then reportedAt = now end

    Service.deaths[source] = {
        at = reportedAt,
        cause = tonumber(info.deathCause),
    }
    Service.treatments[source] = nil

    exports.qbx_core:SetMetadata(source, 'deathTimeStamp', reportedAt)
    exports.qbx_core:SetMetadata(source, 'isdead', true)
    return true
end

function Service.requestTreatment(source, requestedCategory)
    if not Service.settings.enabled then return false, 'disabled' end
    if not isDead(source) then return false, 'not_dead' end

    local status = publicStatus(source)
    if status.remaining > 0 then return false, 'cooldown', status.remaining end

    local active = Service.treatments[source]
    local expiresAfter = math.ceil(((PR.AutoMedic.Npc.arrivalTimeout or 90000) + (PR.AutoMedic.Npc.treatmentDuration or 10000)) / 1000) + 15
    if active and os.time() - active.approvedAt <= expiresAfter then return false, 'already_active' end
    Service.treatments[source] = nil

    local token = ('%s:%s:%s'):format(source, os.time(), math.random(100000, 999999))
    local category = classify(source, requestedCategory)
    Service.treatments[source] = {
        token = token,
        category = category,
        approvedAt = os.time(),
    }

    return true, {
        token = token,
        category = category,
        loseInventory = Service.settings.loseInventory[category] == true,
        treatmentPrice = Service.settings.treatmentPrice,
    }
end

function Service.completeTreatment(source, token)
    local treatment = Service.treatments[source]
    if not treatment or treatment.token ~= token then return false, 'invalid_treatment' end
    if not isDead(source) then
        Service.treatments[source] = nil
        return false, 'not_dead'
    end

    local minimum = math.max(1, math.floor((PR.AutoMedic.Npc.treatmentDuration or 10000) / 1000) - 2)
    if os.time() - treatment.approvedAt < minimum then return false, 'treatment_too_fast' end

    local paid, paymentAccount, chargedAmount = chargeTreatment(source, Service.settings.treatmentPrice)
    if not paid then return false, paymentAccount end

    if Service.settings.loseInventory[treatment.category] == true then
        local cleared, reason = clearInventory(source)
        if not cleared then
            refundTreatment(source, paymentAccount, chargedAmount)
            return false, reason
        end
    end

    local revived, reason = revive(source)
    if not revived then
        refundTreatment(source, paymentAccount, chargedAmount)
        return false, reason
    end

    Service.treatments[source] = nil
    Service.deaths[source] = nil
    return true, {
        category = treatment.category,
        inventoryLost = Service.settings.loseInventory[treatment.category] == true,
        chargedAmount = chargedAmount,
        paymentAccount = paymentAccount,
    }
end

function Service.cancelTreatment(source, token)
    local treatment = Service.treatments[source]
    if treatment and treatment.token == token then
        Service.treatments[source] = nil
    end
    return true
end

function Service.start()
    if Service.started then return end
    Service.started = true
    Service.settings = readSettings()
end

AddEventHandler('qbx_core:server:onSetMetaData', function(metadata, _, value, playerSource)
    if metadata ~= 'isdead' then return end

    playerSource = tonumber(playerSource)
    if not playerSource or playerSource <= 0 then return end

    if value == true then
        local player = exports.qbx_core:GetPlayer(playerSource)
        local playerMetadata = player and player.PlayerData and player.PlayerData.metadata or {}
        local cachedTime = tonumber(playerMetadata.deathTimeStamp)
        Service.deaths[playerSource] = Service.deaths[playerSource] or {
            at = cachedTime and cachedTime > 0 and cachedTime or os.time(),
        }
        return
    end

    Service.deaths[playerSource] = nil
    Service.treatments[playerSource] = nil
end)

RegisterNetEvent(PR.AutoMedic.Events.reportDeath, function(info)
    local playerSource = source
    if playerSource <= 0 then return end
    Service.reportDeath(playerSource, info)
end)

AddEventHandler('playerDropped', function()
    Service.deaths[source] = nil
    Service.treatments[source] = nil
end)

ForgeCore.AutoMedicService = Service
