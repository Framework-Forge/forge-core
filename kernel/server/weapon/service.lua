-- Complete inactive installed service, with persistence wrapping deferred to explicit Initialize.
return function(ports)
    local services, library, native=assert(ports.services),assert(ports.library),assert(ports.native)
    local PR, translate={Weapons=assert(ports.config),NotifyPos=ports.notifyPosition,AdminAce=ports.adminAce},assert(ports.translate)
    assert(type(ports.resource)=='string','local core resource name required')
    local events={}
    local function listen(name,handler)events[#events+1]={name=name,handler=handler,network=false}end
local Service = {
    started = false,
}

local function notify(source, data)
    if source == 0 then return end
    if not library or not library.notify or not library.notify.NotifyPlayer then return end

    library.notify.NotifyPlayer(source, {
        title = data.title or translate('weapons.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function canManage(source)
    if services.JobService and services.JobService.canManage then
        local ok = services.JobService.canManage(source)
        if ok then return true end
    end

    if source == 0 then return true end

    return native.isAceAllowed(source, PR.AdminAce or 'forge-core.admin')
        or native.isAceAllowed(source, 'admin')
        or native.isAceAllowed(source, 'group.admin')
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getPayload()
    return services.WeaponRegistry.payload()
end

function Service.save(draft)
    draft = draft or services.WeaponRegistry
    local saved, err = services.WeaponStorage.save(draft.weapons)
    if not saved then return false, err end
    services.WeaponRegistry.weapons = draft.weapons
    services.WeaponRegistry.revision = draft.revision
    return true
end

function Service.reload()
    local weapons = services.WeaponStorage.load()
    services.WeaponRegistry.setAll(weapons)
    -- Persiste a forma normalizada para também migrar registros antigos que
    -- ainda não possuem o booleano `throwable` explícito.
    Service.save()
    services.WeaponQbxSync.syncAll()
    services.WeaponOxSync.syncAll()

    return true
end

function Service.saveAndSync(draft)
    local saved = Service.save(draft)
    if not saved then return false end
    services.WeaponQbxSync.syncAll()
    services.WeaponOxSync.syncAll()
    return saved
end

function Service.upsert(source, weaponData)
    if not canManage(source) then return false, 'no_permission' end

    local draft = library.jsonDraft(services.WeaponRegistry, {weapons=true})
    local ok, result = services.WeaponRegistry.upsert(weaponData, draft)
    if not ok then return false, result end

    if not Service.saveAndSync(draft) then return false, 'save_failed' end

    notify(source, {
        description = translate('notify.weapons.saved', { weapon = result.label or result.name }),
        type = 'success',
    })

    return true, result
end

function Service.delete(source, name)
    if not canManage(source) then return false, 'no_permission' end

    local draft = library.jsonDraft(services.WeaponRegistry, {weapons=true})
    local ok, err = services.WeaponRegistry.remove(name, draft)
    if not ok then return false, err end

    if not Service.saveAndSync(draft) then return false, 'save_failed' end

    notify(source, {
        description = translate('notify.weapons.removed', { weapon = name }),
        type = 'success',
    })

    return true
end

function Service.setActive(source, name, active)
    if not canManage(source) then return false, 'no_permission' end

    local draft = library.jsonDraft(services.WeaponRegistry, {weapons=true})
    local ok, weapon = services.WeaponRegistry.setActive(name, active, draft)
    if not ok then return false, weapon end

    if not Service.saveAndSync(draft) then return false, 'save_failed' end

    notify(source, {
        description = translate(active ~= false and 'notify.weapons.activated' or 'notify.weapons.deactivated', {
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

listen('onResourceStart', function(resourceName)
    if resourceName == ports.resource and Service.started then
        native.setTimeout(1500, function()
            services.WeaponQbxSync.syncAll()
        end)
    elseif resourceName == 'ox_inventory' and Service.started then
        native.setTimeout(1500, function()
            services.WeaponOxSync.syncAll()
        end)
    end
end)




    Service.Events=events
    local initialized,initializing=false,false
    function Service.Initialize()
        if initialized or initializing then return false end
        initializing=true
        local ok,err=pcall(function()
            library.wrapJsonMutations(PR.Weapons.Storage.file, Service, { 'upsert', 'delete', 'setActive' })
        end)
        initializing=false
        if not ok then error(err,0)end
        initialized=true
        return true
    end
    return Service
end
