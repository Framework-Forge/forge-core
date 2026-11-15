-- Actual installed native sound/chat bodies and graph67; no sound, network, NUI or resource effects.
local R=dofile('tests/kernel_support_context_harness.lua')
local T=dofile('tests/kernel_helpers_harness.lua');local V=dofile('tests/kernel_legacy_harness.lua')
local H=R.H;local M={R=R,H=H,T=T,V=V}
function M.provider()
    local r={states={pr_3dsound='started'},calls={},events={},raw={},handlers={},nui={},threads={},current=true,
        players={'1','2','3'},positions={[10]=V.vector(0,0,0),[20]=V.vector(10,0,0),[30]=V.vector(100,0,0)},exists={[99]=true}}
    local function send(name,target,payload)
        r.events[#r.events+1]={name=name,target=target,payload=T.P.snapshot(payload)}
        if r.onSend then r.onSend(name,target,payload)end
        if name=='chat:addMessage'then assert(r.handlers[name])(payload)end
        return table.unpack(r.sendResult or{},1,(r.sendResult or{}).n or 0)
    end
    local env=T.env({vector3=V.vector,GetGameTimer=function()return 1000 end,
        GetPlayers=function()return r.players end,GetPlayerPed=function(src)return tonumber(src)*10 end,
        GetEntityCoords=function(entity)return r.positions[entity]or V.vector(0,0,0)end,
        DoesEntityExist=function(entity)return r.exists[entity]==true end,
        NetworkGetNetworkIdFromEntity=function(entity)return entity+1000 end,
        NetworkGetEntityFromNetworkId=function(net)return net-1000 end,
        TriggerClientEvent=send,RegisterNetEvent=function()end,exports=function(name,fn)
            r.raw[name]=function(self,...)assert(self==r.raw,'Cfx receiver preserved');r.calls[#r.calls+1]={name=name,args=T.P.snapshot(table.pack(...))}
                if r.onExport then r.onExport(name,...)end
                if r.fail then error('virtual audio export error',0)end
                if r.override then return table.unpack(r.override,1,r.override.n)end
                return fn(...)
            end
        end})
    H.load('../../../[standalone]/pr_3dsound/server/native_sound.lua',env)
    local chatEnv=H.environment({RegisterNetEvent=function(name,fn)if fn then r.handlers[name]=fn end end,
        AddEventHandler=function(name,fn)r.handlers[name]=fn end,RegisterNUICallback=function()end,
        CreateThread=function(fn)r.threads[#r.threads+1]=fn end,SendNUIMessage=function(payload)r.nui[#r.nui+1]=payload end,
        pr_lib={addKeybind=function()return{}end,addExports=function()end}})
    H.load('../forge-chat/cl_chat.lua',chatEnv)
    r.ports={nativeSound=r.raw,resourceState=function(name)r.statesRead=(r.statesRead or 0)+1;return r.states[name]or'stopped'end,
        sendClient=send,isCurrent=function()return r.current end}
    r.factory=H.load('../pr_bridge/bridge/delivery/forge_media.lua',H.environment())
    function r.mount()r.api=r.factory(r.ports);return r.api end
    return r
end
function M.helper(ported,provider)
    local h=T.new(ported,'server');h.states.pr_3dsound=provider.states.pr_3dsound
    for _,name in ipairs({'PlayNativeSound','PlayNativeSoundFromEntity','PlayNativeSoundFromCoords'})do
        h.audio[name]=function(...)
            h.record('audio-'..name,...)
            if ported then return provider.api.Audio[name](...)end
            return provider.raw[name](provider.raw,...)
        end
        if not ported then h.env.exports.pr_3dsound[name]=function(_,...)return h.audio[name](...)end end
    end
    return h
end
function M.context()
    local r=R.context();r.media=M.provider();r.mediaCaptures={}
    r.mediaPorts={supportContext=r.supportPorts,createMedia=r.media.factory,media=r.media.ports}
    local env=R.C.V.B.O.P.T.T.W.D.R.env();local requireModule=env.require
    env.require=function(name)local ctor=requireModule(name)
        if name=='kernel.helpers'or name=='kernel.server.commands'then return function(p)r.mediaCaptures[name]=p;return ctor(p)end end
        return ctor
    end
    env.print=function(...)r.fixture.central.record('print',...)end
    r.mediaFactory=H.load('kernel/server/media_context.lua',env)
    function r.prepareMedia()r.api=r.mediaFactory(r.fixture.base,r.mediaPorts);r.graph=r.api.Graph;return r.api end
    function r.mediaInstall()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    function r.startMedia()assert(r.mediaInstall());r.emit('onResourceStart','forge-core');r.begin();r.resume();assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[2]))end
    return r
end
return M
