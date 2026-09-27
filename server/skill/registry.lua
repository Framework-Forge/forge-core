ForgeCore = ForgeCore or {}

local Registry = {
    settings = {},
    skills = {},
    reputations = {},
    revision = 0,
}

local function trim(value)
    return (tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function normalizeName(value)
    value = trim(value):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_%-]', '')
    return value
end

local function clone(value, seen)
    if type(value) ~= 'table' then return value end

    seen = seen or {}
    if seen[value] then return seen[value] end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        copy[clone(key, seen)] = clone(item, seen)
    end

    return copy
end

local function normalizeLevels(levels)
    local normalized = {}

    if type(levels) ~= 'table' then return normalized end

    for _, level in ipairs(levels) do
        local from = math.max(0, math.floor(tonumber(level.from) or 0))
        local to = math.max(from + 1, math.floor(tonumber(level.to) or from + 1))

        normalized[#normalized + 1] = {
            title = trim(level.title) ~= '' and trim(level.title) or ('Nivel %s'):format(#normalized),
            from = from,
            to = to,
        }
    end

    table.sort(normalized, function(left, right)
        return left.from < right.from
    end)

    return normalized
end

local function normalizeSettings(settings)
    local defaults = PR.Skills.Defaults.settings
    settings = type(settings) == 'table' and settings or {}

    local levels = normalizeLevels(settings.defaultLevels)
    if #levels == 0 then
        levels = normalizeLevels(defaults.defaultLevels)
    end

    return {
        enabled = settings.enabled ~= false,
        defaultLevels = levels,
    }
end

local function normalizeSkill(rawSkill, fallbackName)
    if type(rawSkill) ~= 'table' then return nil, 'invalid_skill' end

    local name = normalizeName(rawSkill.name or rawSkill.skill or rawSkill.code or fallbackName)
    if name == '' then return nil, 'missing_name' end

    local label = trim(rawSkill.label)
    local calculation = rawSkill.calculation or rawSkill.calculateBy or PR.Skills.Calculation.direct
    if calculation ~= PR.Skills.Calculation.sumReputations then
        calculation = PR.Skills.Calculation.direct
    end

    local levels = normalizeLevels(rawSkill.levels or rawSkill.skillLevels)

    return {
        name = name,
        code = name,
        label = label ~= '' and label or name,
        icon = trim(rawSkill.icon) ~= '' and trim(rawSkill.icon) or PR.Skills.Defaults.icon,
        calculation = calculation,
        integration = PR.Skills.normalizeIntegration(rawSkill.integration),
        decay = PR.Skills.normalizeDecay(rawSkill.decay),
        clientGain = rawSkill.clientGain == true,
        maxDeltaPerMinute = math.max(0, tonumber(rawSkill.maxDeltaPerMinute) or PR.Skills.Client.maxDeltaPerMinute),
        maxXp = math.max(0, math.floor(tonumber(rawSkill.maxXp or rawSkill.maxLevel) or PR.Skills.Defaults.maxXp)),
        levels = #levels > 0 and levels or nil,
    }
end

local function normalizeReputation(rawRep, fallbackName)
    if type(rawRep) ~= 'table' then return nil, 'invalid_reputation' end

    local name = normalizeName(rawRep.name or rawRep.rep or rawRep.code or fallbackName)
    if name == '' then return nil, 'missing_name' end

    local skill = normalizeName(rawRep.skill or rawRep.linkedSkill or rawRep.parentSkill or rawRep.parent)
    if skill ~= '' and not Registry.skills[skill] then return nil, 'skill_not_found' end

    local label = trim(rawRep.label)
    local levels = normalizeLevels(rawRep.levels or rawRep.skillLevels)

    return {
        name = name,
        code = name,
        label = label ~= '' and label or name,
        icon = trim(rawRep.icon) ~= '' and trim(rawRep.icon) or PR.Skills.Defaults.icon,
        skill = skill,
        linkedSkill = skill,
        integration = PR.Skills.normalizeIntegration(rawRep.integration),
        decay = PR.Skills.normalizeDecay(rawRep.decay),
        clientGain = rawRep.clientGain == true,
        maxDeltaPerMinute = math.max(0, tonumber(rawRep.maxDeltaPerMinute) or PR.Skills.Client.maxDeltaPerMinute),
        maxXp = math.max(0, math.floor(tonumber(rawRep.maxXp or rawRep.maxLevel) or PR.Skills.Defaults.maxXp)),
        levels = #levels > 0 and levels or nil,
    }
end

local function mapSkills(skills)
    local mapped = {}

    for key, value in pairs(skills or {}) do
        local skill = normalizeSkill(value, key)
        if skill then
            mapped[skill.name] = skill
        end
    end

    return mapped
end

local function mapReputations(reputations)
    local mapped = {}

    for key, value in pairs(reputations or {}) do
        local reputation = normalizeReputation(value, key)
        if reputation then
            mapped[reputation.name] = reputation
        end
    end

    return mapped
end

local function listItems(items)
    local list = {}

    for _, item in pairs(items or {}) do
        list[#list + 1] = clone(item)
    end

    table.sort(list, function(left, right)
        return tostring(left.label or left.name) < tostring(right.label or right.name)
    end)

    return list
end

function Registry.setAll(data)
    data = type(data) == 'table' and data or {}

    Registry.settings = normalizeSettings(data.settings)
    Registry.skills = mapSkills(data.skills)
    Registry.reputations = mapReputations(data.reputations)
    Registry.revision = Registry.revision + 1
end

function Registry.export()
    return {
        settings = clone(Registry.settings),
        skills = clone(Registry.skills),
        reputations = clone(Registry.reputations),
    }
end

function Registry.payload()
    return {
        settings = clone(Registry.settings),
        skills = listItems(Registry.skills),
        reputations = listItems(Registry.reputations),
        revision = Registry.revision,
    }
end

function Registry.upsertSkill(skill)
    if type(skill) ~= 'table' then return false, 'invalid_definition' end
    if skill.integration and not PR.Skills.normalizeIntegration(skill.integration) then
        return false, 'invalid_integration'
    end
    if Registry.reputations[normalizeName(skill.name or skill.code)] then return false, 'code_used_by_reputation' end
    local normalized, err = normalizeSkill(skill)
    if not normalized then return false, err end

    Registry.skills[normalized.name] = normalized
    Registry.revision = Registry.revision + 1

    return true, normalized
end

function Registry.upsertReputation(reputation)
    if type(reputation) ~= 'table' then return false, 'invalid_definition' end
    if reputation.integration and not PR.Skills.normalizeIntegration(reputation.integration) then
        return false, 'invalid_integration'
    end
    if Registry.skills[normalizeName(reputation.name or reputation.code)] then return false, 'code_used_by_skill' end
    local normalized, err = normalizeReputation(reputation)
    if not normalized then return false, err end

    Registry.reputations[normalized.name] = normalized
    Registry.revision = Registry.revision + 1

    return true, normalized
end

function Registry.removeSkill(name)
    local normalizedName = normalizeName(name)
    if not Registry.skills[normalizedName] then return false, 'not_found' end

    for _, reputation in pairs(Registry.reputations) do
        if reputation.skill == normalizedName then return false, 'skill_has_reputations' end
    end

    Registry.skills[normalizedName] = nil
    Registry.revision = Registry.revision + 1

    return true
end

function Registry.removeReputation(name)
    local normalizedName = normalizeName(name)
    if not Registry.reputations[normalizedName] then return false, 'not_found' end

    Registry.reputations[normalizedName] = nil
    Registry.revision = Registry.revision + 1

    return true
end

function Registry.getSkill(name)
    return clone(Registry.skills[normalizeName(name)])
end

function Registry.getReputation(name)
    return clone(Registry.reputations[normalizeName(name)])
end

function Registry.getDefinition(name)
    local normalizedName = normalizeName(name)
    return clone(Registry.skills[normalizedName] or Registry.reputations[normalizedName])
end

function Registry.getLinkedReputations(skillName)
    local normalizedName = normalizeName(skillName)
    local linked = {}

    for key, reputation in pairs(Registry.reputations) do
        if reputation.skill == normalizedName then
            linked[key] = clone(reputation)
        end
    end

    return linked
end

function Registry.getLevels(definition)
    if definition and type(definition.levels) == 'table' and #definition.levels > 0 then
        return definition.levels
    end

    return Registry.settings.defaultLevels or PR.Skills.Defaults.settings.defaultLevels
end

ForgeCore.SkillRegistry = Registry
