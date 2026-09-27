ForgeCore = ForgeCore or {}

local resourceName = GetCurrentResourceName()

local Service = {
    entries = {},
    vehicles = {},
    revision = 0,
}

local function notify(source, key, params, notificationType)
    if source == 0 then return end
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = ForgeCore.t('menu.vehicles.title'),
        description = ForgeCore.t(key, params),
        type = notificationType or 'success',
        position = PR.NotifyPos,
    })
end

local function canManage(source)
    if source == 0 then return true end
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        return ForgeCore.JobService.canManage(source)
    end

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

local function trim(value)
    return (tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function normalizeIdentifier(value)
    return trim(value):lower():gsub('%s+', '_'):gsub('[^%w_%-]', '')
end

local function normalizeVehicleClass(value)
    local class = trim(value):upper()
    if class == '' then return PR.Vehicles.Defaults.class end

    for index = 1, #(PR.Vehicles.Classes or {}) do
        if class == PR.Vehicles.Classes[index] then return class end
    end

    return nil
end

local function decodeCatalog()
    local content = LoadResourceFile(resourceName, PR.Vehicles.Storage)
    if type(content) ~= 'string' or content == '' then return {} end

    local ok, decoded = pcall(json.decode, content)
    if not ok or type(decoded) ~= 'table' then
        print(('[forge-core:vehicles][error] catalogo JSON invalido em %s'):format(PR.Vehicles.Storage))
        return {}
    end

    return decoded
end

local function saveCatalog(catalog)
    local ok, encoded = pcall(json.encode, catalog or Service.entries)
    if not ok or type(encoded) ~= 'string' then return false, 'encode_failed' end

    local saved = SaveResourceFile(resourceName, PR.Vehicles.Storage, encoded, -1)
    if saved == false or saved == nil then return false, 'save_failed' end

    return true
end

local function normalizeVehicle(data, fallbackKey)
    if type(data) ~= 'table' then return nil, nil, 'invalid_vehicle' end

    local model = normalizeIdentifier(data.model or fallbackKey)
    if model == '' then return nil, nil, 'missing_model' end

    local entry = clone(data)
    entry.model = model
    entry.name = trim(entry.name) ~= '' and trim(entry.name) or model
    entry.brand = trim(entry.brand)
    entry.price = math.max(0, math.floor(tonumber(entry.price) or 0))
    entry.category = normalizeIdentifier(entry.category)
    if entry.category == '' then entry.category = PR.Vehicles.Defaults.category end
    entry.class = normalizeVehicleClass(entry.class)
    if not entry.class then return nil, nil, 'invalid_class' end
    entry.type = normalizeIdentifier(entry.type)
    if entry.type == '' then entry.type = PR.Vehicles.Defaults.type end
    entry.stock = math.max(0, math.floor(tonumber(entry.stock) or 0))
    entry.active = entry.active ~= false

    local store = trim(entry.store)
    entry.store = store ~= '' and store or nil

    local rawHash = entry.hash
    if type(rawHash) == 'string' then
        local hashText = trim(rawHash)
        local numericHash = hashText:match('^%-?%d+$') and tonumber(hashText) or nil
        rawHash = numericHash or normalizeIdentifier(hashText)
        if rawHash == '' then rawHash = model end
    elseif type(rawHash) ~= 'number' then
        rawHash = model
    end
    entry.hash = rawHash

    local runtime = clone(entry)
    runtime.hash = type(rawHash) == 'number' and rawHash or joaat(rawHash)
    runtime.active = nil

    return entry, runtime
end

local function rebuildRuntime(catalog)
    local entries = {}
    local vehicles = {}

    for key, data in pairs(type(catalog) == 'table' and catalog or {}) do
        local entry, runtime, err = normalizeVehicle(data, key)
        if entry then
            entries[entry.model] = entry
            if entry.active ~= false then vehicles[entry.model] = runtime end
        else
            print(('[forge-core:vehicles][warn] veiculo ignorado key=%s reason=%s'):format(tostring(key), tostring(err)))
        end
    end

    Service.entries = entries
    Service.vehicles = vehicles
    Service.revision = Service.revision + 1
end

local function listEntries()
    local entries = {}
    for _, entry in pairs(Service.entries) do entries[#entries + 1] = clone(entry) end
    table.sort(entries, function(left, right)
        local leftName = tostring(left.brand or '') .. ' ' .. tostring(left.name or left.model or '')
        local rightName = tostring(right.brand or '') .. ' ' .. tostring(right.name or right.model or '')
        return leftName:lower() < rightName:lower()
    end)
    return entries
end

local function commitCatalog(catalog)
    local saved, saveErr = saveCatalog(catalog)
    if not saved then return false, saveErr end

    rebuildRuntime(catalog)
    local synced, syncResult = Service.sync()
    if not synced then return false, syncResult end
    return true, syncResult
end

local function parseSnippet(snippet)
    snippet = tostring(snippet or '')
    if trim(snippet) == '' then return nil, 'empty_definition' end

    snippet = snippet:gsub('`([^`]+)`', function(model)
        return string.format('%q', model)
    end)

    local source = snippet:find('^%s*return') and snippet or ('return { %s }'):format(snippet)
    local chunk, loadErr = load(source, '@forge_vehicle_paste', 't', {})
    if not chunk then return nil, loadErr or 'parse_failed' end

    local ok, result = pcall(chunk)
    if not ok or type(result) ~= 'table' then return nil, result or 'parse_failed' end
    return result
end

function Service.canManage(source)
    return canManage(source)
end

function Service.sync()
    if GetResourceState('qbx_core') ~= 'started' then return false, 'qbx_core_not_started' end

    local ok, accepted, result = pcall(function()
        return exports.qbx_core:SetVehicleCatalog(Service.vehicles)
    end)

    if not ok then
        print(('[forge-core:vehicles][error] falha ao sincronizar qbx_core: %s'):format(tostring(accepted)))
        return false, 'sync_failed'
    end
    if accepted == false then
        print(('[forge-core:vehicles][error] qbx_core recusou catalogo: %s'):format(tostring(result)))
        return false, result or 'sync_rejected'
    end

    print(('[forge-core:vehicles] catalogo sincronizado: %d veiculo(s), revisao %d'):format(result or 0, Service.revision))
    return true, result or 0
end

function Service.reload()
    rebuildRuntime(decodeCatalog())
    return Service.sync()
end

function Service.getPayload()
    return { vehicles = listEntries(), revision = Service.revision }
end

function Service.getAll()
    return clone(Service.vehicles)
end

function Service.getEntry(model)
    return clone(Service.entries[normalizeIdentifier(model)])
end

function Service.get(model)
    return clone(Service.vehicles[normalizeIdentifier(model)])
end

function Service.upsert(data)
    local entry, _, err = normalizeVehicle(data, data and data.model)
    if not entry then return false, err end

    local nextEntries = clone(Service.entries)
    nextEntries[entry.model] = entry
    local ok, result = commitCatalog(nextEntries)
    if not ok then return false, result end

    return true, clone(Service.entries[entry.model])
end

function Service.remove(model)
    model = normalizeIdentifier(model)
    if model == '' or not Service.entries[model] then return false, 'not_found' end

    local nextEntries = clone(Service.entries)
    nextEntries[model] = nil
    local ok, result = commitCatalog(nextEntries)
    if not ok then return false, result end
    return true
end

function Service.setActive(model, active)
    model = normalizeIdentifier(model)
    if model == '' or not Service.entries[model] then return false, 'not_found' end

    local nextEntries = clone(Service.entries)
    nextEntries[model].active = active == true
    local ok, result = commitCatalog(nextEntries)
    if not ok then return false, result end
    return true, clone(Service.entries[model])
end

function Service.importDefinition(snippet)
    local parsed, parseErr = parseSnippet(snippet)
    if not parsed then return false, parseErr end

    local rawEntries = {}
    if parsed.model or parsed.name or parsed.brand then
        rawEntries[1] = parsed
    else
        for key, value in pairs(parsed) do
            if type(value) == 'table' then
                local item = clone(value)
                item.model = item.model or key
                rawEntries[#rawEntries + 1] = item
            end
        end
    end
    if #rawEntries == 0 then return false, 'empty_definition' end

    local nextEntries = clone(Service.entries)
    for index = 1, #rawEntries do
        local entry, _, err = normalizeVehicle(rawEntries[index], rawEntries[index].model)
        if not entry then return false, ('entry_%d:%s'):format(index, tostring(err)) end
        nextEntries[entry.model] = entry
    end

    local ok, result = commitCatalog(nextEntries)
    if not ok then return false, result end
    return true, #rawEntries
end

AddEventHandler('onResourceStart', function(startedResource)
    if startedResource == 'qbx_core' then
        SetTimeout(500, function() Service.sync() end)
    end
end)

rebuildRuntime(decodeCatalog())
SetTimeout(0, function() Service.sync() end)

ForgeCore.VehicleService = Service

exports('GetVehicles', function(model)
    if model ~= nil then return Service.get(model) end
    return Service.getAll()
end)
exports('ReloadVehicles', function() return Service.reload() end)
exports('UpsertVehicle', function(data) return Service.upsert(data) end)
exports('RemoveVehicle', function(model) return Service.remove(model) end)