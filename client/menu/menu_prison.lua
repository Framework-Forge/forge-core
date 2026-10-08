local Menu, Shared = ForgeCore.Client.Menu, ForgeCore.Client.MenuShared
local t = Shared.t

function Shared.prisonDescription(status)
    if not status or not (status.jailed or status.fugitive or status.status == 'fugitive') then return t('prison.free') end
    local minutes = math.max(0, math.ceil(tonumber(status.remainingMinutes) or 0))
    local text = t('prison.status', { status = t('prison.' .. ((status.fugitive or status.status == 'fugitive') and 'fugitive' or 'jailed')) })
        .. '\n' .. t('prison.duration', { days = tostring(math.floor(minutes / 1440)), hours = tostring(math.floor(minutes % 1440 / 60)), minutes = tostring(minutes % 60) })
    if status.sentence then
        local sentence = status.sentence
        local unit = ({ minutes = 'minutes', hours = 'hours', days = 'days' })[sentence.unit] or 'minutes'
        text = text .. '\n' .. t('prison.original', { amount = tostring(sentence.amount or 0), unit = t('prison.' .. unit) })
    end
    return text
end

local function action(callback, target, sentence)
    -- Prison entry includes fades and streaming: do not use the generic 10s wait.
    local ok, success, reason = pcall(pr_lib.callback.await, callback, 60000, target, sentence)
    if not ok or success ~= true then Shared.notifyFailure('prison.failed', ok and reason or success) end
    Menu.openManagedPlayer(target)
end

function Menu.setPlayerPrison(target)
    local ok, data = Shared.awaitServer(PR.PlayerManagement.Callbacks.details, target)
    if not ok or not data.prison then Shared.notifyFailure('prison.failed', 'prison_unavailable'); return end
    local form = Shared.inputDialog(t('prison.set'), {
        { type = 'number', label = t('prison.amount'), default = 1, min = 1, max = data.prison.maxAmount or 9999, required = true },
        { type = 'select', label = t('prison.unit'), default = 'minutes', required = true, options = {
            { value = 'minutes', label = t('prison.minutes') }, { value = 'hours', label = t('prison.hours') }, { value = 'days', label = t('prison.days') },
        } },
        { type = 'select', label = t('prison.clock'), default = 'real', required = true, options = {
            { value = 'real', label = t('prison.real') }, { value = 'game', label = t('prison.game') },
        } },
    })
    if not form then return Menu.openManagedPlayer(target) end
    action(PR.PlayerManagement.Callbacks.prisonSentence, target, { amount = tonumber(form[1]), unit = form[2], clock = form[3] })
end

function Menu.releasePlayerPrison(target)
    local answer = Shared.alertDialog({ header = t('prison.release'), content = t('prison.confirm_release'), centered = true, cancel = true })
    if answer ~= 'confirm' then return Menu.openManagedPlayer(target) end
    action(PR.PlayerManagement.Callbacks.prisonRelease, target)
end
