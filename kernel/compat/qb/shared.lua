-- Port of installed QBX bridge/qb/shared/main.lua; see kernel/NOTICE-87.md.
-- A compatibility view: catalog references are shared, legacy-only keys stay out of canonical Shared.
return function(ports)
assert(type(ports.shared)=='table' and type(ports.config)=='table','QB shared/config ports required')
assert(type(ports.lib)=='table' and type(ports.helpers)=='table','QB utility ports required')
local qbShared = {}
for key,value in pairs(ports.shared) do qbShared[key]=value end

local itemsRemovedError = 'QBCore.Shared.Items foi removido. Use exports.ox_inventory:Items(item).'

local function rejectLegacyItemsAccess()
    error(itemsRemovedError, 2)
end

qbShared.Items = setmetatable({}, {
    __index = rejectLegacyItemsAccess,
    __newindex = rejectLegacyItemsAccess,
    __pairs = rejectLegacyItemsAccess,
    __len = rejectLegacyItemsAccess,
    __metatable = false,
})

local starterItems = ports.config.starterItems
---@deprecated use starterItems in config/shared.lua
qbShared.StarterItems = {}

if type(starterItems) == 'table' then
    for i = 1, #starterItems do
        local item = starterItems[i]

        ---@diagnostic disable-next-line: deprecated
        qbShared.StarterItems[item.name] = {
            amount = item.amount,
            item = item.name,
        }
    end
end

---@deprecated use ports.lib.math.groupdigits from ox_lib
qbShared.CommaValue = ports.lib.math.groupdigits

---@deprecated use ports.lib.string.random from ox_lib
qbShared.RandomStr = function(length)
    if length <= 0 then return '' end
    local pattern = math.random(2) == 1 and 'a' or 'A'

    ---@diagnostic disable-next-line: deprecated
    return qbShared.RandomStr(length - 1) .. ports.lib.string.random(pattern)
end

---@deprecated use ports.lib.string.random from ox_lib
qbShared.RandomInt = function(length)
    if length <= 0 then return '' end

    ---@diagnostic disable-next-line: deprecated
    return qbShared.RandomInt(length - 1) .. ports.lib.string.random('1')
end

---@deprecated use string.strsplit with CfxLua 5.4
qbShared.SplitStr = function(str, delimiter)
    local result = table.pack(string.strsplit(delimiter, str))
    result.n = nil
    return result
end

---@deprecated use ports.helpers.string.trim from modules/ports.lib.lua
qbShared.Trim = function(str)
    if not str then return nil end
    return ports.helpers.string.trim(str)
end

---@deprecated use ports.helpers.string.capitalize from modules/ports.lib.lua
qbShared.FirstToUpper = function(str)
    if not str then return nil end
    return ports.helpers.string.capitalize(str)
end

---@deprecated use ports.helpers.math.round from modules/ports.lib.lua
qbShared.Round = ports.helpers.math.round

---@deprecated use ports.helpers.setVehicleExtra from modules/ports.lib.lua
qbShared.ChangeVehicleExtra = ports.helpers.setVehicleExtras

---@deprecated use ports.helpers.setVehicleExtra from modules/ports.lib.lua
qbShared.SetDefaultVehicleExtras = ports.helpers.setVehicleExtras

---@deprecated use ports.helpers.armsWithoutGloves.male from modules/ports.lib.lua
qbShared.MaleNoGloves = ports.helpers.armsWithoutGloves.male

---@deprecated use ports.helpers.armsWithoutGloves.female from modules/ports.lib.lua
qbShared.FemaleNoGloves = ports.helpers.armsWithoutGloves.female

return qbShared

end
