-- QBX-owned delivery queue. No database reads, polling or network transport.
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for k, v in pairs(value) do result[k] = copy(v) end; return result
end
local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
return function(ports, event)
    assert(type(ports) == 'table', 'cache delivery ports required')
    local getResourceState = assert(ports.getResourceState, 'resource-state port required')
    local writeCache = assert(ports.writeCache, 'PR cache writer port required')
    local emit = assert(ports.emit, 'cache event port required')
    local values, pending, delivered, fieldSets = {}, {}, {}, {}
    local pendingCount=0
    local function markPending(key)
        if not pending[key]then pending[key]=true;pendingCount=pendingCount+1 end
    end
    local writer = { copy = copy }
    function writer.stage(key, value)
        if values[key] and equal(values[key].value, value) then return end
        values[key] = { value = copy(value) }; markPending(key)
    end
    -- Replacing an authoritative field set also records fields removed from
    -- that record. This is explicit data replacement, not namespace cleanup.
    function writer.fields(prefix, data)
        for field in pairs(fieldSets[prefix] or {}) do
            if data[field] == nil then writer.stage(prefix .. field, nil) end
        end
        local fields = {}
        for field, value in pairs(data) do writer.stage(prefix .. field, value); fields[field] = true end
        fieldSets[prefix] = fields
    end
    function writer.flush(reason, force)
        if not force and pendingCount==0 then return {} end
        if getResourceState('pr_bridge') ~= 'started' then return {} end
        local changes = {}
        for key in pairs(force and values or pending) do
            local value = values[key].value
            if force or not delivered[key] or not equal(delivered[key].value, value) then
                writeCache('set', key, value)
                delivered[key] = { value = copy(value) }; changes[key] = true
            end
            if pending[key]then pending[key]=nil;pendingCount=pendingCount-1 end
        end
        if next(changes) then emit(event, changes, reason) end
        return changes
    end
    -- Only the supplied fields cross the resource boundary; large item lists
    -- are not serialized again for a health/oxygen change.
    function writer.patch(key, delta)
        local entry = values[key]
        if not entry or type(entry.value) ~= 'table' then return end
        local changed = {}
        for field, value in pairs(delta) do
            if not equal(entry.value[field], value) then
                entry.value[field] = copy(value); changed[field] = copy(value)
            end
        end
        if not next(changed) then return end
        if getResourceState('pr_bridge') ~= 'started' or not delivered[key] then markPending(key); return end
        writeCache('patch', key, changed)
        for field, value in pairs(changed) do delivered[key].value[field] = copy(value) end
    end
    function writer.record(key, data)
        local entry = values[key]
        if not entry or type(entry.value) ~= 'table' then writer.stage(key, data); return end
        -- Field removal/character replacement uses a complete explicit record.
        for field in pairs(entry.value) do
            if data[field] == nil then writer.stage(key, data); return end
        end
        writer.patch(key, data)
    end
    return writer
end
