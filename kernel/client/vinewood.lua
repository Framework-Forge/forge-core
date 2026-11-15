-- Whole installed renderer; workers/subscriptions/stop are inert descriptors until the owner binds them.
return function(ports)
    local PR,library,native=assert(ports.config),assert(ports.library),assert(ports.native)
    local world,session=assert(ports.world),assert(ports.session)
    local api={Threads={},Subscriptions={},Events={}}
    local function describeThread(fn)api.Threads[#api.Threads+1]=fn end
    local function subscribe(key,fn)api.Subscriptions[#api.Subscriptions+1]={key=key,handler=fn}end
    local function listen(name,fn)api.Events[#api.Events+1]={name=name,handler=fn,network=false}end
    local DoesEntityExist=assert(native.DoesEntityExist)
    local DeleteEntity=assert(native.DeleteEntity)
    local RemoveReplaceTexture=assert(native.RemoveReplaceTexture)
    local CreateRuntimeTxd=assert(native.CreateRuntimeTxd)
    local CreateRuntimeTexture=assert(native.CreateRuntimeTexture)
    local SetRuntimeTexturePixel=assert(native.SetRuntimeTexturePixel)
    local CommitRuntimeTexture=assert(native.CommitRuntimeTexture)
    local AddReplaceTexture=assert(native.AddReplaceTexture)
    local joaat=assert(native.joaat)
    local RequestModel=assert(native.RequestModel)
    local GetGameTimer=assert(native.GetGameTimer)
    local HasModelLoaded=assert(native.HasModelLoaded)
    local Wait=assert(native.Wait)
    local CreateObject=assert(native.CreateObject)
    local SetEntityHeading=assert(native.SetEntityHeading)
    local FreezeEntityPosition=assert(native.FreezeEntityPosition)
    local SetModelAsNoLongerNeeded=assert(native.SetModelAsNoLongerNeeded)
    local GetCurrentResourceName=assert(native.GetCurrentResourceName)
local spawnedLetters = {}
local lastRevision = nil

local function deleteLetters()
    for i = 1, #spawnedLetters do
        local entity = spawnedLetters[i]
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    spawnedLetters = {}
end

local function hexToRgb(color)
    local ok, r, g, b = pcall(library.math.hexToRGB, color or '#FFFFFF')
    if ok then return r, g, b end
    return 255, 255, 255
end

local function applyTextureColor(color)
    local texture = PR.Vinewood.Texture
    local r, g, b = hexToRgb(color)

    if r == 255 and g == 255 and b == 255 then
        RemoveReplaceTexture(texture.dictionary, texture.name)
        return
    end

    local dict = CreateRuntimeTxd(texture.runtimeTxd)
    local runtimeTexture = CreateRuntimeTexture(dict, texture.runtimeTxn, 4, 4)
    SetRuntimeTexturePixel(runtimeTexture, 0, 0, r, g, b, 255)
    CommitRuntimeTexture(runtimeTexture)
    AddReplaceTexture(texture.dictionary, texture.name, texture.runtimeTxd, texture.runtimeTxn)
end

local function createLetter(modelName, coords, heading)
    local model = joaat(modelName)
    RequestModel(model)

    local started = GetGameTimer()
    while not HasModelLoaded(model) do
        if GetGameTimer() - started > 5000 then return nil end
        Wait(0)
    end

    local entity = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(entity, heading or 0.0)
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(model)

    return entity
end

local function applySettings(settings)
    settings = type(settings) == 'table' and settings or PR.Vinewood.Defaults
    if settings.revision == lastRevision then return end

    lastRevision = settings.revision
    deleteLetters()

    if settings.enabled == false then
        RemoveReplaceTexture(PR.Vinewood.Texture.dictionary, PR.Vinewood.Texture.name)
        return
    end

    applyTextureColor(settings.color)

    local text = tostring(settings.text or ''):lower()
    for index = 1, math.min(#text, #(PR.Vinewood.Coords or {})) do
        local letter = text:sub(index, index)
        local point = PR.Vinewood.Coords[index]

        if letter ~= ' ' and point then
            local entity = createLetter(letter, point.coords, point.heading)
            if entity then
                spawnedLetters[#spawnedLetters + 1] = entity
            end
        end
    end
end

local function currentSettings()
    local settings = world.peek('vinewood')
    if type(settings) ~= 'table' then return PR.Vinewood.Defaults end
    return settings
end

describeThread(function()
    while not session.isLoaded() do
        Wait(1000)
        if GetGameTimer() > 10000 then break end
    end

    applySettings(currentSettings())
end)

subscribe('vinewood', function(value)
    applySettings(value)
end)

listen('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deleteLetters()
    RemoveReplaceTexture(PR.Vinewood.Texture.dictionary, PR.Vinewood.Texture.name)
end)
    return api
end
