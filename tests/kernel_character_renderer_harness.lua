-- Installed renderer reference and port in strict environments; no real Cfx/UI/media.
local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local R = {P = P, H = H}
local meta = {}
function R.vector(x,y,z)
    return setmetatable({x=x,y=y,z=z},meta)
end
meta.__add = function(a,b) return R.vector(a.x+b.x,a.y+b.y,a.z+b.z) end
meta.__sub = function(a,b) return R.vector(a.x-b.x,a.y-b.y,a.z-b.z) end
meta.__mul = function(a,b) return R.vector(a.x*b,a.y*b,a.z*b) end
local names = {'configuredPreviewLocations','clearConfiguredPreviews','previewCameraTargetPosition',
    'previewCameraPosition','configuredOverview','transitionPreviewCamera','showConfiguredOverview',
    'setupPreviewCam','destroyPreviewCam','randomPed','previewPed','playSlotPreviewAnimation',
    'createSlotPreviewPed','buildConfiguredPreviews','focusConfiguredPreview'}
R.names = names
function R.new(ported, configure)
    local r = {trace={},threads={},entities={},cameras={},skins={},now=0,nextPed=100,nextCam=500,
        randomIndex=0,randomValues={1},cache={ped=10,playerId=1},appearanceResult=true}
    r.entities[10]={coords=R.vector(0,0,0),heading=0}
    r.config={loadingModelsTimeout=1234,characters={previewCameraDistance=3.2}}
    r.fallback={pedCoords={x=8,y=9,z=10,w=45},camCoords={x=11,y=12,z=13,w=90}}
    r.record=function(kind,...) r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))} end
    local n = {vector3=R.vector}
    n.joaat=function(model)
        if model=='mp_m_freemode_01' then return 1885233650 end
        if model=='mp_f_freemode_01' then return 2627665880 end
        if type(model)=='number' then return model end
        local value=0; for i=1,#model do value=(value*31+model:byte(i))%4294967296 end
        return value
    end
    n.GetGameTimer=function() r.record('GetGameTimer'); return r.now end
    n.PlayerPedId=function() r.record('PlayerPedId'); return r.cache.ped end
    n.DoesEntityExist=function(ped) r.record('DoesEntityExist',ped); return r.entities[ped]~=nil end
    n.DoesCamExist=function(cam) r.record('DoesCamExist',cam); return r.cameras[cam]~=nil end
    n.GetCamCoord=function(cam) r.record('GetCamCoord',cam); return r.cameras[cam].coords end
    n.GetPedBoneCoords=function(ped,bone,x,y,z)
        r.record('GetPedBoneCoords',ped,bone,x,y,z)
        local pos=r.entities[ped].coords
        return R.vector(pos.x+0.2,pos.y-0.1,pos.z+1.7)
    end
    n.CreatePed=function(...)
        r.record('CreatePed',...)
        if r.failPed then return r.failPedValue end
        local _,model,x,y,z,heading=...
        r.nextPed=r.nextPed+1
        r.entities[r.nextPed]={model=model,coords=R.vector(x,y,z),heading=heading}
        return r.nextPed
    end
    n.CreateCamWithParams=function(...)
        r.record('CreateCamWithParams',...)
        local _,x,y,z=...
        r.nextCam=r.nextCam+1
        r.cameras[r.nextCam]={coords=R.vector(x,y,z)}
        return r.nextCam
    end
    n.CreateThread=function(fn)
        r.record('CreateThread')
        r.threads[#r.threads+1]=coroutine.create(fn)
    end
    n.Wait=function(ms)
        r.record('Wait',ms); r.now=r.now+(ms==0 and 100 or ms)
        if coroutine.isyieldable() then return coroutine.yield(ms) end
    end
    n.SetPlayerModel=function(player,model)
        r.record('SetPlayerModel',player,model)
        if r.swapPed then
            r.cache.ped=r.swapPed
            r.entities[r.swapPed]={coords=R.vector(0,0,0),model=model}
        end
    end
    n.SetEntityCoords=function(ped,x,y,z,...)
        r.record('SetEntityCoords',ped,x,y,z,...)
        if r.entities[ped] then r.entities[ped].coords=R.vector(x,y,z) end
    end
    n.SetEntityHeading=function(ped,heading)
        r.record('SetEntityHeading',ped,heading)
        if r.entities[ped] then r.entities[ped].heading=heading end
    end
    n.SetCamCoord=function(cam,x,y,z)
        r.record('SetCamCoord',cam,x,y,z)
        r.cameras[cam].coords=R.vector(x,y,z)
    end
    n.DeleteEntity=function(ped) r.record('DeleteEntity',ped); r.entities[ped]=nil end
    n.DestroyCam=function(cam,flag) r.record('DestroyCam',cam,flag); r.cameras[cam]=nil end
    for _,name in ipairs({'ClearPedTasksImmediately','DisplayRadar','DoScreenFadeIn','FreezeEntityPosition',
        'PointCamAtCoord','RenderScriptCams','SetBlockingOfNonTemporaryEvents','SetCamActive','SetCamDofStrength',
        'SetCamFarDof','SetCamNearDof','SetCamUseShallowDofMode','SetEntityAsMissionEntity','SetEntityCollision',
        'SetEntityInvincible','SetEntityVisible','SetModelAsNoLongerNeeded','SetTimecycleModifier',
        'SetTimecycleModifierStrength','SetUseHiDof','TaskPlayAnim','TaskStartScenarioInPlace'}) do
        n[name]=function(...) r.record(name,...) end
    end
    local streaming={}
    for _,name in ipairs({'requestModel','requestAnimDict'}) do
        streaming[name]=function(...)
            r.record(name,...)
            if r.streamingError then error('streaming failed',0) end
            if r.streamingYield then coroutine.yield('streaming pending') end
            return r.streamingResult
        end
    end
    local function appearance(ped,data)
        r.record('setPedAppearance',ped,data)
        if r.appearanceError then error('appearance failed',0) end
        return r.appearanceResult
    end
    local function decode(value)
        r.record('decode',value)
        if value=='bad' then error('invalid JSON',0) end
        return H.copy(r.decoded and r.decoded[value])
    end
    local function preview(id)
        r.record('getPreviewPedData',id)
        if r.previewError then error('callback failed',0) end
        if r.previewYield then coroutine.yield('preview pending') end
        return table.unpack(r.skins[id] or {},1,2)
    end
    local random=function(low,high)
        r.record('random',low,high)
        r.randomIndex=r.randomIndex+1
        return r.randomValues[(r.randomIndex-1)%#r.randomValues+1]
    end
    r.bridgeCache={refreshContext=function(reason) r.record('refreshContext',reason) end}
    r.native=n
    r.bindings={native=n,cache=r.cache,config=r.config,bridgeCache=r.bridgeCache,streaming=streaming,
        json={decode=decode},random=random,fallbackLocation=function() return r.fallback end,
        getPreviewPedData=preview,setPedAppearance=appearance}
    if configure then configure(r) end
    local env=H.environment()
    if ported then
        r.factory=H.load('kernel/client/character_renderer.lua',env)
        r.api=r.factory(r.bindings)
    else
        env.config=r.config; env.cache=r.cache; env.randomLocation=r.fallback
        env.QBX={BridgeCache=r.bridgeCache}; env.json=r.bindings.json
        env.lib={requestModel=streaming.requestModel,requestAnimDict=streaming.requestAnimDict,
            callback={await=function(name,delay,id)
                assert(name=='qbx_core:server:getPreviewPedData' and delay==false)
                return preview(id)
            end}}
        env.exports={['illenium-appearance']={setPedAppearance=function(_,...) return appearance(...) end}}
        env.math.random=random
        for key,fn in pairs(n) do env[key]=fn end
        -- Extract complete function bodies/presets, omitting unrelated startup/menu/spawn code.
        local text=P.source('client/character.lua')
        local function section(first,last)
            local a=assert(text:find(first,1,true))
            local b=assert(text:find(last,a,true))
            return text:sub(a,b-1)
        end
        local text54=section('local function configuredPreviewLocations(', 'local previewCam')
            .. 'local previewCam; local previewCameraRevision=0; local previewCameraTarget; '
            .. 'local previewPeds={}; local previewLocations={}; local configuredPreviewActive=false\n'
            ..section('local randomPeds =','NetworkStartSoloTutorialSession()')
            ..section('local function clearConfiguredPreviews()', '---@param slotSettings table?')
        text54=text54:gsub('`([^`]+)`',function(name) return 'joaat('..string.format('%q',name)..')' end)
        local entries={}; for _,name in ipairs(names) do entries[#entries+1]=name..'='..name end
        text54=text54..'\nreturn {'..table.concat(entries,',')
            ..',IsConfigured=function() return configuredPreviewActive end}'
        r.api=P.loadOrigin('client/character.lua',env,text54)
    end
    assert(#r.trace==0 and #r.threads==0,'Renderer construction must not affect the runtime')
    r.env=env
    function r.step(id)
        assert(coroutine.status(r.threads[id])~='dead','Thread already ended')
        local ok,value=coroutine.resume(r.threads[id]); assert(ok,value); return value
    end
    function r.run(id,max)
        for _=1,max or 30 do
            if coroutine.status(r.threads[id])=='dead' then return end
            r.step(id)
        end
        assert(coroutine.status(r.threads[id])=='dead','Bounded simulated thread did not end')
    end
    return r
end
function R.compare(label,action,configure)
    local a,b=R.new(false,configure),R.new(true,configure)
    local aa,bb=table.pack(pcall(action,a)),table.pack(pcall(action,b))
    if aa[1]==false and bb[1]==false then
        -- Stack locations differ; keep the actual error message and all prior effects.
        aa[2]=tostring(aa[2]):gsub('^.-:%d+: ','')
        bb[2]=tostring(bb[2]):gsub('^.-:%d+: ','')
    end
    H.same(P.snapshot(bb),P.snapshot(aa),label..' returns')
    H.same(b.trace,a.trace,label..' effects')
    H.same(P.snapshot(b.entities),P.snapshot(a.entities),label..' entities')
    H.same(P.snapshot(b.cameras),P.snapshot(a.cameras),label..' cameras')
    H.same(b.cache,a.cache,label..' cache')
    assert(#a.threads==#b.threads,label..' threads')
    for i=1,#a.threads do assert(coroutine.status(a.threads[i])==coroutine.status(b.threads[i]),label..' scheduler') end
    return b,bb
end
return R
