PR = PR or {}
PR.MultiJob = PR.MultiJob or {}

PR.MultiJob.Storage = {
    file = 'data/multijob.json',
}

PR.MultiJob.Defaults = {
    enabled = true,
    maxJobs = 3,
    allowPlayerRemove = true,
    includeCurrentJob = true,
    blockedJobs = {
        'unemployed',
    },
}

PR.MultiJob.Callbacks = {
    getSettings = 'forge-core:server:multijob:getSettings',
    saveSettings = 'forge-core:server:multijob:saveSettings',
    getPlayerJobs = 'forge-core:server:multijob:getPlayerJobs',
    setActiveJob = 'forge-core:server:multijob:setActiveJob',
    removeOwnJob = 'forge-core:server:multijob:removeOwnJob',
    addJob = 'forge-core:server:multijob:addJob',
    removeJob = 'forge-core:server:multijob:removeJob',
    getTargetJobs = 'forge-core:server:multijob:getTargetJobs',
}
