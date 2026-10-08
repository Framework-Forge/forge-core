ForgeCore = ForgeCore or {}

local Registry = {
    jobs = {},
    gangs = {},
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

local function tableHasValues(value)
    return type(value) == 'table' and next(value) ~= nil
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

local function normalizeGrades(grades, groupType)
    local normalized = {}
    local highestGrade = -1

    if tableHasValues(grades) then
        for key, value in pairs(grades) do
            local grade = tonumber(key) or key
            local gradeData = clone(value)

            normalized[grade] = gradeData

            if type(grade) == 'number' and grade > highestGrade then
                highestGrade = grade
            end
        end
    else
        normalized[0] = groupType == 'job'
            and clone(PR.Job.Defaults.job.grades[0])
            or clone(PR.Job.Defaults.gang.grades[0])
        highestGrade = 0
    end

    if highestGrade >= 0 and normalized[highestGrade] then
        normalized[highestGrade].isboss = normalized[highestGrade].isboss ~= false
        normalized[highestGrade].bankAuth = normalized[highestGrade].bankAuth ~= false
    end

    return normalized
end

local function normalizeGroup(rawGroup, forcedType, fallbackName)
    if type(rawGroup) ~= 'table' then return nil, 'invalid_group' end

    local groupType = forcedType or rawGroup.type
    groupType = groupType == 'gang' and 'gang' or 'job'

    local name = normalizeName(rawGroup.name or rawGroup.job or fallbackName)
    if name == '' then return nil, 'missing_name' end

    local defaults = PR.Job.Defaults[groupType] or {}
    local group = clone(defaults)

    for key, value in pairs(rawGroup) do
        group[key] = clone(value)
    end

    group.name = name
    group.job = name
    group.type = groupType
    group.label = trim(group.label) ~= '' and trim(group.label) or name
    group.jobtype = group.jobtype or group.typejob
    group.defaultDuty = group.defaultDuty ~= false
    group.craftings = nil
    group.registers = nil
    group.alarms = nil
    group.bossMenus = nil
    group.applications = nil
    group.stashes = type(group.stashes) == 'table' and group.stashes or {}
    group.grades = normalizeGrades(group.grades, groupType)

    if group.jobtype == 'none' then group.jobtype = nil end

    return group
end

local function mapGroups(groups, forcedType)
    local mapped = {}

    for key, value in pairs(groups or {}) do
        local rawGroup = value
        local fallbackName = key

        if type(key) == 'number' then
            fallbackName = value and (value.name or value.job)
        end

        local group = normalizeGroup(rawGroup, forcedType, fallbackName)
        if group then
            mapped[group.name] = group
        end
    end

    return mapped
end

local function listGroups(groups)
    local list = {}

    for _, group in pairs(groups or {}) do
        list[#list + 1] = clone(group)
    end

    table.sort(list, function(left, right)
        return tostring(left.label or left.name) < tostring(right.label or right.name)
    end)

    return list
end

function Registry.setAll(jobs, gangs)
    Registry.jobs = mapGroups(jobs, 'job')
    Registry.gangs = mapGroups(gangs, 'gang')
    Registry.revision = Registry.revision + 1
end

function Registry.normalizeGroup(group, forcedType)
    return normalizeGroup(group, forcedType)
end

function Registry.upsert(group, forcedType, state)
    state = state or Registry
    local normalized, err = normalizeGroup(group, forcedType)
    if not normalized then return false, err end

    local target = normalized.type == 'gang' and state.gangs or state.jobs
    target[normalized.name] = normalized
    state.revision = state.revision + 1

    return true, normalized
end

function Registry.remove(groupType, name, state)
    state = state or Registry
    local normalizedName = normalizeName(name)
    local target = groupType == 'gang' and state.gangs or state.jobs

    if not target[normalizedName] then return false, 'not_found' end

    target[normalizedName] = nil
    state.revision = state.revision + 1

    return true
end

function Registry.exists(groupType, name)
    local target = groupType == 'gang' and Registry.gangs or Registry.jobs
    return target[normalizeName(name)] ~= nil
end

function Registry.get(groupType, name)
    local target = groupType == 'gang' and Registry.gangs or Registry.jobs
    return clone(target[normalizeName(name)])
end

function Registry.getJobs()
    return clone(Registry.jobs)
end

function Registry.getGangs()
    return clone(Registry.gangs)
end

function Registry.list(groupType)
    return listGroups(groupType == 'gang' and Registry.gangs or Registry.jobs)
end

function Registry.payload()
    return {
        jobs = Registry.list('job'),
        gangs = Registry.list('gang'),
        revision = Registry.revision,
    }
end

ForgeCore.JobRegistry = Registry
