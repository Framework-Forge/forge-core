return function(ports)
    local PR,service,library=assert(ports.config),assert(ports.service),assert(ports.library)
    local callbacks={}
    local function describeCallback(name,handler,options)callbacks[#callbacks+1]={name=name,handler=handler,options=options or{access='admin'}}end
describeCallback(PR.CharacterSlots.callbacks.getSettings, function()
    local settings, errorCode = service.getSettings()
    if not settings then return false, errorCode end
    settings.itemOptions = {}
    for name, item in pairs(library.inventory.Items()) do
        settings.itemOptions[#settings.itemOptions + 1] = { value = name, label = ('%s (%s)'):format(item.label or name, name) }
    end
    table.sort(settings.itemOptions, function(a, b) return a.label < b.label end)
    settings.previews = service.getPreviews()
    settings.previewAnimations = PR.CharacterSlots.previewAnimations or {}
    settings.previewModel = PR.CharacterSlots.previewModel or 'mp_m_freemode_01'
    return true, settings
end)

describeCallback(PR.CharacterSlots.callbacks.saveSettings, function(_, settings)
    if type(settings) ~= 'table' or type(settings.starterItems) ~= 'table' then return false, 'invalid_settings' end
    local catalog, seen = library.inventory.Items(), {}
    for _, item in ipairs(settings.starterItems) do
        if type(item) ~= 'table' or type(item.name) ~= 'string' or not catalog[item.name] or seen[item.name] then return false, 'invalid_item' end
        local amount = tonumber(item.amount)
        if not amount or amount ~= amount or amount < 1 or amount > 1000000 or amount % 1 ~= 0 then return false, 'invalid_amount' end
        seen[item.name] = true
    end
    return service.saveSettings(settings)
end)

describeCallback(PR.CharacterSlots.callbacks.getPlayer, function(_, target)
    return service.getPlayer(target)
end)

describeCallback(PR.CharacterSlots.callbacks.setPlayerSlot, function(_, target, slot, unlocked)
    return service.setPlayerSlot(target, slot, unlocked)
end)

describeCallback(PR.CharacterSlots.callbacks.savePreview, function(_, index, data)
    return service.savePreview(index, data)
end)

describeCallback(PR.CharacterSlots.callbacks.deletePreview, function(_, index)
    return service.deletePreview(index)
end)

describeCallback(PR.CharacterSlots.playerCallbacks.getCharacters, function(source)
    return service.getOwnCharacters(source)
end, { access = 'player', limit = 5 })

describeCallback(PR.CharacterSlots.playerCallbacks.logout, function(source)
    return service.logout(source)
end, { access = 'player', limit = 2 })
    return callbacks
end
