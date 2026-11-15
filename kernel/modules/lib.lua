-- Private installed-QBX port. Inactive; see kernel/NOTICE-07.md.
return function(ports)
    assert(type(ports) == 'table', 'explicit helper ports required')
    assert(type(ports.isServer) == 'boolean', 'server/client side required')
    local native = assert(ports.native, 'native helper ports required')
    local lib = assert(ports.library, 'PR library ports required')
    local cache = assert(ports.cache, 'passive context cache required')
    local core = ports.core
    local audio = assert(ports.audio, 'PR audio integration ports required')
    local warn = assert(ports.warn, 'warning port required')
    if ports.isServer then
        assert(type(core) == 'table' and type(core.getVehiclesByHash) == 'function'
            and type(core.setEntityBucket) == 'function' and type(core.enablePersistence) == 'function',
            'internal vehicle services required')
    end
local isServer = ports.isServer

local qbx = {}
qbx.string = {}
qbx.math = {}
qbx.table = {}
qbx.array = {}

qbx.armsWithoutGloves = lib.table.freeze({
    male = lib.table.freeze({
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
        [14] = true,
        [15] = true,
        [18] = true,
        [26] = true,
        [52] = true,
        [53] = true,
        [54] = true,
        [55] = true,
        [56] = true,
        [57] = true,
        [58] = true,
        [59] = true,
        [60] = true,
        [61] = true,
        [62] = true,
        [112] = true,
        [113] = true,
        [114] = true,
        [118] = true,
        [125] = true,
        [132] = true
    }),

    female = lib.table.freeze({
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
        [14] = true,
        [15] = true,
        [19] = true,
        [59] = true,
        [60] = true,
        [61] = true,
        [62] = true,
        [63] = true,
        [64] = true,
        [65] = true,
        [66] = true,
        [67] = true,
        [68] = true,
        [69] = true,
        [70] = true,
        [71] = true,
        [129] = true,
        [130] = true,
        [131] = true,
        [135] = true,
        [142] = true,
        [149] = true,
        [153] = true,
        [157] = true,
        [161] = true,
        [165] = true
    }),
})


qbx.duffelbagIndexes = lib.table.freeze({
    male = lib.table.freeze({
        [40] = true,
        [41] = true,
        [44] = true,
        [45] = true,
        [81] = true,
        [82] = true,
        [85] = true,
        [86] = true,
        [130] = true,
        [131] = true,
        [132] = true
    }),
    female = lib.table.freeze({
        [40] = true,
        [41] = true,
        [44] = true,
        [45] = true,
        [81] = true,
        [82] = true,
        [85] = true,
        [86] = true,
        [131] = true,
        [132] = true,
        [133] = true
    })
})


---Returns the given string with its trailing whitespaces removed.
---@param str string
---@return string
function qbx.string.trim(str)
    local trimmed = str:gsub('^%s*(.-)%s*$', '%1')
    return trimmed
end

---Returns the given string with its first character capitalized.
---@param str string
---@return string
function qbx.string.capitalize(str)
    local capitalized = str:gsub('^%l', string.upper)
    return capitalized
end

---Rounds and returns the given number.
---@param num number
---@param decimalPlaces? integer
---@return number rounded integer if `decimalPlaces` isn't passed, number otherwise
function qbx.math.round(num, decimalPlaces)
    if not decimalPlaces then return math.floor(num + 0.5) end
    local power = 10 ^ decimalPlaces
    return math.floor((num * power) + 0.5) / power
end

---Returns the number of items in a table. Useful for non-array tables.
---@param tbl table
---@return integer
function qbx.table.size(tbl)
    local size = 0
    for _ in pairs(tbl) do
        size = size + 1
    end
    return size
end

---Maps and returns the values of the given table by the given subfield.
---@param tble table
---@param subfield any
---@return table<any, table[]>
function qbx.table.mapBySubfield(tble, subfield)
    local map = {}

    for _, subTable in pairs(tble) do
        local subfieldValue = subTable[subfield]

        if subfieldValue then
            if not map[subfieldValue] then
                map[subfieldValue] = {}
            end

            map[subfieldValue][#map[subfieldValue] + 1] = subTable
        end
    end

    return map
end

---Returns true if the given array contains the given value.
---@generic T
---@param arr T[]
---@param val T
---@return boolean
function qbx.array.contains(arr, val)
    for i = 1, #arr do
        if arr[i] == val then
            return true
        end
    end

    return false
end

---Returns the number plate of the given vehicle.
---@param vehicle integer
---@return string?
function qbx.getVehiclePlate(vehicle)
    local plate = native.GetVehicleNumberPlateText(vehicle)
    if not plate then return end
    return qbx.string.trim(plate)
end

---Generates and returns a random number plate with the given pattern.
---Note that the generated plate may or may not be already used by an existing vehicle.
---For more info about the pattern see [`lib.string.random`](https://coxdocs.dev/ox_lib/Modules/String/Shared#stringrandom) from ox_lib.
---@param pattern? string
---@return string
function qbx.generateRandomPlate(pattern)
    pattern = pattern or '........'
    return lib.string.random(pattern):upper()
end

---Returns the cardinal direction that the given entity is staring towards, or nil if the entity doesn't exist.
---```
---                 North
---     45°           0°           315°
---       \    .- - - - - - -.    /
---          X                 X
---        .'   \           /   '.
---       |        \     /        |
--- West  |           X           |  East
---       |        /     \        |
---        '.   /           \   .'
---          X                 X
---       /    '- - - - - - -'    \
---     135°                      225°
---                 South
---```
---(art inspired by [`SET_PED_TURNING_THRESHOLDS`](https://github.com/citizenfx/fivem/blob/0b61c93a3308360ea70d443398eab17f47453e11/code/components/extra-natives-five/src/PedExtraNatives.cpp#L390-L400))
---@param entity integer
---@return 'North' | 'South' | 'East' | 'West'
function qbx.getCardinalDirection(entity)
    -- heading is between 0 - 360 (excluding 360)
    local heading = native.GetEntityHeading(entity) % 360

    if heading < 45 or heading >= 315 then
        return 'North'
    end

    if heading >= 45 and heading < 135 then
        return 'West'
    end

    if heading >= 135 and heading < 225 then
        return 'South'
    end

    -- heading >= 225 and heading < 315
    return 'East'
end

if isServer then
    ---@class LibSpawnVehicleParams
    ---@field model integer
    ---@field spawnSource integer | vector3 | vector4 ped id or coords
    ---@field warp? boolean | integer a ped id to warp inside the vehicle, or additionally a boolean if `spawnSource` is a ped
    ---@field props? table https://coxdocs.dev/ox_lib/Modules/VehicleProperties/Client#vehicle-properties
    ---@field bucket? integer routing bucket to move spawned entity to.

    ---Creates a vehicle on the server-side and returns its `netId`.
    ---
    ---The `CreateVehicleServerSetter` native uses only the server to create a vehicle instead of using the client as well.
    ---To get the vehicle on the client first check and wait for it to exist using the `NetworkDoesEntityExistWithNetworkId` native,
    ---then get the vehicle's id by using `NetToVeh`.
    --[[

    lib.waitFor(function()
        if native.NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(netId)
        end
    end)
    ]]
    ---@param params LibSpawnVehicleParams
    ---@return integer netId
    ---@return number veh
    function qbx.spawnVehicle(params)
        local model = params.model
        local source = params.spawnSource
        local sourceType = type(source)
        local warp = params.warp
        local ped = type(warp) == 'number' and warp or (sourceType == 'number' and warp and source or nil)
        local props = params.props
        local bucket = params.bucket or ped and native.GetEntityRoutingBucket(ped) or nil

        ---@type vector4
        local coords
        if sourceType == 'vector3' then
            coords = native.vec4(source.x, source.y, source.z, 0)
        elseif sourceType == 'vector4' then
            coords = source
        else
            local pedCoords = native.GetEntityCoords(source)
            coords = native.vec4(pedCoords.x, pedCoords.y, pedCoords.z, native.GetEntityHeading(source))
        end

        local vehicleType = core.getVehiclesByHash(native.joaat(model)).type
        if not vehicleType then
            warn(('No vehicle type found for model: %s temp vehicle was created and taken in type'):format(
                model))

            local tempVehicle = native.CreateVehicle(model, 0, 0, -200, 0, true, true)
            while not native.DoesEntityExist(tempVehicle) do native.Wait(0) end

            vehicleType = native.GetVehicleType(tempVehicle)
            native.DeleteEntity(tempVehicle)
        end

        local attempts = 0

        local veh, netId
        while attempts < 3 do
            veh = native.CreateVehicleServerSetter(model, vehicleType, coords.x, coords.y, coords.z, coords.w)

            if bucket and bucket > 0 then
                core.setEntityBucket(veh, bucket)
            end

            while not native.DoesEntityExist(veh) do native.Wait(0) end
            while native.GetVehicleNumberPlateText(veh) == '' do native.Wait(0) end

            if ped then
                native.SetPedIntoVehicle(ped, veh, -1)
            end

            if not pcall(function()
                lib.waitFor(function()
                    local owner = native.NetworkGetEntityOwner(veh)
                    if ped then
                        --- the owner should be transferred to the driver
                        if owner == native.NetworkGetEntityOwner(ped) then return true end
                    else
                        if owner ~= -1 then return true end
                    end
                end, 'client never set as owner', 5000)
            end) then
                native.DeleteEntity(veh)
                error('Deleting vehicle which timed out finding an owner')
            end

            local state = native.Entity(veh).state
            local owner = native.NetworkGetEntityOwner(veh)
            state:set('initVehicle', true, true)
            netId = native.NetworkGetNetworkIdFromEntity(veh)
            if props and type(props) == 'table' and props.plate then
                native.TriggerClientEvent('qbx_core:client:setVehicleProperties', owner, netId, props)
                local success = pcall(function()
                    local plateMatched = false
                    lib.waitFor(function()
                        if qbx.string.trim(native.GetVehicleNumberPlateText(veh)) == qbx.string.trim(props.plate) then
                            local currentOwner = native.NetworkGetEntityOwner(veh)
                            assert(currentOwner == owner, ('Owner changed during vehicle init. expected=%s, actual=%s'):format(owner, currentOwner))
                            --- check that the plate matches twice, 100ms apart as a bug has been observed in which server side matches but plate is not observed by clients to match
                            if plateMatched then
                                return true
                            end
                            plateMatched = true
                            native.Wait(100)
                        end
                    end, 'Failed to set vehicle properties within 1 second', 1000)
                end)
                if success then
                    break
                else
                    native.DeleteEntity(veh)
                    attempts = attempts + 1
                end
            else
                break
            end
        end

        if attempts == 3 then
            error('unable to successfully spawn vehicle after 3 attempts')
        end

        --- prevent server from deleting a vehicle without an owner
        native.SetEntityOrphanMode(veh, 2)
        core.enablePersistence(veh)
        return netId, veh
    end

    ---@class LibPlayAudioParams
    ---@field audioBank? string
    ---@field audioName string|string[]
    ---@field audioRef string
    ---@field soundSet? string alias for audioRef
    ---@field audioSource? number | vector3 server entity handle or vector3 coords
    ---@field source? number | vector3 alias for audioSource
    ---@field entity? number alias for audioSource
    ---@field coords? vector3 alias for audioSource
    ---@field range? number
    ---@field radius? number alias for range
    ---@field timeout? number audio bank load timeout

    ---Plays a native GTA/FiveM sound through pr_3dsound server exports.
    ---Use this from server code when the sound should be heard by other players.
    ---@param target? number|number[] player source, -1, nil, or a source list
    ---@param params? LibPlayAudioParams
    ---@return boolean
    function qbx.playAudio(target, params)
        if type(target) == 'table' and not params and target.audioName then
            params = target
            target = -1
        end

        if native.GetResourceState('pr_3dsound') ~= 'started' then return false end
        if type(params) ~= 'table' then return false end

        local audioSource = params.audioSource or params.source or params.entity or params.coords
        local range = params.range or params.radius or 5.0
        local payload = {
            audioBank = params.audioBank,
            audioName = params.audioName,
            audioRef = params.audioRef,
            soundSet = params.soundSet,
            range = range,
            timeout = params.timeout,
            occlusion = params.occlusion,
            skipOnOcclusion = params.skipOnOcclusion,
            occlusionMode = params.occlusionMode,
            occludedAudioName = params.occludedAudioName,
            occludedAudioRef = params.occludedAudioRef,
            interval = params.interval or params.delayBetweenSounds,
        }

        local sourceType = type(audioSource)
        local ok, result

        if sourceType == 'vector3' or (sourceType == 'table' and audioSource.x and audioSource.y and audioSource.z) then
            payload.coords = audioSource
            ok, result = pcall(function()
                return audio.PlayNativeSoundFromCoords(target or -1, payload)
            end)
        elseif sourceType == 'number' then
            payload.entity = audioSource
            ok, result = pcall(function()
                return audio.PlayNativeSoundFromEntity(target or -1, payload)
            end)
        else
            ok, result = pcall(function()
                return audio.PlayNativeSound(target or -1, payload)
            end)
        end

        return ok and result == true
    end
else
    ---@class LibDrawTextParams
    ---@field text string
    ---@field scale? integer default: `0.35`
    ---@field font? integer default: `4`
    ---@field color? vector4 rgba, white by default
    ---@field enableDropShadow? boolean
    ---@field enableOutline? boolean

    ---@class LibDrawText2DParams : LibDrawTextParams
    ---@field coords vector2
    ---@field width? number default: `1.0`
    ---@field height? number default: `1.0`

    ---Draws text onto the screen in 2D space for a single frame.
    ---@param params LibDrawText2DParams
    function qbx.drawText2d(params)
        local text = params.text
        local coords = params.coords
        local scale = params.scale or 0.35
        local font = params.font or 4
        local color = params.color or native.vec4(255, 255, 255, 255)
        local width = params.width or 1.0
        local height = params.height or 1.0
        local enableDropShadow = params.enableDropShadow or false
        local enableOutline = params.enableOutline or false

        native.SetTextScale(scale, scale)
        native.SetTextFont(font)
        native.SetTextColour(math.floor(color.r), math.floor(color.g), math.floor(color.b), math.floor(color.a))
        if enableDropShadow then
            native.SetTextDropShadow()
        end
        if enableOutline then
            native.SetTextOutline()
        end

        native.SetTextCentre(true)
        native.BeginTextCommandDisplayText('STRING')
        native.AddTextComponentSubstringPlayerName(text)
        native.EndTextCommandDisplayText(coords.x - width / 2, coords.y - height / 2 + 0.005)
    end

    ---@class LibDrawText3DParams : LibDrawTextParams
    ---@field coords vector3
    ---@field disableDrawRect? boolean
    ---@field scale? integer | vector2 default: `native.vec2(0.35,0.35)`

    ---Draws text onto the screen in 3D space for a single frame.
    ---@param params LibDrawText3DParams
    function qbx.drawText3d(params) -- luacheck: ignore
        local isScaleparamANumber = type(params.scale) == "number"
        local text = params.text
        local coords = params.coords
        local scale = (isScaleparamANumber and native.vec2(params.scale, params.scale))
        or params.scale
        or native.vec2(0.35, 0.35)
        local font = params.font or 4
        local color = params.color or native.vec4(255, 255, 255, 255)
        local enableDropShadow = params.enableDropShadow or false
        local enableOutline = params.enableOutline or false

        native.SetTextScale(scale.x, scale.y)
        native.SetTextFont(font)
        native.SetTextColour(math.floor(color.r), math.floor(color.g), math.floor(color.b), math.floor(color.a))
        if enableDropShadow then
            native.SetTextDropShadow()
        end
        if enableOutline then
            native.SetTextOutline()
        end
        native.SetTextCentre(true)
        native.BeginTextCommandDisplayText('STRING')
        native.AddTextComponentSubstringPlayerName(text)
        native.SetDrawOrigin(coords.x, coords.y, coords.z, 0)
        native.EndTextCommandDisplayText(0.0, 0.0)

        if not params.disableDrawRect then
            local factor = #text / 370
            native.DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
        end
        native.ClearDrawOrigin()
    end

    ---Gets and returns an entity handle and network id from a state bag name
    ---([source](https://github.com/overextended/ox_core/blob/main/client/utils.lua)).
    ---@async
    ---@param bagName string
    ---@return integer entity, integer netId
    function qbx.getEntityAndNetIdFromBagName(bagName)
        local netId = tonumber(bagName:gsub('entity:', ''), 10)

        local entity = lib.waitFor(function()
            if native.NetworkDoesEntityExistWithNetworkId(netId) then
                return native.NetworkGetEntityFromNetworkId(netId)
            end
        end, ('statebag timed out while awaiting entity creation! (%s)'):format(bagName), 10000)

        if not entity then
            lib.print.error(('statebag received invalid entity! (%s)'):format(bagName))
            return 0, 0
        end

        return entity, netId
    end

    ---Returns a state bag handler made for entities
    ---([source](https://github.com/overextended/ox_core/blob/main/client/utils.lua)).
    ---@param keyFilter string
    ---@param cb fun(entity: number, netId: number, value: any, bagName: string)
    ---@return number
    function qbx.entityStateHandler(keyFilter, cb)
        return native.AddStateBagChangeHandler(keyFilter, '', function(bagName, _, value)
            local entity, netId = qbx.getEntityAndNetIdFromBagName(bagName)
            if entity then
                cb(entity, netId, value, bagName)
            end
        end)
    end

    ---Deletes the specified vehicle and returns whether it was successful.
    ---@param vehicle integer
    ---@return boolean deleted
    function qbx.deleteVehicle(vehicle)
        native.SetEntityAsMissionEntity(vehicle, true, true)
        native.DeleteVehicle(vehicle)
        return not native.DoesEntityExist(vehicle)
    end

    ---Returns the model name of the given vehicle.
    ---@param vehicle integer
    ---@return string
    function qbx.getVehicleDisplayName(vehicle)
        return native.GetLabelText(native.GetDisplayNameFromVehicleModel(native.GetEntityModel(vehicle)))
    end

    ---Returns the brand name of the given vehicle.
    ---@param vehicle integer
    ---@return string
    function qbx.getVehicleMakeName(vehicle)
        return native.GetLabelText(native.GetMakeNameFromVehicleModel(native.GetEntityModel(vehicle)))
    end

    ---Returns the mod type name of the given vehicle.
    ---@param vehicle integer
    ---@param modType integer
    ---@param modIndex integer
    ---@return string
    function qbx.getVehicleModName(vehicle, modType, modIndex)
        return native.GetLabelText(native.GetModTextLabel(vehicle, modType, modIndex))
    end

    ---Returns the livery name of the given vehicle.
    ---@param vehicle integer
    ---@param liveryIndex integer
    ---@return string
    function qbx.getVehicleLiveryName(vehicle, liveryIndex)
        return native.GetLabelText(native.GetLiveryName(vehicle, liveryIndex))
    end

    ---Returns the street name and cross section name at the given coords.
    ---@param coords vector3
    ---@return { main: string, cross: string }
    function qbx.getStreetName(coords)
        local street1, street2 = native.GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        return { main = native.GetStreetNameFromHashKey(street1), cross = native.GetStreetNameFromHashKey(street2) }
    end

    ---Returns the name of the zone at the given coords.
    ---@param coords vector3
    ---@return string
    function qbx.getZoneName(coords)
        return native.GetLabelText(native.GetNameOfZone(coords.x, coords.y, coords.z))
    end

    ---Set an extra on the given vehicle.
    ---@param vehicle integer
    ---@param extra integer
    ---@param enable boolean
    function qbx.setVehicleExtra(vehicle, extra, enable)
        if not native.DoesExtraExist(vehicle, extra) then return end
        native.SetVehicleExtra(vehicle, extra, not enable)
    end

    ---Enables all the extras of the given vehicle.
    ---@param vehicle integer
    function qbx.resetVehicleExtras(vehicle)
        for i = 1, 20 do
            qbx.setVehicleExtra(vehicle, i, true)
        end
    end

    ---Sets all the extras of the given vehicle.
    ---@param vehicle integer
    ---@param extras table<integer, boolean>
    function qbx.setVehicleExtras(vehicle, extras)
        qbx.resetVehicleExtras(vehicle)

        for id, enable in pairs(extras) do
            qbx.setVehicleExtra(vehicle, id, enable)
        end
    end

    ---Returns if the local ped is wearing gloves.
    ---@return boolean
    function qbx.isWearingGloves()
        local armIndex = native.GetPedDrawableVariation(cache.ped, 3)
        local model = native.GetEntityModel(cache.ped)
        local tble = qbx.armsWithoutGloves[model == native.joaat('mp_m_freemode_01') and 'male' or 'female']
        return not tble[armIndex]
    end

    --- Returns if the local ped is wearing a duffel bag.
    --- @return boolean
    function qbx.isWearingDuffelbag()
        local torsoIndex = native.GetPedDrawableVariation(cache.ped, 5) -- Duffel bags are in component 5
        local model = native.GetEntityModel(cache.ped)
        local tble = qbx.duffelbagIndexes[model == native.joaat('mp_m_freemode_01') and 'male' or 'female']
        return tble[torsoIndex] == true
    end

    ---Attempts to load an audio bank and returns whether it was successful.
    ---Remember to use `ReleaseScriptAudioBank` since you can only load up to 10 banks.
    ---@param audioBank string
    ---@param timeout number?
    ---@return boolean
    function qbx.loadAudioBank(audioBank, timeout)
        local loaded = lib.waitFor(function()
            if native.RequestScriptAudioBank(audioBank, false) then
                return true
            end
        end, ('timed out while requesting audio bank! (%s)'):format(audioBank), timeout or 500) or false

        if loaded then
            qbx.lastAudioBank = audioBank
        end

        return loaded
    end

    ---@class LibPlayAudioParams
    ---@field audioBank? string
    ---@field audioName string|string[]
    ---@field audioRef string
    ---@field soundSet? string alias for audioRef
    ---@field returnSoundId? boolean
    ---@field audioSource? number | vector3 entity handle or vector3 coords
    ---@field source? number | vector3 alias for audioSource
    ---@field entity? number alias for audioSource
    ---@field coords? vector3 alias for audioSource
    ---@field range? number only used if `audioSource` is a vector3 coordinate
    ---@field radius? number alias for range
    ---@field shared? boolean set false to force local-only playback
    ---@field timeout? number audio bank load timeout

    ---@deprecated use pr_3dsound native exports instead
    ---Plays a sound with the provided audio name and audio ref.
    ---Positional sounds are shared through pr_3dsound by default.
    ---If `returnSoundId` is false or not specified the soundId is released,
    ---otherwise the function returns the soundId without releasing it.
    ---@param params LibPlayAudioParams
    ---@return number? soundId
    function qbx.playAudio(params)
        if type(params) ~= 'table' then return end

        local audioName = params.audioName
        local audioRef = params.audioRef or params.soundSet
        local returnSoundId = params.returnSoundId or false
        local audioSource = params.audioSource or params.source or params.entity or params.coords
        local range = params.range or params.radius or 5.0

        local function fallback()
            local soundId = native.GetSoundId()

            local sourceType = type(audioSource)
            if sourceType == 'vector3' or (sourceType == 'table' and audioSource.x and audioSource.y and audioSource.z) then
                local coords = sourceType == 'vector3' and audioSource or native.vector3(audioSource.x, audioSource.y, audioSource.z)
                native.PlaySoundFromCoord(soundId, audioName, coords.x, coords.y, coords.z, audioRef, false, range, false)
            elseif sourceType == 'number' then
                native.PlaySoundFromEntity(soundId, audioName, audioSource, audioRef, false, false)
            else
                native.PlaySoundFrontend(soundId, audioName, audioRef, true)
            end

            if returnSoundId then
                return soundId
            end

            native.ReleaseSoundId(soundId)
            return true
        end

        if native.GetResourceState('pr_3dsound') ~= 'started' or returnSoundId then
            return fallback()
        end

        local payload = {
            audioBank = params.audioBank or qbx.lastAudioBank,
            audioName = audioName,
            audioRef = audioRef,
            range = range,
            timeout = params.timeout,
            occlusion = params.occlusion,
            skipOnOcclusion = params.skipOnOcclusion,
            occlusionMode = params.occlusionMode,
            occludedAudioName = params.occludedAudioName,
            occludedAudioRef = params.occludedAudioRef,
            interval = params.interval or params.delayBetweenSounds,
        }

        local sourceType = type(audioSource)
        local ok, result

        if sourceType == 'vector3' or (sourceType == 'table' and audioSource.x and audioSource.y and audioSource.z) then
            payload.coords = audioSource
            if params.shared == false then
                ok, result = pcall(function()
                    return audio.PlayLocalNativeSoundFromCoords(payload)
                end)
            else
                ok, result = pcall(function()
                    return audio.PlaySharedNativeSoundFromCoords(payload)
                end)
            end
        elseif sourceType == 'number' then
            payload.entity = audioSource
            if params.shared == false then
                ok, result = pcall(function()
                    return audio.PlayLocalNativeSoundFromEntity(payload)
                end)
            else
                ok, result = pcall(function()
                    return audio.PlaySharedNativeSoundFromEntity(payload)
                end)
            end
        else
            ok, result = pcall(function()
                return audio.PlayLocalNativeSound(payload)
            end)
        end

        if ok and result then
            return result
        end

        return fallback()
    end
end

return qbx
end
