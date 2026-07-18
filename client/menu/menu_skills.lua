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
local skillCalculationOptions = Shared.skillCalculationOptions
local calculationLabel = Shared.calculationLabel
local fetchSkillsPayload = Shared.fetchSkillsPayload
local countLinkedReputations = Shared.countLinkedReputations
local skillSelectOptions = Shared.skillSelectOptions
local levelCount = Shared.levelCount
local saveSkillDefinition = Shared.saveSkillDefinition
local fetchPlayerSkillsPayload = Shared.fetchPlayerSkillsPayload
local levelProgress = Shared.levelProgress
local levelXpText = Shared.levelXpText
local playerSkillDescription = Shared.playerSkillDescription
local linkedPlayerReputations = Shared.linkedPlayerReputations


local skillActionLocked = false

function Menu.openSkillsMenu()
    local payload = fetchSkillsPayload()

    showContext({
        id = 'forge_core_skills',
        title = t('menu.skills.title'),
        menu = 'forge_core_main',
        options = {
            {
                title = t('menu.skills.skills'),
                description = t('menu.skills.skills_description', { count = tostring(#payload.skills) }),
                icon = 'brain',
                onSelect = function()
                    Menu.openSkillList()
                end,
            },
            {
                title = t('menu.skills.reputations'),
                description = t('menu.skills.reputations_description', { count = tostring(#payload.reputations) }),
                icon = 'star',
                onSelect = function()
                    Menu.openReputationList()
                end,
            },
        },
    })
end

function Menu.openPlayerSkillsMenu(parentMenu)
    local payload = fetchPlayerSkillsPayload()
    if not payload then return false end

    local options = {}

    for _, skill in ipairs(payload.skills or {}) do
        options[#options + 1] = {
            title = skill.label or skill.name,
            description = playerSkillDescription(skill),
            icon = skill.icon or PR.Skills.Defaults.icon,
            progress = levelProgress(skill.level),
            colorScheme = 'green',
            arrow = true,
            onSelect = function()
                Menu.openPlayerSkillDetails(payload, skill)
            end,
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = t('menu.skills.no_items'),
            icon = 'circle-info',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_player_skills',
        title = t('menu.skills.my_skills'),
        menu = parentMenu,
        options = options,
    })

    return true
end

function Menu.openPlayerReputationsMenu(parentSkill)
    local payload = fetchPlayerSkillsPayload()
    if not payload then return false end

    local options = {}

    for _, reputation in ipairs(payload.reputations or {}) do
        if not parentSkill or reputation.skill == parentSkill then
            options[#options + 1] = {
                title = reputation.label or reputation.name,
                description = t('menu.skills.player_reputation_description', {
                    skill = tostring(reputation.skill or ''),
                    level = tostring(reputation.level and reputation.level.title or '0'),
                    xp = levelXpText(reputation),
                }),
                icon = reputation.icon or PR.Skills.Defaults.icon,
                progress = levelProgress(reputation.level),
                colorScheme = 'blue',
            }
        end
    end

    if #options == 0 then
        options[#options + 1] = {
            title = t('menu.skills.no_items'),
            icon = 'circle-info',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_player_reputations_' .. tostring(parentSkill or 'all'),
        title = t('menu.skills.my_reputations'),
        menu = parentSkill and 'forge_core_player_skill_details_' .. tostring(parentSkill) or nil,
        options = options,
    })

    return true
end

function Menu.openPlayerSkillDetails(payload, skill)
    local linked = linkedPlayerReputations(payload, skill.name)
    local options = {
        {
            title = skill.label or skill.name,
            description = playerSkillDescription(skill),
            icon = skill.icon or PR.Skills.Defaults.icon,
            progress = levelProgress(skill.level),
            colorScheme = 'green',
            disabled = true,
        },
    }

    if #linked > 0 then
        options[#options + 1] = {
            title = t('menu.skills.my_reputations'),
            description = t('menu.skills.reputations_description', { count = tostring(#linked) }),
            icon = 'star',
            arrow = true,
            onSelect = function()
                Menu.openPlayerReputationsMenu(skill.name)
            end,
        }
    end

    showContext({
        id = 'forge_core_player_skill_details_' .. tostring(skill.name),
        title = skill.label or skill.name,
        menu = 'forge_core_player_skills',
        options = options,
    })
end

function Menu.openSkillList()
    local payload = fetchSkillsPayload()
    local options = {
        {
            title = t('menu.skills.create_skill'),
            icon = 'plus',
            onSelect = function()
                Menu.openSkillEditor(nil, true)
            end,
        },
    }

    for _, skill in ipairs(payload.skills or {}) do
        options[#options + 1] = {
            title = ('%s - %s'):format(skill.label or skill.name, skill.name),
            description = t('menu.skills.skill_description', {
                calculation = calculationLabel(skill.calculation),
                reps = tostring(countLinkedReputations(payload, skill.name)),
                levels = tostring(levelCount(skill)),
            }),
            icon = skill.icon or PR.Skills.Defaults.icon,
            onSelect = function()
                Menu.openSkillDetails(skill)
            end,
        }
    end

    showContext({
        id = 'forge_core_skill_list',
        title = t('menu.skills.skills'),
        menu = 'forge_core_skills',
        options = options,
    })
end

function Menu.openSkillDetails(skill)
    showContext({
        id = 'forge_core_skill_details_' .. tostring(skill.name),
        title = skill.label or skill.name,
        menu = 'forge_core_skill_list',
        options = {
            {
                title = t('menu.actions.edit_data'),
                icon = 'pen',
                onSelect = function()
                    Menu.openSkillEditor(skill, false)
                end,
            },
            {
                title = t('menu.skills.reputations'),
                icon = 'star',
                onSelect = function()
                    Menu.openReputationList(skill.name)
                end,
            },
            {
                title = t('menu.skills.levels'),
                description = t('menu.skills.levels_description', { count = tostring(levelCount(skill)) }),
                icon = 'list-ordered',
                onSelect = function()
                    Menu.openSkillLevelList('skill', skill)
                end,
            },
            {
                title = t('menu.actions.remove'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.remove_skill_header'),
                        content = t('dialogs.remove_skill_content', { item = skill.label or skill.name }),
                        centered = true,
                        cancel = true,
                    })

                    if confirmed == 'confirm' then
                        local ok, response = awaitServer(PR.Skills.Callbacks.deleteSkill, skill.name)
                        if not ok then
                            notifyFailure('notify.skills.remove_failed', response)
                        end
                    end

                    SetTimeout(500, function()
                        Menu.openSkillList()
                    end)
                end,
            },
        },
    })
end

function Menu.openSkillEditor(skill, isNew)
    skill = skill or {}

    local rows = {}
    if isNew then
        rows[#rows + 1] = {
            type = 'input',
            label = t('inputs.code'),
            description = t('inputs.code_description'),
            required = true,
            min = 1,
            max = 32,
        }
    end

    rows[#rows + 1] = {
        type = 'input',
        label = t('inputs.display_name'),
        default = skill.label,
        required = true,
        min = 1,
        max = 64,
    }
    rows[#rows + 1] = {
        type = 'input',
        label = t('inputs.skill_icon'),
        default = skill.icon or PR.Skills.Defaults.icon,
        required = true,
        min = 1,
        max = 48,
    }
    rows[#rows + 1] = {
        type = 'select',
        label = t('inputs.skill_calculation'),
        options = skillCalculationOptions(),
        default = skill.calculation or PR.Skills.Calculation.direct,
        required = true,
    }
    rows[#rows + 1] = {
        type = 'number',
        label = t('inputs.skill_max_xp'),
        default = tonumber(skill.maxXp) or PR.Skills.Defaults.maxXp,
        required = true,
        min = 0,
    }

    local result = inputDialog(isNew and t('menu.skills.create_skill') or t('dialogs.edit_skill'), rows)
    if not result then return Menu.openSkillList() end
    if skillActionLocked then return Menu.openSkillList() end

    local index = 1
    local updated = clone(skill)

    if isNew then
        updated.name = result[index]
        updated.code = result[index]
        index = index + 1
    end

    updated.label = result[index]
    index = index + 1
    updated.icon = result[index] or PR.Skills.Defaults.icon
    index = index + 1
    updated.calculation = result[index] or PR.Skills.Calculation.direct
    index = index + 1
    updated.maxXp = tonumber(result[index]) or PR.Skills.Defaults.maxXp

    skillActionLocked = true
    saveSkillDefinition('skill', updated)

    SetTimeout(500, function()
        Menu.openSkillList()
    end)

    SetTimeout(1000, function()
        skillActionLocked = false
    end)
end

function Menu.openReputationList(skillName)
    local payload = fetchSkillsPayload()
    local options = {
        {
            title = t('menu.skills.create_reputation'),
            icon = 'plus',
            disabled = #(payload.skills or {}) == 0,
            onSelect = function()
                Menu.openReputationEditor(skillName and { skill = skillName } or nil, true)
            end,
        },
    }

    for _, reputation in ipairs(payload.reputations or {}) do
        if not skillName or reputation.skill == skillName then
            options[#options + 1] = {
                title = ('%s - %s'):format(reputation.label or reputation.name, reputation.name),
                description = t('menu.skills.reputation_description', {
                    skill = tostring(reputation.skill or ''),
                    levels = tostring(levelCount(reputation)),
                }),
                icon = reputation.icon or PR.Skills.Defaults.icon,
                onSelect = function()
                    Menu.openReputationDetails(reputation, skillName)
                end,
            }
        end
    end

    showContext({
        id = 'forge_core_reputation_list_' .. tostring(skillName or 'all'),
        title = t('menu.skills.reputations'),
        menu = skillName and ('forge_core_skill_details_' .. tostring(skillName)) or 'forge_core_skills',
        options = options,
    })
end

function Menu.openReputationDetails(reputation, parentSkill)
    showContext({
        id = 'forge_core_reputation_details_' .. tostring(reputation.name),
        title = reputation.label or reputation.name,
        menu = 'forge_core_reputation_list_' .. tostring(parentSkill or 'all'),
        options = {
            {
                title = t('menu.actions.edit_data'),
                icon = 'pen',
                onSelect = function()
                    Menu.openReputationEditor(reputation, false, parentSkill)
                end,
            },
            {
                title = t('menu.skills.levels'),
                description = t('menu.skills.levels_description', { count = tostring(levelCount(reputation)) }),
                icon = 'list-ordered',
                onSelect = function()
                    Menu.openSkillLevelList('rep', reputation, parentSkill)
                end,
            },
            {
                title = t('menu.actions.remove'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.remove_reputation_header'),
                        content = t('dialogs.remove_skill_content', { item = reputation.label or reputation.name }),
                        centered = true,
                        cancel = true,
                    })

                    if confirmed == 'confirm' then
                        local ok, response = awaitServer(PR.Skills.Callbacks.deleteReputation, reputation.name)
                        if not ok then
                            notifyFailure('notify.skills.remove_failed', response)
                        end
                    end

                    SetTimeout(500, function()
                        Menu.openReputationList(parentSkill)
                    end)
                end,
            },
        },
    })
end

function Menu.openReputationEditor(reputation, isNew, parentSkill)
    reputation = reputation or {}
    local payload = fetchSkillsPayload()
    local rows = {}

    if isNew then
        rows[#rows + 1] = {
            type = 'input',
            label = t('inputs.code'),
            description = t('inputs.code_description'),
            required = true,
            min = 1,
            max = 32,
        }
    end

    rows[#rows + 1] = {
        type = 'input',
        label = t('inputs.display_name'),
        default = reputation.label,
        required = true,
        min = 1,
        max = 64,
    }
    rows[#rows + 1] = {
        type = 'input',
        label = t('inputs.skill_icon'),
        default = reputation.icon or PR.Skills.Defaults.icon,
        required = true,
        min = 1,
        max = 48,
    }
    rows[#rows + 1] = {
        type = 'select',
        label = t('inputs.parent_skill'),
        options = skillSelectOptions(payload),
        default = reputation.skill or parentSkill,
        required = true,
        searchable = true,
    }
    rows[#rows + 1] = {
        type = 'number',
        label = t('inputs.skill_max_xp'),
        default = tonumber(reputation.maxXp) or PR.Skills.Defaults.maxXp,
        required = true,
        min = 0,
    }

    local result = inputDialog(isNew and t('menu.skills.create_reputation') or t('dialogs.edit_reputation'), rows)
    if not result then return Menu.openReputationList(parentSkill) end
    if skillActionLocked then return Menu.openReputationList(parentSkill) end

    local index = 1
    local updated = clone(reputation)

    if isNew then
        updated.name = result[index]
        updated.code = result[index]
        index = index + 1
    end

    updated.label = result[index]
    index = index + 1
    updated.icon = result[index] or PR.Skills.Defaults.icon
    index = index + 1
    updated.skill = result[index]
    updated.linkedSkill = result[index]
    index = index + 1
    updated.maxXp = tonumber(result[index]) or PR.Skills.Defaults.maxXp

    skillActionLocked = true
    saveSkillDefinition('rep', updated)

    SetTimeout(500, function()
        Menu.openReputationList(parentSkill)
    end)

    SetTimeout(1000, function()
        skillActionLocked = false
    end)
end

function Menu.openSkillLevelList(kind, item, parentSkill)
    local levels = clone(item.levels or {})
    local menuId = 'forge_core_skill_levels_' .. tostring(kind) .. '_' .. tostring(item.name)
    local options = {
        {
            title = t('menu.skills.create_level'),
            icon = 'plus',
            onSelect = function()
                Menu.openSkillLevelEditor(kind, item, nil, nil, true, parentSkill)
            end,
        },
    }

    if #levels == 0 then
        options[#options + 1] = {
            title = t('menu.skills.default_levels'),
            description = t('menu.skills.default_levels_description'),
            icon = 'info',
            disabled = true,
        }
    end

    for index, level in ipairs(levels) do
        options[#options + 1] = {
            title = level.title or ('Nivel ' .. tostring(index - 1)),
            description = t('menu.skills.level_description', {
                from = tostring(level.from or 0),
                to = tostring(level.to or 0),
            }),
            icon = 'list-ordered',
            onSelect = function()
                Menu.openSkillLevelDetails(kind, item, index, level, parentSkill)
            end,
        }
    end

    showContext({
        id = menuId,
        title = t('menu.skills.levels'),
        menu = kind == 'rep' and ('forge_core_reputation_details_' .. tostring(item.name)) or ('forge_core_skill_details_' .. tostring(item.name)),
        options = options,
    })
end

function Menu.openSkillLevelDetails(kind, item, index, level, parentSkill)
    showContext({
        id = 'forge_core_skill_level_details_' .. tostring(kind) .. '_' .. tostring(item.name) .. '_' .. tostring(index),
        title = level.title or ('Nivel ' .. tostring(index - 1)),
        menu = 'forge_core_skill_levels_' .. tostring(kind) .. '_' .. tostring(item.name),
        options = {
            {
                title = t('menu.actions.edit'),
                icon = 'pen',
                onSelect = function()
                    Menu.openSkillLevelEditor(kind, item, index, level, false, parentSkill)
                end,
            },
            {
                title = t('menu.actions.remove'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local updated = clone(item)
                    updated.levels = clone(updated.levels or {})
                    table.remove(updated.levels, index)
                    saveSkillDefinition(kind, updated)

                    SetTimeout(500, function()
                        Menu.openSkillLevelList(kind, updated, parentSkill)
                    end)
                end,
            },
        },
    })
end

function Menu.openSkillLevelEditor(kind, item, index, level, isNew, parentSkill)
    level = level or {}

    local result = inputDialog(isNew and t('menu.skills.create_level') or t('dialogs.edit_level'), {
        {
            type = 'input',
            label = t('inputs.level_title'),
            default = level.title,
            required = true,
            min = 1,
            max = 48,
        },
        {
            type = 'number',
            label = t('inputs.level_from'),
            default = tonumber(level.from) or 0,
            required = true,
            min = 0,
        },
        {
            type = 'number',
            label = t('inputs.level_to'),
            default = tonumber(level.to) or 100,
            required = true,
            min = 1,
        },
    })

    if not result then return Menu.openSkillLevelList(kind, item, parentSkill) end

    local updated = clone(item)
    updated.levels = clone(updated.levels or {})

    local levelData = {
        title = result[1],
        from = tonumber(result[2]) or 0,
        to = tonumber(result[3]) or 1,
    }

    if isNew then
        updated.levels[#updated.levels + 1] = levelData
    else
        updated.levels[index] = levelData
    end

    saveSkillDefinition(kind, updated)

    SetTimeout(500, function()
        Menu.openSkillLevelList(kind, updated, parentSkill)
    end)
end

-- Camada 3: categorias do modulo de trabalhos.
pr_lib.callback.register(PR.Skills.Callbacks.openAdmin, function()
    Menu.openSkillsMenu()
    return true
end)

local function registerClientCommand(commandName, properties, callback)
    if pr_lib and pr_lib.command then
        return pr_lib.command(commandName, properties, callback)
    end

    RegisterCommand(commandName, function()
        callback()
    end, false)

    return true
end

registerClientCommand(PR.Skills.Commands.viewSkills, {
    help = t('commands.skills_view_help'),
}, function()
    Menu.openPlayerSkillsMenu()
end)

registerClientCommand(PR.Skills.Commands.viewReputations, {
    help = t('commands.reps_view_help'),
}, function()
    Menu.openPlayerReputationsMenu()
end)

