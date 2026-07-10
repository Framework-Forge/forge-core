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
local clone = Shared.clone
local boolLabel = Shared.boolLabel
local boolDefault = Shared.boolDefault
local boolValue = Shared.boolValue
local boolOptions = Shared.boolOptions

local whitelistActionLocked = false

local function fetchWhitelistConfig()
    local ok, payload = awaitServer(PR.Whitelist.Callbacks.getConfig)
    if not ok then
        notifyFailure('notify.whitelist.load_failed', payload)
        return nil
    end

    return type(payload) == 'table' and payload or clone(PR.Whitelist.Defaults)
end

local function saveWhitelistConfig(config, reopen)
    if whitelistActionLocked then return false end
    whitelistActionLocked = true

    local ok, response = awaitServer(PR.Whitelist.Callbacks.saveConfig, config)
    if not ok then
        notifyFailure('notify.whitelist.save_failed', response)
    end

    SetTimeout(500, function()
        if reopen then reopen() end
    end)

    SetTimeout(1000, function()
        whitelistActionLocked = false
    end)

    return ok
end

local function runWhitelistAction(callbackName, failureLocale, ...)
    if whitelistActionLocked then return false end
    whitelistActionLocked = true

    local ok, response = awaitServer(callbackName, ...)
    if not ok then
        notifyFailure(failureLocale or 'notify.whitelist.action_failed', response)
    end

    SetTimeout(1000, function()
        whitelistActionLocked = false
    end)

    return ok, response
end

function Menu.openWhitelistMenu()
    local config = fetchWhitelistConfig()
    if not config then return false end

    showContext({
        id = 'forge_core_whitelist',
        title = t('menu.whitelist.title'),
        menu = 'forge_core_server_settings',
        options = {
            {
                title = t('menu.whitelist.settings'),
                description = t('menu.whitelist.settings_summary', {
                    status = config.enabled and t('common.active') or t('common.inactive'),
                    percent = tostring(config.percent or 70),
                }),
                icon = 'settings',
                onSelect = function()
                    Menu.openWhitelistSettingsEditor(config)
                end,
            },
            {
                title = t('menu.whitelist.questions'),
                description = t('menu.whitelist.questions_summary', { count = tostring(#(config.questions or {})) }),
                icon = 'clipboard-question',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistQuestions(config)
                end,
            },
            {
                title = t('menu.whitelist.players'),
                description = t('menu.whitelist.players_description'),
                icon = 'users',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistPlayers()
                end,
            },
            {
                title = t('menu.whitelist.add_player'),
                description = t('menu.whitelist.add_player_description'),
                icon = 'user-plus',
                onSelect = function()
                    Menu.openWhitelistPlayerAction('add')
                end,
            },
            {
                title = t('menu.whitelist.remove_player'),
                description = t('menu.whitelist.remove_player_description'),
                icon = 'user-minus',
                iconColor = 'red',
                onSelect = function()
                    Menu.openWhitelistPlayerAction('remove')
                end,
            },
        },
    })

    return true
end

function Menu.openWhitelistPlayers()
    local ok, payload = awaitServer(PR.Whitelist.Callbacks.listPlayers)
    if not ok then
        notifyFailure('notify.whitelist.load_failed', payload)
        return Menu.openWhitelistMenu()
    end

    payload = type(payload) == 'table' and payload or {}
    local players = type(payload.players) == 'table' and payload.players or {}
    local options = {}

    for _, player in ipairs(players) do
        local status = player.whitelisted and t('menu.whitelist.has_whitelist') or t('menu.whitelist.no_whitelist')
        local source = player.online and tostring(player.source) or t('common.offline')

        options[#options + 1] = {
            title = player.name or player.citizenid,
            description = t('menu.whitelist.player_status', {
                status = status,
                source = source,
                citizenid = tostring(player.citizenid or ''),
            }),
            icon = player.whitelisted and 'user-check' or 'user-x',
            iconColor = player.whitelisted and 'green' or 'red',
            arrow = true,
            onSelect = function()
                Menu.openWhitelistPlayerDetails(player)
            end,
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = t('menu.whitelist.no_players'),
            icon = 'circle-info',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_whitelist_players',
        title = t('menu.whitelist.players'),
        description = t('menu.whitelist.players_summary', {
            whitelisted = tostring(payload.whitelisted or 0),
            pending = tostring(payload.pending or 0),
        }),
        menu = 'forge_core_whitelist',
        options = options,
    })
end

function Menu.openWhitelistPlayerDetails(player)
    local identifier = player.source or player.citizenid
    local options = {}

    if player.whitelisted then
        options[#options + 1] = {
            title = t('menu.whitelist.remove_player'),
            description = t('menu.whitelist.remove_player_description'),
            icon = 'user-minus',
            iconColor = 'red',
            onSelect = function()
                local ok = runWhitelistAction(PR.Whitelist.Callbacks.remove, 'notify.whitelist.remove_failed', identifier)
                SetTimeout(500, function()
                    if ok then Menu.openWhitelistPlayers() else Menu.openWhitelistPlayerDetails(player) end
                end)
            end,
        }
    else
        options[#options + 1] = {
            title = t('menu.whitelist.add_player'),
            description = t('menu.whitelist.add_player_description'),
            icon = 'user-plus',
            iconColor = 'green',
            onSelect = function()
                local ok = runWhitelistAction(PR.Whitelist.Callbacks.add, 'notify.whitelist.add_failed', identifier)
                SetTimeout(500, function()
                    if ok then Menu.openWhitelistPlayers() else Menu.openWhitelistPlayerDetails(player) end
                end)
            end,
        }
    end

    options[#options + 1] = {
        title = t('menu.whitelist.ban_player'),
        description = t('menu.whitelist.ban_player_description'),
        icon = 'ban',
        iconColor = 'red',
        onSelect = function()
            Menu.openWhitelistBanDialog(player)
        end,
    }

    showContext({
        id = 'forge_core_whitelist_player_' .. tostring(player.citizenid),
        title = player.name or player.citizenid,
        description = t('menu.whitelist.player_status', {
            status = player.whitelisted and t('menu.whitelist.has_whitelist') or t('menu.whitelist.no_whitelist'),
            source = player.online and tostring(player.source) or t('common.offline'),
            citizenid = tostring(player.citizenid or ''),
        }),
        menu = 'forge_core_whitelist_players',
        options = options,
    })
end

function Menu.openWhitelistBanDialog(player)
    local result = inputDialog(t('menu.whitelist.ban_player'), {
        { type = 'input', label = t('inputs.ban_reason'), default = t('menu.whitelist.default_ban_reason'), required = true },
        { type = 'number', label = t('inputs.ban_hours'), default = 0, min = 0 },
        { type = 'number', label = t('inputs.ban_days'), default = 0, min = 0 },
        { type = 'number', label = t('inputs.ban_months'), default = 0, min = 0 },
    })

    if not result then return Menu.openWhitelistPlayerDetails(player) end

    local ok = runWhitelistAction(PR.Whitelist.Callbacks.ban, 'notify.whitelist.ban_failed', {
        identifier = player.source or player.citizenid,
        reason = result[1],
        hours = tonumber(result[2]) or 0,
        days = tonumber(result[3]) or 0,
        months = tonumber(result[4]) or 0,
    })

    SetTimeout(500, function()
        if ok then Menu.openWhitelistPlayers() else Menu.openWhitelistPlayerDetails(player) end
    end)
end

function Menu.openWhitelistSettingsEditor(config)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if not config then return false end

    local result = inputDialog(t('menu.whitelist.settings'), {
        { type = 'select', label = t('inputs.whitelist_enabled'), options = boolOptions(), default = boolDefault(config.enabled), required = true },
        { type = 'number', label = t('inputs.whitelist_percent'), default = tonumber(config.percent) or 70, min = 0, max = 100, required = true },
        { type = 'input', label = t('inputs.whitelist_load_notify'), default = config.loadNotify, required = true },
        { type = 'input', label = t('inputs.whitelist_escape_notify'), default = config.escapeNotify, required = true },
        { type = 'input', label = t('inputs.whitelist_start_label'), default = config.startExamLabel, required = true },
    })

    if not result then return Menu.openWhitelistMenu() end

    config.enabled = boolValue(result[1])
    config.percent = tonumber(result[2]) or 70
    config.loadNotify = result[3]
    config.escapeNotify = result[4]
    config.startExamLabel = result[5]

    saveWhitelistConfig(config, function()
        Menu.openWhitelistMenu()
    end)
end

function Menu.openWhitelistPlayerAction(action)
    local result = inputDialog(action == 'add' and t('menu.whitelist.add_player') or t('menu.whitelist.remove_player'), {
        {
            type = 'input',
            label = t('inputs.whitelist_identifier'),
            description = t('inputs.whitelist_identifier_description'),
            required = true,
        },
    })

    if not result then return Menu.openWhitelistMenu() end

    local identifier = result[1]
    if tonumber(identifier) then identifier = tonumber(identifier) end

    local callback = action == 'add' and PR.Whitelist.Callbacks.add or PR.Whitelist.Callbacks.remove
    local failure = action == 'add' and 'notify.whitelist.add_failed' or 'notify.whitelist.remove_failed'

    runWhitelistAction(callback, failure, identifier)

    SetTimeout(500, function()
        Menu.openWhitelistMenu()
    end)
end

function Menu.openWhitelistQuestions(config)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if not config then return false end

    local options = {
        {
            title = t('menu.whitelist.create_question'),
            icon = 'plus',
            onSelect = function()
                Menu.openWhitelistQuestionEditor(config, nil)
            end,
        },
    }

    for index, question in ipairs(config.questions or {}) do
        options[#options + 1] = {
            title = question.question,
            description = t('menu.whitelist.question_summary', {
                index = tostring(index),
                options = tostring(#(question.options or {})),
            }),
            icon = 'clipboard-question',
            arrow = true,
            onSelect = function()
                Menu.openWhitelistQuestionDetails(config, index)
            end,
        }
    end

    showContext({
        id = 'forge_core_whitelist_questions',
        title = t('menu.whitelist.questions'),
        menu = 'forge_core_whitelist',
        options = options,
    })
end

function Menu.openWhitelistQuestionDetails(config, index)
    local question = config.questions[index]
    if not question then return Menu.openWhitelistQuestions(config) end

    showContext({
        id = 'forge_core_whitelist_question_' .. tostring(index),
        title = question.question,
        menu = 'forge_core_whitelist_questions',
        options = {
            {
                title = t('menu.actions.edit'),
                icon = 'pen',
                onSelect = function()
                    Menu.openWhitelistQuestionEditor(config, index)
                end,
            },
            {
                title = t('menu.whitelist.options'),
                description = t('menu.whitelist.options_summary', { count = tostring(#(question.options or {})) }),
                icon = 'list',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistOptions(config, index)
                end,
            },
            {
                title = t('menu.actions.remove'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.remove_whitelist_question_header'),
                        content = t('dialogs.remove_whitelist_question_content'),
                        centered = true,
                        cancel = true,
                    })

                    if confirmed == 'confirm' then
                        table.remove(config.questions, index)
                        saveWhitelistConfig(config, function()
                            Menu.openWhitelistQuestions(config)
                        end)
                    end
                end,
            },
        },
    })
end

function Menu.openWhitelistQuestionEditor(config, index)
    local question = index and config.questions[index] or { question = '', options = {} }
    local result = inputDialog(index and t('dialogs.edit_whitelist_question') or t('menu.whitelist.create_question'), {
        {
            type = 'input',
            label = t('inputs.whitelist_question'),
            default = question.question,
            required = true,
            min = 3,
        },
    })

    if not result then return index and Menu.openWhitelistQuestionDetails(config, index) or Menu.openWhitelistQuestions(config) end

    question.question = result[1]
    question.options = question.options or {}

    if index then
        config.questions[index] = question
    else
        config.questions[#config.questions + 1] = question
    end

    saveWhitelistConfig(config, function()
        Menu.openWhitelistQuestions(config)
    end)
end

function Menu.openWhitelistOptions(config, questionIndex)
    local question = config.questions[questionIndex]
    if not question then return Menu.openWhitelistQuestions(config) end

    local options = {
        {
            title = t('menu.whitelist.create_option'),
            icon = 'plus',
            onSelect = function()
                Menu.openWhitelistOptionEditor(config, questionIndex, nil)
            end,
        },
    }

    for index, option in ipairs(question.options or {}) do
        options[#options + 1] = {
            title = option.label,
            description = t('menu.whitelist.option_summary', { correct = boolLabel(option.value == true) }),
            icon = option.value == true and 'circle-check' or 'circle-x',
            iconColor = option.value == true and 'green' or 'red',
            onSelect = function()
                Menu.openWhitelistOptionEditor(config, questionIndex, index)
            end,
        }
    end

    showContext({
        id = 'forge_core_whitelist_options_' .. tostring(questionIndex),
        title = t('menu.whitelist.options'),
        menu = 'forge_core_whitelist_question_' .. tostring(questionIndex),
        options = options,
    })
end

function Menu.openWhitelistOptionEditor(config, questionIndex, optionIndex)
    local question = config.questions[questionIndex]
    if not question then return Menu.openWhitelistQuestions(config) end

    local option = optionIndex and question.options[optionIndex] or { label = '', value = false }
    local result = inputDialog(optionIndex and t('dialogs.edit_whitelist_option') or t('menu.whitelist.create_option'), {
        { type = 'input', label = t('inputs.whitelist_option'), default = option.label, required = true, min = 1 },
        { type = 'select', label = t('inputs.whitelist_option_correct'), options = boolOptions(), default = boolDefault(option.value), required = true },
    })

    if not result then return Menu.openWhitelistOptions(config, questionIndex) end

    option.label = result[1]
    option.value = boolValue(result[2])
    question.options = question.options or {}

    if optionIndex then
        question.options[optionIndex] = option
    else
        question.options[#question.options + 1] = option
    end

    config.questions[questionIndex] = question

    saveWhitelistConfig(config, function()
        Menu.openWhitelistOptions(config, questionIndex)
    end)
end
