ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Points = {
    zones = {},
    lastPayload = nil,
    refreshPending = false,
}

local trim = pr_lib.utils.trim

local function normalizeId(value)
    value = (trim(value) or ''):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_%-]', '')
    value = value:gsub('_+', '_'):gsub('^_+', ''):gsub('_+$', '')
    return value
end

local function coordsVector(coords)
    if type(coords) ~= 'table' then return nil end

    local ok, vector = pcall(pr_lib.math.toVector, coords)
    if ok and type(vector) == 'vector3' then return vector end
end

local function getPlayerData()
    if pr_lib and pr_lib.framework and pr_lib.framework.GetPlayerData then
        local data = pr_lib.framework.GetPlayerData()
        if type(data) == 'table' then return data end
    end

    if pr_lib and pr_lib.framework and pr_lib.framework.GetJobInfo then
        local job = pr_lib.framework.GetJobInfo() or {}
        return {
            job = {
                name = job.jobName,
                label = job.jobLabel,
                grade = {
                    level = job.grade,
                    name = job.gradeName,
                },
            },
        }
    end

    return {}
end

local function playerGroup(data, groupType)
    return groupType == 'gang' and data.gang or data.job
end

local function gradeLevel(group)
    local grade = group and group.grade
    if type(grade) == 'table' then
        return tonumber(grade.level or grade.grade or grade.value) or 0
    end

    return tonumber(grade) or 0
end

local function accessSignature()
    local data = getPlayerData()
    local job, gang = data.job or {}, data.gang or {}
    return table.concat({ tostring(job.name or ''):lower(), tostring(gradeLevel(job)),
        tostring(gang.name or ''):lower(), tostring(gradeLevel(gang)) }, '|')
end

local function canUseGroup(groupType, groupName, minGrade)
    local data = getPlayerData()
    local group = playerGroup(data, groupType)
    local activeName = group and tostring(group.name or ''):lower() or ''
    local requiredName = tostring(groupName or ''):lower()

    return activeName == requiredName and gradeLevel(group) >= (tonumber(minGrade) or 0)
end

local function notify(data)
    if not pr_lib or not pr_lib.Notify then return end

    pr_lib.Notify({
        title = data.title or ForgeCore.t('core.title'),
        description = data.description,
        type = data.type,
        position = PR.NotifyPos,
    })
end

local function awaitServer(callbackName, ...)
    if not pr_lib or not pr_lib.callback or not pr_lib.callback.await then
        return false, 'callback_unavailable'
    end

    return pr_lib.callback.await(callbackName, 10000, ...)
end

local function inputDialog(title, rows, options)
    if not pr_lib or not pr_lib.menus or not pr_lib.menus.InputDialog then return nil end
    return pr_lib.menus.InputDialog(title, rows, options)
end

local function clearZones()
    if not pr_lib or not pr_lib.target or not pr_lib.target.removeZone then
        Points.zones = {}
        return
    end

    for i = 1, #Points.zones do
        pr_lib.target.removeZone(Points.zones[i])
    end

    Points.zones = {}
end

local function addZone(data)
    if not pr_lib or not pr_lib.target or not pr_lib.target.addBoxZone then return end

    local zoneId = pr_lib.target.addBoxZone({
        coords = data.coords,
        size = PR.Job.Points.targetSize or vec3(1.0, 1.0, 1.8),
        rotation = tonumber(data.rotation) or 0.0,
        debug = PR.Debug == true,
        options = data.options,
    })

    if zoneId then
        Points.zones[#Points.zones + 1] = zoneId
    end
end

local function pointTitle(group, point)
    local title = trim(point.title) or ''
    if title ~= '' then return title end
    return group.label or group.name
end

local function openStash(groupType, group, point)
    local stash = point.stash or {}
    local password

    if (trim(stash.password) or '') ~= '' then
        local result = inputDialog(ForgeCore.t('menu.stashes.password_title'), {
            {
                type = 'input',
                label = ForgeCore.t('inputs.stash_password'),
                password = true,
                required = true,
            },
        })

        if not result then return end
        password = result[1]
    end

    local ok, result = awaitServer(PR.Job.Callbacks.openStash, groupType, group.name, point.id, password)
    if not ok then
        notify({
            description = ForgeCore.t('notify.stashes.open_failed', { error = tostring(result or 'unknown') }),
            type = 'error',
        })
    end
end

local function toggleDuty(group, point)
    local ok, result = awaitServer(PR.Job.Callbacks.toggleDuty, group.name, point.id)
    if not ok then
        notify({
            description = ForgeCore.t('notify.stashes.duty_failed', { error = tostring(result or 'unknown') }),
            type = 'error',
        })
        return
    end

    notify({
        description = result and ForgeCore.t('notify.stashes.duty_on') or ForgeCore.t('notify.stashes.duty_off'),
        type = 'success',
    })
end

local function buildForGroup(groupType, group)
    if not canUseGroup(groupType, group.name, 0) then return end

    local points = type(group.stashes) == 'table' and group.stashes or {}

    for i = 1, #points do
        local point = points[i]

        if type(point) == 'table' and point.enabled ~= false then
            local title = pointTitle(group, point)
            local stash = type(point.stash) == 'table' and point.stash or {}
            local duty = type(point.duty) == 'table' and point.duty or {}

            if stash.enabled ~= false then
                local coords = coordsVector(stash.coords or point.coords)

                if coords and canUseGroup(groupType, group.name, stash.minGrade) then
                    addZone({
                        coords = coords,
                        rotation = stash.rotation or point.rotation,
                        options = {
                            {
                                name = ('forge_core_stash_%s_%s_%s'):format(groupType, group.name, normalizeId(point.id)),
                                icon = 'box-seam-fill',
                                label = stash.label or ForgeCore.t('menu.stashes.open_target', { title = title }),
                                distance = PR.Job.Points.targetDistance or 2.0,
                                canInteract = function()
                                    return canUseGroup(groupType, group.name, stash.minGrade)
                                end,
                                onSelect = function()
                                    openStash(groupType, group, point)
                                end,
                            },
                        },
                    })
                end
            end

            if groupType == 'job' and duty.enabled == true then
                local coords = coordsVector(duty.coords)

                if coords and canUseGroup('job', group.name, duty.minGrade) then
                    addZone({
                        coords = coords,
                        rotation = duty.rotation or point.rotation,
                        options = {
                            {
                                name = ('forge_core_duty_%s_%s'):format(group.name, normalizeId(point.id)),
                                icon = 'clipboard2-check-fill',
                                label = duty.label or ForgeCore.t('menu.stashes.duty_target', { title = title }),
                                distance = PR.Job.Points.targetDistance or 2.0,
                                canInteract = function()
                                    return canUseGroup('job', group.name, duty.minGrade)
                                end,
                                onSelect = function()
                                    toggleDuty(group, point)
                                end,
                            },
                        },
                    })
                end
            end
        end
    end
end

function Points.refresh(payload)
    clearZones()

    if type(payload) ~= 'table' then return end
    Points.lastPayload = payload
    Points.accessSignature = accessSignature()

    local jobs = type(payload.jobs) == 'table' and payload.jobs or {}
    local gangs = type(payload.gangs) == 'table' and payload.gangs or {}

    for i = 1, #jobs do
        buildForGroup('job', jobs[i])
    end

    for i = 1, #gangs do
        buildForGroup('gang', gangs[i])
    end
end

function Points.refreshCurrent(accessOnly)
    if accessOnly and Points.accessSignature == accessSignature() then return end
    if Points.refreshPending then return end

    Points.refreshPending = true
    SetTimeout(250, function()
        Points.refreshPending = false

        if type(Points.lastPayload) == 'table' then
            Points.refresh(Points.lastPayload)
        end
    end)
end

RegisterNetEvent('QBCore:Player:SetPlayerData', function()
    Points.refreshCurrent(true)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    Points.refreshCurrent()
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function()
    Points.refreshCurrent()
end)

RegisterNetEvent('esx:setJob', function()
    Points.refreshCurrent()
end)

RegisterNetEvent('forge-core:client:jobPoints:refresh', function()
    Points.refreshCurrent()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        clearZones()
    end
end)

ForgeCore.Client.JobPoints = Points
