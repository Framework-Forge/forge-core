ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    schemaReady = false,
}
local P = PRProgression
local sessions, loading, forwarding = {}, {}, {}
local syncSession

local function debug(level, message)
    local debugApi = pr_lib and pr_lib.debug
    if not debugApi then return end

    local fn = debugApi[level]
    if type(fn) == 'function' then
        fn(message)
    elseif type(debugApi) == 'function' then
        debugApi(level, message)
    end
end

local function notify(source, data)
    if not source or source <= 0 then return end
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('skills.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function canManage(source)
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        return ForgeCore.JobService.canManage(source)
    end

    if source == 0 then return true end
    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function qbxReady()
    local state = GetResourceState('qbx_core')
    return state == 'started' or state == 'starting'
end

local function getQbxPlayer(source)
    if not qbxReady() then return nil end

    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)

    if ok then return player end
end

local function getCitizenid(source)
    local player = getQbxPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid
end

local function decodeValues(value)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return {} end

    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then return decoded end

    return {}
end

local function valueFromData(data, key)
    local value = data and data[key]
    if type(value) == 'table' then
        value = value.Current or value.current or value.xp
    end

    return math.max(0, P.round(P.number(value) or 0))
end

local function database()
    local db = pr_lib and pr_lib.db
    if not db or not db.scalar or not db.update then return nil end
    if db.isReady and not db.isReady() then return nil end

    return db
end

local function normalizePlayerValues(data)
    local values = P.copy(type(data) == 'table' and data or {})
    local payload = ForgeCore.SkillRegistry.payload()

    for _, skill in ipairs(payload.skills or {}) do
        values[skill.name] = math.min(skill.maxXp, valueFromData(data, skill.name))
    end

    for _, reputation in ipairs(payload.reputations or {}) do
        values[reputation.name] = math.min(reputation.maxXp, valueFromData(data, reputation.name))
    end

    return values
end

local function encodeValues(values)
    return json.encode(normalizePlayerValues(values))
end

local function ensureSkillsColumn()
    if Service.schemaReady then return true end
    local db = database()
    if not db then return false end

    local column = PR.Skills.Storage.playerColumn
    local exists = db.scalar(([[
        SELECT COUNT(*)
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'players'
            AND COLUMN_NAME = '%s'
    ]]):format(column))

    if tonumber(exists) == 0 then
        db.update(('ALTER TABLE `players` ADD COLUMN `%s` LONGTEXT NULL'):format(column))
        debug('success', ForgeCore.t('debug.skills.column_created', { column = column }))
    end

    Service.schemaReady = true
    return true
end

local function loadPlayerValues(source)
    source = tonumber(source)
    local citizenid = getCitizenid(source)
    if not citizenid then return nil, 'invalid_player' end
    if sessions[source] and sessions[source].citizenid == citizenid then
        return sessions[source].values, citizenid
    end
    if loading[source] then
        Citizen.Await(loading[source])
        if sessions[source] and sessions[source].citizenid == citizenid then return sessions[source].values, citizenid end
        return nil, 'load_failed'
    end
    if not ensureSkillsColumn() then return nil, 'database_unavailable' end

    local db = database()
    if not db then return nil, 'database_unavailable' end


    local column = PR.Skills.Storage.playerColumn
    local pending = promise.new()
    loading[source] = pending
    local ok, stored = pcall(db.scalar, ('SELECT `%s` FROM `players` WHERE `citizenid` = ?'):format(column), { citizenid })
    loading[source] = nil
    if not ok or getCitizenid(source) ~= citizenid then pending:resolve(false); return nil, 'load_failed' end
    local decoded = decodeValues(stored)
    local values = normalizePlayerValues(decoded)
    local capped = false
    local previousCaps = type(values._previousCaps) == 'table' and values._previousCaps or {}
    for name, value in pairs(values) do
        if type(value) == 'number' and valueFromData(decoded, name) > value then
            if previousCaps[name] == nil then previousCaps[name] = P.copy(decoded[name]) end
            capped = true
        end
    end
    if capped then values._previousCaps = previousCaps end
    local session = P.session(values, citizenid .. ':' .. GetGameTimer() .. ':' .. math.random(100000, 999999), GetGameTimer())
    session.citizenid, session.dirty = citizenid, capped
    sessions[source] = session
    pending:resolve(true)
    return session.values, citizenid
end

local function savePlayerValues(citizenid, values)
    if not citizenid then return false end
    if not ensureSkillsColumn() then return false end

    local db = database()
    if not db then return false end

    local column = PR.Skills.Storage.playerColumn
    local affected = db.update(('UPDATE `players` SET `%s` = ? WHERE `citizenid` = ?'):format(column), {
        encodeValues(values),
        citizenid,
    })

    return affected ~= false
end

local function getEffectiveXp(values, name)
    local skill = ForgeCore.SkillRegistry.getSkill(name)
    if not skill then return valueFromData(values, name) end

    if skill.calculation ~= PR.Skills.Calculation.sumReputations then
        return valueFromData(values, skill.name)
    end

    local total = 0
    local reputations = ForgeCore.SkillRegistry.getLinkedReputations(skill.name)
    for reputationName in pairs(reputations) do
        total = total + valueFromData(values, reputationName)
    end

    return math.min(skill.maxXp or total, P.round(total))
end

local function getLevelData(definition, xp)
    local levels = ForgeCore.SkillRegistry.getLevels(definition)
    local last = levels[1] or { title = 'Nivel 0', from = 0, to = 1 }

    for index, level in ipairs(levels) do
        last = level
        if xp >= level.from and xp < level.to then
            return {
                index = index - 1,
                title = level.title or ('Nivel %s'):format(index - 1),
                from = level.from,
                to = level.to,
                progress = xp,
            }
        end
    end

    return {
        index = #levels,
        title = 'Maestria',
        from = last.to,
        to = last.to,
        progress = xp,
    }
end

local function buildEntry(definition, values, entryType)
    local xp = entryType == 'skill' and getEffectiveXp(values, definition.name) or valueFromData(values, definition.name)
    local level = getLevelData(definition, xp)

    return {
        name = definition.name,
        code = definition.name,
        label = definition.label,
        icon = definition.icon,
        type = entryType,
        skill = definition.skill,
        calculation = definition.calculation,
        xp = xp,
        level = level,
    }
end

local function buildPlayerPayload(values)
    local payload = ForgeCore.SkillRegistry.payload()
    local skills = {}
    local reputations = {}

    for _, skill in ipairs(payload.skills or {}) do
        skills[#skills + 1] = buildEntry(skill, values, 'skill')
    end

    for _, reputation in ipairs(payload.reputations or {}) do
        reputations[#reputations + 1] = buildEntry(reputation, values, 'rep')
    end

    return {
        values = normalizePlayerValues(values),
        skills = skills,
        reputations = reputations,
        revision = payload.revision,
    }
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getPayload()
    return ForgeCore.SkillRegistry.payload()
end

function Service.save(draft)
    draft = draft or ForgeCore.SkillRegistry
    local saved = ForgeCore.SkillStorage.save({settings=draft.settings,skills=draft.skills,reputations=draft.reputations})
    if saved then
        ForgeCore.SkillRegistry.settings = draft.settings
        ForgeCore.SkillRegistry.skills = draft.skills
        ForgeCore.SkillRegistry.reputations = draft.reputations
        ForgeCore.SkillRegistry.revision = draft.revision
        debug('success', ForgeCore.t('debug.skills.saved'))
    end

    if saved and syncSession then
        for src in pairs(sessions) do syncSession(src, true) end
    end
    return saved
end

function Service.reload()
    ForgeCore.SkillRegistry.setAll(ForgeCore.SkillStorage.load())
    return true
end

function Service.upsertSkill(source, skill)
    if not canManage(source) then return false, 'no_permission' end

    local draft = pr_lib.jsonDraft(ForgeCore.SkillRegistry, {settings=true,skills=true,reputations=true})
    local ok, result = ForgeCore.SkillRegistry.upsertSkill(skill, draft)
    if not ok then return false, result end
    if not Service.save(draft) then return false, 'save_failed' end

    notify(source, {
        description = ForgeCore.t('notify.skills.saved', { item = result.label }),
        type = 'success',
    })

    return true, result
end

function Service.deleteSkill(source, name)
    if not canManage(source) then return false, 'no_permission' end

    local draft = pr_lib.jsonDraft(ForgeCore.SkillRegistry, {settings=true,skills=true,reputations=true})
    local ok, result = ForgeCore.SkillRegistry.removeSkill(name, draft)
    if not ok then return false, result end
    if not Service.save(draft) then return false, 'save_failed' end

    notify(source, {
        description = ForgeCore.t('notify.skills.removed'),
        type = 'success',
    })

    return true
end

function Service.upsertReputation(source, reputation)
    if not canManage(source) then return false, 'no_permission' end

    local draft = pr_lib.jsonDraft(ForgeCore.SkillRegistry, {settings=true,skills=true,reputations=true})
    local ok, result = ForgeCore.SkillRegistry.upsertReputation(reputation, draft)
    if not ok then return false, result end
    if not Service.save(draft) then return false, 'save_failed' end

    notify(source, {
        description = ForgeCore.t('notify.skills.saved', { item = result.label }),
        type = 'success',
    })

    return true, result
end

function Service.deleteReputation(source, name)
    if not canManage(source) then return false, 'no_permission' end

    local draft = pr_lib.jsonDraft(ForgeCore.SkillRegistry, {settings=true,skills=true,reputations=true})
    local ok, result = ForgeCore.SkillRegistry.removeReputation(name, draft)
    if not ok then return false, result end
    if not Service.save(draft) then return false, 'save_failed' end

    notify(source, {
        description = ForgeCore.t('notify.skills.removed'),
        type = 'success',
    })

    return true
end

function Service.fetchPlayer(source)
    local values, err = loadPlayerValues(source)
    if not values then return false, err end

    return true, buildPlayerPayload(values)
end

function Service.addXp(source, name, amount, context)
    source = tonumber(source)
    if ForgeCore.SkillRegistry.settings.enabled == false then return false, 'disabled' end
    local values, citizenid = loadPlayerValues(source)
    if not values then return false, citizenid end

    local definition = ForgeCore.SkillRegistry.getDefinition(name)
    if not definition then return false, 'not_found' end

    local skill = ForgeCore.SkillRegistry.getSkill(name)
    if skill and skill.calculation == PR.Skills.Calculation.sumReputations then
        return false, 'skill_uses_reputation_sum'
    end

    local current = valueFromData(values, definition.name)
    local maxXp = math.max(0, tonumber(definition.maxXp) or PR.Skills.Defaults.maxXp)
    local rawAmount = P.number(amount)
    if not rawAmount then return false, 'invalid_amount' end
    local multiplier = 1.0
    if rawAmount > 0 and not (type(context) == 'table' and context.normalizedXp) and ForgeCore.VipService then
        local activeVip = ForgeCore.VipService.get(source)
        multiplier = activeVip and (tonumber(activeVip.config.xpMultiplier) or 1.0) or 1.0
    end
    local nextValue = P.round(current + rawAmount * multiplier)

    if nextValue < 0 then nextValue = 0 end
    if nextValue > maxXp then nextValue = maxXp end


    local actual = P.change(sessions[source], definition.name, nextValue - current, maxXp)
    if Service.forwardChange then Service.forwardChange(source, definition, actual, context) end
    syncSession(source)

    return true, buildPlayerPayload(values)
end

function Service.getCurrentSkill(source, name)
    local values = loadPlayerValues(source)
    if not values then return nil end

    return getEffectiveXp(values, name)
end

function Service.getCurrentLevel(source, name)
    local values = loadPlayerValues(source)
    if not values then return nil end

    local definition = ForgeCore.SkillRegistry.getDefinition(name)
    if not definition then return nil end

    return getLevelData(definition, getEffectiveXp(values, name))
end

function Service.getSkillInfo(name)
    return ForgeCore.SkillRegistry.getDefinition(name)
end

function Service.start()
    if Service.started then return true end

    Service.started = true
    Service.reload()

    CreateThread(function()
        for _ = 1, 30 do
            if ensureSkillsColumn() then return end
            Wait(1000)
        end
    end)

    debug('success', ForgeCore.t('debug.skills.started'))
    return true
end

pr_lib.wrapJsonMutations(PR.Skills.Storage.file, Service, { 'upsertSkill', 'deleteSkill', 'upsertReputation', 'deleteReputation' })

ForgeCore.SkillService = Service

exports('updateSkill', function(source, name, amount, context)
    return Service.addXp(source, name, amount, context)
end)

exports('fetchSkills', function(source)
    local ok, payload = Service.fetchPlayer(source)
    return ok and payload or nil
end)

exports('getCurrentSkill', function(source, name)
    return Service.getCurrentSkill(source, name)
end)

exports('getCurrentLevel', function(source, name)
    return Service.getCurrentLevel(source, name)
end)

exports('getSkillInfo', function(name)
    return Service.getSkillInfo(name)
end)

-- Server cache mirrors client counters. SQL is only used on load/checkpoint.
local function clientRule(name)
    if ForgeCore.SkillRegistry.settings.enabled == false then return nil end
    local definition = ForgeCore.SkillRegistry.getDefinition(name)
    if not definition or definition.calculation == PR.Skills.Calculation.sumReputations then return nil end
    return { maximum = definition.maxXp, client = definition.clientGain or (definition.decay and definition.decay.enabled),
        gains = definition.clientGain == true, losses = definition.clientGain == true or (definition.decay and definition.decay.enabled == true) or false,
        rate = definition.maxDeltaPerMinute or PR.Skills.Client.maxDeltaPerMinute }
end

syncSession = function(src, definitions)
    local session = sessions[src]
    if not session then return end
    local packet = P.packet(session)
    if definitions or session.definitionRevision ~= ForgeCore.SkillRegistry.revision then
        packet.definitions = ForgeCore.SkillRegistry.payload()
        session.definitionRevision = ForgeCore.SkillRegistry.revision
    end
    pr_lib.cache.set('forge-core:skills:' .. src, P.copy(session.values))
    TriggerClientEvent('forge-core:client:skills:sync', src, packet)
end

function Service.forward(src, definition, delta, context)
    if delta == 0 then return end
    local integration = definition.integration
    if not integration or (delta > 0 and not integration.gains) or (delta < 0 and not integration.losses) then return end
    context = type(context) == 'table' and context or {}
    local visited = P.copy(context.visited or {})
    local route = GetCurrentResourceName() .. ':' .. definition.name
    if visited[route] or forwarding[src] then return end
    visited[route] = true
    if GetResourceState(integration.resource) ~= 'started' then return end
    local targetName = integration.identifier ~= '' and integration.identifier or definition.name
    if visited[integration.resource .. ':' .. targetName] then return end
    forwarding[src] = true
    local ok, result = pcall(function()
        local api = exports[integration.resource]
        return api[integration.export](api, src, targetName, delta * integration.multiplier, { visited = visited })
    end)
    forwarding[src] = nil
    if not ok or result == false then
        print(('[forge-core:skills] export failed %s:%s (%s)'):format(integration.resource, integration.export, tostring(result)))
    end
end

function Service.forwardChange(src, definition, delta, context)
    local parent = definition.skill and ForgeCore.SkillRegistry.getSkill(definition.skill)
    local parentDelta = 0
    if parent and parent.calculation == PR.Skills.Calculation.sumReputations then
        local total = 0
        for name in pairs(ForgeCore.SkillRegistry.getLinkedReputations(parent.name)) do
            total = total + valueFromData(sessions[src].values, name)
        end
        parentDelta = P.round(math.min(parent.maxXp, total) - math.min(parent.maxXp, total - delta))
    end
    Service.forward(src, definition, delta, context)
    if parentDelta ~= 0 then Service.forward(src, parent, parentDelta, context) end
end

local function accept(src, packet)
    local session = sessions[src]
    if not session then return false end
    local before = P.copy(session.values)
    local ok, changes = P.accept(session, packet, clientRule, GetGameTimer())
    if ok then
        local parents, outgoing = {}, {}
        for name, delta in pairs(changes) do
            local definition = ForgeCore.SkillRegistry.getDefinition(name)
            outgoing[#outgoing + 1] = { definition = definition, delta = delta }
            local parent = definition.skill and ForgeCore.SkillRegistry.getSkill(definition.skill)
            if parent and parent.calculation == PR.Skills.Calculation.sumReputations then parents[parent.name] = parent end
        end
        for name, parent in pairs(parents) do
            outgoing[#outgoing + 1] = { definition = parent,
                delta = P.round(getEffectiveXp(session.values, name) - getEffectiveXp(before, name)) }
        end
        for _, change in ipairs(outgoing) do Service.forward(src, change.definition, change.delta) end
    end
    syncSession(src)
    return ok
end

function Service.flush(src, citizenid)
    src = tonumber(src)
    local session = sessions[src]
    if not session or (citizenid and session.citizenid ~= citizenid) then return true end
    if session.saving then Citizen.Await(session.saving) end
    if not session.dirty then return true end
    local lock = promise.new()
    session.saving = lock
    local success = true
    repeat
        local revision = session.revision
        local ok, saved = pcall(savePlayerValues, session.citizenid, P.copy(session.values))
        success = ok and saved == true
        if success and revision == session.revision then session.dirty = false end
    until not success or not session.dirty
    session.saving = nil
    lock:resolve(success)
    return success
end

local lastRequest, lastMirror = {}, {}
RegisterNetEvent('forge-core:server:skills:initialize', function()
    local src = source
    local now = GetGameTimer()
    if lastRequest[src] and now - lastRequest[src] < 1000 then return end
    lastRequest[src] = now
    if loadPlayerValues(src) then syncSession(src, true) end
end)

RegisterNetEvent('forge-core:server:skills:mirror', function(packet)
    local src, now = source, GetGameTimer()
    if lastMirror[src] and now - lastMirror[src] < 250 then return end
    lastMirror[src] = now
    accept(src, packet)
end)

AddEventHandler('qbx_core:server:statusExtensions', function(src, extensions)
    if extensions.forgeSkills then accept(tonumber(src), extensions.forgeSkills) end
end)
AddEventHandler('qbx_core:server:progressionCheckpoint', function(src, citizenid)
    if not Service.flush(src, citizenid) then print('[forge-core:skills] checkpoint failed for ' .. tostring(src)) end
end)
AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    src = tonumber(src)
    local session = sessions[src]
    if Service.flush(src) and sessions[src] == session then sessions[src] = nil end
    lastRequest[src], lastMirror[src] = nil, nil
    pr_lib.cache.clear('forge-core:skills:' .. src)
end)
AddEventHandler('playerDropped', function()
    local src = tonumber(source)
    local session = sessions[src]
    if Service.flush(src) and sessions[src] == session then sessions[src] = nil end
    lastRequest[src], lastMirror[src] = nil, nil
    pr_lib.cache.clear('forge-core:skills:' .. src)
end)
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for src in pairs(sessions) do Service.flush(src) end
end)

exports('getSkillDefinitions', function() return ForgeCore.SkillRegistry.payload() end)
