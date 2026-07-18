ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local alertDialog = Shared.alertDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local boolValue = Shared.boolValue
local boolDefault = Shared.boolDefault
local boolOptions = Shared.boolOptions

local actionLocked = false

local function fetchPlayerJobs()
    local ok, payload = awaitServer(PR.MultiJob.Callbacks.getPlayerJobs)
    if not ok then
        notifyFailure('notify.multijob.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.jobs = type(payload.jobs) == 'table' and payload.jobs or {}
    payload.settings = type(payload.settings) == 'table' and payload.settings or {}
    return payload
end

local function fetchSettings()
    local ok, payload = awaitServer(PR.MultiJob.Callbacks.getSettings)
    if not ok then
        notifyFailure('notify.multijob.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.enabled = payload.enabled == true
    payload.maxJobs = tonumber(payload.maxJobs) or PR.MultiJob.Defaults.maxJobs
    payload.allowPlayerRemove = payload.allowPlayerRemove == true
    payload.includeCurrentJob = payload.includeCurrentJob ~= false
    payload.blockedJobs = type(payload.blockedJobs) == 'table' and payload.blockedJobs or {}
    return payload
end

local function blockedText(settings)
    if not settings or type(settings.blockedJobs) ~= 'table' or #settings.blockedJobs == 0 then
        return t('common.none')
    end

    return table.concat(settings.blockedJobs, ', ')
end

function Menu.openMultiJobMenu(parent)
    local payload = fetchPlayerJobs()
    if not payload then return false end

    local jobs = payload.jobs or {}
    local options = {}

    if #jobs == 0 then
        options[#options + 1] = {
            title = t('menu.multijob.no_jobs'),
            description = t('menu.multijob.no_jobs_description'),
            icon = 'briefcase',
            disabled = true,
        }
    end

    for _, job in ipairs(jobs) do
        local active = job.active == true
        local dutyText = active and t('menu.multijob.duty_status', {
            status = job.onDuty == true and t('menu.multijob.duty_on') or t('menu.multijob.duty_off'),
        }) or ''
        local description = t('menu.multijob.job_description', {
            grade = tostring(job.gradeLabel or job.grade or 0),
            payment = tostring(job.payment or 0),
            status = active and ((t('menu.multijob.active') .. ' | ' .. dutyText)) or t('menu.multijob.available'),
        })

        options[#options + 1] = {
            title = job.label or job.name,
            description = description,
            icon = 'briefcase',
            iconColor = active and '#22c55e' or '#ffffff',
            arrow = true,
            onSelect = function()
                Menu.openMultiJobDetails(job, payload.settings or {}, parent or 'forge_core_player_menu')
            end,
        }
    end

    showContext({
        id = 'forge_core_multijob_player',
        title = t('menu.multijob.title'),
        menu = parent or 'forge_core_player_menu',
        options = options,
    })

    return true
end

function Menu.openMultiJobDetails(job, settings, parent)
    local options = {
        {
            title = t('menu.multijob.set_active'),
            description = job.active and t('menu.multijob.already_active') or t('menu.multijob.set_active_description'),
            icon = 'briefcase',
            iconColor = job.active and '#22c55e' or '#ffffff',
            disabled = job.active == true,
            onSelect = function()
                if actionLocked then return end
                actionLocked = true

                local ok, result = awaitServer(PR.MultiJob.Callbacks.setActiveJob, job.name)
                if not ok then
                    notifyFailure('notify.multijob.set_failed', result)
                end

                SetTimeout(500, function()
                    actionLocked = false
                    Menu.openMultiJobMenu(parent)
                end)
            end,
        },
    }

    if job.removable == true then
        options[#options + 1] = {
            title = t('menu.multijob.remove'),
            description = t('menu.multijob.remove_description'),
            icon = 'trash-2',
            iconColor = '#ef4444',
            onSelect = function()
                local confirmed = alertDialog({
                    header = t('dialogs.multijob_remove_header'),
                    content = t('dialogs.multijob_remove_content', { job = job.label or job.name }),
                    centered = true,
                    cancel = true,
                })

                if confirmed ~= 'confirm' then
                    Menu.openMultiJobDetails(job, settings, parent)
                    return
                end

                if actionLocked then return end
                actionLocked = true

                local ok, result = awaitServer(PR.MultiJob.Callbacks.removeOwnJob, job.name)
                if not ok then
                    notifyFailure('notify.multijob.remove_failed', result)
                end

                SetTimeout(500, function()
                    actionLocked = false
                    Menu.openMultiJobMenu(parent)
                end)
            end,
        }
    end

    showContext({
        id = 'forge_core_multijob_details_' .. tostring(job.name),
        title = job.label or job.name,
        menu = 'forge_core_multijob_player',
        options = options,
    })
end

function Menu.openMultiJobAdminMenu()
    local settings = fetchSettings() or PR.MultiJob.Defaults

    showContext({
        id = 'forge_core_multijob_admin',
        title = t('menu.multijob.admin_title'),
        menu = 'forge_core_server_settings',
        options = {
            {
                title = t('menu.multijob.settings'),
                description = t('menu.multijob.settings_summary', {
                    status = settings.enabled and t('common.active') or t('common.inactive'),
                    max = tostring(settings.maxJobs),
                    remove = settings.allowPlayerRemove and t('common.yes') or t('common.no'),
                }),
                icon = 'settings',
                onSelect = function()
                    Menu.openMultiJobSettingsEditor(settings)
                end,
            },
            {
                title = t('menu.multijob.blocked_jobs'),
                description = blockedText(settings),
                icon = 'ban',
                iconColor = '#ef4444',
                onSelect = function()
                    Menu.openMultiJobSettingsEditor(settings)
                end,
            },
            {
                title = t('menu.multijob.admin_add'),
                description = t('menu.multijob.admin_add_description'),
                icon = 'user-plus',
                onSelect = function()
                    Menu.openMultiJobAdminAdd()
                end,
            },
            {
                title = t('menu.multijob.admin_remove'),
                description = t('menu.multijob.admin_remove_description'),
                icon = 'user-minus',
                onSelect = function()
                    Menu.openMultiJobAdminRemove()
                end,
            },
            {
                title = t('menu.multijob.admin_view'),
                description = t('menu.multijob.admin_view_description'),
                icon = 'search',
                onSelect = function()
                    Menu.openMultiJobAdminView()
                end,
            },
        },
    })
end

function Menu.openMultiJobSettingsEditor(settings)
    settings = type(settings) == 'table' and settings or {}

    local result = inputDialog(t('menu.multijob.settings'), {
        {
            type = 'select',
            label = t('inputs.multijob_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.enabled),
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.multijob_max_jobs'),
            default = tonumber(settings.maxJobs) or PR.MultiJob.Defaults.maxJobs,
            required = true,
            min = -1,
            max = 50,
        },
        {
            type = 'select',
            label = t('inputs.multijob_allow_remove'),
            options = boolOptions(),
            default = boolDefault(settings.allowPlayerRemove),
            required = true,
        },
        {
            type = 'textarea',
            label = t('inputs.multijob_blocked_jobs'),
            description = t('inputs.multijob_blocked_jobs_description'),
            default = blockedText(settings),
            required = false,
        },
    })

    if not result then
        Menu.openMultiJobAdminMenu()
        return
    end

    local blocked = {}
    for value in tostring(result[4] or ''):gmatch('[^,%s]+') do
        blocked[#blocked + 1] = value
    end

    local ok, response = awaitServer(PR.MultiJob.Callbacks.saveSettings, {
        enabled = boolValue(result[1]),
        maxJobs = tonumber(result[2]) or PR.MultiJob.Defaults.maxJobs,
        allowPlayerRemove = boolValue(result[3]),
        includeCurrentJob = true,
        blockedJobs = blocked,
    })

    if not ok then
        notifyFailure('notify.multijob.save_failed', response)
    end

    SetTimeout(500, function()
        Menu.openMultiJobAdminMenu()
    end)
end

function Menu.openMultiJobAdminAdd()
    local result = inputDialog(t('menu.multijob.admin_add'), {
        { type = 'number', label = t('inputs.player_id'), required = true, min = 1 },
        { type = 'input', label = t('inputs.job_code'), required = true },
        { type = 'number', label = t('inputs.grade_level'), required = true, min = 0 },
    })

    if not result then
        Menu.openMultiJobAdminMenu()
        return
    end

    local ok, response = awaitServer(PR.MultiJob.Callbacks.addJob, tonumber(result[1]), tostring(result[2] or ''), tonumber(result[3]) or 0)
    if not ok then notifyFailure('notify.multijob.add_failed', response) end

    SetTimeout(500, function()
        Menu.openMultiJobAdminMenu()
    end)
end

function Menu.openMultiJobAdminRemove()
    local result = inputDialog(t('menu.multijob.admin_remove'), {
        { type = 'number', label = t('inputs.player_id'), required = true, min = 1 },
        { type = 'input', label = t('inputs.job_code'), required = true },
    })

    if not result then
        Menu.openMultiJobAdminMenu()
        return
    end

    local ok, response = awaitServer(PR.MultiJob.Callbacks.removeJob, tonumber(result[1]), tostring(result[2] or ''))
    if not ok then notifyFailure('notify.multijob.remove_failed', response) end

    SetTimeout(500, function()
        Menu.openMultiJobAdminMenu()
    end)
end

function Menu.openMultiJobAdminView()
    local result = inputDialog(t('menu.multijob.admin_view'), {
        { type = 'number', label = t('inputs.player_id'), required = true, min = 1 },
    })

    if not result then
        Menu.openMultiJobAdminMenu()
        return
    end

    local ok, payload = awaitServer(PR.MultiJob.Callbacks.getTargetJobs, tonumber(result[1]))
    if not ok then
        notifyFailure('notify.multijob.load_failed', payload)
        SetTimeout(500, function()
            Menu.openMultiJobAdminMenu()
        end)
        return
    end

    local jobs = type(payload) == 'table' and type(payload.jobs) == 'table' and payload.jobs or {}
    local options = {}

    if #jobs == 0 then
        options[#options + 1] = {
            title = t('menu.multijob.no_jobs'),
            icon = 'briefcase',
            disabled = true,
        }
    end

    for _, job in ipairs(jobs) do
        options[#options + 1] = {
            title = job.label or job.name,
            description = t('menu.multijob.job_description', {
                grade = tostring(job.gradeLabel or job.grade or 0),
                payment = tostring(job.payment or 0),
                status = job.active and t('menu.multijob.active') or t('menu.multijob.available'),
            }),
            icon = 'briefcase',
            iconColor = job.active and '#22c55e' or '#ffffff',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_multijob_admin_view',
        title = t('menu.multijob.admin_view'),
        menu = 'forge_core_multijob_admin',
        options = options,
    })
end
