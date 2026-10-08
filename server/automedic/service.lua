ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    settings = {},
    deaths = {},
    treatments = {},
    recoveries = {},
    occupiedBeds = {},
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

local function finite(value)
    return type(value) == 'number' and value == value and math.abs(value) < 100000
end

local function position(value)
    if type(value) ~= 'table' or not finite(value.x) or not finite(value.y) or not finite(value.z) then return nil end
    return { x = value.x, y = value.y, z = value.z }
end

local function normalizeBed(bed)
    if type(bed) ~= 'table' then return nil end
    local coords, exit = position(bed.coords), position(bed.exit)
    if not coords or not exit or not finite(bed.heading) or not finite(bed.exitHeading) then return nil end
    local allowed = false
    for _, model in ipairs(PR.AutoMedic.Hospital.models) do if model == bed.model then allowed = true end end
    if not allowed or type(bed.id) ~= 'string' or not bed.id:match('^[%w_%-]+$') or #bed.id > 64 then return nil end
    local distance = (coords.x-exit.x)^2 + (coords.y-exit.y)^2 + (coords.z-exit.z)^2
    if distance > 100 then return nil end -- Safe standing exit must be near the bed.
    return {
        id = bed.id, label = tostring(bed.label or bed.id):sub(1, 80), model = bed.model,
        coords = coords, heading = bed.heading % 360, exit = exit, exitHeading = bed.exitHeading % 360,
        prison = bed.prison == true,
    }
end

local function normalizeSettings(settings)
    settings = type(settings) == 'table' and settings or {}
    local loss = type(settings.loseInventory) == 'table' and settings.loseInventory or {}
    local defaults = PR.AutoMedic.Defaults
    local cooldown = math.floor(tonumber(settings.cooldown) or defaults.cooldown)
    local treatmentPrice = math.floor(tonumber(settings.treatmentPrice) or defaults.treatmentPrice)
    local reviveHealthPercent = math.floor(tonumber(settings.reviveHealthPercent) or defaults.reviveHealthPercent)
    local beds, seen = {}, {}
    for _, value in ipairs(type(settings.beds) == 'table' and settings.beds or {}) do
        local bed = normalizeBed(value)
        if bed and not seen[bed.id] then beds[#beds+1] = bed; seen[bed.id] = true end
    end

    return {
        enabled = boolValue(settings.enabled, defaults.enabled),
        cooldown = math.max(0, math.min(cooldown, 3600)),
        bandageHealPercent = math.max(1, math.min(math.floor(tonumber(settings.bandageHealPercent) or defaults.bandageHealPercent), 100)),
        treatmentPrice = math.max(0, math.min(treatmentPrice, 1000000000)),
        reviveHealthPercent = math.max(1, math.min(reviveHealthPercent, 100)),
        hospitalFallback = boolValue(settings.hospitalFallback, defaults.hospitalFallback),
        beds = beds,
        loseInventory = {
            gunshot = boolValue(loss.gunshot, defaults.loseInventory.gunshot),
            other = boolValue(loss.other, defaults.loseInventory.other),
            collapse = boolValue(loss.collapse, defaults.loseInventory.collapse),
        },
    }
end

local function readSettings()
    local decoded = pr_lib.loadJsonRecovery(PR.AutoMedic.Storage.file)
    if type(decoded) == 'table' then return normalizeSettings(decoded) end
    return normalizeSettings(PR.AutoMedic.Defaults)
end

local function writeSettings(settings)
    return pr_lib.saveJsonRecovery(PR.AutoMedic.Storage.file, settings) == true
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
    if cash >= amount and framework.removePlayerMoney(source, 'cash', amount, 'forge-core:automedic-treatment') == true then
        return true, 'cash', amount
    end

    -- O QBX permite saldo bancario negativo; quando o dinheiro em maos nao
    -- cobre tudo, o valor integral e debitado da conta bancaria.
    if framework.removePlayerMoney(source, 'bank', amount, 'forge-core:automedic-treatment') == true then
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

local function revive(source, hospital)
    ensureMinimumReviveNeeds(source)
    exports.qbx_core:SetMetadata(source, 'isdead', false)
    exports.qbx_core:SetMetadata(source, 'inlaststand', false)
    exports.qbx_core:SetMetadata(source, 'deathTimeStamp', 0)
    TriggerClientEvent(PR.AutoMedic.Events.revive, source, hospital)
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

function Service.saveBed(source, bed)
    if not canManage(source) then return false, 'no_permission' end
    local normalized = normalizeBed(bed)
    if not normalized then return false, 'invalid_bed' end
    local draft, found = Service.getSettings(), false
    for index, existing in ipairs(draft.beds) do
        if existing.id == normalized.id then draft.beds[index] = normalized; found = true; break end
    end
    if not found then draft.beds[#draft.beds+1] = normalized end
    return Service.save(source, draft)
end

function Service.deleteBed(source, id)
    if not canManage(source) then return false, 'no_permission' end
    local draft = Service.getSettings()
    for index, bed in ipairs(draft.beds) do
        if bed.id == id then table.remove(draft.beds, index); return Service.save(source, draft) end
    end
    return false, 'invalid_bed'
end

local function character(source)
    if ForgeCore.Session and ForgeCore.Session.character then return ForgeCore.Session.character(source) end
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid
end

function Service.releaseHospital(source, token)
    local recovery = Service.recoveries[source]
    if not recovery or (token and recovery.token ~= token) then return false end
    if Service.occupiedBeds[recovery.key] == recovery then Service.occupiedBeds[recovery.key] = nil end
    Service.recoveries[source] = nil
    return true
end

local function nearestBed(source)
    local ped = GetPlayerPed(source)
    if ped == 0 or not DoesEntityExist(ped) then return nil end
    local origin, bucket = GetEntityCoords(ped), GetPlayerRoutingBucket(source)
    local prisoner = ForgeCore.PrisonService and not ForgeCore.PrisonService.canChangeJobs(source)
    local best, bestDistance, bestKey
    for _, bed in ipairs(Service.settings.beds) do
        local key = tostring(bucket) .. ':' .. bed.id
        local occupied = Service.occupiedBeds[key]
        if occupied and character(occupied.source) ~= occupied.character then
            Service.releaseHospital(occupied.source, occupied.token)
            occupied = nil
        end
        if not occupied and bed.prison == (prisoner == true) then
            local distance = (origin.x-bed.coords.x)^2 + (origin.y-bed.coords.y)^2 + (origin.z-bed.coords.z)^2
            if not bestDistance or distance < bestDistance then best, bestDistance, bestKey = bed, distance, key end
        end
    end
    return best, bestKey
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

    Service.releaseHospital(source)
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
    local citizenid = character(source)
    if not citizenid then return false, 'player_unavailable' end
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
        character = citizenid,
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

function Service.completeTreatment(source, token, hospital)
    local treatment = Service.treatments[source]
    if not treatment or treatment.token ~= token or treatment.character ~= character(source) then return false, 'invalid_treatment' end
    if treatment.processing then return false, 'already_active' end
    if not isDead(source) then
        Service.treatments[source] = nil
        return false, 'not_dead'
    end

    local minimum = math.max(1, math.floor((PR.AutoMedic.Npc.treatmentDuration or 10000) / 1000) - 2)
    if not hospital and os.time() - treatment.approvedAt < minimum then return false, 'treatment_too_fast' end
    treatment.processing = true

    local paid, paymentAccount, chargedAmount = chargeTreatment(source, Service.settings.treatmentPrice)
    if not paid then treatment.processing = false; return false, paymentAccount end

    if Service.settings.loseInventory[treatment.category] == true then
        local cleared, reason = clearInventory(source)
        if not cleared then
            refundTreatment(source, paymentAccount, chargedAmount)
            treatment.processing = false
            return false, reason
        end
    end

    local revived, reason = revive(source, hospital)
    if not revived then
        refundTreatment(source, paymentAccount, chargedAmount)
        treatment.processing = false
        return false, reason
    end

    Service.treatments[source] = nil
    Service.deaths[source] = nil
    return true, {
        category = treatment.category,
        inventoryLost = Service.settings.loseInventory[treatment.category] == true,
        chargedAmount = chargedAmount,
        paymentAccount = paymentAccount,
        hospital = hospital ~= nil,
    }
end

local fallbackReasons = { model_failed=true, spawn_failed=true, unreachable=true, alignment_failed=true, npc_lost=true, animation_failed=true }
function Service.recoverHospital(source, token, reason)
    if not Service.settings.enabled or not Service.settings.hospitalFallback then return false, 'disabled' end
    local treatment = Service.treatments[source]
    if not fallbackReasons[reason] or not treatment or treatment.token ~= token
        or treatment.character ~= character(source) or treatment.processing or not isDead(source) then
        return false, 'invalid_treatment'
    end
    local bed, key = nearestBed(source)
    if not bed then return false, 'no_hospital_beds' end
    local recovery = { source=source, character=treatment.character, token=token, key=key, bed=clone(bed) }
    Service.releaseHospital(source)
    Service.recoveries[source], Service.occupiedBeds[key] = recovery, recovery
    local ok, payload = Service.completeTreatment(source, token, { bed=clone(bed), token=token })
    if not ok then Service.releaseHospital(source, token) end
    return ok, payload
end

function Service.cancelTreatment(source, token)
    local treatment = Service.treatments[source]
    if treatment and treatment.processing then return false, 'already_active' end
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
        Service.releaseHospital(playerSource)
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
    Service.releaseHospital(source)
    Service.deaths[source] = nil
    Service.treatments[source] = nil
end)

local function clearCharacter(playerSource)
    playerSource = tonumber(playerSource) or source
    if not playerSource then return end
    Service.releaseHospital(playerSource)
    Service.treatments[playerSource], Service.deaths[playerSource] = nil, nil
end
AddEventHandler('QBCore:Server:OnPlayerUnload', clearCharacter)
AddEventHandler('pr_bridge:server:OnPlayerUnloaded', clearCharacter)
RegisterNetEvent(PR.AutoMedic.Events.leaveHospital, function(token)
    local playerSource = source
    if type(token) == 'string' then Service.releaseHospital(playerSource, token) end
end)

ForgeCore.AutoMedicService = Service
