-- Core-local usable dispatch from the installed PR OX adapter, external hooks remain PR-owned.
return function(ports)
    local library, native = assert(ports.library), assert(ports.native)
    local registry = {RegisterUsableItem=assert(ports.registerLocal)}
    local Debug = ports.debug
    local api = {}
local function debugUsable(options, level, message)
    if options and options.debug then
        native.print(("[pr_bridge][inventory:ox][%s] %s"):format(level, message))
        return
    end

    if Debug then
        Debug(level, ("[inventory:ox] %s"):format(message))
    end
end

local function safeUseItemCallback(item, cb, source, itemData)
    if type(itemData) ~= "table" then
        itemData = { name = item }
    elseif not itemData.name then
        itemData.name = item
    end

    local ok, result = pcall(cb, source, itemData)
    if ok then return result end

    if Debug then
        Debug("ERROR", ("ox_inventory usable item '%s' failed: %s"):format(tostring(item), tostring(result)))
    end

    return false
end

function api.RegisterUsableItem(item, cb, options)
    if type(item) ~= "string" or item == "" or type(cb) ~= "function" then return false end

    options = options or {}
    local cancelUse = options.cancelUse
    if cancelUse == nil then cancelUse = true end
    local recentUse = {}

    local function dispatchUse(source, itemData)
        if type(itemData) ~= "table" then
            itemData = { name = item }
        elseif not itemData.name then
            itemData.name = item
        end

        local useKey = ("%s:%s:%s"):format(tostring(source), item, tostring(itemData.slot))

        if recentUse[useKey] then
            debugUsable(options, "WARNING", ("duplicate ignored item=%s source=%s slot=%s"):format(item, tostring(source), tostring(itemData.slot)))
            if cancelUse then return false end
            return
        end

        recentUse[useKey] = true
        native.setTimeout(750, function()
            recentUse[useKey] = nil
        end)

        debugUsable(options, "INFO", ("dispatch item=%s source=%s slot=%s"):format(item, tostring(source), tostring(itemData.slot)))
        local result = safeUseItemCallback(item, cb, source, itemData)
        if result ~= nil then return result end
        if cancelUse then return false end
    end

    local function handleUse(payload)
        local usedItem = payload and payload.item
        local usedName = type(usedItem) == "table" and usedItem.name or usedItem

        debugUsable(options, "INFO", ("inventory hook payload item=%s source=%s slot=%s"):format(
            tostring(usedName),
            tostring(payload and payload.source),
            tostring(payload and payload.slot)
        ))

        if usedName ~= item then return end

        if type(usedItem) ~= "table" then
            usedItem = { name = item, slot = payload and payload.slot }
        elseif not usedItem.slot and payload and payload.slot then
            usedItem.slot = payload.slot
        end

        return dispatchUse(payload and payload.source, usedItem)
    end

    local hookOptions = {
        itemFilter = {
            [item] = true
        }
    }

    local framework = registry
    local frameworkFallback = not options.disableFrameworkFallback
        and type(framework) == "table"
        and type(framework.RegisterUsableItem) == "function"
        and framework.RegisterUsableItem ~= api.RegisterUsableItem

    debugUsable(options, "INFO", ("register item=%s framework=%s inventoryHook=%s frameworkFallback=%s"):format(
        item,
        tostring(ports.frameworkLabel or 'qbx'),
        tostring(not options.disableInventoryHook),
        tostring(frameworkFallback)
    ))

    local registered = false

    -- Items without an ox_inventory `consume` value are delegated to the
    -- framework's usable-item registry before ox_inventory emits usingItem.
    -- Registering this fallback is therefore required for dynamic Forge items.
    if frameworkFallback then
        local ok, result = pcall(framework.RegisterUsableItem, item, function(source, itemData)
            return dispatchUse(source, itemData)
        end)
        local fallbackRegistered = ok and result ~= false
        registered = registered or fallbackRegistered
        debugUsable(options, fallbackRegistered and "SUCCESS" or "WARNING", (
            "framework fallback item=%s ok=%s result=%s"
        ):format(item, tostring(ok), tostring(result)))
    end

    if not options.disableInventoryHook then
        local ok = pcall(function()
            library.inventory.RegisterHook("useItem", handleUse, hookOptions)
        end)
        registered = registered or ok
        debugUsable(options, ok and "SUCCESS" or "WARNING", ("hook useItem item=%s ok=%s"):format(item, tostring(ok)))

        ok = pcall(function()
            library.inventory.RegisterHook("usingItem", handleUse, hookOptions)
        end)
        registered = registered or ok
        debugUsable(options, ok and "SUCCESS" or "WARNING", ("hook usingItem item=%s ok=%s"):format(item, tostring(ok)))
    end

    debugUsable(options, registered and "SUCCESS" or "ERROR", ("register result item=%s registered=%s"):format(item, tostring(registered)))
    return registered
end

    return api
end
