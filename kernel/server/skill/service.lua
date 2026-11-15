-- Whole server service. Construction collects boundaries but never installs or starts them.
return function(ports)
    local PR={Skills=assert(ports.config),AdminAce=ports.adminAce,NotifyPos=ports.notifyPosition}
    local registry,storage=assert(ports.registry),assert(ports.storage)
    local library,codec,translate=assert(ports.library),assert(ports.json),assert(ports.translate)
    local services,kernel,native=assert(ports.services),assert(ports.kernel),assert(ports.native)
    local integrations=assert(ports.integrations)
    assert(type(integrations.invoke)=='function','explicit PR progression integration required')
    local api={Exports={},NetEvents={},Listeners={}}
    local function describeExport(name,handler)api.Exports[#api.Exports+1]={name=name,handler=handler}end
    local function describeNetEvent(name,handler)api.NetEvents[#api.NetEvents+1]={name=name,handler=handler}end
    local function describeListener(name,handler)api.Listeners[#api.Listeners+1]={name=name,handler=handler}end
local Service = {
    started = false,
    schemaReady = false,
}
local P = assert(ports.progression)
local sessions, loading, forwarding = {}, {}, {}
local syncSession

local function debug(level, message)
    local debugApi = library and library.debug
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
    if not library or not library.notify or not library.notify.NotifyPlayer then return end

    library.notify.NotifyPlayer(source, {
        title = data.title or translate('skills.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function canManage(source)
    if services.JobService and services.JobService.canManage then
        return services.JobService.canManage(source)
    end

    if source == 0 then return true end
    return native.isAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function qbxReady()
    return kernel.isReady()
end

local function getQbxPlayer(source)
    if not qbxReady() then return nil end

    local ok, player = pcall(function()
        return kernel.GetPlayer(source)
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

    local ok, decoded = pcall(codec.decode, value)
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
    local db = library and library.db
    if not db or not db.scalar or not db.update then return nil end
    if db.isReady and not db.isReady() then return nil end

    return db
end

local function normalizePlayerValues(data)
    local values = P.copy(type(data) == 'table' and data or {})
    local payload = registry.payload()

    for _, skill in ipairs(payload.skills or {}) do
        values[skill.name] = math.min(skill.maxXp, valueFromData(data, skill.name))
    end

    for _, reputation in ipairs(payload.reputations or {}) do
        values[reputation.name] = math.min(reputation.maxXp, valueFromData(data, reputation.name))
    end

    return values
end

local function encodeValues(values)
    return codec.encode(normalizePlayerValues(values))
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
        debug('success', translate('debug.skills.column_created', { column = column }))
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
        native.await(loading[source])
        if sessions[source] and sessions[source].citizenid == citizenid then return sessions[source].values, citizenid end
        return nil, 'load_failed'
    end
    if not ensureSkillsColumn() then return nil, 'database_unavailable' end

    local db = database()
    if not db then return nil, 'database_unavailable' end


    local column = PR.Skills.Storage.playerColumn
    local pending = native.promise()
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
    local session = P.session(values, citizenid .. ':' .. native.time() .. ':' .. math.random(100000, 999999), native.time())
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
    local skill = registry.getSkill(name)
    if not skill then return valueFromData(values, name) end

    if skill.calculation ~= PR.Skills.Calculation.sumReputations then
        return valueFromData(values, skill.name)
    end

    local total = 0
    local reputations = registry.getLinkedReputations(skill.name)
    for reputationName in pairs(reputations) do
        total = total + valueFromData(values, reputationName)
    end

    return math.min(skill.maxXp or total, P.round(total))
end

local function getLevelData(definition, xp)
    local levels = registry.getLevels(definition)
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
    local payload = registry.payload()
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
    return registry.payload()
end

function Service.save(draft)
    draft = draft or registry
    local saved = storage.save({settings=draft.settings,skills=draft.skills,reputations=draft.reputations})
    if saved then
        registry.settings = draft.settings
        registry.skills = draft.skills
        registry.reputations = draft.reputations
        registry.revision = draft.revision
        debug('success', translate('debug.skills.saved'))
    end

    if saved and syncSession then
        for src in pairs(sessions) do syncSession(src, true) end
    end
    return saved
end

function Service.reload()
    registry.setAll(storage.load())
    return true
end

function Service.upsertSkill(source, skill)
    if not canManage(source) then return false, 'no_permission' end

    local draft = library.jsonDraft(registry, {settings=true,skills=true,reputations=true})
    local ok, result = registry.upsertSkill(skill, draft)
    if not ok then return false, result end
    if not Service.save(draft) then return false, 'save_failed' end

    notify(source, {
        description = translate('notify.skills.saved', { item = result.label }),
        type = 'success',
    })

    return true, result
end

function Service.deleteSkill(source, name)
    if not canManage(source) then return false, 'no_permission' end

    local draft = library.jsonDraft(registry, {settings=true,skills=true,reputations=true})
    local ok, result = registry.removeSkill(name, draft)
    if not ok then return false, result end
    if not Service.save(draft) then return false, 'save_failed' end

    notify(source, {
        description = translate('notify.skills.removed'),
        type = 'success',
    })

    return true
end

function Service.upsertReputation(source, reputation)
    if not canManage(source) then return false, 'no_permission' end

    local draft = library.jsonDraft(registry, {settings=true,skills=true,reputations=true})
    local ok, result = registry.upsertReputation(reputation, draft)
    if not ok then return false, result end
    if not Service.save(draft) then return false, 'save_failed' end

    notify(source, {
        description = translate('notify.skills.saved', { item = result.label }),
        type = 'success',
    })

    return true, result
end

function Service.deleteReputation(source, name)
    if not canManage(source) then return false, 'no_permission' end

    local draft = library.jsonDraft(registry, {settings=true,skills=true,reputations=true})
    local ok, result = registry.removeReputation(name, draft)
    if not ok then return false, result end
    if not Service.save(draft) then return false, 'save_failed' end

    notify(source, {
        description = translate('notify.skills.removed'),
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
    if registry.settings.enabled == false then return false, 'disabled' end
    local values, citizenid = loadPlayerValues(source)
    if not values then return false, citizenid end

    local definition = registry.getDefinition(name)
    if not definition then return false, 'not_found' end

    local skill = registry.getSkill(name)
    if skill and skill.calculation == PR.Skills.Calculation.sumReputations then
        return false, 'skill_uses_reputation_sum'
    end

    local current = valueFromData(values, definition.name)
    local maxXp = math.max(0, tonumber(definition.maxXp) or PR.Skills.Defaults.maxXp)
    local rawAmount = P.number(amount)
    if not rawAmount then return false, 'invalid_amount' end
    local multiplier = 1.0
    if rawAmount > 0 and not (type(context) == 'table' and context.normalizedXp) and services.VipService then
        local activeVip = services.VipService.get(source)
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

    local definition = registry.getDefinition(name)
    if not definition then return nil end

    return getLevelData(definition, getEffectiveXp(values, name))
end

function Service.getSkillInfo(name)
    return registry.getDefinition(name)
end

function Service.start()
    if Service.started then return true end

    Service.started = true
    Service.reload()

    native.spawn(function()
        for _ = 1, 30 do
            if ensureSkillsColumn() then return end
            native.wait(1000)
        end
    end)

    debug('success', translate('debug.skills.started'))
    return true
end

library.wrapJsonMutations(PR.Skills.Storage.file, Service, { 'upsertSkill', 'deleteSkill', 'upsertReputation', 'deleteReputation' })

api.Service = Service

describeExport('updateSkill', function(source, name, amount, context)
    return Service.addXp(source, name, amount, context)
end)

describeExport('fetchSkills', function(source)
    local ok, payload = Service.fetchPlayer(source)
    return ok and payload or nil
end)

describeExport('getCurrentSkill', function(source, name)
    return Service.getCurrentSkill(source, name)
end)

describeExport('getCurrentLevel', function(source, name)
    return Service.getCurrentLevel(source, name)
end)

describeExport('getSkillInfo', function(name)
    return Service.getSkillInfo(name)
end)

-- Server cache mirrors client counters. SQL is only used on load/checkpoint.
local function clientRule(name)
    if registry.settings.enabled == false then return nil end
    local definition = registry.getDefinition(name)
    if not definition or definition.calculation == PR.Skills.Calculation.sumReputations then return nil end
    return { maximum = definition.maxXp, client = definition.clientGain or (definition.decay and definition.decay.enabled),
        gains = definition.clientGain == true, losses = definition.clientGain == true or (definition.decay and definition.decay.enabled == true) or false,
        rate = definition.maxDeltaPerMinute or PR.Skills.Client.maxDeltaPerMinute }
end

syncSession = function(src, definitions)
    local session = sessions[src]
    if not session then return end
    local packet = P.packet(session)
    if definitions or session.definitionRevision ~= registry.revision then
        packet.definitions = registry.payload()
        session.definitionRevision = registry.revision
    end
    library.cache.set('forge-core:skills:' .. src, P.copy(session.values))
    native.emitClient('forge-core:client:skills:sync', src, packet)
end

function Service.forward(src, definition, delta, context)
    if delta == 0 then return end
    local integration = definition.integration
    if not integration or (delta > 0 and not integration.gains) or (delta < 0 and not integration.losses) then return end
    context = type(context) == 'table' and context or {}
    local visited = P.copy(context.visited or {})
    local route = native.resource() .. ':' .. definition.name
    if visited[route] or forwarding[src] then return end
    visited[route] = true
    if native.resourceState(integration.resource) ~= 'started' then return end
    local targetName = integration.identifier ~= '' and integration.identifier or definition.name
    if visited[integration.resource .. ':' .. targetName] then return end
    forwarding[src] = true
    local ok, result = pcall(function()
        return integrations.invoke(integration.resource, integration.export, src, targetName, delta * integration.multiplier, { visited = visited })
    end)
    forwarding[src] = nil
    if not ok or result == false then
        native.print(('[forge-core:skills] export failed %s:%s (%s)'):format(integration.resource, integration.export, tostring(result)))
    end
end

function Service.forwardChange(src, definition, delta, context)
    local parent = definition.skill and registry.getSkill(definition.skill)
    local parentDelta = 0
    if parent and parent.calculation == PR.Skills.Calculation.sumReputations then
        local total = 0
        for name in pairs(registry.getLinkedReputations(parent.name)) do
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
    local ok, changes = P.accept(session, packet, clientRule, native.time())
    if ok then
        local parents, outgoing = {}, {}
        for name, delta in pairs(changes) do
            local definition = registry.getDefinition(name)
            outgoing[#outgoing + 1] = { definition = definition, delta = delta }
            local parent = definition.skill and registry.getSkill(definition.skill)
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
    if session.saving then native.await(session.saving) end
    if not session.dirty then return true end
    local lock = native.promise()
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
describeNetEvent('forge-core:server:skills:initialize', function()
    local src = native.source()
    local now = native.time()
    if lastRequest[src] and now - lastRequest[src] < 1000 then return end
    lastRequest[src] = now
    if loadPlayerValues(src) then syncSession(src, true) end
end)

describeNetEvent('forge-core:server:skills:mirror', function(packet)
    local src, now = native.source(), native.time()
    if lastMirror[src] and now - lastMirror[src] < 250 then return end
    lastMirror[src] = now
    accept(src, packet)
end)

describeListener('qbx_core:server:statusExtensions', function(src, extensions)
    if extensions.forgeSkills then accept(tonumber(src), extensions.forgeSkills) end
end)
describeListener('qbx_core:server:progressionCheckpoint', function(src, citizenid)
    if not Service.flush(src, citizenid) then native.print('[forge-core:skills] checkpoint failed for ' .. tostring(src)) end
end)
describeListener('QBCore:Server:OnPlayerUnload', function(src)
    src = tonumber(src)
    local session = sessions[src]
    if Service.flush(src) and sessions[src] == session then sessions[src] = nil end
    lastRequest[src], lastMirror[src] = nil, nil
    library.cache.clear('forge-core:skills:' .. src)
end)
describeListener('playerDropped', function()
    local src = tonumber(native.source())
    local session = sessions[src]
    if Service.flush(src) and sessions[src] == session then sessions[src] = nil end
    lastRequest[src], lastMirror[src] = nil, nil
    library.cache.clear('forge-core:skills:' .. src)
end)
describeListener('onResourceStop', function(resource)
    if resource ~= native.resource() then return end
    for src in pairs(sessions) do Service.flush(src) end
end)

describeExport('getSkillDefinitions', function() return registry.payload() end)
    return api
end

