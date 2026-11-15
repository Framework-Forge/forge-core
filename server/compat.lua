-- Private server exports, never network events. The facade itself runs in
-- pr_bridge; other trusted server resources need explicit resource ACE access.
local function trusted()
    local caller = GetInvokingResource()
    assert(caller == 'pr_bridge' or caller and IsPrincipalAceAllowed('resource.' .. caller, 'forge-core.compat'),
        'Forge compatibility service: server resource not authorized')
end
local function player(source)
    return assert(exports.qbx_core:GetPlayer(tonumber(source)), 'Invalid player')
end
exports('CompatCreateJob', function(input)
    trusted()
    local H = pr_lib.load('@pr_bridge/bridge/frameworks/compat_helpers')
    local native = exports.qbx_core:GetJobs()[input.name]
    local job, added = H.qbJob(input, native)
    if not added then return false, 'job_or_grades_exist' end
    local existing = ForgeCore.JobRegistry.jobs[input.name]
    local group = H.copy(existing or {})
    group.name = input.name
    group.label = job.label
    group.jobtype = job.type
    group.grades = job.grades
    group.defaultDuty = job.defaultDuty
    group.offDutyPay = job.offDutyPay
    -- Console authority here is used only after validating the calling server
    -- resource. Clients cannot invoke this export or impersonate source 0.
    local ok, result = ForgeCore.JobService.upsert(0, group, 'job')
    if not ok then return false, result end
    local live = exports.qbx_core:GetJobs()[input.name]
    if not live then return false, 'core_sync_failed' end
    for key in pairs(job.grades) do
        if not (live.grades[key] or live.grades[tonumber(key)]) then return false, 'core_grade_sync_failed' end
    end
    return true, result
end)
exports('CompatRefreshJobs', function()
    trusted()
    if not ForgeCore.JobService.reload() then return false, 'reload_failed' end
    return exports.qbx_core:GetJobs()
end)
exports('CompatRefreshJob', function(name)
    trusted()
    -- Forge's registry sync is catalog-wide; do not replace it with ESX SQL.
    if not ForgeCore.JobService.reload() then return false, 'reload_failed' end
    return exports.qbx_core:GetJobs()[name]
end)
exports('CompatAddItems', function(items)
    trusted()
    assert(type(items) == 'table', 'Invalid item definitions')
    return ForgeCore.InventoryService.addCompatibilityItems(items)
end)
exports('CompatRefreshItems', function()
    trusted()
    if not ForgeCore.InventoryService.reload() then return false, 'reload_failed' end
    local count = 0
    for _ in pairs(exports.ox_inventory:Items()) do count = count + 1 end
    return count
end)
exports('CompatIsPaycheckEnabled', function(source)
    trusted()
    return (player(source).PlayerData.metadata or {}).prCompatPaycheckEnabled ~= false
end)
exports('CompatTogglePaycheck', function(source, enabled)
    trusted()
    assert(type(enabled) == 'boolean', 'Paycheck state must be boolean')
    local p = player(source)
    p.Functions.SetMetaData('prCompatPaycheckEnabled', enabled)
    p.Functions.Save()
    return p.PlayerData.metadata.prCompatPaycheckEnabled == enabled
end)
