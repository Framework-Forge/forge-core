PR = PR or {}
PR.Skills = PR.Skills or {}

PR.Skills.Storage = {
    file = 'data/skills.json',
    playerColumn = 'skills',
}

PR.Skills.Callbacks = {
    getAll = 'forge-core:server:skills:getAll',
    openAdmin = 'forge-core:client:skills:openAdmin',
    saveSkill = 'forge-core:server:skills:skill:save',
    deleteSkill = 'forge-core:server:skills:skill:delete',
    saveReputation = 'forge-core:server:skills:reputation:save',
    deleteReputation = 'forge-core:server:skills:reputation:delete',
    fetchPlayer = 'forge-core:server:skills:player:fetch',
    addXp = 'forge-core:server:skills:xp:add',
}

PR.Skills.Commands = {
    admin = 'forgeskills',
    viewSkills = 'skills',
    viewReputations = 'reps',
}

-- Client deltas are mirrored to the server cache; the QBX save cycle persists them.
PR.Skills.Client = { mirrorMs = 1000, maxDeltaPerMinute = 100 }

function PR.Skills.normalizeIntegration(value)
    value = type(value) == 'table' and value or {}
    local resource = tostring(value.resource or ''):match('^%s*(.-)%s*$')
    local name = tostring(value.export or ''):match('^%s*(.-)%s*$')
    if resource == '' and name == '' then return nil end
    if not resource:match('^[%w_%-]+$') or not name:match('^[%w_]+$') then return nil end
    local multiplier = tonumber(value.multiplier) or 1
    if multiplier ~= multiplier or multiplier < 0 or multiplier > 10000 then multiplier = 1 end
    return { resource = resource, export = name, identifier = tostring(value.identifier or ''),
        multiplier = multiplier, gains = value.gains ~= false, losses = value.losses ~= false }
end

function PR.Skills.normalizeDecay(value)
    value = type(value) == 'table' and value or {}
    local amount = tonumber(value.amount) or 0
    local interval = tonumber(value.intervalMs) or 300000
    if amount ~= amount or amount < 0 or amount > 1000000 then amount = 0 end
    if interval ~= interval or interval < 10000 or interval > 86400000 then interval = 300000 end
    return { enabled = value.enabled == true and amount > 0, amount = amount, intervalMs = interval }
end

PR.Skills.Calculation = {
    direct = 'direct',
    sumReputations = 'sum_reputations',
}

PR.Skills.Defaults = {
    icon = 'book-fill',
    maxXp = 1000000000,
    settings = {
        enabled = true,
        defaultLevels = {
            { title = 'Nivel 0', from = 0, to = 100 },
            { title = 'Nivel 1', from = 100, to = 250 },
            { title = 'Nivel 2', from = 250, to = 500 },
            { title = 'Nivel 3', from = 500, to = 1000 },
            { title = 'Nivel 4', from = 1000, to = 2000 },
        },
    },
}
