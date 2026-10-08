ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared
local actionLocked = false
local function t(key, params) return ForgeCore.t('automedic.' .. key, params) end

local function currentPosition()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return {x=coords.x, y=coords.y, z=coords.z}, GetEntityHeading(ped)
end

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
                title = t('beds_title'),
                description = t('beds_description', {count=#(settings.beds or {})}),
                icon = 'hospital', arrow = true,
                onSelect = function() Menu.openAutoMedicBeds() end,
            },
            {
                title = t('fallback_title'),
                description = settings.hospitalFallback and t('fallback_enabled') or t('fallback_disabled'),
                icon = 'ambulance',
                onSelect = function()
                    settings.hospitalFallback = not settings.hospitalFallback
                    saveSettings(settings)
                end,
            },
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

local function saveBed(bed)
    if actionLocked then return end
    actionLocked = true
    local ok, payload = Shared.awaitServer(PR.AutoMedic.Callbacks.saveBed, bed)
    actionLocked = false
    if not ok then Shared.notifyFailure('notify.automedic.save_failed', payload) end
    Menu.openAutoMedicBeds()
end

local function placeBed(existing)
    local devtools = pr_lib.fivem and (pr_lib.fivem.devtools or pr_lib.fivem.devTools)
    if not devtools or type(devtools.placeAnimatedPed) ~= 'function' then
        Shared.notify({description=t('editor_unavailable'), type='error'})
        return Menu.openAutoMedicBeds()
    end
    local models = {}
    for _, model in ipairs(PR.AutoMedic.Hospital.models) do models[#models+1]={value=model,label=model} end
    local form = Shared.inputDialog(t('place_title'), {
        {type='input', label=t('bed_name'), default=existing and existing.label, required=true, max=80},
        {type='select', label=t('bed_model'), options=models, default=existing and existing.model or models[1].value, required=true},
    })
    if not form then return Menu.openAutoMedicBeds() end
    -- Capture the standing exit before opening the editor; no numeric coordinate inputs.
    local exit, exitHeading = currentPosition()
    if existing then exit, exitHeading = existing.exit, existing.exitHeading end
    local animation = {}
    for key, value in pairs(PR.AutoMedic.Hospital.animation) do animation[key]=value end
    animation.label = t('lying_pose')
    animation.animDict, animation.animName, animation.flag = animation.dict, animation.clip, animation.flags
    Shared.notify({description=t('placement_hint'), type='inform'})
    local started = devtools.placeAnimatedPed('mp_m_freemode_01', 1, {animation}, function(result)
        if not result then return Menu.openAutoMedicBeds() end
        local position = result.coords or result
        saveBed({
            id=existing and existing.id or ('bed_%s_%s'):format(GetGameTimer(), math.random(100000,999999)),
            label=form[1], model=form[2], coords={x=position.x,y=position.y,z=position.z},
            heading=result.heading or 0, exit=exit, exitHeading=exitHeading, prison=existing and existing.prison == true,
        })
    end, {freezePlayer=true, previewAlpha=210, moveSpeed=0.6})
    if not started then
        Shared.notify({description=t('editor_unavailable'), type='error'})
        Menu.openAutoMedicBeds()
    end
end

function Menu.openAutoMedicBeds()
    local settings = fetchSettings()
    if not settings then return false end
    local options = {{title=t('add_bed'), description=t('add_description'), icon='plus-lg', onSelect=function() placeBed() end}}
    for _, bed in ipairs(settings.beds or {}) do
        local currentBed = bed
        local imageApi = pr_lib.fivem and pr_lib.fivem.blips and pr_lib.fivem.blips.getPropImageUrl
        options[#options+1] = {
            title=bed.label, description=bed.model, icon='hospital', arrow=true,
            image=type(imageApi)=='function' and imageApi(bed.model) or nil,
            metadata={{label=t('location'),value=('%.2f, %.2f, %.2f'):format(bed.coords.x,bed.coords.y,bed.coords.z)}},
            onSelect=function()
                Shared.showContext({id='forge_core_automedic_bed', title=currentBed.label, menu='forge_core_automedic_beds', options={
                    {title=t('reposition'), description=t('placement_hint'), icon='arrows-move', onSelect=function() placeBed(currentBed) end},
                    {title=t('set_exit'), description=t('exit_description'), icon='person-walking', onSelect=function()
                        currentBed.exit, currentBed.exitHeading = currentPosition()
                        saveBed(currentBed)
                    end},
                    {title=t('prison_bed'), description=currentBed.prison and t('prison_only') or t('civilian_only'), icon='lock', onSelect=function()
                        currentBed.prison = not currentBed.prison
                        saveBed(currentBed)
                    end},
                    {title=t('delete_bed'), icon='trash', onSelect=function()
                        if Shared.alertDialog({header=t('delete_bed'),content=t('confirm_delete'),cancel=true,centered=true})=='confirm' then
                            local ok, payload=Shared.awaitServer(PR.AutoMedic.Callbacks.deleteBed,currentBed.id)
                            if not ok then Shared.notifyFailure('notify.automedic.save_failed',payload) end
                        end
                        Menu.openAutoMedicBeds()
                    end},
                }})
            end,
        }
    end
    Shared.showContext({id='forge_core_automedic_beds', title=t('beds_title'), menu='forge_core_automedic', options=options})
    return true
end
