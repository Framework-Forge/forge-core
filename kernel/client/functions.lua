-- Inactive installed-QBX port; see kernel/NOTICE-08.md.
return function(ports)
    assert(type(ports) == 'table', 'explicit legacy/client ports required')
    local core = assert(ports.core, 'canonical client state required')
    local membership = assert(ports.membership, 'internal membership functions required')
    local notify = assert(ports.notify, 'PR notification delivery port required')
    local api = {Exports = {}}
local positionConfig = ports.notifyPosition

---Text box popup for player which dissappears after a set time.
---@param text table|string text of the notification
---@param notifyType? NotificationType informs default styling. Defaults to 'inform'
---@param duration? integer milliseconds notification will remain on screen. Defaults to 5000
---@param subTitle? string extra text under the title
---@param notifyPosition? NotificationPosition
---@param notifyStyle? table Custom styling. Please refer too https://coxdocs.dev/ox_lib/Modules/Interface/Client/notify#libnotify
---@param notifyIcon? string Font Awesome 6 icon name
---@param notifyIconColor? string Custom color for the icon chosen before
local function Notify(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
    local title, description
    if type(text) == 'table' then
        title = text.text or 'Placeholder'
        description = text.caption or nil
    elseif subTitle then
        title = text
        description = subTitle
    else
        description = text
    end
    local position = notifyPosition or positionConfig

    notify({
        id = title,
        title = title,
        description = description,
        duration = duration,
        type = notifyType,
        position = position,
        style = notifyStyle,
        icon = notifyIcon,
        iconColor = notifyIconColor
    })
end

api.Notify = Notify; api.Exports.Notify = Notify

---@return PlayerData? playerData
local function GetPlayerData()
    return core.PlayerData
end

api.GetPlayerData = GetPlayerData; api.Exports.GetPlayerData = GetPlayerData

---@param filter string | string[] | table<string, number>
---@return boolean
local function HasPrimaryGroup(filter)
    return membership.HasPlayerGotGroup(filter, core.PlayerData, true)
end

api.HasPrimaryGroup = HasPrimaryGroup; api.Exports.HasPrimaryGroup = HasPrimaryGroup

---@param filter string | string[] | table<string, number>
---@return boolean
local function HasGroup(filter)
    return membership.HasPlayerGotGroup(filter, core.PlayerData)
end

api.HasGroup = HasGroup; api.Exports.HasGroup = HasGroup

---@return table<string, integer>
local function GetGroups()
    local playerData = core.PlayerData
    return membership.GetPlayerGroups(playerData)
end

api.GetGroups = GetGroups; api.Exports.GetGroups = GetGroups
return api
end
