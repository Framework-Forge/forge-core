-- Actual private server32/client31/session/PR transport and context, with virtual IO/SQL/natives only.
local R=dofile('tests/kernel_access_client_harness.lua')
local A=dofile('tests/kernel_access_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_automedic_client_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('assert(core.State==state',1,true))
-- Reuse immutable canonical assembly before its treatment cases or runtime initialization.
local graph=assert(load(source:sub(1,cut-1)..[[
return {state=state,medical=core,ports=ports,r=r,producer=producer,client=client,shared=shared,
    context=context,server=server,p=p,wire=wire,register=register,config=config}
]],'@canonical-client31-server30','t',_ENV))()
local state,medical,r,wire=graph.state,graph.medical,graph.r,graph.wire
local base,p=graph.server.base,graph.p
local server=A.new(true)
-- The actual canonical Session30 already closes over the original server PR cache.
server.native.source=function()return wire.server.source end
server.native.GetPlayers=function()return{'1','2'}end
server.library.framework=setmetatable({},{__index=function()error('forbidden PR framework cycle')end})
server.library.callback.await=function(target,name,timeout,...)
    -- Single simulated client endpoint; preserve/restore response origin, including yields.
    local oldPlayer,oldSource=wire.playerSource,wire.server.source;wire.playerSource=target
    local result=table.pack(pcall(wire.server.api.request,name,target,nil,timeout,...))
    wire.playerSource,wire.server.source=oldPlayer,oldSource
    assert(result[1],result[2]);return table.unpack(result,2,result.n)
end
local cfg=R.new(true).cfg
server.m.seed(server.config.Whitelist.Storage.configFile,cfg)
local accessServer=H.load('kernel/server/access_core.lua',A.env())(base,{
    config=server.config,library=server.library,native=server.native,json=server.m.codec,
    translate=server.translate,webhookIntegration=server.webhookIntegration})
for _,d in ipairs(accessServer.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
assert(accessServer.Whitelist.Service.start())
local config=graph.config
config.Whitelist,config.Afk=accessServer.Config.Whitelist,accessServer.Config.Afk
-- Complete the actual canonical WorkMenus Shared helpers, not an invented boolLabel/clone.
H.load('kernel/client/menu/central.lua',R.env())({menu=graph.client.Menu,shared=graph.shared,client=graph.client,
    config=config,library=r.library,native=r.native,translate=r.translate,integrations={}})
for _,n in ipairs({"AddBlipForCoord","AddTextComponentString","BeginTextCommandSetBlipName","ClearDrawOrigin","CreateThread","DoScreenFadeIn","DoScreenFadeOut","DoesBlipExist","DrawMarker","DrawText","EndTextCommandSetBlipName","GetEntityCoords","GetGameTimer","IsControlJustPressed","PlayerPedId","RemoveBlip","SetBlipAsShortRange","SetBlipColour","SetBlipScale","SetBlipSprite","SetDrawOrigin","SetEntityCoords","SetEntityHeading","SetTextCentre","SetTextEntry","SetTextFont","SetTextScale","SetTimeout","Wait","FreezeEntityPosition","GetEntityHeading","IsControlJustReleased","IsDisabledControlJustReleased","RequestCollisionAtCoord"})do
    if not r.native[n]then r.native[n]=function(...)r.record(n,...)end end
end
r.native.vec3=R.vector
r.native.AddBlipForCoord=function(...)r.record('exam-blip',...);r.blips[66]=true;return 66 end
r.native.IsControlJustReleased=function()return false end
r.native.IsDisabledControlJustReleased=function()return false end
r.library.target={addBoxZone=function(data)r.target=data;r.record('target-add',data);return 77 end,
    removeZone=function(id)r.record('target-remove',id);r.target=nil end}
local uiInputs,uiAlerts={},{}
r.library.menus.InputDialog=function(...)r.record('input',...);return table.remove(uiInputs,1)end
r.library.menus.AlertDialog=function(...)r.record('alert',...);return table.remove(uiAlerts,1)end
local integration={resourceState=function(name)assert(name=='spacebox_multichar');return'stopped'end,
    isInCharacterCreation=function()error('stopped provider cannot be called')end}
local ports={client=graph.client,config=config,library=r.library,native=r.native,translate=r.translate,
    characterIntegration=integration}
local oldTrace,oldQueue=#r.trace,#r.queue
local access=H.load('kernel/client/access_core.lua',R.env())(state,ports)
assert(#r.trace==oldTrace and #r.queue==oldQueue,'no constructor UI/worker/RPC')
assert(access.Session==medical.Session and access.Runtime.State==access.Whitelist
    and access.Menu==state.WorkMenus.Menu and access.Shared==state.AdministrationMenus.Shared)
assert(access.Session.Session~=graph.producer.Session,'Forge view is not producer readiness')
assert(not pcall(H.load('kernel/client/access_core.lua',R.env()),state,ports),'duplicate attachment refused')
for name,fn in pairs(access.Callbacks)do wire.client.api.register(name,fn)end
graph.register(medical.Session.Events);graph.producer.Initialize();medical.Initialize()
-- Producer Initialize publishes the existing not-yet-world-ready flag. Deliver the actual load transition.
for _,d in ipairs(graph.producer.Session.Events)do
    if d.name=='QBCore:Client:OnPlayerLoaded'then d.handler()end
end
medical.Session.Session.refresh()
graph.register(access.Events)
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
local c=config.Whitelist.Callbacks
wire.playerSource=1
local ok,err=rpc(c.add);assert(not ok and err=='no_permission','ordinary exam cannot bypass server admin guard')
-- Player check is allowed and maps the canonical bucket, then actual local exam starts.
r.native.CreateThread(function()R.find(access.Events[#access.Events].handler,'checkWhitelist')()end)
r.advance(3200)
assert(access.Whitelist.active and p.core.Player_Buckets[1]==1001 and r.target,'client exam uses actual server check/target')
assert(access.Session.Session.isLoaded(),'actual Forge Session31 loaded')
local pos=r.native.GetEntityCoords(r.ped);assert(pos.x==cfg.spawnCoords.x)
-- Full exam to actual submitPreExam then denied add: no self-grant and active area retained.
uiInputs={{'1'}};uiAlerts={'confirm','confirm'}
r.native.CreateThread(r.target.options[1].onSelect);r.advance(50)
assert(access.Whitelist.active and not access.Whitelist.examRunning and server.records.PATIENT==nil)
assert(server.answers.PATIENT,'exam result reaches real private service over installed PR transport')
-- Parent-child navigation uses installed PR context; administrative config edits remain server-guarded.
wire.playerSource=2
assert(access.Menu.openWhitelistMenu())
local context=graph.context.api
context.RegisterContext({id='forge_core_server_settings',title='Parent pending',options={}})
context.HandleSelect('forge_core_whitelist',2)
assert(context.GetOpenContextMenu()=='forge_core_whitelist_questions')
context.HandleSelect('forge_core_whitelist_questions',2)
assert(context.GetOpenContextMenu()=='forge_core_whitelist_question_1')
context.HandleBack();context.HandleBack();context.HandleBack()
assert(context.GetOpenContextMenu()=='forge_core_server_settings','actual PR parent navigation retained')
-- Server add -> actual client callback -> completion teleport; scheduler and buckets remain virtual.
r.native.CreateThread(function()assert(rpc(c.add,1))end);r.advance(650)
assert(server.records.PATIENT and not access.Whitelist.active and p.core.Player_Buckets[1]==0)
assert(r.native.GetEntityCoords(r.ped).x==cfg.completionCoords.x)
-- Server remove re-enters the exam area through the actual client callback and canonical Functions.
wire.playerSource=2
r.native.CreateThread(function()assert(rpc(c.remove,1))end);r.advance(650)
assert(access.Whitelist.active and server.records.PATIENT==nil and p.core.Player_Buckets[1]==1001)
-- AFK editor uses the same controller/Shared/RPC and server32 persistence, no duplicate parent.
uiInputs={{'true',25}};wire.playerSource=2
access.Menu.openAfkSettingsEditor({})
local saved=server.m.codec.decode(server.m.files[config.Afk.Storage.file])
assert(saved.enabled and saved.minutes==25,'AFK editor persists only virtual JSON via actual service')
-- Session replacement clears the client exam target/blip and starts a new check generation.
r.fire('pr_bridge:client:OnPlayerUnloaded',nil)
assert(not access.Whitelist.active and not access.Whitelist.checking and not r.target)
assert(not access.Session.Session.isLoaded())
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending RPC')
assert(state.PlayerData.citizenid=='PATIENT','no second PlayerData or implicit logout mutation')
print('PASS access client composition: canonical Producer/Session31/Menu/Shared and server32 Player/Functions/Security, actual PR transport/context/JSON/DB adapter in memory; check/exam/admin refusal/add/remove/teleport/AFK and unload; provider binder/parent server menu and real startup pending')
