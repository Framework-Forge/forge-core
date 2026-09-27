ForgeCore.Callbacks.register(PR.CharacterSlots.callbacks.getSettings, function()
    local settings, errorCode = ForgeCore.CharacterSlotService.getSettings()
    if not settings then return false, errorCode end
    settings.itemOptions = {}
    for name, item in pairs(exports.ox_inventory:Items()) do
        settings.itemOptions[#settings.itemOptions + 1] = { value = name, label = ('%s (%s)'):format(item.label or name, name) }
    end
    table.sort(settings.itemOptions, function(a, b) return a.label < b.label end)
    settings.previews = ForgeCore.CharacterSlotService.getPreviews()
    settings.previewAnimations = PR.CharacterSlots.previewAnimations or {}
    settings.previewModel = PR.CharacterSlots.previewModel or 'mp_m_freemode_01'
    return true, settings
end)

ForgeCore.Callbacks.register(PR.CharacterSlots.callbacks.saveSettings, function(_, settings)
    if type(settings) ~= 'table' or type(settings.starterItems) ~= 'table' then return false, 'invalid_settings' end
    local catalog, seen = exports.ox_inventory:Items(), {}
    for _, item in ipairs(settings.starterItems) do
        if type(item) ~= 'table' or type(item.name) ~= 'string' or not catalog[item.name] or seen[item.name] then return false, 'invalid_item' end
        local amount = tonumber(item.amount)
        if not amount or amount ~= amount or amount < 1 or amount > 1000000 or amount % 1 ~= 0 then return false, 'invalid_amount' end
        seen[item.name] = true
    end
    return ForgeCore.CharacterSlotService.saveSettings(settings)
end)

ForgeCore.Callbacks.register(PR.CharacterSlots.callbacks.getPlayer, function(_, target)
    return ForgeCore.CharacterSlotService.getPlayer(target)
end)

ForgeCore.Callbacks.register(PR.CharacterSlots.callbacks.setPlayerSlot, function(_, target, slot, unlocked)
    return ForgeCore.CharacterSlotService.setPlayerSlot(target, slot, unlocked)
end)

ForgeCore.Callbacks.register(PR.CharacterSlots.callbacks.savePreview, function(_, index, data)
    return ForgeCore.CharacterSlotService.savePreview(index, data)
end)

ForgeCore.Callbacks.register(PR.CharacterSlots.callbacks.deletePreview, function(_, index)
    return ForgeCore.CharacterSlotService.deletePreview(index)
end)

ForgeCore.Callbacks.register(PR.CharacterSlots.playerCallbacks.getCharacters, function(source)
    return ForgeCore.CharacterSlotService.getOwnCharacters(source)
end, { access = 'player', limit = 5 })

ForgeCore.Callbacks.register(PR.CharacterSlots.playerCallbacks.logout, function(source)
    return ForgeCore.CharacterSlotService.logout(source)
end, { access = 'player', limit = 2 })
