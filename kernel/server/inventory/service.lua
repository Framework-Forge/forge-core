-- Complete inactive installed InventoryService; custom OX mutations are future PR integration contracts.
return function(ports)
    local PR, services = {Inventory=assert(ports.config),AdminAce=ports.adminAce,NotifyPos=ports.notifyPosition}, assert(ports.services)
    local library, native, playerAccess = assert(ports.library), assert(ports.native), assert(ports.playerAccess)
    local integrations, translate, compile = assert(ports.integrations), assert(ports.translate), assert(ports.compile)
    local events, exportDescriptors = {}, {}
    local function listen(name,handler) events[#events+1]={name=name,handler=handler,network=false} end
    local function describeExport(name,handler) exportDescriptors[name]=handler end
local resourceName = ports.resource

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
    if not library or not library.notify or not library.notify.NotifyPlayer then return end

    library.notify.NotifyPlayer(source, {
        title = data.title or translate('inventory.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function canManage(source)
    if services.WeaponService and services.WeaponService.canManage then
        return services.WeaponService.canManage(source)
    end

    if source == 0 then return true end

    return native.isAceAllowed(source, PR.AdminAce or 'forge-core.admin')
        or native.isAceAllowed(source, 'admin')
        or native.isAceAllowed(source, 'group.admin')
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

local function decodeJson(path, fallback)
    return library.loadJsonRecovery(path) or fallback
end

local function saveJson(path, data)
    return library.saveJsonRecovery(path, data)
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

local function normalizeVipAccess(values)
    local result, seen = {}, {}
    for _, value in ipairs(type(values) == 'table' and values or {}) do
        if type(value) == 'string' then
            local id = trim(value):lower():gsub('%s+', '_'):gsub('[^%w_%-]', '')
            if id ~= '' and not seen[id] then
                seen[id] = true
                result[#result + 1] = id
            end
        end
    end
    return result
end

local function normalizeAccess(access)
    access = type(access) == 'table' and access or {}

    local normalized = {
        jobs = normalizeAccessList(access.jobs),
        gangs = normalizeAccessList(access.gangs),
        vips = normalizeVipAccess(access.vips),
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
    if library and playerAccess and playerAccess.GetPlayerData then
        local data = playerAccess.GetPlayerData(source)
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
            or native.isAceAllowed(source, 'mod')
            or native.isAceAllowed(source, 'group.mod')
    elseif groupName == 'staff' then
        return canManage(source)
            or native.isAceAllowed(source, 'mod')
            or native.isAceAllowed(source, 'group.mod')
            or native.isAceAllowed(source, 'staff')
            or native.isAceAllowed(source, 'support')
            or native.isAceAllowed(source, 'group.staff')
            or native.isAceAllowed(source, 'group.support')
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
    if #access.vips > 0 then
        local vip = services.VipService and services.VipService.get(source)
        local allowed = false
        for _, id in ipairs(access.vips) do
            if vip and vip.tier == id then allowed = true break end
        end
        if not allowed then return false, 'vip_required' end
    end
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

local function listMap(map)
    local list = {}

    for key, value in pairs(map or {}) do
        local entry = clone(value)
        if type(entry) == 'table' and trim(entry.name) == '' then
            entry.name = tostring(key)
        end
        list[#list + 1] = entry
    end

    table.sort(list, function(left, right)
        return tostring(left.label or left.name) < tostring(right.label or right.name)
    end)

    return list
end

local function syncItem(name, item)
    if not integrations.inventoryReady() then return end

    local ok = pcall(function()
        if item and item.active == false then
            integrations.disableItemDefinition(name, item)
        elseif item then
            integrations.setItemDefinition(name, item, true)
        else
            integrations.removeItemDefinition(name)
        end
    end)

    if not ok then
        native.print(('[forge-core:inventory][warn] ox item sync failed item=%s'):format(tostring(name)))
    end
end

local function syncAllItems()
    for name, item in pairs(Service.items or {}) do
        syncItem(name, item)
    end
end

local function syncInventoryEntry(group, name, entry)
    if not integrations.inventoryReady() then return end

    local ok = pcall(function()
        if not entry or entry.active == false then
            integrations.removeItemDefinition(name)
            return
        end

        local item = clone(entry)
        item.name = name

        if group == 'ammo' then
            item.stack = true
            item.ammo = true
            item.close = true
        elseif group == 'components' then
            item.stack = false
            item.component = true
            item.close = false
        end

        integrations.setItemDefinition(name, item, true)
    end)

    if not ok then
        native.print(('[forge-core:inventory][warn] ox %s sync failed item=%s'):format(tostring(group), tostring(name)))
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

local function clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    return math.max(minimum, math.min(maximum, value))
end

local function normalizeRange(value)
    value = type(value) == 'table' and value or {}
    local minimum = clamp(value.min or value[1], -100, 100)
    local maximum = clamp(value.max or value[2] or minimum, -100, 100)
    if minimum > maximum then minimum, maximum = maximum, minimum end
    return { min = minimum, max = maximum }
end

local function normalizeVector(value)
    value = type(value) == 'table' and value or {}
    return {
        x = tonumber(value.x or value[1]) or 0.0,
        y = tonumber(value.y or value[2]) or 0.0,
        z = tonumber(value.z or value[3]) or 0.0,
    }
end

local function getGrantDefinition(kind, name)
    kind = tostring(kind or ''):lower()

    if kind == 'item' then
        local entry = Service.items[normalizeItemName(name)]
        return entry, entry and entry.name
    elseif kind == 'ammo' or kind == 'component' then
        local entries = kind == 'ammo' and Service.weaponInventory.ammo or Service.weaponInventory.components
        local normalizedName = normalizeOxName(name)
        local entry = entries[normalizedName]
        local inventoryName = entry and normalizedName or nil

        if not entry then
            for key, candidate in pairs(entries or {}) do
                if normalizeOxName(candidate.name or candidate.oxName) == normalizedName then
                    entry = candidate
                    inventoryName = tostring(key)
                    break
                end
            end
        end

        return entry, inventoryName
    elseif kind == 'weapon' and services.WeaponRegistry then
        local weapons = services.WeaponRegistry.getWeapons()
        local entry = weapons[normalizeItemName(name)]
        return entry, entry and (entry.oxName or entry.name)
    end

    return nil, nil
end

function Service.getGiveCatalog(source)
    if not canManage(source) then return false, 'no_permission' end

    local catalog = {}
    local labels = {
        item = 'Item',
        weapon = 'Arma',
        ammo = 'Municao',
        component = 'Componente',
    }

    local function append(kind, entries)
        for index = 1, #(entries or {}) do
            local entry = entries[index]
            if entry.active ~= false then
                catalog[#catalog + 1] = {
                    token = ('%s:%s'):format(kind, tostring(entry.name)),
                    kind = kind,
                    name = entry.name,
                    label = ('[%s] %s (%s)'):format(labels[kind], entry.label or entry.name, entry.name),
                }
            end
        end
    end

    local payload = Service.getPayload()
    append('item', payload.items)
    append('ammo', payload.ammo)
    append('component', payload.components)

    if services.WeaponService then
        append('weapon', services.WeaponService.getPayload().weapons)
    end

    table.sort(catalog, function(left, right)
        return tostring(left.label):lower() < tostring(right.label):lower()
    end)

    return true, catalog
end

function Service.give(source, target, kind, name, count)
    if not canManage(source) then return false, 'no_permission' end

    target = tonumber(target)
    if not target or target < 1 or not native.getPlayerName(target) then return false, 'invalid_player' end

    count = math.floor(tonumber(count) or 0)
    if count < 1 or count > 100000 then return false, 'invalid_amount' end
    if tostring(kind or ''):lower() == 'weapon' and count > 25 then return false, 'invalid_amount' end

    local entry, inventoryName = getGrantDefinition(kind, name)
    if not entry then return false, 'not_found' end
    if entry.active == false then return false, 'entry_inactive' end

    local inventory = library and library.inventory
    if type(inventory) ~= 'table' or type(inventory.AddItem) ~= 'function' then
        return false, 'inventory_unavailable'
    end

    if type(inventory.CanCarryItem) == 'function' then
        local carryOk, canCarry = pcall(inventory.CanCarryItem, target, inventoryName, count)
        if not carryOk then return false, 'inventory_check_failed' end
        if canCarry == false then return false, 'inventory_full' end
    end

    local addOk, added, addReason = pcall(inventory.AddItem, target, inventoryName, count)
    if not addOk then return false, 'inventory_add_failed' end
    if added == false or added == nil then return false, addReason or 'inventory_add_failed' end

    local label = entry.label or entry.name or inventoryName
    notify(target, {
        title = translate('menu.inventory.title'),
        description = translate('notify.inventory.received', { count = tostring(count), item = label }),
        type = 'success',
    })

    if source ~= target then
        notify(source, {
            title = translate('menu.inventory.title'),
            description = translate('notify.inventory.given', {
                count = tostring(count),
                item = label,
                player = native.getPlayerName(target) or tostring(target),
            }),
            type = 'success',
        })
    end

    return true, { kind = kind, name = inventoryName, count = count, target = target }
end

local function normalizeProps(props)
    if type(props) ~= 'table' then return {} end
    if props.model then props = { props } end
    local output = {}
    for index = 1, math.min(#props, 4) do
        local prop = props[index]
        if type(prop) == 'table' and trim(prop.model) ~= '' then
            output[#output + 1] = {
                model = trim(prop.model),
                bone = math.floor(tonumber(prop.bone) or 57005),
                pos = normalizeVector(prop.pos),
                rot = normalizeVector(prop.rot),
                rotationOrder = math.floor(tonumber(prop.rotationOrder or prop.rotOrder) or 2),
            }
        end
    end
    return output
end

local function normalizeInteraction(value)
    if type(value) ~= 'table' then return nil end
    local interaction = clone(value)
    interaction.enabled = interaction.enabled == true
    interaction.kind = interaction.kind == 'interact' and 'interact' or 'consumable'
    local categories = { food = true, drink = true, alcohol = true, narco = true }
    interaction.category = categories[interaction.category] and interaction.category or 'food'
    local duration = tonumber(interaction.duration)
    if duration == nil then duration = 5000 end
    interaction.duration = duration <= 0 and 0 or math.floor(clamp(duration, 250, 120000))
    interaction.canCancel = interaction.canCancel ~= false
    interaction.remove = math.floor(clamp(interaction.remove or 1, 0, 100))
    interaction.label = trim(interaction.label)
    local effectAliases = {
        maconha = 'weed', marijuana = 'weed',
        cocaina = 'coke', cocaine = 'coke',
        metanfetamina = 'meth', methamphetamine = 'meth',
        oxicodona = 'oxy', oxycodone = 'oxy',
        adrenalina = 'adrenaline',
    }
    interaction.effect = trim(interaction.effect):lower()
    interaction.effect = effectAliases[interaction.effect] or interaction.effect
    interaction.effectDuration = math.floor(clamp(interaction.effectDuration or 12000, 1000, 300000))
    interaction.effectStrength = clamp(interaction.effectStrength or 1.15, 1.0, 1.49)
    interaction.alcohol = clamp(interaction.alcohol, 0, 10)

    local animation = type(interaction.animation) == 'table' and interaction.animation or {}
    animation.mode = animation.mode == 'full' and 'full' or animation.mode == 'custom' and 'custom' or 'partial'
    animation.dict = trim(animation.dict)
    animation.anim = trim(animation.anim or animation.clip)
    animation.flags = math.floor(tonumber(animation.flags or animation.flag) or (animation.mode == 'full' and 1 or 49))
    animation.props = normalizeProps(animation.props or interaction.props)
    interaction.animation = animation
    interaction.props = nil

    local effects = type(interaction.effects) == 'table' and interaction.effects or {}
    interaction.effects = {
        health = normalizeRange(effects.health or interaction.health),
        armor = normalizeRange(effects.armor or interaction.armor),
        hunger = normalizeRange(effects.hunger or interaction.hunger),
        thirst = normalizeRange(effects.thirst or interaction.thirst),
        stress = normalizeRange(effects.stress or interaction.stress),
        oxygen = normalizeRange(effects.oxygen or interaction.oxygen),
    }
    interaction.health, interaction.armor, interaction.hunger = nil, nil, nil
    interaction.thirst, interaction.stress, interaction.oxygen = nil, nil, nil
    return interaction
end

local function legacyInteraction(data)
    if type(data) ~= 'table' then return nil end
    local category = data.category or 'food'
    local defaults = {
        food = { dict = 'mp_player_inteat@burger', anim = 'mp_player_int_eat_burger', model = 'prop_cs_burger_01', bone = 18905, pos = { x = 0.13, y = 0.05, z = 0.02 }, rot = { x = -50.0, y = 16.0, z = 60.0 } },
        drink = { dict = 'mp_player_intdrink', anim = 'loop_bottle', model = 'prop_ld_flow_bottle', bone = 18905, pos = { x = 0.12, y = 0.008, z = 0.03 }, rot = { x = 240.0, y = -60.0, z = 0.0 } },
        alcohol = { dict = 'mp_player_intdrink', anim = 'loop_bottle', model = 'prop_amb_beer_bottle', bone = 18905, pos = { x = 0.12, y = 0.008, z = 0.03 }, rot = { x = 240.0, y = -60.0, z = 0.0 } },
        narco = { dict = 'mp_suicide', anim = 'pill', model = nil, bone = 57005, pos = {}, rot = {} },
    }
    local fallback = defaults[category] or defaults.food
    local animation = data.animation or {}
    local props = data.props
    if not props and fallback.model then props = { { model = fallback.model, bone = fallback.bone, pos = fallback.pos, rot = fallback.rot, rotationOrder = 2 } } end
    return normalizeInteraction({
        enabled = true, kind = 'consumable', category = category,
        duration = data.duration or 5000, canCancel = true, remove = 1,
        effect = data.effect, alcohol = data.alcohol,
        animation = {
            mode = 'partial', dict = animation.dict or fallback.dict,
            anim = animation.anim or fallback.anim, flags = animation.flags or 49,
            props = props,
        },
        effects = {
            health = data.health, armor = data.armor, hunger = data.hunger,
            thirst = data.thirst, stress = data.stress, oxygen = data.oxygen,
        },
    })
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

    item.stack = item.stack == true
    item.close = item.close ~= false
    item.active = item.active ~= false
    item.access = normalizeAccess(item.access)
    item.interaction = normalizeInteraction(item.interaction)

    if type(item.client) ~= 'table' then item.client = nil end

    local rawImage = item.image or (item.client and item.client.image)
    if trim(rawImage) ~= '' then
        local imageName = normalizeFileName(rawImage)

        if isUrl(rawImage) then
            local ext = extensionFromUrl(rawImage)
            imageName = normalizeFileName(('%s.%s'):format(item.name, ext))
            item.imageUrl = rawImage
            item.localImage = imageName
            -- A interface usa a URL diretamente; nao gravar copias nao utilizadas em outro resource.

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

local function saveInventoryFile(draft)
    return saveJson(PR.Inventory.Storage.weaponInventory, draft or Service.weaponInventory)
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getItem(name)
    return Service.items[normalizeItemName(name)]
end

local function migrateLegacyInteractions()
    local changed = false
    for name, data in pairs(PR.Inventory.LegacyInteractions or {}) do
        local item = Service.items[name]
        if item and item.interaction == nil then
            item.interaction = legacyInteraction(data)
            changed = true
        end
    end
    return changed
end

function Service.reload()
    Service.items = decodeJson(PR.Inventory.Storage.items, {})
    for name, itemData in pairs(Service.items) do
        local normalized = normalizeItem(itemData, name)
        if normalized then Service.items[name] = normalized end
    end
    if migrateLegacyInteractions() then Service.saveItems() end
    loadInventoryFile()
    bumpRevision()
    syncAllItems()
    syncAllWeaponInventory()
    native.emit('forge-core:server:inventory:reloaded')
    return true
end

function Service.saveItems(draft)
    return saveJson(PR.Inventory.Storage.items, draft or Service.items)
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

    if services.WeaponRegistry and services.WeaponRegistry.getWeapons then
        local weapons = services.WeaponRegistry.getWeapons()
        local weapon = weapons[lowerName]
        if weapon then return checkAccess(source, weapon) end
    end

    return true
end

function Service.upsertItem(source, itemData)
    if not canManage(source) then return false, 'no_permission' end
    local draft = library.jsonDraft(Service.items, {})

    local item, err = normalizeItem(itemData)
    if not item then return false, err end

    draft[item.name] = item
    if not Service.saveItems(draft) then return false, 'save_failed' end
    Service.items = draft
    bumpRevision()
    syncItem(item.name, item)
    if services.ConsumableService then
        services.ConsumableService.refreshItem(item.name)
    end

    notify(source, { description = translate('notify.inventory.saved', { item = item.label or item.name }), type = 'success' })

    return true, item
end

-- Trusted server compatibility service; validate the entire batch before save.
-- Runtime definitions and Forge's JSON registry must have the same authority.
function Service.addCompatibilityItems(items)
    if not integrations.inventoryReady() then return false, 'inventory_unavailable' end
    local draft = clone(Service.items)
    local prepared, count = {}, 0
    for _, data in ipairs(items) do
        local item, err = normalizeItem(data)
        if not item then return false, err end
        if not library.inventory.Items(item.name) then
            if not draft[item.name] then
                draft[item.name] = item
                count = count + 1
            end
            prepared[item.name] = draft[item.name]
        end
    end
    if not next(prepared) then return true, 0 end
    if count > 0 then
        if not Service.saveItems(draft) then return false, 'save_failed' end
        Service.items = draft
        bumpRevision()
    end
    for name, item in pairs(prepared) do
        syncItem(name, item)
        local live = library.inventory.Items(name)
        if not live or live.label ~= item.label or live.weight ~= item.weight then
            return false, 'runtime_sync_failed:' .. name
        end
        if services.ConsumableService then services.ConsumableService.refreshItem(name) end
    end
    return true, count
end

function Service.deleteItem(source, name)
    if not canManage(source) then return false, 'no_permission' end
    local draft = library.jsonDraft(Service.items, {})

    name = normalizeItemName(name)
    if not draft[name] then return false, 'not_found' end

    draft[name] = nil
    if not Service.saveItems(draft) then return false, 'save_failed' end
    Service.items = draft
    bumpRevision()
    syncItem(name, nil)

    notify(source, { description = translate('notify.inventory.removed', { item = name }), type = 'success' })

    return true
end

function Service.setItemActive(source, name, active)
    if not canManage(source) then return false, 'no_permission' end
    local draft = library.jsonDraft(Service.items)

    name = normalizeItemName(name)
    local item = draft[name]
    if not item then return false, 'not_found' end

    item.active = active ~= false
    if not Service.saveItems(draft) then return false, 'save_failed' end
    Service.items = draft
    bumpRevision()
    syncItem(name, item)

    notify(source, { description = translate(active ~= false and 'notify.inventory.activated' or 'notify.inventory.deactivated', { item = item.label or item.name }), type = 'success' })

    return true, item
end

local function upsertInventoryEntry(source, group, defaults, data)
    if not canManage(source) then return false, 'no_permission' end
    local draft = library.jsonDraft(Service.weaponInventory, { [group] = true })

    local entry, err = normalizeInventoryEntry(data, nil, defaults)
    if not entry then return false, err end

    draft[group][entry.name] = entry
    if not saveInventoryFile(draft) then return false, 'save_failed' end
    Service.weaponInventory = draft
    bumpRevision()
    syncInventoryEntry(group, entry.name, entry)
    if services.WeaponOxSync then services.WeaponOxSync.syncAll() end

    notify(source, { description = translate('notify.inventory.saved', { item = entry.label or entry.name }), type = 'success' })

    return true, entry
end

local function deleteInventoryEntry(source, group, name)
    if not canManage(source) then return false, 'no_permission' end
    local draft = library.jsonDraft(Service.weaponInventory, { [group] = true })

    name = normalizeOxName(name)
    if not draft[group][name] then return false, 'not_found' end

    draft[group][name] = nil
    if not saveInventoryFile(draft) then return false, 'save_failed' end
    Service.weaponInventory = draft
    bumpRevision()
    syncInventoryEntry(group, name, nil)
    if services.WeaponOxSync then services.WeaponOxSync.syncAll() end

    notify(source, { description = translate('notify.inventory.removed', { item = name }), type = 'success' })

    return true
end

local function setInventoryEntryActive(source, group, name, active)
    if not canManage(source) then return false, 'no_permission' end
    local draft = library.jsonDraft(Service.weaponInventory, { [group] = true })

    name = normalizeOxName(name)
    local entry = draft[group][name]
    if not entry then return false, 'not_found' end

    entry.active = active ~= false
    if not saveInventoryFile(draft) then return false, 'save_failed' end
    Service.weaponInventory = draft
    bumpRevision()
    syncInventoryEntry(group, name, entry)
    if services.WeaponOxSync then services.WeaponOxSync.syncAll() end

    notify(source, { description = translate(active ~= false and 'notify.inventory.activated' or 'notify.inventory.deactivated', { item = entry.label or entry.name }), type = 'success' })

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

    local source
    if snippet:find('^%s*return') then
        source = snippet
    elseif snippet:find('^%s*{') then
        source = 'return ' .. snippet
    else
        source = ('return { %s }'):format(snippet)
    end

    local env = {
        T = function(key) return key end,
        vec3 = function(x, y, z) return { x = x, y = y, z = z } end,
        vector3 = function(x, y, z) return { x = x, y = y, z = z } end,
    }

    local chunk, loadErr = compile(source, '@forge_inventory_paste', 't', env)
    if not chunk then return nil, loadErr or 'parse_failed' end

    local ok, result = pcall(chunk)
    if not ok or type(result) ~= 'table' then return nil, result or 'parse_failed' end

    return result
end

function Service.parseDefinition(source, kind, snippet)
    if not canManage(source) then return false, 'no_permission' end

    local parsed, err = parseSnippet(snippet)
    if not parsed then return false, err end

    if kind == 'animation' then
        local animation = {
            dict = trim(parsed.dict),
            anim = trim(parsed.anim or parsed.clip),
            flags = math.floor(tonumber(parsed.flags or parsed.flag) or 49),
            props = normalizeProps(parsed.props),
        }

        if animation.dict == '' or animation.anim == '' then
            return false, 'invalid_animation'
        end

        return true, animation
    end

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

listen('onResourceStart', function(resourceNameStarted)
    if resourceNameStarted == 'ox_inventory' then
        native.setTimeout(1500, function()
            syncAllItems()
            syncAllWeaponInventory()
        end)
    end
end)


describeExport('CanUseInventoryItem', function(source, itemName)
    return Service.canUseItem(source, itemName)
end)


local initialized, initializing = false, false
function Service.Initialize()
    if initialized or initializing then return false end
    initializing = true
    local ok, err = pcall(function()

Service.reload()

library.wrapJsonMutations(PR.Inventory.Storage.items, Service, { 'upsertItem', 'deleteItem', 'setItemActive', 'addCompatibilityItems' })
library.wrapJsonMutations(PR.Inventory.Storage.weaponInventory, Service, {
    'upsertAmmo', 'deleteAmmo', 'setAmmoActive', 'upsertComponent', 'deleteComponent', 'setComponentActive',
})


    end)
    initializing = false
    if not ok then error(err,0) end
    initialized = true
    return true
end
Service.Events, Service.Exports = events, exportDescriptors
return Service
end
