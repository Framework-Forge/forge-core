-- Native command descriptors only; names and legacy diagnostic text are retained.
return function(ports)
    local services, library, native=assert(ports.services),assert(ports.library),assert(ports.native)
    local kernel, integrations, isReady=assert(ports.kernel),assert(ports.integrations),assert(ports.isReady)
    local PR={NotifyPos=ports.notifyPosition}
    local commands={}
    local function command(name,handler,restricted)commands[#commands+1]={name=name,handler=handler,restricted=restricted}end
local function notify(source, message, notifyType)
    if source <= 0 then
        native.print(('[forge-core] %s'):format(message))
        return
    end

    if not library or not library.notify or not library.notify.NotifyPlayer then return end

    library.notify.NotifyPlayer(source, {
        title = 'Armas',
        description = message,
        type = notifyType or 'inform',
        position = PR.NotifyPos,
    })
end

local function normalizeName(name)
    name = tostring(name or ''):lower():gsub('%s+', '_')
    if name == '' then return nil end
    if name:find('^weapon_') or name:find('^gadget_') then return name end

    return ('weapon_%s'):format(name)
end

local function canCheck(source)
    if source == 0 then return true end
    return services.WeaponService and services.WeaponService.canManage(source)
end

local function checkWeapon(source, args)
    if not canCheck(source) then
        notify(source, 'Acesso negado.', 'error')
        return
    end

    local weaponName = normalizeName(args and args[1])
    if not weaponName then
        notify(source, 'Use: /armaqbx weapon_pistol', 'error')
        return
    end

    local qbxStatus = 'qbx: indisponivel'
    local oxStatus = 'ox: indisponivel'
    local notifyType = 'error'

    if isReady() then
        local ok, exists, weapon, managedByForge, hash = pcall(function()
            return kernel.HasWeapon(weaponName)
        end)

        if ok and exists then
            qbxStatus = ('qbx: ativa hash=%s Forge=%s label=%s'):format(
                tostring(hash),
                managedByForge and 'sim' or 'nao',
                weapon and weapon.label or 'sem label'
            )
            notifyType = 'success'
        elseif ok then
            qbxStatus = 'qbx: desativada'
        else
            qbxStatus = 'qbx: erro na consulta'
        end
    end

    if integrations.inventoryState():find('start') ~= nil then
        local ok, exists, item, isWeapon = pcall(function()
            return integrations.HasWeaponItem(weaponName)
        end)

        if ok and exists and isWeapon then
            oxStatus = ('ox: weapon ativo label=%s'):format(item and item.label or 'sem label')
            notifyType = 'success'
        elseif ok and exists then
            oxStatus = ('ox: item inutilizado label=%s'):format(item and item.label or 'sem label')
        elseif ok then
            oxStatus = 'ox: item nao existe'
        else
            oxStatus = 'ox: erro na consulta'
        end
    end

    notify(source, ('%s | %s | %s'):format(weaponName, qbxStatus, oxStatus), notifyType)
end

command('armaqbx', function(source, args)
    checkWeapon(source, args)
end, false)

command('forgeweaponcheck', function(source, args)
    checkWeapon(source, args)
end, false)
    return commands
end
