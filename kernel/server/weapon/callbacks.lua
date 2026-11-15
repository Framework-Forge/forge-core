-- Four private descriptors, to be classified by the shared transport before any runtime binding.
return function(ports)
    local services, PR=assert(ports.services),{Weapons=assert(ports.config)}
    local callbacks={}
    local function callback(name,handler)callbacks[#callbacks+1]={name=name,handler=handler}end
callback(PR.Weapons.Callbacks.getAll, function(source)
    if not services.WeaponService.canManage(source) then return false, 'no_permission' end
    return true, services.WeaponService.getPayload()
end)

callback(PR.Weapons.Callbacks.save, function(source, weaponData)
    return services.WeaponService.upsert(source, weaponData)
end)

callback(PR.Weapons.Callbacks.delete, function(source, name)
    return services.WeaponService.delete(source, name)
end)

callback(PR.Weapons.Callbacks.setActive, function(source, name, active)
    return services.WeaponService.setActive(source, name, active)
end)
    return callbacks
end
