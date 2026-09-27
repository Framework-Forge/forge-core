PR = PR or {}
ForgeCore = ForgeCore or {}

ForgeCore.Lang = pr_lib.locale()

function ForgeCore.t(key, params)
    local translator = ForgeCore.Lang

    if type(translator) == 'table' then
        if type(translator.t) == 'function' then
            return translator:t(key, params)
        end

        local mt = getmetatable(translator)
        if mt and type(mt.__call) == 'function' then
            return translator(key, params)
        end
    elseif type(translator) == 'function' then
        return translator(key, params)
    end

    return key
end

-- Ativa logs do Forge Core pelo pr_bridge.
PR.Debug = false

-- Comando principal para abrir o menu administrativo.
PR.Command = 'forgecore'

-- Tecla principal para abrir o menu administrativo pelo pr_bridge.
PR.Keybind = {
    'ALT',
    '7'
}

PR.PlayerKeybind = {
    'F9'
}

-- Permissao principal. Pode ser liberada no server.cfg via ACE.
PR.AdminAce = 'forge-core.admin'

-- Integracoes diretas com outros sistemas Forge.
PR.Garage = {
    AdminMenu = {
        enabled = true,
        resource = 'forge-garage',
        event = 'forge_garage:client:garagelist',
    },
}

PR.Rental = {
    AdminMenu = {
        enabled = true,
        resource = 'forge-rental',
        event = 'forge-rental:server:openAdminMenu',
    },
}

local function normalizeImagePath(path)
    return (path or 'nui://ox_inventory/web/images'):gsub('/+$', '') .. '/'
end

-- Diretorio das imagens utilizado pelo inventory.
PR.ImagePath = normalizeImagePath(GetConvar('inventory:imagepath', 'nui://ox_inventory/web/images'))


PR.NotifyPos = 'center-left'
