ForgeCore = ForgeCore or {}
local Menu, Shared = ForgeCore.Client.Menu, ForgeCore.Client.MenuShared

local function boolOptions()
    return {
        { value = 'true', label = 'Sim' },
        { value = 'false', label = 'Não' },
    }
end

local function isTrue(value)
    return value == true or value == 'true' or value == 1 or value == '1'
end

function Menu.openCharacterSlotSettings(parent)
    local ok, settings = Shared.awaitServer(PR.CharacterSlots.callbacks.getSettings)
    if not ok then Shared.notifyFailure('notify.player.load_failed', settings); return end
    local selected, amounts, labels = {}, {}, {}
    for _, item in ipairs(settings.starterItems or {}) do
        selected[#selected + 1] = item.name
        amounts[item.name] = item.amount
    end
    for _, option in ipairs(settings.itemOptions or {}) do labels[option.value] = option.label end
    local form = Shared.inputDialog('Slots de personagem', {
        { type = 'number', label = 'Limite máximo de slots', default = settings.maxSlots, min = 1, max = 50, required = true },
        { type = 'select', label = 'Exigir item new_slot', default = tostring(settings.requireItem), options = boolOptions(), required = true },
        { type = 'number', label = 'Slots liberados por item', default = settings.slotsPerItem, min = 1, max = 50, required = true },
        { type = 'select', label = 'Perder slot comprado ao excluir personagem', default = tostring(settings.loseSlotOnDelete), options = boolOptions(), required = true },
        { type = 'input', label = 'Exemplo de nome', default = settings.firstNamePlaceholder, required = true, max = 50 },
        { type = 'input', label = 'Exemplo de sobrenome', default = settings.lastNamePlaceholder, required = true, max = 50 },
        { type = 'select', label = 'Exigir idade mínima', default = tostring(settings.minimumAgeEnabled), options = boolOptions(), required = true },
        { type = 'number', label = 'Idade mínima', default = settings.minimumAge, min = 1, max = 100, required = true },
        { type = 'select', label = 'Exigir aceite dos termos', default = tostring(settings.termsEnabled), options = boolOptions(), required = true },
        { type = 'input', label = 'Título dos termos', default = settings.termsTitle, required = true, max = 120 },
        { type = 'input', label = 'Versão dos termos', default = settings.termsVersion, required = true, max = 40 },
        { type = 'textarea', label = 'Termos de uso e responsabilidade', default = settings.termsText, required = true, min = 1, max = 8000, autosize = true },
        { type = 'multi-select', label = 'Itens iniciais do personagem', description = 'Selecione os itens e depois informe as quantidades. Sem seleção, nenhum item será entregue.', options = settings.itemOptions or {}, default = selected, searchable = true, tags = true },
    })
    if not form then return parent and Menu.openCharacterCreationSettings(parent) end
    local starterItems, rows = {}, {}
    for _, name in ipairs(form[13] or {}) do
        rows[#rows + 1] = { type = 'number', label = labels[name] or name, default = amounts[name] or 1, min = 1, max = 1000000, precision = 0, required = true }
    end
    if #rows > 0 then
        local quantities = Shared.inputDialog('Quantidade dos itens iniciais', rows)
        if not quantities then return end
        for i, name in ipairs(form[13]) do starterItems[#starterItems + 1] = { name = name, amount = quantities[i] } end
    end
    local saved, errorCode = Shared.awaitServer(PR.CharacterSlots.callbacks.saveSettings, {
        starterItems = starterItems,
        maxSlots = form[1], requireItem = isTrue(form[2]), slotsPerItem = form[3],
        loseSlotOnDelete = isTrue(form[4]), firstNamePlaceholder = form[5], lastNamePlaceholder = form[6],
        minimumAgeEnabled = isTrue(form[7]), minimumAge = form[8], termsEnabled = isTrue(form[9]),
        termsTitle = form[10], termsVersion = form[11], termsText = form[12],
    })
    if not saved then Shared.notifyFailure('notify.player.load_failed', errorCode) end
    SetTimeout(300, function() Menu.openCharacterCreationSettings(parent) end)
end

local function previewAnimationLabel(settings, animationId)
    for _, animation in ipairs(settings.previewAnimations or {}) do
        if animation.id == animationId then return animation.label or animation.id end
    end
    return animationId or 'Em pé'
end

local function positionCharacterPreview(parent, index)
    local ok, settings = Shared.awaitServer(PR.CharacterSlots.callbacks.getSettings)
    if not ok then Shared.notifyFailure('notify.player.load_failed', settings); return end
    local devtools = pr_lib.fivem and (pr_lib.fivem.devtools or pr_lib.fivem.devTools)
    local placeAnimatedPed = devtools and (devtools.placeAnimatedPed or devtools.PlaceAnimatedPed)
    if type(placeAnimatedPed) ~= 'function' then
        Shared.notify({ title = 'Criação de personagens', description = 'Posicionador animado do PR Bridge indisponível.', type = 'error' })
        return
    end

    Shared.notify({
        title = 'Preview de personagem',
        description = 'Setas esquerda/direita alteram a animação. Posicione e pressione ENTER para salvar.',
        type = 'inform',
    })
    local started = placeAnimatedPed(settings.previewModel or 'mp_m_freemode_01', 1, settings.previewAnimations or {}, function(result)
        if result then
            local saved, errorCode = Shared.awaitServer(PR.CharacterSlots.callbacks.savePreview, index, result)
            if not saved then
                Shared.notifyFailure('notify.player.load_failed', errorCode)
            else
                Shared.notify({ title = 'Criação de personagens', description = index and 'Preview atualizado.' or 'Preview adicionado.', type = 'success' })
            end
        end
        SetTimeout(300, function() Menu.openCharacterPreviewSettings(parent) end)
    end, { freezePlayer = true, moveSpeed = 0.6, previewAlpha = 210 })
    if not started then
        Shared.notify({ title = 'Criação de personagens', description = 'Não foi possível iniciar o posicionador.', type = 'error' })
        SetTimeout(300, function() Menu.openCharacterPreviewSettings(parent) end)
    end
end

function Menu.openCharacterPreviewSettings(parent)
    local ok, settings = Shared.awaitServer(PR.CharacterSlots.callbacks.getSettings)
    if not ok then Shared.notifyFailure('notify.player.load_failed', settings); return end
    local previews = settings.previews or {}
    local options = {{
        title = 'Adicionar posição de preview',
        description = 'Posicione um ped e escolha sua animação com as setas esquerda/direita.',
        icon = 'person-circle-plus',
        onSelect = function() positionCharacterPreview(parent) end,
    }}
    for index, preview in ipairs(previews) do
        local currentIndex = index
        options[#options + 1] = {
            title = ('Preview do slot #%s'):format(index),
            description = ('%s | %.2f, %.2f, %.2f | direção %.2f'):format(
                previewAnimationLabel(settings, preview.animation), preview.x, preview.y, preview.z, preview.heading
            ),
            icon = 'person-standing',
            arrow = true,
            onSelect = function()
                Shared.showContext({
                    id = 'forge_core_character_preview_actions',
                    title = ('Preview do slot #%s'):format(currentIndex),
                    menu = 'forge_core_character_preview_settings',
                    options = {
                        {
                            title = 'Reposicionar e alterar animação', icon = 'arrows-move',
                            onSelect = function() positionCharacterPreview(parent, currentIndex) end,
                        },
                        {
                            title = 'Remover preview', icon = 'trash-fill', iconColor = '#ef4444',
                            onSelect = function()
                                local answer = Shared.alertDialog({
                                    header = 'Remover preview',
                                    content = ('Remover a posição do slot #%s? Os pontos seguintes serão reorganizados.'):format(currentIndex),
                                    centered = true, cancel = true,
                                })
                                if answer == 'confirm' then
                                    local removed, errorCode = Shared.awaitServer(PR.CharacterSlots.callbacks.deletePreview, currentIndex)
                                    if not removed then Shared.notifyFailure('notify.player.load_failed', errorCode) end
                                end
                                SetTimeout(250, function() Menu.openCharacterPreviewSettings(parent) end)
                            end,
                        },
                    },
                })
            end,
        }
    end
    if #previews == 0 then
        options[#options + 1] = { title = 'Nenhuma posição cadastrada', description = 'O QBX continuará usando o preview padrão.', icon = 'info-circle', disabled = true }
    end
    Shared.showContext({
        id = 'forge_core_character_preview_settings',
        title = 'Posicionamento dos previews',
        menu = 'forge_core_character_creation_settings',
        options = options,
    })
end

function Menu.openCharacterCreationSettings(parent)
    Shared.showContext({
        id = 'forge_core_character_creation_settings',
        title = 'Criação de personagens',
        menu = parent or 'forge_core_players_management',
        options = {
            {
                title = 'Configuração de slots',
                description = 'Limite, item new_slot, idade mínima, termos, nomes e itens iniciais.',
                icon = 'person-circle-plus', arrow = true,
                onSelect = function() Menu.openCharacterSlotSettings(parent or 'forge_core_players_management') end,
            },
            {
                title = 'Posicionamento dos previews',
                description = 'Cadastre um ped animado para cada slot. Pontos extras ficam prontos para futuros slots.',
                icon = 'people-fill', arrow = true,
                onSelect = function() Menu.openCharacterPreviewSettings(parent or 'forge_core_players_management') end,
            },
        },
    })
end

function Menu.openPlayerCharacterSlots(target)
    local ok, data = Shared.awaitServer(PR.CharacterSlots.callbacks.getPlayer, target)
    if not ok then Shared.notifyFailure('notify.player.load_failed', data); return Menu.openManagedPlayer(target) end
    local options = {{
        title = ('Slots liberados: %s/%s'):format(data.unlockedCount or 1, data.settings.maxSlots or 1),
        description = 'Suspender impede o uso sem apagar o personagem ou retirar o direito ao slot. Inclui o primeiro slot e slots vazios.',
        icon = 'person-circle-check', disabled = true,
    }}
    for slot = 1, data.maxSlots do
        local unlocked = data.unlocked[slot] == true or data.unlocked[tostring(slot)] == true
        local blocked = data.blocked[slot] == true or data.blocked[tostring(slot)] == true
        local occupant = data.occupied[slot] or data.occupied[tostring(slot)]
        local slotId = slot
        options[#options + 1] = {
            title = ('Slot #%s — %s'):format(slot, blocked and 'Suspenso' or occupant and ('Ocupado por ' .. occupant) or unlocked and 'Liberado' or 'Não adquirido'),
            description = (occupant and ('Personagem: ' .. occupant .. '. ') or 'Slot vazio. ') .. (blocked and 'Clique para retirar a suspensão.' or 'Clique para suspender o uso deste slot.'),
            icon = blocked and 'lock-fill' or 'person-fill',
            onSelect = function()
                local saved, errorCode = Shared.awaitServer(PR.CharacterSlots.callbacks.setPlayerSlot, target, slotId, blocked)
                if not saved then Shared.notifyFailure('notify.player.load_failed', errorCode) end
                SetTimeout(250, function() Menu.openPlayerCharacterSlots(target) end)
            end,
        }
        if not blocked and not unlocked then
            options[#options + 1] = {
                title = ('Conceder slot #%s'):format(slot), icon = 'unlock-fill',
                onSelect = function()
                    local saved, errorCode = Shared.awaitServer(PR.CharacterSlots.callbacks.setPlayerSlot, target, slotId, true)
                    if not saved then Shared.notifyFailure('notify.player.load_failed', errorCode) end
                    SetTimeout(250, function() Menu.openPlayerCharacterSlots(target) end)
                end,
            }
        end
    end
    Shared.showContext({ id = 'forge_core_player_character_slots', title = 'Slots do jogador', menu = 'forge_core_managed_player', options = options })
end
