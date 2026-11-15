-- Whole installed PR streaming/native_sound and actual57/58, with virtual native/clock/wire only.
local S=dofile('tests/kernel_shutdown_harness.lua');local T=dofile('tests/kernel_helpers_harness.lua');local V=dofile('tests/kernel_legacy_harness.lua')
local H=S.H;local M={S=S,T=T,V=V,H=H}
function M.provider()
    local r={now=0,loaded=true,valid=true,anim=true,exists={},positions={},trace={},raw={},shared={},events={},current=true,nextId=200}
    local function record(kind,...)r.trace[#r.trace+1]={kind=kind,args=T.P.snapshot(table.pack(...))}end
    local n={}
    local function effect(name)return function(...)record(name,...)end end
    for _,name in ipairs({'SetEntityAsMissionEntity','SetEntityAlpha','SetEntityCollision','FreezeEntityPosition','SetEntityInvincible',
        'SetEntityVisible','SetBlockingOfNonTemporaryEvents','SetEntityHeading','SetEntityCoordsNoOffset','SetEntityCoords',
        'PlaySoundFrontend','PlaySoundFromCoord','PlaySoundFromEntity','ReleaseSoundId','ReleaseNamedScriptAudioBank'})do n[name]=effect(name)end
    n.GetGameTimer=function()return r.now end;n.Wait=function(ms)record('wait',ms);r.now=r.now+math.max(1,ms);if r.waitHook then r.waitHook(ms)end end
    n.joaat=function(v)return type(v)=='number'and v or #v+100 end;n.vector3=V.vector
    n.IsModelInCdimage=function()return r.valid end;n.IsModelValid=function()return r.valid end
    n.HasModelLoaded=function()return r.loaded end;n.RequestModel=effect('requestModel');n.SetModelAsNoLongerNeeded=effect('releaseModel')
    n.HasAnimDictLoaded=function()return r.anim end;n.DoesAnimDictExist=function()return r.animValid~=false end
    n.RequestAnimDict=effect('requestAnimDict');n.RemoveAnimDict=effect('releaseAnimDict')
    n.DoesEntityExist=function(id)return r.exists[id]==true end
    n.DeleteEntity=function(id)record('delete',id);r.exists[id]=nil end
    n.IsEntityAPed=function()return false end;n.PlayerPedId=function()return 1 end
    n.GetEntityCoords=function(id)return r.positions[id]or V.vector(0,0,0)end
    local function create(model,x,y,z,...)record('create',model,x,y,z,...);r.nextId=r.nextId+1;r.exists[r.nextId]=true;r.positions[r.nextId]=V.vector(x,y,z);return r.nextId end
    n.CreateObjectNoOffset=create;n.CreateObject=create;n.CreateVehicle=create
    n.CreatePed=function(kind,model,...)return create(model,...)end
    n.NetworkDoesEntityExistWithNetworkId=function(id)return r.exists[id-1000]==true end
    n.NetworkGetEntityFromNetworkId=function(id)return id-1000 end;n.NetworkGetNetworkIdFromEntity=function(id)return id+1000 end
    n.GetResourceState=function()record('state');return r.state or'started'end
    n.GetSoundId=function()r.sound=(r.sound or 50)+1;record('soundId',r.sound);return r.sound end
    n.RequestScriptAudioBank=function(...)record('bank',...);return r.bank~=false end
    n.GetVehiclePedIsIn=function()return 0 end;n.StartShapeTestLosProbe=function()return 1 end
    n.GetShapeTestResult=function()return 1,r.occluded and 1 or 0 end
    n.TriggerServerEvent=function(...)record('server',...);r.shared[#r.shared+1]=table.pack(...)end
    r.native=n
    local streamEnv=T.env(n);streamEnv.Bridge={debug={warn=effect('warn')}}
    r.streaming=H.load('../pr_bridge/bridge/fivem/streaming/client.lua',streamEnv)
    local soundEnv=T.env(n);soundEnv.exports=function(name,fn)r.raw[name]=function(self,...)
        assert(self==r.raw);if r.audioError then error('virtual export error',0)end;return fn(...)
    end end;soundEnv.RegisterNetEvent=function(name,fn)r.events[name]=fn end
    H.load('../../../[standalone]/pr_3dsound/client/native_sound.lua',soundEnv)
    r.ports={nativeSound=r.raw,streaming=r.streaming,nativeAudio=n,isCurrent=function()return r.current end,running=coroutine.running}
    r.factory=H.load('../pr_bridge/bridge/delivery/forge_client_media.lua',H.environment())
    function r.mount()r.api=r.factory(r.ports);return r.api end
    return r
end
function M.helper(ported,provider)
    local h=T.new(ported,'client');h.states.pr_3dsound=provider.state or'started'
    for _,name in ipairs({'PlayLocalNativeSound','PlayLocalNativeSoundFromEntity','PlayLocalNativeSoundFromCoords','PlaySharedNativeSoundFromEntity','PlaySharedNativeSoundFromCoords'})do
        h.audio[name]=function(...)if ported then return provider.api.Audio[name](...)end;return provider.raw[name](provider.raw,...)end
        if not ported then h.env.exports.pr_3dsound[name]=function(_,...)return h.audio[name](...)end end
    end
    return h
end
function M.context()
    -- Retain established transport/input/bus fixture, but defer its worker construction until69 injects ports.
    local old=S.W.new;local workerPorts
    S.W.new=function()local r=old();workerPorts=r.ports;r.prepare=function()r.api={Graph={Central={Parts={Helpers={Lib={getEntityAndNetIdFromBagName=function()end}}}}}}end;return r end
    local ok,r=pcall(S.new);S.W.new=old;assert(ok,r)
    r.media=M.provider();local object=r.fixture.fixtures.Objects
    r.media.exists,r.media.positions=object.entities,object.positions
    local env=S.W.D.A.E.env();env.type=r.fixture.modules.Stores.environment().type
    local requireModule=env.require;r.captures={}
    env.require=function(name)local ctor=requireModule(name)
        if name=='kernel.helpers'or name=='kernel.client.character_renderer'then return function(p)r.captures[name]=p;return ctor(p)end end;return ctor
    end
    env.print=function()end
    r.mediaPorts={worker=workerPorts,shutdown=r.ports,media=r.media.ports,createMedia=r.media.factory}
    r.mediaFactory=H.load('kernel/client/media_context.lua',env)
    function r.prepareMedia()r.api=r.mediaFactory(r.fixture.state,r.mediaPorts);r.graph=r.api.Graph;r.worker=r.api.Worker
        r.keys.ports.resolveEntity=r.graph.Central.Parts.Helpers.Lib.getEntityAndNetIdFromBagName;return r.api end
    function r.installMedia()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return M
