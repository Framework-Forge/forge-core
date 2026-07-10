ForgeCore = ForgeCore or {}

local LOAD_CALLBACK = 'forge-core:server:plugin:load'
local ACTION_CALLBACK = 'forge-core:server:plugin:action'

local plugins = {
    {
        id = 'forge-afk',
        label = ForgeCore.t('plugins.afk.label'),
        icon = 'clock',
        module = 'afk',
        order = 10,
        description = ForgeCore.t('plugins.afk.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            save = ForgeCore.t('plugins.actions.save_config'),
        },
        fields = {
            {
                path = 'enabled',
                type = 'boolean',
                label = ForgeCore.t('inputs.afk_enabled'),
                action = 'save',
                options = {
                    { label = ForgeCore.t('common.yes'), value = true },
                    { label = ForgeCore.t('common.no'), value = false },
                },
            },
            {
                path = 'minutes',
                type = 'number',
                label = ForgeCore.t('inputs.afk_minutes'),
                min = 1,
                max = 240,
                step = 1,
                action = 'save',
            },
        },
    },
    {
        id = 'forge-density',
        label = ForgeCore.t('plugins.density.label'),
        icon = 'activity',
        module = 'density',
        order = 20,
        description = ForgeCore.t('plugins.density.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            save = ForgeCore.t('plugins.actions.save_config'),
        },
        fields = {
            { path = 'enabled', type = 'boolean', label = ForgeCore.t('inputs.density_enabled'), action = 'save', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'disableAll', type = 'boolean', label = ForgeCore.t('inputs.density_disable_all'), action = 'save', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'disableDispatchServices', type = 'boolean', label = ForgeCore.t('inputs.density_disable_dispatch'), action = 'save', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'values.parked', type = 'number', label = ForgeCore.t('inputs.density_parked'), min = 0, max = 1, step = 0.1, action = 'save' },
            { path = 'values.vehicle', type = 'number', label = ForgeCore.t('inputs.density_vehicle'), min = 0, max = 1, step = 0.1, action = 'save' },
            { path = 'values.multiplier', type = 'number', label = ForgeCore.t('inputs.density_multiplier'), min = 0, max = 1, step = 0.1, action = 'save' },
            { path = 'values.peds', type = 'number', label = ForgeCore.t('inputs.density_peds'), min = 0, max = 1, step = 0.1, action = 'save' },
            { path = 'values.scenario', type = 'number', label = ForgeCore.t('inputs.density_scenario'), min = 0, max = 1, step = 0.1, action = 'save' },
            { path = 'pedPopulationBudget', type = 'number', label = ForgeCore.t('inputs.density_ped_budget'), min = 0, max = 3, step = 1, action = 'save' },
            { path = 'vehiclePopulationBudget', type = 'number', label = ForgeCore.t('inputs.density_vehicle_budget'), min = 0, max = 3, step = 1, action = 'save' },
            { path = 'blacklist.enabled', type = 'boolean', label = ForgeCore.t('inputs.density_blacklist_enabled'), action = 'save', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
        },
    },
    {
        id = 'forge-job',
        label = ForgeCore.t('plugins.job.label'),
        icon = 'briefcase',
        module = 'job',
        order = 30,
        description = ForgeCore.t('plugins.job.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            saveGroup = ForgeCore.t('plugins.actions.save_group'),
            deleteGroup = ForgeCore.t('plugins.actions.delete_group'),
            savePayments = ForgeCore.t('plugins.actions.save_payments'),
            saveMei = ForgeCore.t('plugins.actions.save_mei'),
            createMei = ForgeCore.t('plugins.actions.create_mei'),
            forcePayment = ForgeCore.t('plugins.actions.force_payment'),
        },
        fields = {
            { path = 'payments.enabled', type = 'boolean', label = ForgeCore.t('inputs.payment_enabled'), action = 'savePayments', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'payments.intervalMinutes', type = 'number', label = ForgeCore.t('inputs.payment_interval'), min = 1, max = 1440, step = 1, action = 'savePayments' },
            { path = 'payments.account', type = 'select', label = ForgeCore.t('inputs.payment_account'), action = 'savePayments', options = { { label = ForgeCore.t('payments.accounts.bank'), value = 'bank' }, { label = ForgeCore.t('payments.accounts.cash'), value = 'cash' }, { label = ForgeCore.t('payments.accounts.crypto'), value = 'crypto' } } },
            { path = 'payments.payOffDuty', type = 'boolean', label = ForgeCore.t('inputs.pay_off_duty'), action = 'savePayments', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'payments.useSociety', type = 'boolean', label = ForgeCore.t('inputs.use_society'), action = 'savePayments', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'payments.notify', type = 'boolean', label = ForgeCore.t('inputs.notify_payment'), action = 'savePayments', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'payments.mei.enabled', type = 'boolean', label = ForgeCore.t('inputs.mei_enabled'), action = 'saveMei', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'payments.mei.openingCost', type = 'number', label = ForgeCore.t('inputs.mei_opening_cost'), min = 0, max = 100000000, step = 1, action = 'saveMei' },
            { path = 'payments.mei.monthlyCost', type = 'number', label = ForgeCore.t('inputs.mei_monthly_cost'), min = 0, max = 100000000, step = 1, action = 'saveMei' },
            { path = 'payments.mei.governmentAccount', type = 'text', label = ForgeCore.t('inputs.mei_government_account'), action = 'saveMei' },
            { path = 'payments.mei.paymentAccount', type = 'select', label = ForgeCore.t('inputs.mei_payment_account'), action = 'saveMei', options = { { label = ForgeCore.t('payments.accounts.bank'), value = 'bank' }, { label = ForgeCore.t('payments.accounts.cash'), value = 'cash' }, { label = ForgeCore.t('payments.accounts.crypto'), value = 'crypto' } } },
        },
    },
    {
        id = 'forge-password',
        label = ForgeCore.t('plugins.password.label'),
        icon = 'lock',
        module = 'password',
        order = 40,
        description = ForgeCore.t('plugins.password.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            save = ForgeCore.t('plugins.actions.save_config'),
        },
        fields = {
            { path = 'enabled', type = 'boolean', label = ForgeCore.t('inputs.password_enabled'), action = 'save', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'password', type = 'text', label = ForgeCore.t('inputs.server_password'), action = 'save' },
            { path = 'supportLink', type = 'text', label = ForgeCore.t('inputs.password_support_link'), action = 'save' },
            { path = 'cardTitle', type = 'text', label = ForgeCore.t('inputs.password_card_title'), action = 'save' },
            { path = 'cardDescription', type = 'textarea', label = ForgeCore.t('inputs.password_card_description'), action = 'save' },
            { path = 'placeholder', type = 'text', label = ForgeCore.t('inputs.password_placeholder'), action = 'save' },
            { path = 'submitText', type = 'text', label = ForgeCore.t('inputs.password_submit_text'), action = 'save' },
        },
    },
    {
        id = 'forge-skill',
        label = ForgeCore.t('plugins.skill.label'),
        icon = 'book-open',
        module = 'skill',
        order = 50,
        description = ForgeCore.t('plugins.skill.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            saveSkill = ForgeCore.t('plugins.actions.save_skill'),
            deleteSkill = ForgeCore.t('plugins.actions.delete_skill'),
            saveReputation = ForgeCore.t('plugins.actions.save_reputation'),
            deleteReputation = ForgeCore.t('plugins.actions.delete_reputation'),
        },
        fields = {
            { path = 'skill.name', type = 'text', label = ForgeCore.t('inputs.code'), action = 'saveSkill' },
            { path = 'skill.label', type = 'text', label = ForgeCore.t('inputs.display_name'), action = 'saveSkill' },
            { path = 'skill.icon', type = 'text', label = ForgeCore.t('inputs.skill_icon'), action = 'saveSkill' },
            { path = 'skill.calculation', type = 'select', label = ForgeCore.t('inputs.skill_calculation'), action = 'saveSkill', options = { { label = ForgeCore.t('skills.calculation.direct'), value = 'direct' }, { label = ForgeCore.t('skills.calculation.sum_reputations'), value = 'sum_reputations' } } },
            { path = 'skill.maxXp', type = 'number', label = ForgeCore.t('inputs.skill_max_xp'), min = 1, max = 100000000, step = 1, action = 'saveSkill' },
            { path = 'reputation.name', type = 'text', label = ForgeCore.t('inputs.code'), action = 'saveReputation' },
            { path = 'reputation.label', type = 'text', label = ForgeCore.t('inputs.display_name'), action = 'saveReputation' },
            { path = 'reputation.skill', type = 'text', label = ForgeCore.t('inputs.parent_skill'), action = 'saveReputation' },
            { path = 'reputation.maxXp', type = 'number', label = ForgeCore.t('inputs.skill_max_xp'), min = 1, max = 100000000, step = 1, action = 'saveReputation' },
        },
    },
    {
        id = 'forge-staff',
        label = ForgeCore.t('plugins.staff.label'),
        icon = 'shield',
        module = 'staff',
        order = 60,
        description = ForgeCore.t('plugins.staff.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            add = ForgeCore.t('plugins.actions.add_staff'),
            remove = ForgeCore.t('plugins.actions.remove_staff'),
        },
        fields = {
            { path = 'data.target', type = 'number', label = ForgeCore.t('inputs.player_id'), min = 1, max = 9999, step = 1, action = 'add' },
            { path = 'data.role', type = 'text', label = ForgeCore.t('inputs.staff_role'), action = 'add' },
        },
    },
    {
        id = 'forge-weapon',
        label = ForgeCore.t('plugins.weapon.label'),
        icon = 'target',
        module = 'weapon',
        order = 70,
        description = ForgeCore.t('plugins.weapon.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            save = ForgeCore.t('plugins.actions.save_weapon'),
            delete = ForgeCore.t('plugins.actions.delete_weapon'),
            setActive = ForgeCore.t('plugins.actions.set_weapon_active'),
        },
        fields = {
            { path = 'weapon.name', type = 'text', label = ForgeCore.t('inputs.weapon_name'), action = 'save' },
            { path = 'weapon.label', type = 'text', label = ForgeCore.t('inputs.weapon_label'), action = 'save' },
            { path = 'weapon.category', type = 'text', label = ForgeCore.t('inputs.weapon_category'), action = 'save' },
            { path = 'weapon.ammotype', type = 'text', label = ForgeCore.t('inputs.weapon_ammo'), action = 'save' },
            { path = 'weapon.damageReason', type = 'text', label = ForgeCore.t('inputs.weapon_damage_reason'), action = 'save' },
            { path = 'weapon.active', type = 'boolean', label = ForgeCore.t('weapons.title'), action = 'save', options = { { label = ForgeCore.t('menu.weapons.status_active'), value = true }, { label = ForgeCore.t('menu.weapons.status_inactive'), value = false } } },
        },
    },
    {
        id = 'forge-weather',
        label = ForgeCore.t('plugins.weather.label'),
        icon = 'cloud-sun',
        module = 'weather',
        order = 80,
        description = ForgeCore.t('plugins.weather.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            setWeather = ForgeCore.t('plugins.actions.set_weather'),
            setDuration = ForgeCore.t('plugins.actions.set_duration'),
            addWeather = ForgeCore.t('plugins.actions.add_weather'),
            removeWeather = ForgeCore.t('plugins.actions.remove_weather'),
            setTime = ForgeCore.t('plugins.actions.set_time'),
            setTimeScale = ForgeCore.t('plugins.actions.set_time_scale'),
            setFreezeTime = ForgeCore.t('plugins.actions.set_freeze_time'),
        },
        fields = {
            { path = 'weather', type = 'select', label = ForgeCore.t('inputs.weather_type'), action = 'setWeather', options = (function()
                local result = {}
                for _, weather in ipairs(PR.Weather.Types or {}) do
                    result[#result + 1] = { label = weather.label or weather.value, value = weather.value }
                end
                return result
            end)() },
            { path = 'duration', type = 'number', label = ForgeCore.t('inputs.weather_duration'), min = 1, max = 1440, step = 1, action = 'setDuration' },
            { path = 'currentTime.hour', type = 'number', label = ForgeCore.t('inputs.time_hour'), min = 0, max = 23, step = 1, action = 'setTime' },
            { path = 'currentTime.minute', type = 'number', label = ForgeCore.t('inputs.time_minute'), min = 0, max = 59, step = 1, action = 'setTime' },
            { path = 'freezeTime', type = 'boolean', label = ForgeCore.t('inputs.freeze_time'), action = 'setFreezeTime', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'timeScale', type = 'number', label = ForgeCore.t('inputs.time_scale'), min = 2000, max = 60000, step = 1000, action = 'setTimeScale' },
        },
    },
    {
        id = 'forge-whitelist',
        label = ForgeCore.t('plugins.whitelist.label'),
        icon = 'user-check',
        module = 'whitelist',
        order = 90,
        description = ForgeCore.t('plugins.whitelist.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            saveConfig = ForgeCore.t('plugins.actions.save_config'),
            add = ForgeCore.t('plugins.actions.add_whitelist'),
            remove = ForgeCore.t('plugins.actions.remove_whitelist'),
            ban = ForgeCore.t('plugins.actions.ban_player'),
        },
        fields = {
            { path = 'config.enabled', type = 'boolean', label = ForgeCore.t('inputs.whitelist_enabled'), action = 'saveConfig', options = { { label = ForgeCore.t('common.yes'), value = true }, { label = ForgeCore.t('common.no'), value = false } } },
            { path = 'config.percent', type = 'number', label = ForgeCore.t('inputs.whitelist_percent'), min = 1, max = 100, step = 1, action = 'saveConfig' },
            { path = 'config.loadNotify', type = 'textarea', label = ForgeCore.t('inputs.whitelist_load_notify'), action = 'saveConfig' },
            { path = 'config.escapeNotify', type = 'textarea', label = ForgeCore.t('inputs.whitelist_escape_notify'), action = 'saveConfig' },
            { path = 'config.startExamLabel', type = 'text', label = ForgeCore.t('inputs.whitelist_start_label'), action = 'saveConfig' },
            { path = 'identifier', type = 'text', label = ForgeCore.t('inputs.whitelist_identifier'), description = ForgeCore.t('inputs.whitelist_identifier_description'), action = 'add' },
            { path = 'data.identifier', type = 'text', label = ForgeCore.t('inputs.whitelist_identifier'), description = ForgeCore.t('inputs.whitelist_identifier_description'), action = 'ban' },
            { path = 'data.reason', type = 'text', label = ForgeCore.t('inputs.ban_reason'), action = 'ban' },
            { path = 'data.hours', type = 'number', label = ForgeCore.t('inputs.ban_hours'), min = 0, max = 24, step = 1, action = 'ban' },
            { path = 'data.days', type = 'number', label = ForgeCore.t('inputs.ban_days'), min = 0, max = 3650, step = 1, action = 'ban' },
            { path = 'data.months', type = 'number', label = ForgeCore.t('inputs.ban_months'), min = 0, max = 120, step = 1, action = 'ban' },
        },
    },
}

local registered = {}

local function registerPlugin(item)
    if GetResourceState('forge-management') ~= 'started' then return false end

    local ok, reason = exports['forge-management']:RegisterPlugin({
        id = item.id,
        label = item.label,
        icon = item.icon,
        renderer = 'native',
        native = {
            module = item.module,
            load = item.load,
            action = item.action,
            actions = item.actions,
            fields = item.fields,
        },
        requiredPerms = {
            ('%s.admin'):format(item.id),
        },
        capabilities = {
            'theme',
            'close',
            'health',
            'read',
            'write',
            'delete',
        },
        capabilityPerms = {
            write = { PR.AdminAce or 'forge-core.admin' },
            delete = { PR.AdminAce or 'forge-core.admin' },
        },
        minProtocolVersion = 2,
        category = 'forge-core',
        order = item.order,
        description = item.description,
        version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or 'dev',
    })

    if not ok then
        print(ForgeCore.t('plugins.rejected', { id = item.id, reason = tostring(reason) }))
        return false
    end

    registered[item.id] = true
    return true
end

local function registerAllPlugins()
    if GetResourceState('forge-management') ~= 'started' then return end

    for i = 1, #plugins do
        registerPlugin(plugins[i])
    end
end

local function unregisterAllPlugins()
    if GetResourceState('forge-management') ~= 'started' then return end

    for id in pairs(registered) do
        exports['forge-management']:UnregisterPlugin(id)
        registered[id] = nil
    end
end

local modules = {}

for i = 1, #plugins do
    modules[plugins[i].module] = plugins[i]
end

local function loadModule(source, module)
    if module == 'afk' then
        if not ForgeCore.AfkService.canManage(source) then return false, 'no_permission' end
        return true, ForgeCore.AfkService.getSettings()
    elseif module == 'density' then
        if not ForgeCore.DensityService.canManage(source) then return false, 'no_permission' end
        return true, ForgeCore.DensityService.getSettings()
    elseif module == 'job' then
        if not ForgeCore.JobService.started then ForgeCore.JobService.start() end
        return true, ForgeCore.JobService.getPayload()
    elseif module == 'password' then
        if not ForgeCore.PasswordService.canManage(source) then return false, 'no_permission' end
        return true, ForgeCore.PasswordService.getSafeSettings()
    elseif module == 'skill' then
        return true, ForgeCore.SkillService.getPayload()
    elseif module == 'staff' then
        if not ForgeCore.StaffService.canManage(source) then return false, 'no_permission' end
        return true, ForgeCore.StaffService.list()
    elseif module == 'weapon' then
        if not ForgeCore.WeaponService.canManage(source) then return false, 'no_permission' end
        return true, ForgeCore.WeaponService.getPayload()
    elseif module == 'weather' then
        local ok, state = ForgeCore.WeatherService.getState(source)
        if not ok then return ok, state end
        state = type(state) == 'table' and state or {}
        state.weather = state.currentWeather and state.currentWeather.weather or state.weather
        state.duration = state.currentWeather and state.currentWeather.time or state.duration
        return true, state
    elseif module == 'whitelist' then
        local configOk, config = ForgeCore.WhitelistService.canManage(source) and true or false, nil
        if not configOk then return false, 'no_permission' end
        config = ForgeCore.WhitelistService.getConfig()
        local playersOk, players = ForgeCore.WhitelistService.listPlayers(source)
        return true, {
            config = config,
            players = playersOk and players or {},
            playersError = playersOk and nil or players,
        }
    end

    return false, 'invalid_module'
end

local function runAction(source, module, action, payload)
    payload = type(payload) == 'table' and payload or {}

    if not modules[module] or not modules[module].actions[action] then
        return false, 'invalid_action'
    end

    if module == 'afk' and action == 'save' then
        return ForgeCore.AfkService.save(source, payload.settings or payload)
    elseif module == 'density' and action == 'save' then
        return ForgeCore.DensityService.save(source, payload.settings or payload)
    elseif module == 'job' then
        if action == 'saveGroup' then return ForgeCore.JobService.upsert(source, payload.group, payload.group and payload.group.type) end
        if action == 'deleteGroup' then return ForgeCore.JobService.delete(source, payload.groupType, payload.name) end
        if action == 'savePayments' then return ForgeCore.JobPayments.update(source, payload.settings or payload.payments or payload) end
        if action == 'saveMei' then return ForgeCore.JobPayments.updateMei(source, payload.settings or (payload.payments and payload.payments.mei) or payload.mei or payload) end
        if action == 'createMei' then return ForgeCore.JobService.createMei(source, payload.data or payload) end
        if action == 'forcePayment' then return ForgeCore.JobPayments.force(source) end
    elseif module == 'password' and action == 'save' then
        return ForgeCore.PasswordService.save(source, payload.settings or payload)
    elseif module == 'skill' then
        if action == 'saveSkill' then return ForgeCore.SkillService.upsertSkill(source, payload.skill or payload) end
        if action == 'deleteSkill' then return ForgeCore.SkillService.deleteSkill(source, payload.name) end
        if action == 'saveReputation' then return ForgeCore.SkillService.upsertReputation(source, payload.reputation or payload) end
        if action == 'deleteReputation' then return ForgeCore.SkillService.deleteReputation(source, payload.name) end
    elseif module == 'staff' then
        if action == 'add' then return ForgeCore.StaffService.add(source, payload.data or payload) end
        if action == 'remove' then return ForgeCore.StaffService.remove(source, payload.data or payload) end
    elseif module == 'weapon' then
        if action == 'save' then return ForgeCore.WeaponService.upsert(source, payload.weapon or payload) end
        if action == 'delete' then return ForgeCore.WeaponService.delete(source, payload.name) end
        if action == 'setActive' then return ForgeCore.WeaponService.setActive(source, payload.name, payload.active == true) end
    elseif module == 'weather' then
        if action == 'setWeather' then return ForgeCore.WeatherService.setWeather(source, payload.index or 1, payload.weather, payload.event or payload.currentWeather) end
        if action == 'setDuration' then return ForgeCore.WeatherService.setDuration(source, payload.index or 1, payload.duration, payload.event or payload.currentWeather) end
        if action == 'addWeather' then return ForgeCore.WeatherService.addWeather(source, payload.data or payload) end
        if action == 'removeWeather' then return ForgeCore.WeatherService.removeWeather(source, payload.index, payload.event) end
        if action == 'setTime' then return ForgeCore.WeatherService.setTime(source, payload.hour or (payload.currentTime and payload.currentTime.hour), payload.minute or (payload.currentTime and payload.currentTime.minute)) end
        if action == 'setTimeScale' then return ForgeCore.WeatherService.setTimeScale(source, payload.scale or payload.timeScale) end
        if action == 'setFreezeTime' then return ForgeCore.WeatherService.setFreezeTime(source, payload.enabled == true or payload.freezeTime == true) end
    elseif module == 'whitelist' then
        if action == 'saveConfig' then return ForgeCore.WhitelistService.saveConfig(source, payload.config or payload) end
        if action == 'add' then return ForgeCore.WhitelistService.add(source, payload.identifier) end
        if action == 'remove' then return ForgeCore.WhitelistService.remove(source, payload.identifier) end
        if action == 'ban' then return ForgeCore.WhitelistService.ban(source, payload.data or payload) end
    end

    return false, 'invalid_action'
end

pr_lib.callback.register(LOAD_CALLBACK, function(source, module)
    return loadModule(source, tostring(module or ''))
end)

pr_lib.callback.register(ACTION_CALLBACK, function(source, module, action, payload)
    return runAction(source, tostring(module or ''), tostring(action or ''), payload)
end)

AddEventHandler('forge-management:server:pluginsReady', registerAllPlugins)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'forge-management' or resourceName == GetCurrentResourceName() then
        SetTimeout(500, registerAllPlugins)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        unregisterAllPlugins()
    end
end)
