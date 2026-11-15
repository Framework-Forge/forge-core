-- Private QBX port; not loaded by the live manifest. See kernel/NOTICE-06.md.
return function(ports)
    assert(type(ports) == 'table', 'explicit support ports required')
    local GetResourceState = assert(ports.getResourceState, 'resource-state port required')
    local GetVehicleNumberPlateText = assert(ports.getVehicleNumberPlateText, 'plate port required')
    local vec4 = assert(ports.vec4, 'vec4 port required')
    local joaat = assert(ports.joaat, 'joaat port required')
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

return {
    statusIntervalSeconds = 5, -- how often to check hunger/thirst status to remove health if 0.
    playerStatus = {
        snapshotDebounceMs = 500, -- Atualiza somente o cache do servidor; nao grava o banco.
        stress = {
            chance = 0.1,
            minimumSpeedUnbuckled = 50,
            minimumSpeedBuckled = 100,
            disablePoliceStress = false,
            vehicleClasses = {
                [0] = true, [1] = true, [2] = true, [3] = true, [4] = true,
                [5] = true, [6] = true, [7] = true, [8] = false, [9] = true,
                [10] = true, [11] = true, [12] = true, [13] = false, [14] = false,
                [15] = false, [16] = false, [18] = false, [19] = false,
                [20] = false, [21] = false,
            },
            whitelistedWeapons = {
                [joaat('weapon_petrolcan')] = true,
                [joaat('weapon_hazardcan')] = true,
                [joaat('weapon_fireextinguisher')] = true,
            },
        },
    },
    loadingModelsTimeout = 30000, -- Waiting time for ox_lib to load the models before throws an error, for low specs pc

    pauseMapText = "Forge Core", -- Text shown above the map when ESC is pressed. If left empty 'FiveM' will appear

    characters = {
        previewCameraDistance = 3.2, -- Distancia da camera frontal dos personagens, em metros.
        useExternalCharacters = false, -- Se você possui um recurso externo de gerenciamento de personagens. (Se verdadeiro, desativa o gerenciamento de personagens dentro do núcleo)
        enableDeleteButton = true, -- Whether players should be able to delete characters themselves.
        startingApartment = false, -- If true, requires an apartments resource handling apartments:client:setupSpawnUI

        dateFormat = "YYYY-MM-DD",
        dateMin = "1900-01-01", -- Has to be in the same format as the dateFormat config
        dateMax = "2006-12-31", -- Has to be in the same format as the dateFormat config

        limitNationalities = true, -- Setting this to false will allow people to enter whatever they want in the nationality field (To edit the list of nationalities, head to data/nationalities.lua)

        profanityWords = {
            ["bad word"] = true,
        },

        locations = { -- Spawn locations for multichar, these are chosen randomly
            {
                pedCoords = vec4(969.25, 72.61, 116.18, 276.55),
                camCoords = vec4(972.2, 72.9, 116.68, 97.27),
            },
            {
                pedCoords = vec4(1104.49, 195.9, -49.44, 44.22),
                camCoords = vec4(1102.29, 198.14, -48.86, 225.07),
            },
            {
                pedCoords = vec4(-2163.87, 1134.51, -24.37, 310.05),
                camCoords = vec4(-2161.7, 1136.4, -23.77, 131.52),
            },
            {
                pedCoords = vec4(-996.71, -68.07, -99.0, 57.61),
                camCoords = vec4(-999.90, -66.30, -98.45, 241.68),
            },
            {
                pedCoords = vec4(-1023.45, -418.42, 67.66, 205.69),
                camCoords = vec4(-1021.8, -421.7, 68.14, 27.11),
            },
            {
                pedCoords = vec4(2265.27, 2925.02, -84.8, 267.77),
                camCoords = vec4(2268.24, 2925.02, -84.36, 90.88),
            },
            {
                pedCoords = vec4(-1004.5, -478.51, 50.03, 28.19),
                camCoords = vec4(-1006.36, -476.19, 50.50, 210.38),
            },
        },
    },

    discord = {
        enabled = true, -- This will enable or disable the built in discord rich presence.

        appId = "1024981890798731345", -- This is the Application ID (Replace this with you own)

        largeIcon = { -- To set this up, visit https://forum.cfx.re/t/how-to-updated-discord-rich-presence-custom-image/157686
            icon = "duck", -- Here you will have to put the image name for the 'large' icon.
            text = "Qbox Ducky", -- Here you can add hover text for the 'large' icon.
        },

        smallIcon = {
            icon = "logo_name", -- Here you will have to put the image name for the 'small' icon.
            text = "This is a small icon with text", -- Here you can add hover text for the 'small' icon.
        },

        firstButton = {
            text = "Forge Discord",
            link = "https://discord.gg/s7JCXjnsEc",
        },

        secondButton = {
            text = "Forge Framework",
            link = "https://github.com/Framework-Forge",
        },
    },

    --- Only used by QB bridge
    hasKeys = function(plate, vehicle)
        if isResourceStarted("pr_carkeys") then
            local currentPlate = trimPlate(plate or (vehicle and GetVehicleNumberPlateText(vehicle)))
            return currentPlate and keys.pr.haveKey(currentPlate) or false
        end

        return not isResourceStarted("qbx_vehiclekeys") or keys.qbx.hasKeys(vehicle)
    end,

    teleport = {
        fadeDuration = 650, -- Screen fade duration in milliseconds when teleporting
        groundSearchMaxZ = 850.0, -- Maximum Z height to search for ground when teleporting
        groundSearchStartZ = 950.0, -- Starting Z height for ground search loop
        groundSearchStep = -25.0, -- Z increment step for ground search loop
        loadSceneRadius = 50.0, -- Radius to load the scene around the teleport destination
        timeout = 1000, -- Timeout in milliseconds for scene loading and collision checks
    },

    getVehiclesInRadius = {
        defaultRadius = 5, -- Default search radius when retrieving nearby vehicles
    },

    meCommand = {
        distance = 25, -- Maximum distance at which players can see each other's /me text
        displayTime = 5000, -- Duration in milliseconds the /me text remains visible
    },

    setVehicleProperties = {
        timeout = 1000, -- Timeout in milliseconds when attempting to set vehicle properties
        waitInterval = 50, -- Wait time in milliseconds between property set attempts
    },

    initVehicle = {
        seats = { -1, 0 }, -- List of seat indices to clear when initializing a vehicle
    },
}
end
