ForgeCore = ForgeCore or {}

local Sync = {
    registeredWeapons = {},
}

local function qbxReady()
    return GetResourceState('qbx_core'):find('start') ~= nil
end

local function qbxCall(method, ...)
    if not qbxReady() then return false end

    local args = { ... }
    local ok, result = pcall(function()
        if method == 'CreateWeapons' then
            return exports.qbx_core:CreateWeapons(args[1])
        elseif method == 'RemoveWeapon' then
            return exports.qbx_core:RemoveWeapon(args[1])
        end

        return false
    end)

    return ok and result ~= false
end

local function removeMissing(previous, current)
    for name in pairs(previous) do
        if not current[name] then
            qbxCall('RemoveWeapon', name)
        end
    end
end

local function toQbxWeapons(weapons)
    local qbxWeapons = {}

    for name, weapon in pairs(weapons or {}) do
        local qbxWeapon = {}

        for key, value in pairs(weapon) do
            if key ~= 'active' then
                qbxWeapon[key] = value
            end
        end

        if qbxWeapon.ammotype == 'none' then
            qbxWeapon.ammotype = nil
        end

        qbxWeapons[name] = qbxWeapon
    end

    return qbxWeapons
end

function Sync.syncAll()
    local registry = ForgeCore.WeaponRegistry
    if not registry then return false end

    local weapons = registry.getActiveWeapons()
    if next(weapons) then
        qbxCall('CreateWeapons', toQbxWeapons(weapons))
    end

    removeMissing(Sync.registeredWeapons, weapons)

    Sync.registeredWeapons = {}
    for name in pairs(weapons) do
        Sync.registeredWeapons[name] = true
    end

    return true
end

ForgeCore.WeaponQbxSync = Sync
