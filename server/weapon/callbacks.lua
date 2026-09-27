ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.Weapons.Callbacks.getAll, function(source)
    if not ForgeCore.WeaponService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.WeaponService.getPayload()
end)

ForgeCore.Callbacks.register(PR.Weapons.Callbacks.save, function(source, weaponData)
    return ForgeCore.WeaponService.upsert(source, weaponData)
end)

ForgeCore.Callbacks.register(PR.Weapons.Callbacks.delete, function(source, name)
    return ForgeCore.WeaponService.delete(source, name)
end)

ForgeCore.Callbacks.register(PR.Weapons.Callbacks.setActive, function(source, name, active)
    return ForgeCore.WeaponService.setActive(source, name, active)
end)
