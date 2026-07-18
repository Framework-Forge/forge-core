ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local alertDialog = Shared.alertDialog

local function notify(description, notifyType)
    if pr_lib and pr_lib.notify and pr_lib.notify.Notify then
        pr_lib.notify.Notify({
            title = t('npcs.title'),
            description = description,
            type = notifyType or 'inform',
            position = PR.NotifyPos,
        })
    end
end

local function fetchPayload()
    local ok, payload = awaitServer(PR.Npcs.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.npcs.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.groups = type(payload.groups) == 'table' and payload.groups or {}
    payload.npcs = type(payload.npcs) == 'table' and payload.npcs or {}

    return payload
end

local function pedImage(model)
    if pr_lib and pr_lib.fivem and pr_lib.fivem.blips and pr_lib.fivem.blips.getPedImageUrl then
        return pr_lib.fivem.blips.getPedImageUrl(model)
    end
end

local function ensureOption(options, value, label)
    value = tostring(value or '')
    if value == '' then return end

    for index = 1, #options do
        if options[index].value == value then return end
    end

    options[#options + 1] = { value = value, label = label or value }
end

local function fetchQbxGroups()
    local groups = {
        job = {},
        gang = {},
    }

    if GetResourceState('qbx_core') ~= 'started' then return groups end

    local okJobs, jobs = pcall(function()
        return exports.qbx_core:GetJobs()
    end)

    if okJobs and type(jobs) == 'table' then
        groups.job = jobs
    end

    local okGangs, gangs = pcall(function()
        return exports.qbx_core:GetGangs()
    end)

    if okGangs and type(gangs) == 'table' then
        groups.gang = gangs
    end

    return groups
end

local function addGroupOptions(options, groups)
    local names = {}

    for name in pairs(groups or {}) do
        names[#names + 1] = name
    end

    table.sort(names, function(left, right)
        local leftGroup = groups[left] or {}
        local rightGroup = groups[right] or {}
        return tostring(leftGroup.label or left) < tostring(rightGroup.label or right)
    end)

    for index = 1, #names do
        local name = names[index]
        local group = groups[name] or {}

        options[#options + 1] = {
            value = name,
            label = group.label or name,
        }
    end
end

local function accessGroupOptions(groupType, currentValue)
    local options = {
        { value = '', label = t('common.none') },
    }

    local groups = fetchQbxGroups()
    addGroupOptions(options, groups[groupType] or {})
    ensureOption(options, currentValue)

    return options
end

local function createGroup()
    local result = inputDialog(t('menu.npcs.create_group'), {
        {
            type = 'input',
            label = t('inputs.npc_group_name'),
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.npc_group_description'),
        },
    })

    if not result then
        Menu.openNpcsMenu()
        return
    end

    local ok, response = awaitServer(PR.Npcs.Callbacks.createGroup, {
        name = tostring(result[1] or ''),
        description = tostring(result[2] or ''),
    })

    if not ok then
        notifyFailure('notify.npcs.group_create_failed', response)
    end

    SetTimeout(400, function()
        Menu.openNpcsMenu()
    end)
end

local function renameGroup(group)
    local result = inputDialog(t('menu.npcs.rename_group'), {
        {
            type = 'input',
            label = t('inputs.npc_group_name'),
            default = group.name,
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.npc_group_description'),
            default = group.description,
        },
    })

    if not result then
        Menu.openNpcsGroup(group.id, group.name)
        return
    end

    local ok, response = awaitServer(PR.Npcs.Callbacks.renameGroup, group.id, {
        name = tostring(result[1] or ''),
        description = tostring(result[2] or ''),
    })

    if not ok then
        notifyFailure('notify.npcs.group_rename_failed', response)
    end

    SetTimeout(400, function()
        Menu.openNpcsMenu()
    end)
end

local function deleteGroup(group)
    local confirmed = true
    if alertDialog then
        local result = alertDialog({
            header = t('dialogs.remove_npc_group_header'),
            content = t('dialogs.remove_npc_group_content', { group = group.name }),
            centered = true,
            cancel = true,
        })
        confirmed = result == 'confirm'
    end

    if not confirmed then
        Menu.openNpcsGroup(group.id, group.name)
        return
    end

    local ok, response = awaitServer(PR.Npcs.Callbacks.deleteGroup, group.id)
    if not ok then
        notifyFailure('notify.npcs.group_delete_failed', response)
    end

    SetTimeout(400, function()
        Menu.openNpcsMenu()
    end)
end

local function findPedModels(search)
    local results = {}
    local needle = tostring(search or ''):lower()
    local models = PR.Npcs.PedModels or {}

    for _, item in ipairs(models) do
        local model = tostring(item[2] or '')
        local label = tostring(item[3] or model)
        local isAnimal = model:sub(1, 4) == 'a_c_'
        if not isAnimal and (needle == '' or model:lower():find(needle, 1, true) or label:lower():find(needle, 1, true)) then
            results[#results + 1] = {
                hash = item[1],
                model = model,
                label = label,
            }
        end
    end

    table.sort(results, function(left, right) return left.model < right.model end)
    return results
end

local function choosePedModel(group, search, page)
    page = math.max(1, tonumber(page) or 1)
    local models = findPedModels(search)
    local perPage = 60
    local totalPages = math.max(1, math.ceil(#models / perPage))
    if page > totalPages then page = totalPages end
    local startIndex = ((page - 1) * perPage) + 1
    local endIndex = math.min(#models, startIndex + perPage - 1)

    local options = {
        {
            title = t('menu.npcs.search_model'),
            description = t('menu.npcs.search_model_description', {
                page = tostring(page),
                pages = tostring(totalPages),
                count = tostring(#models),
            }),
            icon = 'magnifying-glass',
            onSelect = function()
                local result = inputDialog(t('menu.npcs.search_model'), {
                    {
                        type = 'input',
                        label = t('inputs.npc_model_search'),
                        default = search or '',
                    },
                })

                if result then
                    choosePedModel(group, tostring(result[1] or ''), 1)
                else
                    Menu.openNpcsGroup(group.id, group.name)
                end
            end,
        },
    }

    if page > 1 then
        options[#options + 1] = {
            title = t('menu.npcs.previous_page'),
            icon = 'arrow-left',
            onSelect = function()
                choosePedModel(group, search, page - 1)
            end,
        }
    end

    for index = startIndex, endIndex do
        local ped = models[index]
        options[#options + 1] = {
            title = ped.label,
            description = ped.model,
            icon = 'user',
            image = pedImage(ped.model),
            metadata = {
                { label = t('inputs.npc_model'), value = ped.model },
                { label = t('inputs.npc_hash'), value = tostring(ped.hash) },
            },
            onSelect = function()
                local result = inputDialog(t('menu.npcs.create_npc'), {
                    {
                        type = 'input',
                        label = t('inputs.npc_name'),
                        default = ped.label,
                        required = true,
                    },
                    {
                        type = 'input',
                        label = t('inputs.npc_description'),
                        default = ped.model,
                    },
                })

                if not result then
                    choosePedModel(group, search, page)
                    return
                end

                local created, error = ForgeCore.Client.Npcs.createPreview(ped.model, group.id, tostring(result[1] or ''), tostring(result[2] or ''), function()
                    SetTimeout(600, function()
                        Menu.openNpcsGroup(group.id, group.name)
                    end)
                end)

                if not created then
                    notifyFailure('notify.npcs.create_failed', error)
                    Menu.openNpcsGroup(group.id, group.name)
                end
            end,
        }
    end

    if page < totalPages then
        options[#options + 1] = {
            title = t('menu.npcs.next_page'),
            description = t('menu.npcs.page_description', {
                page = tostring(page),
                pages = tostring(totalPages),
            }),
            icon = 'arrow-right',
            onSelect = function()
                choosePedModel(group, search, page + 1)
            end,
        }
    end

    showContext({
        id = 'forge_core_npcs_models',
        title = t('menu.npcs.model_list'),
        menu = 'forge_core_npcs_group',
        options = options,
    })
end

local function createNpc(group)
    choosePedModel(group, '', 1)
end

local function deleteNpc(npc)
    local confirmed = true
    if alertDialog then
        local result = alertDialog({
            header = t('dialogs.remove_npc_header'),
            content = t('dialogs.remove_npc_content', { npc = npc.name }),
            centered = true,
            cancel = true,
        })
        confirmed = result == 'confirm'
    end

    if not confirmed then
        Menu.openNpcActions(npc.id)
        return
    end

    local ok, response = awaitServer(PR.Npcs.Callbacks.deleteNpc, npc.id)
    if not ok then
        notifyFailure('notify.npcs.delete_failed', response)
    end

    SetTimeout(400, function()
        Menu.openNpcsGroup(npc.groupId, t('menu.npcs.group_title', { id = tostring(npc.groupId) }))
    end)
end

local function editBasic(npc)
    local result = inputDialog(t('menu.npcs.edit_basic'), {
        {
            type = 'input',
            label = t('inputs.npc_name'),
            default = npc.name,
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.npc_description'),
            default = npc.description,
        },
        {
            type = 'select',
            label = t('inputs.npc_enabled'),
            options = {
                { label = t('common.yes'), value = 'true' },
                { label = t('common.no'), value = 'false' },
            },
            default = npc.enabled == false and 'false' or 'true',
            required = true,
        },
    })

    if not result then
        Menu.openNpcActions(npc.id)
        return
    end

    local ok, response = awaitServer(PR.Npcs.Callbacks.updateNpc, npc.id, {
        name = tostring(result[1] or ''),
        description = tostring(result[2] or ''),
        enabled = tostring(result[3]) == 'true',
    })

    if not ok then
        notifyFailure('notify.npcs.update_failed', response)
    end

    SetTimeout(400, function()
        Menu.openNpcActions(npc.id)
    end)
end

local function editInteraction(npc)
    local interaction = type(npc.interaction) == 'table' and npc.interaction or {}
    local access = type(interaction.access) == 'table' and interaction.access or {}
    local currentJob = tostring(access.job or '')
    local currentGang = tostring(access.gang or '')

    local result = inputDialog(t('menu.npcs.edit_interaction'), {
        {
            type = 'select',
            label = t('inputs.npc_interaction_mode'),
            options = {
                { label = t('menu.npcs.mode_none'), value = 'none' },
                { label = t('menu.npcs.mode_target'), value = 'target' },
                { label = t('menu.npcs.mode_drawtext'), value = 'drawtext' },
                { label = t('menu.npcs.mode_both'), value = 'both' },
            },
            default = interaction.mode or 'none',
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.npc_target_label'),
            default = interaction.label or npc.name,
        },
        {
            type = 'input',
            label = t('inputs.npc_event'),
            default = interaction.event or '',
        },
        {
            type = 'number',
            label = t('inputs.npc_distance'),
            default = tonumber(interaction.distance) or PR.Npcs.Defaults.interactionDistance,
            min = 1,
            max = 10,
        },
        {
            type = 'select',
            label = t('inputs.npc_job'),
            options = accessGroupOptions('job', currentJob),
            default = currentJob,
            searchable = true,
        },
        {
            type = 'number',
            label = t('inputs.npc_grade'),
            default = tonumber(access.grade) or 0,
            min = 0,
        },
        {
            type = 'select',
            label = t('inputs.npc_gang'),
            options = accessGroupOptions('gang', currentGang),
            default = currentGang,
            searchable = true,
        },
        {
            type = 'number',
            label = t('inputs.npc_gang_grade'),
            default = tonumber(access.gangGrade) or 0,
            min = 0,
        },
    })

    if not result then
        Menu.openNpcActions(npc.id)
        return
    end

    local ok, response = awaitServer(PR.Npcs.Callbacks.updateNpc, npc.id, {
        interaction = {
            mode = tostring(result[1] or 'none'),
            label = tostring(result[2] or ''),
            event = tostring(result[3] or ''),
            distance = tonumber(result[4]) or PR.Npcs.Defaults.interactionDistance,
            access = {
                job = tostring(result[5] or ''),
                grade = tonumber(result[6]) or 0,
                gang = tostring(result[7] or ''),
                gangGrade = tonumber(result[8]) or 0,
            },
        },
    })

    if not ok then
        notifyFailure('notify.npcs.update_failed', response)
    end

    SetTimeout(400, function()
        Menu.openNpcActions(npc.id)
    end)
end

local function editAnimation(npc)
    local animation = type(npc.animation) == 'table' and npc.animation or {}
    local presetOptions = {}
    local selectedPreset = 'manual'

    for _, preset in ipairs(PR.Npcs.AnimationPresets or {}) do
        presetOptions[#presetOptions + 1] = {
            value = preset.value,
            label = preset.label,
        }

        if preset.scenario ~= nil and preset.scenario == animation.scenario then
            selectedPreset = preset.value
        elseif preset.animDict ~= nil and preset.animDict == animation.animDict and preset.animName == animation.animName then
            selectedPreset = preset.value
        end
    end

    if (animation.scenario or '') == '' and (animation.animDict or '') == '' and (animation.animName or '') == '' then
        selectedPreset = 'none'
    end

    local result = inputDialog(t('menu.npcs.edit_animation'), {
        {
            type = 'select',
            label = t('inputs.npc_animation_preset'),
            options = presetOptions,
            default = selectedPreset,
            required = true,
            searchable = true,
        },
        {
            type = 'input',
            label = t('inputs.npc_scenario'),
            default = animation.scenario or '',
            description = t('inputs.npc_manual_only'),
        },
        {
            type = 'input',
            label = t('inputs.npc_anim_dict'),
            default = animation.animDict or '',
            description = t('inputs.npc_manual_only'),
        },
        {
            type = 'input',
            label = t('inputs.npc_anim_name'),
            default = animation.animName or '',
            description = t('inputs.npc_manual_only'),
        },
    })

    if not result then
        Menu.openNpcActions(npc.id)
        return
    end

    local nextAnimation = {
        scenario = tostring(result[2] or ''),
        animDict = tostring(result[3] or ''),
        animName = tostring(result[4] or ''),
    }

    local presetValue = tostring(result[1] or 'manual')
    if presetValue == 'none' then
        nextAnimation = { scenario = '', animDict = '', animName = '' }
    elseif presetValue ~= 'manual' then
        for _, preset in ipairs(PR.Npcs.AnimationPresets or {}) do
            if preset.value == presetValue then
                nextAnimation = {
                    scenario = tostring(preset.scenario or ''),
                    animDict = tostring(preset.animDict or ''),
                    animName = tostring(preset.animName or ''),
                }
                break
            end
        end
    end

    local ok, response = awaitServer(PR.Npcs.Callbacks.updateNpc, npc.id, {
        animation = nextAnimation,
    })

    if not ok then
        notifyFailure('notify.npcs.update_failed', response)
    end

    SetTimeout(400, function()
        Menu.openNpcActions(npc.id)
    end)
end

function Menu.openNpcsMenu()
    local payload = fetchPayload()
    if not payload then return end

    local options = {
        {
            title = t('menu.npcs.create_group'),
            description = t('menu.npcs.create_group_description'),
            icon = 'folder-plus',
            onSelect = createGroup,
        },
        {
            title = ForgeCore.Client.Npcs.debugIds and t('menu.npcs.disable_debug') or t('menu.npcs.enable_debug'),
            description = t('menu.npcs.debug_description'),
            icon = ForgeCore.Client.Npcs.debugIds and 'toggle-right' or 'toggle-left',
            iconColor = ForgeCore.Client.Npcs.debugIds and 'green' or 'red',
            onSelect = function()
                ForgeCore.Client.Npcs.toggleDebug()
                Menu.openNpcsMenu()
            end,
        },
        {
            title = t('menu.npcs.total_groups', { count = tostring(#payload.groups) }),
            icon = 'users',
            disabled = true,
        },
    }

    for _, group in ipairs(payload.groups) do
        options[#options + 1] = {
            title = group.name,
            description = group.description ~= '' and group.description or t('menu.npcs.group_description', { count = tostring(group.count or 0) }),
            icon = 'folder',
            onSelect = function()
                Menu.openNpcsGroup(group.id, group.name)
            end,
        }
    end

    showContext({
        id = 'forge_core_npcs',
        title = t('menu.npcs.title'),
        menu = 'forge_core_server_settings',
        options = options,
    })
end

function Menu.openNpcsGroup(groupId, groupName)
    local payload = fetchPayload()
    if not payload then return end

    local group = { id = groupId, name = groupName, description = '' }
    for _, item in ipairs(payload.groups) do
        if tonumber(item.id) == tonumber(groupId) then group = item break end
    end

    local groupNpcs = {}
    for _, npc in ipairs(payload.npcs) do
        if tonumber(npc.groupId or npc.groupid) == tonumber(groupId) then
            groupNpcs[#groupNpcs + 1] = npc
        end
    end

    table.sort(groupNpcs, function(left, right) return tonumber(left.id) < tonumber(right.id) end)

    local options = {
        {
            title = t('menu.npcs.create_npc'),
            description = t('menu.npcs.create_npc_description'),
            icon = 'user-plus',
            onSelect = function()
                createNpc(group)
            end,
        },
        {
            title = t('menu.npcs.rename_group'),
            description = t('menu.npcs.rename_group_description'),
            icon = 'pen-to-square',
            onSelect = function()
                renameGroup(group)
            end,
        },
        {
            title = t('menu.npcs.delete_group'),
            description = #groupNpcs > 0 and t('menu.npcs.delete_group_blocked') or t('menu.npcs.delete_group_description'),
            icon = 'trash',
            iconColor = 'red',
            disabled = #groupNpcs > 0,
            onSelect = function()
                deleteGroup(group)
            end,
        },
        {
            title = t('menu.npcs.total_npcs', { count = tostring(#groupNpcs) }),
            icon = 'users',
            disabled = true,
        },
    }

    for _, npc in ipairs(groupNpcs) do
        options[#options + 1] = {
            title = ('[%s] %s'):format(npc.id, npc.name),
            description = t('menu.npcs.npc_description', {
                model = npc.model,
                status = npc.enabled == false and t('common.inactive') or t('common.active'),
            }),
            icon = 'user',
            image = pedImage(npc.model),
            onSelect = function()
                Menu.openNpcActions(npc.id)
            end,
        }
    end

    showContext({
        id = 'forge_core_npcs_group',
        title = group.name,
        menu = 'forge_core_npcs',
        onBack = function()
            for _, npc in ipairs(groupNpcs) do
                ForgeCore.Client.Npcs.setOutline(npc.id, false)
            end
        end,
        onExit = function()
            for _, npc in ipairs(groupNpcs) do
                ForgeCore.Client.Npcs.setOutline(npc.id, false)
            end
        end,
        options = options,
    })
end

function Menu.openNpcActions(npcId)
    local npc = ForgeCore.Client.Npcs.get(npcId)
    if not npc then
        notify(t('notify.npcs.npc_missing'), 'error')
        Menu.openNpcsMenu()
        return
    end

    ForgeCore.Client.Npcs.setOutline(npcId, true, 0, 220, 120)

    showContext({
        id = 'forge_core_npc_actions',
        title = ('[%s] %s'):format(npc.id, npc.name),
        menu = 'forge_core_npcs_group',
        onBack = function()
            ForgeCore.Client.Npcs.setOutline(npcId, false)
        end,
        onExit = function()
            ForgeCore.Client.Npcs.setOutline(npcId, false)
        end,
        options = {
            {
                title = t('menu.npcs.edit_position'),
                description = t('menu.npcs.edit_position_description'),
                icon = 'move-3d',
                onSelect = function()
                    ForgeCore.Client.Npcs.setOutline(npcId, false)
                    ForgeCore.Client.Npcs.edit(npcId)
                end,
            },
            {
                title = t('menu.npcs.edit_basic'),
                description = t('menu.npcs.edit_basic_description'),
                icon = 'pen-to-square',
                onSelect = function()
                    ForgeCore.Client.Npcs.setOutline(npcId, false)
                    editBasic(npc)
                end,
            },
            {
                title = t('menu.npcs.edit_interaction'),
                description = t('menu.npcs.edit_interaction_description'),
                icon = 'bolt',
                onSelect = function()
                    ForgeCore.Client.Npcs.setOutline(npcId, false)
                    editInteraction(npc)
                end,
            },
            {
                title = t('menu.npcs.edit_animation'),
                description = t('menu.npcs.edit_animation_description'),
                icon = 'person-walking',
                onSelect = function()
                    ForgeCore.Client.Npcs.setOutline(npcId, false)
                    editAnimation(npc)
                end,
            },
            {
                title = t('menu.npcs.teleport_npc'),
                icon = 'arrows-to-dot',
                onSelect = function()
                    ForgeCore.Client.Npcs.setOutline(npcId, false)
                    ForgeCore.Client.Npcs.teleportTo(npcId)
                    Menu.openNpcActions(npcId)
                end,
            },
            {
                title = t('menu.npcs.delete_npc'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    ForgeCore.Client.Npcs.setOutline(npcId, false)
                    deleteNpc(npc)
                end,
            },
        },
    })
end

if pr_lib and pr_lib.command then
    pr_lib.command(PR.Npcs.Command or 'npcspawner', {
        help = t('commands.npcs_help'),
    }, function()
        Menu.openNpcsMenu()
    end)
else
    RegisterCommand(PR.Npcs.Command or 'npcspawner', function()
        Menu.openNpcsMenu()
    end, false)
end
