return function(ports)
    local PR,services,native,translate=assert(ports.config),assert(ports.services),assert(ports.native),assert(ports.translate)
    local managementIntegration,print=assert(ports.managementIntegration),assert(ports.print)
    for _,n in ipairs({'resourceState','registerPlugin','unregisterPlugin'})do assert(type(managementIntegration[n])=='function','explicit PR plugin contract required: '..n)end
    local GetCurrentResourceName,GetResourceMetadata,SetTimeout=assert(native.GetCurrentResourceName),assert(native.GetResourceMetadata),assert(native.SetTimeout)
    local api={Callbacks={},Events={}}
    local function describeCallback(name,handler,options)api.Callbacks[#api.Callbacks+1]={name=name,handler=handler,options=options}end
    local function listen(name,handler)api.Events[#api.Events+1]={name=name,handler=handler,network=false}end

local LOAD_CALLBACK = 'forge-core:server:plugin:load'
local ACTION_CALLBACK = 'forge-core:server:plugin:action'

local plugins = {
    {
        id = 'forge-afk',
        label = translate('plugins.afk.label'),
        icon = 'clock',
        module = 'afk',
        order = 10,
        description = translate('plugins.afk.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            save = translate('plugins.actions.save_config'),
        },
        fields = {
            {
                path = 'enabled',
                type = 'boolean',
                label = translate('inputs.afk_enabled'),
                action = 'save',
                options = {
                    { label = translate('common.yes'), value = true },
                    { label = translate('common.no'), value = false },
                },
            },
            {
                path = 'minutes',
                type = 'number',
                label = translate('inputs.afk_minutes'),
                min = 1,
                max = 240,
                step = 1,
                action = 'save',
            },
        },
    },
    {
        id = 'forge-density',
        label = translate('plugins.density.label'),
        icon = 'activity',
        module = 'density',
        order = 20,
        description = translate('plugins.density.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            save = translate('plugins.actions.save_config'),
        },
        fields = {
            { path = 'enabled', type = 'boolean', label = translate('inputs.density_enabled'), action = 'save', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'disableAll', type = 'boolean', label = translate('inputs.density_disable_all'), action = 'save', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'disableDispatchServices', type = 'boolean', label = translate('inputs.density_disable_dispatch'), action = 'save', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'values.parked', type = 'number', label = translate('inputs.density_parked'), min = 0, max = 1, step = 0.1, action = 'save' },
            { path = 'values.vehicle', type = 'number', label = translate('inputs.density_vehicle'), min = 0, max = 1, step = 0.1, action = 'save' },
            { path = 'values.multiplier', type = 'number', label = translate('inputs.density_multiplier'), min = 0, max = 1, step = 0.1, action = 'save' },
            { path = 'values.peds', type = 'number', label = translate('inputs.density_peds'), min = 0, max = 1, step = 0.1, action = 'save' },
            { path = 'values.scenario', type = 'number', label = translate('inputs.density_scenario'), min = 0, max = 1, step = 0.1, action = 'save' },
            { path = 'pedPopulationBudget', type = 'number', label = translate('inputs.density_ped_budget'), min = 0, max = 3, step = 1, action = 'save' },
            { path = 'vehiclePopulationBudget', type = 'number', label = translate('inputs.density_vehicle_budget'), min = 0, max = 3, step = 1, action = 'save' },
            { path = 'blacklist.enabled', type = 'boolean', label = translate('inputs.density_blacklist_enabled'), action = 'save', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
        },
    },
    {
        id = 'forge-job',
        label = translate('plugins.job.label'),
        icon = 'briefcase',
        module = 'job',
        order = 30,
        description = translate('plugins.job.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            saveGroup = translate('plugins.actions.save_group'),
            deleteGroup = translate('plugins.actions.delete_group'),
            savePayments = translate('plugins.actions.save_payments'),
            saveMei = translate('plugins.actions.save_mei'),
            createMei = translate('plugins.actions.create_mei'),
            forcePayment = translate('plugins.actions.force_payment'),
        },
        fields = {
            { path = 'payments.enabled', type = 'boolean', label = translate('inputs.payment_enabled'), action = 'savePayments', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'payments.intervalMinutes', type = 'number', label = translate('inputs.payment_interval'), min = 1, max = 1440, step = 1, action = 'savePayments' },
            { path = 'payments.account', type = 'select', label = translate('inputs.payment_account'), action = 'savePayments', options = { { label = translate('payments.accounts.bank'), value = 'bank' }, { label = translate('payments.accounts.cash'), value = 'cash' }, { label = translate('payments.accounts.crypto'), value = 'crypto' } } },
            { path = 'payments.payOffDuty', type = 'boolean', label = translate('inputs.pay_off_duty'), action = 'savePayments', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'payments.useSociety', type = 'boolean', label = translate('inputs.use_society'), action = 'savePayments', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'payments.societySalaryPercent', type = 'number', label = translate('inputs.society_salary_percent'), min = 0, max = 100, step = 1, action = 'savePayments' },
            { path = 'payments.notify', type = 'boolean', label = translate('inputs.notify_payment'), action = 'savePayments', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'payments.mei.enabled', type = 'boolean', label = translate('inputs.mei_enabled'), action = 'saveMei', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'payments.mei.openingCost', type = 'number', label = translate('inputs.mei_opening_cost'), min = 0, max = 100000000, step = 1, action = 'saveMei' },
            { path = 'payments.mei.monthlyCost', type = 'number', label = translate('inputs.mei_monthly_cost'), min = 0, max = 100000000, step = 1, action = 'saveMei' },
            { path = 'payments.mei.governmentAccount', type = 'text', label = translate('inputs.mei_government_account'), action = 'saveMei' },
            { path = 'payments.mei.paymentAccount', type = 'select', label = translate('inputs.mei_payment_account'), action = 'saveMei', options = { { label = translate('payments.accounts.bank'), value = 'bank' }, { label = translate('payments.accounts.cash'), value = 'cash' }, { label = translate('payments.accounts.crypto'), value = 'crypto' } } },
        },
    },
    {
        id = 'forge-password',
        label = translate('plugins.password.label'),
        icon = 'lock',
        module = 'password',
        order = 40,
        description = translate('plugins.password.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            save = translate('plugins.actions.save_config'),
        },
        fields = {
            { path = 'enabled', type = 'boolean', label = translate('inputs.password_enabled'), action = 'save', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'password', type = 'text', label = translate('inputs.server_password'), action = 'save' },
            { path = 'supportLink', type = 'text', label = translate('inputs.password_support_link'), action = 'save' },
            { path = 'cardTitle', type = 'text', label = translate('inputs.password_card_title'), action = 'save' },
            { path = 'cardDescription', type = 'textarea', label = translate('inputs.password_card_description'), action = 'save' },
            { path = 'placeholder', type = 'text', label = translate('inputs.password_placeholder'), action = 'save' },
            { path = 'submitText', type = 'text', label = translate('inputs.password_submit_text'), action = 'save' },
        },
    },
    {
        id = 'forge-skill',
        label = translate('plugins.skill.label'),
        icon = 'book-fill',
        module = 'skill',
        order = 50,
        description = translate('plugins.skill.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            saveSkill = translate('plugins.actions.save_skill'),
            deleteSkill = translate('plugins.actions.delete_skill'),
            saveReputation = translate('plugins.actions.save_reputation'),
            deleteReputation = translate('plugins.actions.delete_reputation'),
        },
        fields = {
            { path = 'skill.name', type = 'text', label = translate('inputs.code'), action = 'saveSkill' },
            { path = 'skill.label', type = 'text', label = translate('inputs.display_name'), action = 'saveSkill' },
            { path = 'skill.icon', type = 'text', label = translate('inputs.skill_icon'), action = 'saveSkill' },
            { path = 'skill.calculation', type = 'select', label = translate('inputs.skill_calculation'), action = 'saveSkill', options = { { label = translate('skills.calculation.direct'), value = 'direct' }, { label = translate('skills.calculation.sum_reputations'), value = 'sum_reputations' } } },
            { path = 'skill.maxXp', type = 'number', label = translate('inputs.skill_max_xp'), min = 1, max = 100000000, step = 1, action = 'saveSkill' },
            { path = 'reputation.name', type = 'text', label = translate('inputs.code'), action = 'saveReputation' },
            { path = 'reputation.label', type = 'text', label = translate('inputs.display_name'), action = 'saveReputation' },
            { path = 'reputation.skill', type = 'text', label = translate('inputs.parent_skill'), action = 'saveReputation' },
            { path = 'reputation.maxXp', type = 'number', label = translate('inputs.skill_max_xp'), min = 1, max = 100000000, step = 1, action = 'saveReputation' },
        },
    },
    {
        id = 'forge-staff',
        label = translate('plugins.staff.label'),
        icon = 'shield',
        module = 'staff',
        order = 60,
        description = translate('plugins.staff.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            add = translate('plugins.actions.add_staff'),
            remove = translate('plugins.actions.remove_staff'),
        },
        fields = {
            { path = 'data.target', type = 'number', label = translate('inputs.player_id'), min = 1, max = 9999, step = 1, action = 'add' },
            { path = 'data.role', type = 'text', label = translate('inputs.staff_role'), action = 'add' },
        },
    },
    {
        id = 'forge-weapon',
        label = translate('plugins.weapon.label'),
        icon = 'bullseye',
        module = 'weapon',
        order = 70,
        description = translate('plugins.weapon.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            save = translate('plugins.actions.save_weapon'),
            delete = translate('plugins.actions.delete_weapon'),
            setActive = translate('plugins.actions.set_weapon_active'),
        },
        fields = {
            { path = 'weapon.name', type = 'text', label = translate('inputs.weapon_name'), action = 'save' },
            { path = 'weapon.label', type = 'text', label = translate('inputs.weapon_label'), action = 'save' },
            { path = 'weapon.category', type = 'text', label = translate('inputs.weapon_category'), action = 'save' },
            { path = 'weapon.ammotype', type = 'text', label = translate('inputs.weapon_ammo'), action = 'save' },
            { path = 'weapon.damageReason', type = 'text', label = translate('inputs.weapon_damage_reason'), action = 'save' },
            { path = 'weapon.active', type = 'boolean', label = translate('weapons.title'), action = 'save', options = { { label = translate('menu.weapons.status_active'), value = true }, { label = translate('menu.weapons.status_inactive'), value = false } } },
        },
    },
    {
        id = 'forge-weather',
        label = translate('plugins.weather.label'),
        icon = 'cloud-sun',
        module = 'weather',
        order = 80,
        description = translate('plugins.weather.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            setWeather = translate('plugins.actions.set_weather'),
            setDuration = translate('plugins.actions.set_duration'),
            addWeather = translate('plugins.actions.add_weather'),
            removeWeather = translate('plugins.actions.remove_weather'),
            setTime = translate('plugins.actions.set_time'),
            setTimeScale = translate('plugins.actions.set_time_scale'),
            setFreezeTime = translate('plugins.actions.set_freeze_time'),
        },
        fields = {
            { path = 'weather', type = 'select', label = translate('inputs.weather_type'), action = 'setWeather', options = (function()
                local result = {}
                for _, weather in ipairs(PR.Weather.Types or {}) do
                    result[#result + 1] = { label = weather.label or weather.value, value = weather.value }
                end
                return result
            end)() },
            { path = 'duration', type = 'number', label = translate('inputs.weather_duration'), min = 1, max = 1440, step = 1, action = 'setDuration' },
            { path = 'currentTime.hour', type = 'number', label = translate('inputs.time_hour'), min = 0, max = 23, step = 1, action = 'setTime' },
            { path = 'currentTime.minute', type = 'number', label = translate('inputs.time_minute'), min = 0, max = 59, step = 1, action = 'setTime' },
            { path = 'freezeTime', type = 'boolean', label = translate('inputs.freeze_time'), action = 'setFreezeTime', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'timeScale', type = 'number', label = translate('inputs.time_scale'), min = 2000, max = 60000, step = 1000, action = 'setTimeScale' },
        },
    },
    {
        id = 'forge-whitelist',
        label = translate('plugins.whitelist.label'),
        icon = 'person-check-fill',
        module = 'whitelist',
        order = 90,
        description = translate('plugins.whitelist.description'),
        load = LOAD_CALLBACK,
        action = ACTION_CALLBACK,
        actions = {
            saveConfig = translate('plugins.actions.save_config'),
            add = translate('plugins.actions.add_whitelist'),
            remove = translate('plugins.actions.remove_whitelist'),
            ban = translate('plugins.actions.ban_player'),
        },
        fields = {
            { path = 'config.enabled', type = 'boolean', label = translate('inputs.whitelist_enabled'), action = 'saveConfig', options = { { label = translate('common.yes'), value = true }, { label = translate('common.no'), value = false } } },
            { path = 'config.percent', type = 'number', label = translate('inputs.whitelist_percent'), min = 1, max = 100, step = 1, action = 'saveConfig' },
            { path = 'config.loadNotify', type = 'textarea', label = translate('inputs.whitelist_load_notify'), action = 'saveConfig' },
            { path = 'config.escapeNotify', type = 'textarea', label = translate('inputs.whitelist_escape_notify'), action = 'saveConfig' },
            { path = 'config.startExamLabel', type = 'text', label = translate('inputs.whitelist_start_label'), action = 'saveConfig' },
            { path = 'identifier', type = 'text', label = translate('inputs.whitelist_identifier'), description = translate('inputs.whitelist_identifier_description'), action = 'add' },
            { path = 'data.identifier', type = 'text', label = translate('inputs.whitelist_identifier'), description = translate('inputs.whitelist_identifier_description'), action = 'ban' },
            { path = 'data.reason', type = 'text', label = translate('inputs.ban_reason'), action = 'ban' },
            { path = 'data.hours', type = 'number', label = translate('inputs.ban_hours'), min = 0, max = 24, step = 1, action = 'ban' },
            { path = 'data.days', type = 'number', label = translate('inputs.ban_days'), min = 0, max = 3650, step = 1, action = 'ban' },
            { path = 'data.months', type = 'number', label = translate('inputs.ban_months'), min = 0, max = 120, step = 1, action = 'ban' },
        },
    },
}

local registered = {}

local function registerPlugin(item)
    if managementIntegration.resourceState() ~= 'started' then return false end

    local ok, reason = managementIntegration.registerPlugin({
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
        print(translate('plugins.rejected', { id = item.id, reason = tostring(reason) }))
        return false
    end

    registered[item.id] = true
    return true
end

local function registerAllPlugins()
    if managementIntegration.resourceState() ~= 'started' then return end

    for i = 1, #plugins do
        registerPlugin(plugins[i])
    end
end

local function unregisterAllPlugins()
    if managementIntegration.resourceState() ~= 'started' then return end

    for id in pairs(registered) do
        managementIntegration.unregisterPlugin(id)
        registered[id] = nil
    end
end

local modules = {}

for i = 1, #plugins do
    modules[plugins[i].module] = plugins[i]
end

local function loadModule(source, module)
    if module == 'afk' then
        if not services.AfkService.canManage(source) then return false, 'no_permission' end
        return true, services.AfkService.getSettings()
    elseif module == 'density' then
        if not services.DensityService.canManage(source) then return false, 'no_permission' end
        return true, services.DensityService.getSettings()
    elseif module == 'job' then
        if not services.JobService.started then services.JobService.start() end
        return true, services.JobService.getPayload()
    elseif module == 'password' then
        if not services.PasswordService.canManage(source) then return false, 'no_permission' end
        return true, services.PasswordService.getSafeSettings()
    elseif module == 'skill' then
        return true, services.SkillService.getPayload()
    elseif module == 'staff' then
        if not services.StaffService.canManage(source) then return false, 'no_permission' end
        return true, services.StaffService.list()
    elseif module == 'weapon' then
        if not services.WeaponService.canManage(source) then return false, 'no_permission' end
        return true, services.WeaponService.getPayload()
    elseif module == 'weather' then
        local ok, state = services.WeatherService.getState(source)
        if not ok then return ok, state end
        state = type(state) == 'table' and state or {}
        state.weather = state.currentWeather and state.currentWeather.weather or state.weather
        state.duration = state.currentWeather and state.currentWeather.time or state.duration
        return true, state
    elseif module == 'whitelist' then
        local configOk, config = services.WhitelistService.canManage(source) and true or false, nil
        if not configOk then return false, 'no_permission' end
        config = services.WhitelistService.getConfig()
        local playersOk, players = services.WhitelistService.listPlayers(source)
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
        return services.AfkService.save(source, payload.settings or payload)
    elseif module == 'density' and action == 'save' then
        return services.DensityService.save(source, payload.settings or payload)
    elseif module == 'job' then
        if action == 'saveGroup' then return services.JobService.upsert(source, payload.group, payload.group and payload.group.type) end
        if action == 'deleteGroup' then return services.JobService.delete(source, payload.groupType, payload.name) end
        if action == 'savePayments' then return services.JobPayments.update(source, payload.settings or payload.payments or payload) end
        if action == 'saveMei' then return services.JobPayments.updateMei(source, payload.settings or (payload.payments and payload.payments.mei) or payload.mei or payload) end
        if action == 'createMei' then return services.JobService.createMei(source, payload.data or payload) end
        if action == 'forcePayment' then return services.JobPayments.force(source) end
    elseif module == 'password' and action == 'save' then
        return services.PasswordService.save(source, payload.settings or payload)
    elseif module == 'skill' then
        if action == 'saveSkill' then return services.SkillService.upsertSkill(source, payload.skill or payload) end
        if action == 'deleteSkill' then return services.SkillService.deleteSkill(source, payload.name) end
        if action == 'saveReputation' then return services.SkillService.upsertReputation(source, payload.reputation or payload) end
        if action == 'deleteReputation' then return services.SkillService.deleteReputation(source, payload.name) end
    elseif module == 'staff' then
        if action == 'add' then return services.StaffService.add(source, payload.data or payload) end
        if action == 'remove' then return services.StaffService.remove(source, payload.data or payload) end
    elseif module == 'weapon' then
        if action == 'save' then return services.WeaponService.upsert(source, payload.weapon or payload) end
        if action == 'delete' then return services.WeaponService.delete(source, payload.name) end
        if action == 'setActive' then return services.WeaponService.setActive(source, payload.name, payload.active == true) end
    elseif module == 'weather' then
        if action == 'setWeather' then return services.WeatherService.setWeather(source, payload.index or 1, payload.weather, payload.event or payload.currentWeather) end
        if action == 'setDuration' then return services.WeatherService.setDuration(source, payload.index or 1, payload.duration, payload.event or payload.currentWeather) end
        if action == 'addWeather' then return services.WeatherService.addWeather(source, payload.data or payload) end
        if action == 'removeWeather' then return services.WeatherService.removeWeather(source, payload.index, payload.event) end
        if action == 'setTime' then return services.WeatherService.setTime(source, payload.hour or (payload.currentTime and payload.currentTime.hour), payload.minute or (payload.currentTime and payload.currentTime.minute)) end
        if action == 'setTimeScale' then return services.WeatherService.setTimeScale(source, payload.scale or payload.timeScale) end
        if action == 'setFreezeTime' then return services.WeatherService.setFreezeTime(source, payload.enabled == true or payload.freezeTime == true) end
    elseif module == 'whitelist' then
        if action == 'saveConfig' then return services.WhitelistService.saveConfig(source, payload.config or payload) end
        if action == 'add' then return services.WhitelistService.add(source, payload.identifier) end
        if action == 'remove' then return services.WhitelistService.remove(source, payload.identifier) end
        if action == 'ban' then return services.WhitelistService.ban(source, payload.data or payload) end
    end

    return false, 'invalid_action'
end

describeCallback(LOAD_CALLBACK, function(source, module)
    return loadModule(source, tostring(module or ''))
end, { access = 'admin', limit = 30 })

describeCallback(ACTION_CALLBACK, function(source, module, action, payload)
    return runAction(source, tostring(module or ''), tostring(action or ''), payload)
end, { access = 'admin' })

listen('forge-management:server:pluginsReady', registerAllPlugins)

listen('onResourceStart', function(resourceName)
    if resourceName == 'forge-management' or resourceName == GetCurrentResourceName() then
        SetTimeout(500, registerAllPlugins)
    end
end)

listen('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        unregisterAllPlugins()
    end
end)
    return api
end
