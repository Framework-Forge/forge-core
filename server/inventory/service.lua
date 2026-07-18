ForgeCore = ForgeCore or {}

local resourceName = GetCurrentResourceName()

local Service = {
    items = {},
    revision = 0,
    weaponInventory = {
        ammo = {},
        components = {},
        tints = {},
    },
}

local function notify(source, data)
    if source == 0 then return end
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('inventory.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function canManage(source)
    if ForgeCore.WeaponService and ForgeCore.WeaponService.canManage then
        return ForgeCore.WeaponService.canManage(source)
    end

    if source == 0 then return true end

    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
        or IsPlayerAceAllowed(source, 'admin')
        or IsPlayerAceAllowed(source, 'group.admin')
end

local function clone(value, seen)
    if type(value) ~= 'table' then return value end

    seen = seen or {}
    if seen[value] then return seen[value] end

    local copy = {}
    seen[value] = copy

    for key, child in pairs(value) do
        copy[clone(key, seen)] = clone(child, seen)
    end

    return copy
end

local function encodeJson(data)
    local ok, encoded = pcall(json.encode, data or {})
    if ok and encoded then return encoded end
    return '{}'
end

local function decodeJson(path, fallback)
    local content = LoadResourceFile(resourceName, path)
    if type(content) ~= 'string' or content == '' then return fallback end

    local ok, decoded = pcall(json.decode, content)
    if ok and type(decoded) == 'table' then return decoded end

    return fallback
end

local function saveJson(path, data)
    local saved = SaveResourceFile(resourceName, path, encodeJson(data), -1)
    return saved ~= false and saved ~= nil
end

local function bumpRevision()
    Service.revision = (tonumber(Service.revision) or 0) + 1
end

local function trim(value)
    return (tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function normalizeItemName(name)
    name = trim(name):lower():gsub('%s+', '_'):gsub('[^%w_%-]', '')
    return name
end

local function normalizeOxName(name)
    return trim(name):gsub('%s+', '_')
end

local function normalizeAccessList(list)
    local output = {}

    if type(list) ~= 'table' then return output end

    for index = 1, #list do
        local entry = list[index]
        if type(entry) == 'table' then
            local name = normalizeItemName(entry.name)
            if name ~= '' then
                output[#output + 1] = {
                    name = name,
                    grade = math.max(0, math.floor(tonumber(entry.grade) or 0)),
                }
            end
        end
    end

    return output
end

local function normalizeAccess(access)
    access = type(access) == 'table' and access or {}

    local normalized = {
        jobs = normalizeAccessList(access.jobs),
        gangs = normalizeAccessList(access.gangs),
    }

    if type(access.job) == 'table' then
        local job = normalizeAccessList({ access.job })[1]
        if job then normalized.jobs[#normalized.jobs + 1] = job end
    end

    if type(access.gang) == 'table' then
        local gang = normalizeAccessList({ access.gang })[1]
        if gang then normalized.gangs[#normalized.gangs + 1] = gang end
    end

    if #normalized.jobs > 0 or #normalized.gangs > 0 then
        return normalized
    end

    local mode = trim(access.mode):lower()
    if mode ~= 'job' and mode ~= 'gang' and mode ~= 'admin' then
        return normalized
    end

    if mode == 'admin' then
        normalized.jobs[1] = { name = 'admin', grade = math.max(0, math.floor(tonumber(access.grade) or 0)) }
    elseif mode == 'job' then
        local name = normalizeItemName(access.name)
        if name ~= '' then normalized.jobs[1] = { name = name, grade = math.max(0, math.floor(tonumber(access.grade) or 0)) } end
    elseif mode == 'gang' then
        local name = normalizeItemName(access.name)
        if name ~= '' then normalized.gangs[1] = { name = name, grade = math.max(0, math.floor(tonumber(access.grade) or 0)) } end
    end

    return normalized
end

local function playerData(source)
    if pr_lib and pr_lib.framework and pr_lib.framework.GetPlayerData then
        local data = pr_lib.framework.GetPlayerData(source)
        if type(data) == 'table' then return data end
    end

    return {}
end

local function hasGroup(source, groupType, groupName, grade)
    groupName = normalizeItemName(groupName)

    if groupName == 'admin' then
        return canManage(source)
    elseif groupName == 'mod' then
        return canManage(source)
            or IsPlayerAceAllowed(source, 'mod')
            or IsPlayerAceAllowed(source, 'group.mod')
    elseif groupName == 'staff' then
        return canManage(source)
            or IsPlayerAceAllowed(source, 'mod')
            or IsPlayerAceAllowed(source, 'group.mod')
            or IsPlayerAceAllowed(source, 'staff')
            or IsPlayerAceAllowed(source, 'support')
            or IsPlayerAceAllowed(source, 'group.staff')
            or IsPlayerAceAllowed(source, 'group.support')
    end

    local data = playerData(source)
    local group = groupType == 'gang' and data.gang or data.job
    group = type(group) == 'table' and group or {}

    local playerGrade = group.grade
    if type(playerGrade) == 'table' then playerGrade = playerGrade.level or playerGrade.grade or playerGrade.id end

    return normalizeItemName(group.name) == normalizeItemName(groupName) and (tonumber(playerGrade) or 0) >= (tonumber(grade) or 0)
end

local function checkAccess(source, entry)
    entry = type(entry) == 'table' and entry or {}
    if entry.active == false then return false, 'disabled' end

    local access = normalizeAccess(entry.access)
    local hasRestriction = false

    for index = 1, #(access.jobs or {}) do
        local rule = access.jobs[index]
        hasRestriction = true
        if hasGroup(source, 'job', rule.name, rule.grade) then return true end
    end

    for index = 1, #(access.gangs or {}) do
        local rule = access.gangs[index]
        hasRestriction = true
        if hasGroup(source, 'gang', rule.name, rule.grade) then return true end
    end

    return not hasRestriction
end

local function normalizeFileName(name)
    name = trim(name):gsub('\\', '/'):match('([^/]+)$') or ''
    name = name:gsub('[^%w_%-%.]', '')
    return name
end

local function isUrl(value)
    value = tostring(value or '')
    return value:find('^https?://') ~= nil
end

local function extensionFromUrl(url)
    local ext = tostring(url or ''):match('%.([%w]+)%??[^/]*$')
    ext = ext and ext:lower() or 'png'
    if ext ~= 'png' and ext ~= 'jpg' and ext ~= 'jpeg' and ext ~= 'webp' then
        ext = 'png'
    end

    return ext
end

local function downloadOxImage(url, fileName)
    if not isUrl(url) then return end

    fileName = normalizeFileName(fileName)
    if fileName == '' then return end

    PerformHttpRequest(url, function(status, body)
        if status < 200 or status >= 300 or type(body) ~= 'string' or body == '' then
            print(('[forge-core:inventory][warn] image download failed status=%s url=%s'):format(tostring(status), tostring(url)))
            return
        end

        local ok = SaveResourceFile('ox_inventory', ('web/images/%s'):format(fileName), body, #body)
        if ok == false or ok == nil then
            print(('[forge-core:inventory][warn] image save failed file=%s'):format(fileName))
        end
    end, 'GET')
end

local function listMap(map)
    local list = {}

    for _, value in pairs(map or {}) do
        list[#list + 1] = clone(value)
    end

    table.sort(list, function(left, right)
        return tostring(left.label or left.name) < tostring(right.label or right.name)
    end)

    return list
end

local function syncItem(name, item)
    if GetResourceState('ox_inventory') ~= 'started' then return end

    local ok = pcall(function()
        if item and item.active == false then
            exports.ox_inventory:DisableItemDefinition(name, item)
        elseif item then
            exports.ox_inventory:SetItemDefinition(name, item, true)
        else
            exports.ox_inventory:RemoveItemDefinition(name)
        end
    end)

    if not ok then
        print(('[forge-core:inventory][warn] ox item sync failed item=%s'):format(tostring(name)))
    end
end

local function syncAllItems()
    for name, item in pairs(Service.items or {}) do
        syncItem(name, item)
    end
end

local function syncInventoryEntry(group, name, entry)
    if GetResourceState('ox_inventory') ~= 'started' then return end

    local ok = pcall(function()
        if not entry or entry.active == false then
            exports.ox_inventory:RemoveItemDefinition(name)
            return
        end

        local item = clone(entry)
        item.name = name
        item.stack = true

        if group == 'ammo' then
            item.ammo = true
            item.close = true
        elseif group == 'components' then
            item.component = true
            item.close = false
        end

        exports.ox_inventory:SetItemDefinition(name, item, true)
    end)

    if not ok then
        print(('[forge-core:inventory][warn] ox %s sync failed item=%s'):format(tostring(group), tostring(name)))
    end
end

local function syncAllWeaponInventory()
    for name, entry in pairs(Service.weaponInventory.ammo or {}) do
        syncInventoryEntry('ammo', name, entry)
    end

    for name, entry in pairs(Service.weaponInventory.components or {}) do
        syncInventoryEntry('components', name, entry)
    end
end

local function normalizeItem(data, fallbackName)
    if type(data) ~= 'table' then return nil, 'invalid_item' end

    local item = clone(data)
    item.name = normalizeItemName(item.name or fallbackName)
    if item.name == '' then return nil, 'missing_name' end

    item.label = trim(item.label) ~= '' and trim(item.label) or item.name
    item.weight = tonumber(item.weight) or 0

    if item.unique ~= nil and item.stack == nil then
        item.stack = item.unique ~= true
    end

    if item.shouldClose ~= nil and item.close == nil then
        item.close = item.shouldClose ~= false
    end

    item.stack = item.stack ~= false
    item.close = item.close ~= false
    item.active = item.active ~= false
    item.access = normalizeAccess(item.access)

    if type(item.client) ~= 'table' then item.client = nil end

    local rawImage = item.image or (item.client and item.client.image)
    if trim(rawImage) ~= '' then
        local imageName = normalizeFileName(rawImage)

        if isUrl(rawImage) then
            local ext = extensionFromUrl(rawImage)
            imageName = normalizeFileName(('%s.%s'):format(item.name, ext))
            item.imageUrl = rawImage
            item.localImage = imageName
            downloadOxImage(rawImage, imageName)

            item.client = item.client or {}
            item.client.image = rawImage
        else
            item.client = item.client or {}
            item.client.image = imageName
        end

        item.image = nil
    end

    item.type = item.type == 'item' and nil or item.type
    item.unique = nil
    item.useable = nil
    item.shouldClose = nil
    item.combinable = nil

    return item
end

local function normalizeInventoryEntry(data, fallbackName, defaults)
    if type(data) ~= 'table' then return nil, 'invalid_entry' end

    local entry = clone(defaults or {})
    for key, value in pairs(data) do
        entry[key] = clone(value)
    end

    entry.name = normalizeOxName(entry.name or fallbackName)
    if entry.name == '' then return nil, 'missing_name' end

    entry.label = trim(entry.label) ~= '' and trim(entry.label) or entry.name
    entry.weight = tonumber(entry.weight) or 0
    entry.active = entry.active ~= false
    entry.access = normalizeAccess(entry.access)

    return entry
end

local function loadInventoryFile()
    local inventory = decodeJson(PR.Inventory.Storage.weaponInventory, {})

    Service.weaponInventory = {
        ammo = type(inventory.ammo) == 'table' and inventory.ammo or {},
        components = type(inventory.components) == 'table' and inventory.components or {},
        tints = type(inventory.tints) == 'table' and inventory.tints or {},
    }
end

local function saveInventoryFile()
    return saveJson(PR.Inventory.Storage.weaponInventory, Service.weaponInventory)
end

function Service.canManage(source)
    return canManage(source)
end

function Service.reload()
    Service.items = decodeJson(PR.Inventory.Storage.items, {})
    loadInventoryFile()
    bumpRevision()
    syncAllItems()
    syncAllWeaponInventory()
    return true
end

function Service.saveItems()
    return saveJson(PR.Inventory.Storage.items, Service.items)
end

function Service.getPayload()
    return {
        items = listMap(Service.items),
        ammo = listMap(Service.weaponInventory.ammo),
        components = listMap(Service.weaponInventory.components),
        revision = Service.revision,
    }
end

function Service.canUseItem(source, itemName)
    itemName = tostring(itemName or '')
    local lowerName = normalizeItemName(itemName)
    local oxName = normalizeOxName(itemName)

    if Service.items[lowerName] then
        return checkAccess(source, Service.items[lowerName])
    end

    if Service.weaponInventory.ammo[oxName] then
        return checkAccess(source, Service.weaponInventory.ammo[oxName])
    end

    if Service.weaponInventory.components[oxName] then
        return checkAccess(source, Service.weaponInventory.components[oxName])
    end

    if ForgeCore.WeaponRegistry and ForgeCore.WeaponRegistry.getWeapons then
        local weapons = ForgeCore.WeaponRegistry.getWeapons()
        local weapon = weapons[lowerName]
        if weapon then return checkAccess(source, weapon) end
    end

    return true
end

function Service.upsertItem(source, itemData)
    if not canManage(source) then return false, 'no_permission' end

    local item, err = normalizeItem(itemData)
    if not item then return false, err end

    Service.items[item.name] = item
    Service.saveItems()
    bumpRevision()
    syncItem(item.name, item)

    notify(source, { description = ForgeCore.t('notify.inventory.saved', { item = item.label or item.name }), type = 'success' })

    return true, item
end

function Service.deleteItem(source, name)
    if not canManage(source) then return false, 'no_permission' end

    name = normalizeItemName(name)
    if not Service.items[name] then return false, 'not_found' end

    Service.items[name] = nil
    Service.saveItems()
    bumpRevision()
    syncItem(name, nil)

    notify(source, { description = ForgeCore.t('notify.inventory.removed', { item = name }), type = 'success' })

    return true
end

function Service.setItemActive(source, name, active)
    if not canManage(source) then return false, 'no_permission' end

    name = normalizeItemName(name)
    local item = Service.items[name]
    if not item then return false, 'not_found' end

    item.active = active ~= false
    Service.saveItems()
    bumpRevision()
    syncItem(name, item)

    notify(source, { description = ForgeCore.t(active ~= false and 'notify.inventory.activated' or 'notify.inventory.deactivated', { item = item.label or item.name }), type = 'success' })

    return true, item
end

local function upsertInventoryEntry(source, group, defaults, data)
    if not canManage(source) then return false, 'no_permission' end

    local entry, err = normalizeInventoryEntry(data, nil, defaults)
    if not entry then return false, err end

    Service.weaponInventory[group][entry.name] = entry
    saveInventoryFile()
    bumpRevision()
    syncInventoryEntry(group, entry.name, entry)
    if ForgeCore.WeaponOxSync then ForgeCore.WeaponOxSync.syncAll() end

    notify(source, { description = ForgeCore.t('notify.inventory.saved', { item = entry.label or entry.name }), type = 'success' })

    return true, entry
end

local function deleteInventoryEntry(source, group, name)
    if not canManage(source) then return false, 'no_permission' end

    name = normalizeOxName(name)
    if not Service.weaponInventory[group][name] then return false, 'not_found' end

    Service.weaponInventory[group][name] = nil
    saveInventoryFile()
    bumpRevision()
    syncInventoryEntry(group, name, nil)
    if ForgeCore.WeaponOxSync then ForgeCore.WeaponOxSync.syncAll() end

    notify(source, { description = ForgeCore.t('notify.inventory.removed', { item = name }), type = 'success' })

    return true
end

local function setInventoryEntryActive(source, group, name, active)
    if not canManage(source) then return false, 'no_permission' end

    name = normalizeOxName(name)
    local entry = Service.weaponInventory[group][name]
    if not entry then return false, 'not_found' end

    entry.active = active ~= false
    saveInventoryFile()
    bumpRevision()
    syncInventoryEntry(group, name, entry)
    if ForgeCore.WeaponOxSync then ForgeCore.WeaponOxSync.syncAll() end

    notify(source, { description = ForgeCore.t(active ~= false and 'notify.inventory.activated' or 'notify.inventory.deactivated', { item = entry.label or entry.name }), type = 'success' })

    return true, entry
end

function Service.upsertAmmo(source, data)
    return upsertInventoryEntry(source, 'ammo', PR.Inventory.AmmoDefaults, data)
end

function Service.deleteAmmo(source, name)
    return deleteInventoryEntry(source, 'ammo', name)
end

function Service.setAmmoActive(source, name, active)
    return setInventoryEntryActive(source, 'ammo', name, active)
end

function Service.upsertComponent(source, data)
    return upsertInventoryEntry(source, 'components', PR.Inventory.ComponentDefaults, data)
end

function Service.deleteComponent(source, name)
    return deleteInventoryEntry(source, 'components', name)
end

function Service.setComponentActive(source, name, active)
    return setInventoryEntryActive(source, 'components', name, active)
end

local function parseSnippet(snippet)
    snippet = tostring(snippet or '')
    if snippet == '' then return nil, 'empty_definition' end

    snippet = snippet:gsub('`([^`]+)`', function(model)
        return string.format('%q', model)
    end)

    local source = snippet:find('^%s*return') and snippet or ('return { %s }'):format(snippet)

    local env = {
        T = function(key) return key end,
        vec3 = function(x, y, z) return { x = x, y = y, z = z } end,
        vector3 = function(x, y, z) return { x = x, y = y, z = z } end,
    }

    local chunk, loadErr = load(source, '@forge_inventory_paste', 't', env)
    if not chunk then return nil, loadErr or 'parse_failed' end

    local ok, result = pcall(chunk)
    if not ok or type(result) ~= 'table' then return nil, result or 'parse_failed' end

    return result
end

function Service.parseDefinition(source, kind, snippet)
    if not canManage(source) then return false, 'no_permission' end

    local parsed, err = parseSnippet(snippet)
    if not parsed then return false, err end

    local entries = {}
    local hasNamedEntries = false

    for key, value in pairs(parsed) do
        if type(value) == 'table' then
            hasNamedEntries = true
            value.name = value.name or key
            entries[#entries + 1] = value
        end
    end

    if not hasNamedEntries then
        entries[1] = parsed
    end

    local normalized = {}

    if kind == 'weapon' then
        if #entries == 1 then return true, entries[1] end
        return true, { entries = entries }
    elseif kind == 'item' then
        for index = 1, #entries do
            local item
            item, err = normalizeItem(entries[index])
            if not item then return false, err end
            normalized[index] = item
        end

        if #normalized == 1 then return true, normalized[1] end
        return true, { entries = normalized }
    elseif kind == 'ammo' then
        for index = 1, #entries do
            local entry
            entry, err = normalizeInventoryEntry(entries[index], nil, PR.Inventory.AmmoDefaults)
            if not entry then return false, err end
            normalized[index] = entry
        end

        if #normalized == 1 then return true, normalized[1] end
        return true, { entries = normalized }
    elseif kind == 'component' then
        for index = 1, #entries do
            local entry
            entry, err = normalizeInventoryEntry(entries[index], nil, PR.Inventory.ComponentDefaults)
            if not entry then return false, err end
            normalized[index] = entry
        end

        if #normalized == 1 then return true, normalized[1] end
        return true, { entries = normalized }
    end

    return false, 'invalid_kind'
end

AddEventHandler('onResourceStart', function(resourceNameStarted)
    if resourceNameStarted == 'ox_inventory' then
        SetTimeout(1500, function()
            syncAllItems()
            syncAllWeaponInventory()
        end)
    end
end)

Service.reload()

ForgeCore.InventoryService = Service

exports('CanUseInventoryItem', function(source, itemName)
    return Service.canUseItem(source, itemName)
end)
