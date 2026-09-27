PR = PR or {}
PR.AutoMedic = PR.AutoMedic or {}

PR.AutoMedic.Storage = {
    file = 'data/automedic.json',
}

PR.AutoMedic.Callbacks = {
    getSettings = 'forge-core:server:automedic:getSettings',
    saveSettings = 'forge-core:server:automedic:saveSettings',
    getStatus = 'forge-core:server:automedic:getStatus',
    requestTreatment = 'forge-core:server:automedic:requestTreatment',
    completeTreatment = 'forge-core:server:automedic:completeTreatment',
    cancelTreatment = 'forge-core:server:automedic:cancelTreatment',
}

PR.AutoMedic.Events = {
    sync = 'forge-core:client:automedic:sync',
    reportDeath = 'forge-core:server:automedic:reportDeath',
    revive = 'forge-core:client:automedic:revive',
}

PR.AutoMedic.Defaults = {
    enabled = true,
    cooldown = 300,
    bandageHealPercent = 10,
    treatmentPrice = 0,
    reviveHealthPercent = 10,
    loseInventory = {
        gunshot = true,
        other = true,
        collapse = false,
    },
}

PR.AutoMedic.Npc = {
    model = 's_m_m_paramedic_01',
    spawnMinDistance = 25.0,
    spawnMaxDistance = 40.0,
    treatmentDistance = 2.0,
    treatmentDuration = 10000,
    walkSpeed = 2.0,
    arrivalTimeout = 90000,
    crowdControl = {
        enabled = true,
        dict = 'amb@code_human_police_crowd_control@idle_a',
        clip = 'idle_a',
        duration = 2200,
    },
    treatmentPosition = {
        sideOffset = 0.72,
        forwardOffset = 0.18,
        verticalOffset = 0.0,
        groundTolerance = 1.25,
        exactDistance = 0.16,
        snapDistance = 0.65,
        approachTimeout = 8000,
    },
    patientPosition = {
        dict = 'mini@cpr@char_b@cpr_def',
        clip = 'cpr_pumpchest_idle',
    },
    wakeup = {
        enabled = true,
        duration = 13000,
        fadeLeadTime = 900,
        sceneZOffset = -1.0,
        maleDict = 'anim@scripted@heist@ig25_beach@male@',
        femaleDict = 'anim@scripted@heist@ig25_beach@heeled@',
    },
}
