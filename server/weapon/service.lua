ForgeCore = ForgeCore or {}

local Service = {
    started = false,
}

local function notify(source, data)
    if source == 0 then return end
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('weapons.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function canManage(source)
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        local ok = ForgeCore.JobService.canManage(source)
        if ok then return true end
    end

    if source == 0 then return true end

    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
        or IsPlayerAceAllowed(source, 'admin')
        or IsPlayerAceAllowed(source, 'group.admin')
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getPayload()
    return ForgeCore.WeaponRegistry.payload()
end

function Service.save()
    return ForgeCore.WeaponStorage.save(ForgeCore.WeaponRegistry.getWeapons())
end

function Service.reload()
    local weapons = ForgeCore.WeaponStorage.load()
    ForgeCore.WeaponRegistry.setAll(weapons)
    ForgeCore.WeaponQbxSync.syncAll()
    ForgeCore.WeaponOxSync.syncAll()

    return true
end

function Service.saveAndSync()
    local saved = Service.save()
    ForgeCore.WeaponQbxSync.syncAll()
    ForgeCore.WeaponOxSync.syncAll()
    return saved
end

function Service.upsert(source, weaponData)
    if not canManage(source) then return false, 'no_permission' end

    local ok, result = ForgeCore.WeaponRegistry.upsert(weaponData)
    if not ok then return false, result end

    Service.saveAndSync()

    notify(source, {
        description = ForgeCore.t('notify.weapons.saved', { weapon = result.label or result.name }),
        type = 'success',
    })

    return true, result
end

function Service.delete(source, name)
    if not canManage(source) then return false, 'no_permission' end

    local ok, err = ForgeCore.WeaponRegistry.remove(name)
    if not ok then return false, err end

    Service.saveAndSync()

    notify(source, {
        description = ForgeCore.t('notify.weapons.removed', { weapon = name }),
        type = 'success',
    })

    return true
end

function Service.setActive(source, name, active)
    if not canManage(source) then return false, 'no_permission' end

    local ok, weapon = ForgeCore.WeaponRegistry.setActive(name, active)
    if not ok then return false, weapon end

    Service.saveAndSync()

    notify(source, {
        description = ForgeCore.t(active ~= false and 'notify.weapons.activated' or 'notify.weapons.deactivated', {
            weapon = weapon.label or weapon.name,
        }),
        type = 'success',
    })

    return true, weapon
end

function Service.start()
    if Service.started then return true end

    Service.started = true
    Service.reload()

    return true
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'qbx_core' and Service.started then
        SetTimeout(1500, function()
            ForgeCore.WeaponQbxSync.syncAll()
        end)
    elseif resourceName == 'ox_inventory' and Service.started then
        SetTimeout(1500, function()
            ForgeCore.WeaponOxSync.syncAll()
        end)
    end
end)

ForgeCore.WeaponService = Service
