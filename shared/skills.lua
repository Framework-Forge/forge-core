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

PR.Skills.Calculation = {
    direct = 'direct',
    sumReputations = 'sum_reputations',
}

PR.Skills.Defaults = {
    icon = 'book-open',
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
