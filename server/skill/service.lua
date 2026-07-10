ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    schemaReady = false,
}

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

    return math.max(0, math.floor(tonumber(value) or 0))
end

local function database()
    local db = pr_lib and pr_lib.db
    if not db or not db.scalar or not db.update then return nil end
    if db.isReady and not db.isReady() then return nil end

    return db
end

local function normalizePlayerValues(data)
    local values = {}
    local payload = ForgeCore.SkillRegistry.payload()

    for _, skill in ipairs(payload.skills or {}) do
        values[skill.name] = valueFromData(data, skill.name)
    end

    for _, reputation in ipairs(payload.reputations or {}) do
        values[reputation.name] = valueFromData(data, reputation.name)
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
    local citizenid = getCitizenid(source)
    if not citizenid then return nil, 'invalid_player' end
    if not ensureSkillsColumn() then return nil, 'database_unavailable' end

    local db = database()
    if not db then return nil, 'database_unavailable' end

    local column = PR.Skills.Storage.playerColumn
    local stored = db.scalar(('SELECT `%s` FROM `players` WHERE `citizenid` = ?'):format(column), { citizenid })
    local values = normalizePlayerValues(decodeValues(stored))

    db.update(('UPDATE `players` SET `%s` = ? WHERE `citizenid` = ?'):format(column), {
        encodeValues(values),
        citizenid,
    })

    return values, citizenid
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

    return total
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

function Service.save()
    local saved = ForgeCore.SkillStorage.save(ForgeCore.SkillRegistry.export())
    if saved then
        debug('success', ForgeCore.t('debug.skills.saved'))
    end

    return saved
end

function Service.reload()
    ForgeCore.SkillRegistry.setAll(ForgeCore.SkillStorage.load())
    return true
end

function Service.upsertSkill(source, skill)
    if not canManage(source) then return false, 'no_permission' end

    local ok, result = ForgeCore.SkillRegistry.upsertSkill(skill)
    if not ok then return false, result end
    if not Service.save() then return false, 'save_failed' end

    notify(source, {
        description = ForgeCore.t('notify.skills.saved', { item = result.label }),
        type = 'success',
    })

    return true, result
end

function Service.deleteSkill(source, name)
    if not canManage(source) then return false, 'no_permission' end

    local ok, result = ForgeCore.SkillRegistry.removeSkill(name)
    if not ok then return false, result end
    if not Service.save() then return false, 'save_failed' end

    notify(source, {
        description = ForgeCore.t('notify.skills.removed'),
        type = 'success',
    })

    return true
end

function Service.upsertReputation(source, reputation)
    if not canManage(source) then return false, 'no_permission' end

    local ok, result = ForgeCore.SkillRegistry.upsertReputation(reputation)
    if not ok then return false, result end
    if not Service.save() then return false, 'save_failed' end

    notify(source, {
        description = ForgeCore.t('notify.skills.saved', { item = result.label }),
        type = 'success',
    })

    return true, result
end

function Service.deleteReputation(source, name)
    if not canManage(source) then return false, 'no_permission' end

    local ok, result = ForgeCore.SkillRegistry.removeReputation(name)
    if not ok then return false, result end
    if not Service.save() then return false, 'save_failed' end

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

function Service.addXp(source, name, amount)
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
    local nextValue = current + math.floor(tonumber(amount) or 0)

    if nextValue < 0 then nextValue = 0 end
    if nextValue > maxXp then nextValue = maxXp end

    values[definition.name] = nextValue

    if not savePlayerValues(citizenid, values) then return false, 'save_failed' end

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

ForgeCore.SkillService = Service

exports('updateSkill', function(source, name, amount)
    return Service.addXp(source, name, amount)
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
