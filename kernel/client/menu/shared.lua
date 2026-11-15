-- Ten complete installed UI boundary helpers, not the entire central menu controller.
return function(ports)
    local library,translate=assert(ports.library),assert(ports.translate)
    local PR={NotifyPos=ports.notifyPosition}
local function t(key, params)
    return translate(key, params)
end
local function notify(data)
    if library and library.Notify then
        library.Notify({
            title = data.title or t('core.title'),
            description = data.description,
            type = data.type,
            position = PR.NotifyPos,
        })
    end
end

local function showContext(context)
    if not library or not library.menus or not library.menus.RegisterContext or not library.menus.ShowContext then
        notify({
            title = t('core.title'),
            description = t('errors.no_menu_system'),
            type = 'error',
        })
        return false
    end

    library.menus.RegisterContext(context)
    library.menus.ShowContext(context.id)
    return true
end

local function inputDialog(title, rows, options)
    if not library or not library.menus or not library.menus.InputDialog then
        notify({
            title = t('core.title'),
            description = t('errors.no_input_dialog'),
            type = 'error',
        })
        return nil
    end

    return library.menus.InputDialog(title, rows, options)
end

local function alertDialog(data)
    if not library or not library.menus or not library.menus.AlertDialog then return nil end
    return library.menus.AlertDialog(data)
end

local function awaitServer(callbackName, ...)
    if not library or not library.callback or not library.callback.await then
        return false, 'callback_unavailable'
    end

    return library.callback.await(callbackName, 10000, ...)
end

local function notifyFailure(localeKey, error)
    notify({
        title = t('core.title'),
        description = t(localeKey, { error = tostring(error or 'unknown') }),
        type = 'error',
    })
end
local function boolValue(value)
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'sim'
end

local function boolDefault(value)
    return value and 'true' or 'false'
end

local function boolOptions()
    return {
        { value = 'true', label = t('common.yes') },
        { value = 'false', label = t('common.no') },
    }
end

    return {t=t,notify=notify,showContext=showContext,inputDialog=inputDialog,alertDialog=alertDialog,
        awaitServer=awaitServer,notifyFailure=notifyFailure,boolValue=boolValue,boolDefault=boolDefault,boolOptions=boolOptions}
end
