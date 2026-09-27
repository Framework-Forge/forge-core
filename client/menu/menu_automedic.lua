ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared
local actionLocked = false

local function disabledIconColor(enabled)
    if enabled then return nil end
    return '#ef4444'
end

local function fetchSettings()
    local ok, payload = Shared.awaitServer(PR.AutoMedic.Callbacks.getSettings)
    if not ok then
        Shared.notifyFailure('notify.automedic.load_failed', payload)
        return nil
    end
    return payload
end

local function saveSettings(settings)
    if actionLocked then return end
    actionLocked = true
    local ok, payload = Shared.awaitServer(PR.AutoMedic.Callbacks.saveSettings, settings)
    if not ok then
        Shared.notifyFailure('notify.automedic.save_failed', payload)
    end
    SetTimeout(500, function()
        actionLocked = false
        Menu.openAutoMedicMenu()
    end)
end

function Menu.openAutoMedicMenu()
    local settings = fetchSettings()
    if not settings then return false end

    Shared.showContext({
        id = 'forge_core_automedic',
        title = 'Auto Atendimento Medico',
        menu = 'forge_core_main',
        options = {
            {
                title = 'Ativar AutoMedic',
                description = settings.enabled and 'Ativo: o NPC pode atender jogadores.' or 'Inativo: chamadas por NPC bloqueadas.',
                icon = 'heart-pulse-fill',
                iconColor = disabledIconColor(settings.enabled),
                onSelect = function()
                    settings.enabled = not settings.enabled
                    saveSettings(settings)
                end,
            },
            {
                title = 'Cooldown',
                description = ('Espera minima: %d minuto(s).'):format(math.floor((settings.cooldown or 0) / 60)),
                icon = 'clock-history',
                onSelect = function()
                    local result = Shared.inputDialog('Cooldown do AutoMedic', {
                        { type = 'number', label = 'Minutos de espera', default = math.floor((settings.cooldown or 0) / 60), min = 0, max = 60, required = true },
                    })
                    if not result then return Menu.openAutoMedicMenu() end
                    settings.cooldown = math.floor((tonumber(result[1]) or 0) * 60)
                    saveSettings(settings)
                end,
            },
            {
                title = 'Cura da bandagem',
                description = ('Cada bandage recupera %d%% da saude maxima.'):format(tonumber(settings.bandageHealPercent) or 10),
                icon = 'bandage-fill',
                onSelect = function()
                    local result = Shared.inputDialog('Cura da bandagem', {
                        { type = 'number', label = 'Porcentagem de cura por item', default = tonumber(settings.bandageHealPercent) or 10, min = 1, max = 100, required = true },
                    })
                    if not result then return Menu.openAutoMedicMenu() end
                    settings.bandageHealPercent = math.max(1, math.min(math.floor(tonumber(result[1]) or 10), 100))
                    saveSettings(settings)
                end,
            },
            {
                title = 'Valor do atendimento',
                description = (tonumber(settings.treatmentPrice) or 0) > 0
                    and ('Cobranca automatica: R$ %d.'):format(math.floor(tonumber(settings.treatmentPrice) or 0))
                    or 'Atendimento gratuito.',
                icon = 'cash-coin',
                onSelect = function()
                    local result = Shared.inputDialog('Valor do atendimento', {
                        { type = 'number', label = 'Valor em R$', default = tonumber(settings.treatmentPrice) or 0, min = 0, max = 1000000000, required = true },
                    })
                    if not result then return Menu.openAutoMedicMenu() end
                    settings.treatmentPrice = math.max(0, math.floor(tonumber(result[1]) or 0))
                    saveSettings(settings)
                end,
            },
            {
                title = 'Saude apos reviver',
                description = ('O jogador retorna com %d%% de saude.'):format(tonumber(settings.reviveHealthPercent) or 10),
                icon = 'heart-pulse',
                onSelect = function()
                    local result = Shared.inputDialog('Saude apos reviver', {
                        { type = 'number', label = 'Porcentagem de saude', default = tonumber(settings.reviveHealthPercent) or 10, min = 1, max = 100, required = true },
                    })
                    if not result then return Menu.openAutoMedicMenu() end
                    settings.reviveHealthPercent = math.max(1, math.min(math.floor(tonumber(result[1]) or 10), 100))
                    saveSettings(settings)
                end,
            },
            {
                title = 'Morte por tiro',
                description = settings.loseInventory.gunshot and 'Perde todo o inventario.' or 'Mantem o inventario.',
                icon = 'crosshair',
                iconColor = disabledIconColor(settings.loseInventory.gunshot),
                onSelect = function()
                    settings.loseInventory.gunshot = not settings.loseInventory.gunshot
                    saveSettings(settings)
                end,
            },
            {
                title = 'Morte por outros motivos',
                description = settings.loseInventory.other and 'Perde todo o inventario.' or 'Mantem o inventario.',
                icon = 'activity',
                iconColor = disabledIconColor(settings.loseInventory.other),
                onSelect = function()
                    settings.loseInventory.other = not settings.loseInventory.other
                    saveSettings(settings)
                end,
            },
            {
                title = 'Desmaio por fome, sede ou sangramento',
                description = settings.loseInventory.collapse and 'Perde todo o inventario.' or 'Mantem o inventario.',
                icon = 'droplet-half',
                iconColor = disabledIconColor(settings.loseInventory.collapse),
                onSelect = function()
                    settings.loseInventory.collapse = not settings.loseInventory.collapse
                    saveSettings(settings)
                end,
            },
        },
    })
    return true
end
