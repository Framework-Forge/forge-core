-- Complete installed menu/menu_mei.lua, inactive and dependency-bound; see NOTICE-25.md.
return function(ports)
    local Menu,Shared,client=assert(ports.menu),assert(ports.shared),assert(ports.client)
    local library,PR,native=assert(ports.library),assert(ports.config),assert(ports.native)
    local translate,integrations=ports.translate,ports.integrations
    local api={Menu=Menu,Shared=Shared,Events={},Callbacks={},Exports={}}
    local function listen(name,handler)api.Events[#api.Events+1]={name=name,handler=handler,network=false}end
    local function callback(name,handler)api.Callbacks[name]=handler end
    local function describeExport(name,handler)api.Exports[name]=handler end
local t = Shared.t
local notify = Shared.notify
local inputDialog = Shared.inputDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local boolOptions = Shared.boolOptions
local boolDefault = Shared.boolDefault
local boolValue = Shared.boolValue
local accountOptions = Shared.accountOptions
local buildGrades = Shared.buildGrades


local meiActionLocked = false

function Menu.openMeiSettingsEditor(settings)
    settings = settings or {}

    local result = inputDialog(t('menu.mei.settings'), {
        {
            type = 'select',
            label = t('inputs.mei_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.enabled),
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.mei_opening_cost'),
            default = tonumber(settings.openingCost) or 0,
            required = true,
            min = 0,
        },
        {
            type = 'number',
            label = t('inputs.mei_monthly_cost'),
            default = tonumber(settings.monthlyCost) or 0,
            required = true,
            min = 0,
        },
        {
            type = 'input',
            label = t('inputs.mei_government_account'),
            default = settings.governmentAccount or 'government',
            required = true,
            min = 1,
            max = 32,
        },
        {
            type = 'select',
            label = t('inputs.mei_payment_account'),
            options = accountOptions(),
            default = settings.paymentAccount or 'bank',
            required = true,
        },
    })

    if not result then return Menu.openPaymentSettings() end
    if meiActionLocked then return Menu.openPaymentSettings() end

    meiActionLocked = true

    local ok, response = awaitServer(PR.Job.Callbacks.saveMeiSettings, {
        enabled = boolValue(result[1]),
        openingCost = tonumber(result[2]) or 0,
        monthlyCost = tonumber(result[3]) or 0,
        governmentAccount = result[4] or 'government',
        paymentAccount = result[5] or 'bank',
    })

    if not ok then
        notifyFailure('notify.mei.settings_failed', response)
    end

    native.setTimeout(500, function()
        Menu.openPaymentSettings()
    end)

    native.setTimeout(1000, function()
        meiActionLocked = false
    end)
end

function Menu.openMeiCreator()
    local state = client.JobState and client.JobState.request()
    local meiSettings = state and state.payments and state.payments.mei or {}

    if not meiSettings.enabled then
        notify({
            title = t('mei.title'),
            description = t('notify.mei.disabled'),
            type = 'error',
        })
        return false
    end

    local result = inputDialog(t('menu.mei.create'), {
        {
            type = 'input',
            label = t('inputs.mei_company_name'),
            required = true,
            min = 3,
            max = 64,
        },
        {
            type = 'number',
            label = t('inputs.grade_count'),
            description = t('inputs.mei_opening_cost_description', {
                cost = tostring(meiSettings.openingCost or 0),
            }),
            required = true,
            default = 1,
            min = 1,
            max = 30,
        },
    })

    if not result then return false end

    local grades = buildGrades('job', result[2])
    if not grades then return false end
    if meiActionLocked then return false end

    meiActionLocked = true

    local ok, response = awaitServer(PR.Job.Callbacks.createMei, {
        label = result[1],
        grades = grades,
    })

    if not ok then
        notifyFailure('notify.mei.create_failed', response)
    end

    native.setTimeout(1000, function()
        meiActionLocked = false
    end)

    return ok, response
end

describeExport('OpenMeiCreator', function()
    return Menu.openMeiCreator()
end)

describeExport('OpenMEICreator', function()
    return Menu.openMeiCreator()
end)

callback(PR.Job.Callbacks.openMei, function()
    Menu.openMeiCreator()
    return true
end)

    return api
end

