ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Weapons.Callbacks.getAll, function(source)
    if not ForgeCore.WeaponService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.WeaponService.getPayload()
end)

pr_lib.callback.register(PR.Weapons.Callbacks.save, function(source, weaponData)
    return ForgeCore.WeaponService.upsert(source, weaponData)
end)

pr_lib.callback.register(PR.Weapons.Callbacks.delete, function(source, name)
    return ForgeCore.WeaponService.delete(source, name)
end)

pr_lib.callback.register(PR.Weapons.Callbacks.setActive, function(source, name, active)
    return ForgeCore.WeaponService.setActive(source, name, active)
end)
