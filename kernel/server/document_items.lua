-- Inactive document classification port; no issuance or external resource read in core.
return function(ports)
    assert(type(ports) == 'table', 'explicit document integration ports required')
    local documentState = assert(ports.documentState, 'PR document resource state required')
    local getDocumentItems = assert(ports.getDocumentItems, 'PR document item catalog required')
    local readDocumentConfig = assert(ports.readDocumentConfig, 'PR saved document bindings required')
    local json = assert(ports.json, 'codec port required')
-- Only classifies documents; the existing starter-kit delivery remains in character.lua.
local DocumentItems = {}

function DocumentItems.get()
    -- Keep legacy document items out of saved kits, even without an active binding.
    local items = { id_card = true, driver_license = true, weaponlicense = true, weapon_license = true }
    if documentState() == 'started' then
        local called, ready, configured = pcall(function() return getDocumentItems() end)
        if called and ready == true and type(configured) == 'table' then
            for name, isDocument in pairs(configured) do
                if type(name) == 'string' and isDocument == true then items[name] = true end
            end
            return items
        end
    end

    -- QBX starts before Forge DK/PR Bridge. Read only the saved item bindings when
    -- DK is starting/stopped; no new dependency, issuance, DB write or kit rewrite.
    for _, path in ipairs({ 'data/config.json', 'data/config.json.bak' }) do
        local raw = readDocumentConfig(path)
        if raw then
            local ok, configured = pcall(json.decode, raw)
            if ok and type(configured) == 'table' and type(configured.types) == 'table' then
                for _, definition in pairs(configured.types) do
                    if type(definition) == 'table' and type(definition.item) == 'string' then
                        items[definition.item] = true
                    end
                end
                return items
            end
        end
    end
    return items
end

    return DocumentItems
end

