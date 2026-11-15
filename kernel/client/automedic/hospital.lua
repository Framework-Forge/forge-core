-- Private installed AutoMedic port; see NOTICE-31.md. No automatic installation.
return function(ports)
    local PR,library,native=assert(ports.config),assert(ports.library),assert(ports.native)
    local api={Events={},Threads={},Exports={},Keybinds={}}
    local function listen(name,handler,network)api.Events[#api.Events+1]={name=name,handler=handler,network=network==true}end
    local function network(name,handler)listen(name,handler,true)end
    local function thread(handler)api.Threads[#api.Threads+1]=handler end
    local function describeExport(name,handler)api.Exports[name]=handler end
    local translate=assert(ports.translate)
    local print=assert(native.print,'print port required')
    local function describeKeybind(data)api.Keybinds[#api.Keybinds+1]=data end
    local ClearPedTasks=assert(native.ClearPedTasks,'ClearPedTasks port required')
    local CreateThread=assert(native.CreateThread,'CreateThread port required')
    local DoScreenFadeIn=assert(native.DoScreenFadeIn,'DoScreenFadeIn port required')
    local DoScreenFadeOut=assert(native.DoScreenFadeOut,'DoScreenFadeOut port required')
    local FreezeEntityPosition=assert(native.FreezeEntityPosition,'FreezeEntityPosition port required')
    local GetCurrentResourceName=assert(native.GetCurrentResourceName,'GetCurrentResourceName port required')
    local GetGameTimer=assert(native.GetGameTimer,'GetGameTimer port required')
    local HasAnimDictLoaded=assert(native.HasAnimDictLoaded,'HasAnimDictLoaded port required')
    local HasCollisionLoadedAroundEntity=assert(native.HasCollisionLoadedAroundEntity,'HasCollisionLoadedAroundEntity port required')
    local IsPedDeadOrDying=assert(native.IsPedDeadOrDying,'IsPedDeadOrDying port required')
    local IsScreenFadedIn=assert(native.IsScreenFadedIn,'IsScreenFadedIn port required')
    local IsScreenFadedOut=assert(native.IsScreenFadedOut,'IsScreenFadedOut port required')
    local NetworkResurrectLocalPlayer=assert(native.NetworkResurrectLocalPlayer,'NetworkResurrectLocalPlayer port required')
    local PlayerPedId=assert(native.PlayerPedId,'PlayerPedId port required')
    local RequestAnimDict=assert(native.RequestAnimDict,'RequestAnimDict port required')
    local RequestCollisionAtCoord=assert(native.RequestCollisionAtCoord,'RequestCollisionAtCoord port required')
    local SetEntityCoords=assert(native.SetEntityCoords,'SetEntityCoords port required')
    local SetEntityCoordsNoOffset=assert(native.SetEntityCoordsNoOffset,'SetEntityCoordsNoOffset port required')
    local SetEntityHeading=assert(native.SetEntityHeading,'SetEntityHeading port required')
    local SetEntityInvincible=assert(native.SetEntityInvincible,'SetEntityInvincible port required')
    local SetPedCanRagdoll=assert(native.SetPedCanRagdoll,'SetPedCanRagdoll port required')
    local TaskPlayAnim=assert(native.TaskPlayAnim,'TaskPlayAnim port required')
    local TriggerServerEvent=assert(native.TriggerServerEvent,'TriggerServerEvent port required')
    local Wait=assert(native.Wait,'Wait port required')
-- Hospital recovery is event-driven: no bed scanning or idle polling thread.
local Hospital = { current=nil, leaving=false, generation=0 }

local function t(key) return translate('automedic.' .. key) end
local function requestAnimation(dict)
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do Wait(10) end
    return HasAnimDictLoaded(dict)
end
local function current(generation)
    return Hospital.generation == generation and Hospital.current ~= nil
end
function Hospital.isRecovering() return Hospital.current ~= nil end
function Hospital.clear(release)
    local previous = Hospital.current
    Hospital.generation = Hospital.generation + 1
    Hospital.current, Hospital.leaving = nil, false
    if not previous then return end
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetPedCanRagdoll(ped, true)
    ClearPedTasks(ped)
    if library.HideTextUI then library.HideTextUI() end
    if release then TriggerServerEvent(PR.AutoMedic.Events.leaveHospital, previous.token) end
    if not IsScreenFadedIn() then DoScreenFadeIn(300) end
end

function Hospital.recover(payload, applyHealth)
    if type(payload) ~= 'table' or type(payload.bed) ~= 'table' or type(payload.token) ~= 'string' then return false end
    local bed = payload.bed
    if type(bed.coords) ~= 'table' or type(bed.exit) ~= 'table' then return false end
    Hospital.clear(true)
    Hospital.current = payload
    local generation = Hospital.generation
    CreateThread(function()
        local ok, err = xpcall(function()
            DoScreenFadeOut(500)
            local deadline = GetGameTimer() + 1500
            while not IsScreenFadedOut() and GetGameTimer() < deadline do Wait(10) end
            if not current(generation) then return end
            local coords = bed.coords
            RequestCollisionAtCoord(coords.x, coords.y, coords.z)
            local ped = PlayerPedId()
            SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
            FreezeEntityPosition(ped, true)
            deadline = GetGameTimer() + 5000
            while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do Wait(20) end
            if not current(generation) then return end
            NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, bed.heading, true, true, false)
            ped = PlayerPedId()
            applyHealth(ped)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetPedCanRagdoll(ped, false)
            local animation = PR.AutoMedic.Hospital.animation
            if not requestAnimation(animation.dict) then error('hospital_animation_unavailable') end
            if not current(generation) then return end
            -- Animated placement saves support coordinates. Match its initial
            -- SetEntityCoords origin calibration, including the ped model height.
            SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
            SetEntityHeading(ped, bed.heading)
            TaskPlayAnim(ped, animation.dict, animation.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
            DoScreenFadeIn(700)
            if library.ShowTextUI then library.ShowTextUI(t('leave_hint'), {position='bottom-center', icon='hospital'}) end
        end, debug.traceback)
        if not ok and current(generation) then
            print(('[forge-core:automedic] hospital recovery failed: %s'):format(tostring(err)))
            local exit = bed.exit
            SetEntityCoordsNoOffset(PlayerPedId(), exit.x, exit.y, exit.z, false, false, false)
            Hospital.clear(true)
        end
    end)
    return true
end

function Hospital.leave()
    if not Hospital.current or Hospital.leaving then return false end
    Hospital.leaving = true
    local payload, generation = Hospital.current, Hospital.generation
    CreateThread(function()
        local ok, err = xpcall(function()
            local ped, animation = PlayerPedId(), PR.AutoMedic.Hospital.exitAnimation
            if not IsPedDeadOrDying(ped, true) and requestAnimation(animation.dict) and current(generation) then
                FreezeEntityPosition(ped, false)
                SetEntityHeading(ped, (payload.bed.heading + 90) % 360)
                TaskPlayAnim(ped, animation.dict, animation.clip, 8.0, -8.0, animation.duration, 0, 0.0, false, false, false)
                -- This animation sits on the edge before standing; let it finish.
                Wait(animation.duration)
            end
            if not current(generation) then return end
            if not IsPedDeadOrDying(PlayerPedId(), true) then
                local exit = payload.bed.exit
                SetEntityCoordsNoOffset(PlayerPedId(), exit.x, exit.y, exit.z, false, false, false)
                SetEntityHeading(PlayerPedId(), payload.bed.exitHeading)
            end
        end, debug.traceback)
        if not ok then print(('[forge-core:automedic] hospital exit failed: %s'):format(tostring(err))) end
        if current(generation) then Hospital.clear(true) end
    end)
    return true
end

listen('forge-core:session:changed', function() Hospital.clear(true) end)
listen('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then Hospital.clear(true) end
end)
    local initialized=false
    function api.Initialize()
        if initialized then return false end
        initialized=true
if library.addKeybind then
    describeKeybind({name='forge_core_leave_hospital_bed', description=t('leave_keybind'),
        defaultKey=PR.AutoMedic.Hospital.leaveKey, onPressed=Hospital.leave})
end
        return true
    end
    api.Hospital=Hospital
    return api
end
