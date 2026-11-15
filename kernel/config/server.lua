-- Private QBX port; not loaded by the live manifest. See kernel/NOTICE-06.md.
return function(ports)
    assert(type(ports) == 'table', 'explicit support ports required')
    local GetResourceState = assert(ports.getResourceState, 'resource-state port required')
    local GetVehicleNumberPlateText = assert(ports.getVehicleNumberPlateText, 'plate port required')
    local SetVehicleDoorsLocked = assert(ports.setVehicleDoorsLocked, 'native lock port required')
    local random = assert(ports.random, 'random port required')
    local randomString = assert(ports.randomString, 'random-string port required')
    -- Provider labels preserve installed selection semantics, not direct exports.
    -- These functions must be bound through PR Bridge before any activation.
    local keys = assert(ports.vehicleKeys, 'PR vehicle-key integration ports required')
local function isResourceStarted(resource)
    local state = GetResourceState(resource)
    return state == "started" or state == "starting"
end

local function trimPlate(plate)
    if not plate then
        return
    end
    return tostring(plate):gsub("^%s*(.-)%s*$", "%1")
end

local function normalizeLockState(state)
    if state == "lock" then
        return 2
    end
    if state == "unlock" then
        return 1
    end
    return state
end

local function givePrCarkeysVehicleKey(src, plate, vehicle, keyType, duration)
    plate = trimPlate(plate or (vehicle and GetVehicleNumberPlateText(vehicle)))
    if not plate then
        return false
    end

    if keyType == "permanent" then
        local ok, result = pcall(function()
            return keys.pr.buyOriginalKey(src, plate)
        end)
        return ok and result
    end

    if keyType == "timed" then
        local ok, result = pcall(function()
            return keys.pr.buyOriginalKey(src, plate, duration)
        end)
        return ok and result
    end

    local ok, barcode = pcall(function()
        return keys.pr.createTempKeyItem(src, plate)
    end)
    if ok and barcode then
        return barcode
    end

    ok = pcall(function()
        keys.pr.giveTempKey(src, plate)
    end)
    return ok
end

return {
    money = {
        ---@alias MoneyType 'cash' | 'bank' | 'crypto'
        ---@alias Money {cash: number, bank: number, crypto: number}
        ---@type Money
        moneyTypes = { cash = 0, bank = 0, crypto = 0 }, -- type = startamount -Adicione ou remova tipos de dinheiro do seu servidor (por exemplo, blackmoney = 0), lembre-se que uma vez adicionado ele não será removido do banco de dados!
        dontAllowMinus = { "cash", "crypto" }, -- Dinheiro que não é permitido entrar em menos
    },

    player = {
        status = {
            decayIntervalMinutes = 5, -- Intervalo logico para reduzir fome e sede.
            checkpointMinutes = 15, -- Distribui os salvamentos completos ao longo deste periodo.
            hungerRate = 4.2,
            thirstRate = 3.8,
        },

        ---@enum BloodType
        bloodTypes = {
            "A+",
            "A-",
            "B+",
            "B-",
            "AB+",
            "AB-",
            "O+",
            "O-",
        },

        ---@alias UniqueIdType 'citizenid' | 'AccountNumber' | 'PhoneNumber' | 'FingerId' | 'WalletId' | 'SerialNumber'
        ---@type table<UniqueIdType, {valueFunction: function}>
        identifierTypes = {
            citizenid = {
                valueFunction = function()
                    return randomString("A.......")
                end,
            },
            AccountNumber = {
                valueFunction = function()
                    return "US0"
                        .. random(1, 9)
                        .. "QBX"
                        .. random(1111, 9999)
                        .. random(1111, 9999)
                        .. random(11, 99)
                end,
            },
            PhoneNumber = {
                valueFunction = function()
                    return random(100, 999) .. random(1000000, 9999999)
                end,
            },
            FingerId = {
                valueFunction = function()
                    return randomString("...............")
                end,
            },
            WalletId = {
                valueFunction = function()
                    return "QB-" .. random(11111111, 99999999)
                end,
            },
            SerialNumber = {
                valueFunction = function()
                    return random(11111111, 99999999)
                end,
            },
        },
    },

    ---@alias TableName string
    ---@alias ColumnName string
    ---@type [TableName, ColumnName][]
    characterDataTables = {
        --  ps-housing
        --{ 'properties',                    'owner' },
        { "properties", "owner_citizenid" },
        -- ps-housing
        { "bank_accounts_new", "id" },
        { "playerskins", "citizenid" },
        { "player_mails", "citizenid" },
        { "player_outfits", "citizenid" },
        { "player_vehicles", "citizenid" },
        { "player_groups", "citizenid" },
        { "players", "citizenid" },
        { "npwd_calls", "identifier" },
        { "npwd_darkchat_channel_members", "user_identifier" },
        { "npwd_marketplace_listings", "identifier" },
        { "npwd_messages_participants", "participant" },
        { "npwd_notes", "identifier" },
        { "npwd_phone_contacts", "identifier" },
        { "npwd_phone_gallery", "identifier" },
        { "npwd_twitter_profiles", "identifier" },
        { "npwd_match_profiles", "identifier" },
    }, -- Linhas a serem excluídas quando o caractere for excluído

    server = {
        pvp = true, -- Habilite ou desabilite o pvp no servidor (capacidade de atirar em outros jogadores)
        closed = false, -- Definir servidor fechado (ninguém pode entrar, exceto pessoas com permissão ace 'qbadmin.join')
        closedReason = "Server Closed", -- Mensagem de motivo a ser exibida quando as pessoas não conseguem entrar no servidor
        whitelist = false, -- Habilite ou desabilite a lista de permissões no servidor
        whitelistPermission = "admin", -- Permissão que permite entrar no servidor quando a lista de permissões está ativada
        discord = "", -- Link de convite do Discord
        checkDuplicateLicense = false, -- Permite dois clientes locais (-cl2) com a mesma licença para testes
        ---@deprecated use cfg ACE system instead
        requireOptIn = false, -- Defina como false para desativar o requisito de usar o comando /optin antes de acessar comandos administrativos
        permissions = { "god", "admin", "mod", "forge-core.admin" }, -- Adicione quantos grupos quiser aqui depois de criá-los em seu server.cfg
    },

    characters = {
        playersNumberOfCharacters = { -- Defina a quantidade máxima de personagens dos jogadores por licença rockstar (você pode encontrar esta licença no banco de dados do seu servidor na tabela de jogadores)
            ["license2:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"] = 5,
        },

        defaultNumberOfCharacters = 3, -- Definir quantidade máxima de caracteres padrão (máximo 3 caracteres definidos por padrão)
    },

    -- esta configuração é apenas para eventos principais. colocar outros webhooks aqui não terá efeito
    logging = {
        webhook = {
            ["default"] = nil, -- default
            ["joinleave"] = nil, -- default
            ["ooc"] = nil, -- default
            ["anticheat"] = nil, -- default
            ["playermoney"] = nil, -- default
        },
        role = {}, -- Função a ser marcada para logs de alta prioridade. As funções usam <@%roleid> e os usuários/canais são <@userid/channelid>
    },

    persistence = {
        lockState = "lock", -- 'lock': o veículo será bloqueado quando gerado, 'unlock': o veículo será desbloqueado quando gerado
    },

    giveVehicleKeys = function(src, plate, vehicle, keyType, duration)
        if isResourceStarted("pr_carkeys") then
            return givePrCarkeysVehicleKey(src, plate, vehicle, keyType, duration)
        end

        if isResourceStarted("qbx_vehiclekeys") then
            return keys.qbx.giveKeys(src, vehicle)
        end
    end,

    setVehicleLock = function(vehicle, state)
        if isResourceStarted("pr_carkeys") then
            keys.pr.setLockState(vehicle, normalizeLockState(state))
            return
        end

        if isResourceStarted("qbx_vehiclekeys") then
            keys.qbx.setLockState(vehicle, state)
            return
        end

        SetVehicleDoorsLocked(vehicle, normalizeLockState(state))
    end,
}
end
