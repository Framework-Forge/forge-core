ForgeCore = ForgeCore or {}

local function valueOrNone(value)
    value = tostring(value or '')
    return value ~= '' and value or ForgeCore.t('common.none')
end

local function splitBirthdate(value)
    value = tostring(value or '')

    local year, month, day = value:match('^(%d%d%d%d)[%-/](%d%d?)[%-/](%d%d?)$')
    if year then
        return tonumber(day), tonumber(month), tonumber(year)
    end

    day, month, year = value:match('^(%d%d?)[%-/](%d%d?)[%-/](%d%d%d%d)$')
    if year then
        return tonumber(day), tonumber(month), tonumber(year)
    end

    return nil, nil, nil
end

local function formatBirthdate(value)
    local day, month, year = splitBirthdate(value)
    if not day or not month or not year then return valueOrNone(value) end

    return ('%02d/%02d/%04d'):format(day, month, year)
end

local function calculateAge(value)
    local day, month, year = splitBirthdate(value)
    if not day or not month or not year then return ForgeCore.t('common.none') end

    local now = os.date('*t')
    local age = now.year - year

    if now.month < month or (now.month == month and now.day < day) then
        age = age - 1
    end

    if age < 0 then return ForgeCore.t('common.none') end
    return tostring(age)
end

local function groupLabel(group)
    group = type(group) == 'table' and group or {}

    local label = group.label or group.name
    local grade = group.grade
    local gradeName = type(grade) == 'table' and (grade.name or grade.label) or nil

    if gradeName and gradeName ~= '' then
        return ('%s - %s'):format(valueOrNone(label), gradeName)
    end

    return valueOrNone(label)
end

pr_lib.callback.register(PR.Player.Callbacks.getInfo, function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or not player.PlayerData then return false, 'invalid_player' end

    local data = player.PlayerData
    local charinfo = type(data.charinfo) == 'table' and data.charinfo or {}

    return true, {
        firstname = valueOrNone(charinfo.firstname or charinfo.firstName),
        lastname = valueOrNone(charinfo.lastname or charinfo.lastName),
        age = calculateAge(charinfo.birthdate),
        birthdate = formatBirthdate(charinfo.birthdate),
        nationality = valueOrNone(charinfo.nationality),
        job = groupLabel(data.job),
        gang = groupLabel(data.gang),
    }
end)
