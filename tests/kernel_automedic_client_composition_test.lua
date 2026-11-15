-- End-to-end private client/server slice; SQL/IO/natives/scheduler/inventory are simulated.
local R=dofile('tests/kernel_automedic_client_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_automedic_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('wire.playerSource=1\np.api.CheckPlayerData',1,true))
-- Reuse the immutable full server assembly, not a second copy of its implementation.
local server=assert(load(source:sub(1,cut-1)..[[
return {p=p,base=base,core=core,wire=wire,config=configAuto,an=an,inventory=inventory,
    clock=function(v)if v then clock=v end;return clock end,transport=transport}
]],'@server30-assembly','t',_ENV))()
local p,wire=server.p,server.wire
wire.playerSource=1
p.api.CheckPlayerData(1,{citizenid='PATIENT',license='license:patient',userId=101,
    money={cash=400,bank=50},metadata={isdead=true,hunger=5,thirst=8}})
p.api.CheckPlayerData(2,{citizenid='ADMIN',license='license:admin',userId=102})
server.core.Service.start();server.inventory.seed(1)
local player=p.lookup.GetPlayer(1)
local r=R.new(true)
-- Drop the differential fixture descriptors before assembling the canonical graph.
r.events={};r.eventsList={};r.queue={}
local U=dofile('tests/kernel_session_harness.lua')
local fixture=U.new(true,'client')
local state=fixture.core;state.PlayerData=H.copy(player.PlayerData)
for name,fn in pairs(fixture.native)do if r.native[name]==nil then r.native[name]=fn end end
r.native.GetInvokingResource=function()return nil end
r.native.GetPlayerServerId=function()return 1 end
r.native.GetPedArmour=function()return 0 end
local delivery={getResourceState=function()return'started'end,emit=r.native.TriggerEvent,
    writeCache=function(mode,key,value)
        if mode=='set'then r.library.cache.set(key,H.copy(value))
        else local old=r.library.cache.get(key)or{};for k,v in pairs(value)do old[k]=H.copy(v)end;r.library.cache.set(key,old)end
    end}
local producer=H.load('kernel/client/session_core.lua',R.env())(state,{native=r.native,delivery=delivery,statusConfig=fixture.clientConfig})
local events=H.load('kernel/client/events.lua',R.env())({core=state,native=r.native,cache={resource='forge-core'},config={},
    helpers={},library=r.library,globalState={},notify=function()end,locale=function(k)return k end})
local function register(entries)
    for _,entry in ipairs(entries)do
        r.events[entry.name]=r.events[entry.name]or{}
        r.events[entry.name][#r.events[entry.name]+1]={fn=entry.handler}
    end
end
for _,m in ipairs({producer.Cache,producer.Status,producer.Session,events})do register(m.Events)end
-- Actual existing Shared helpers and context implementation; other work-controller methods remain fixtures.
local M=dofile('tests/kernel_admin_menu_harness.lua')
local ui=R.menu(true)
ui.menu.openAutoMedicMenu,ui.menu.openAutoMedicBeds=nil,nil
local context=M.context()
r.library.menus=ui.library.menus
r.library.menus.RegisterContext=context.api.RegisterContext
r.library.menus.ShowContext=context.api.ShowContext
local shared=H.load('kernel/client/menu/shared.lua',R.env())({library=r.library,translate=r.translate,notifyPosition='top-right'})
local client={Menu=ui.menu}
state.AdministrationMenus={State=state,Menu=ui.menu,Shared=shared}
state.WorkMenus={State=state,Client=client,Menu=ui.menu,Shared=shared}
r.library.callback.await=function(name,timeout,...)
    return wire.client.api.request(name,nil,nil,timeout,...)
end
r.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
local config={AutoMedic=server.config,NotifyPos='top-right'}
local ports={client=client,config=config,library=r.library,native=r.native,translate=r.translate}
local core=H.load('kernel/client/automedic/automedic_core.lua',R.env())(state,ports)
assert(core.State==state and core.Producer==producer and core.Menu.Shared==shared and client.Hospital==core.Hospital.Hospital)
assert(not pcall(H.load('kernel/client/automedic/automedic_core.lua',R.env()),state,ports),'duplicate attachment refused')
register(core.Session.Events)
producer.Initialize()
core.Initialize();assert(not core.Initialize())
register(core.Hospital.Events);register(core.Runtime.Events)
-- Preserve original order: Forge Session initial refresh before its hospital/runtime listeners.
local originalClient=p.platform.emitClient
p.platform.emitClient=function(name,target,...)
    originalClient(name,target,...)
    if target==1 or target==-1 then r.fire(name,65535,...)end
end
server.an.emitClient=function(name,target,...)if target==1 or target==-1 then r.fire(name,65535,...)end end
r.send=function(name,...)
    local old=wire.server.source;wire.server.source=1
    p.platform.emitServer(name,...);wire.server.source=old
end
r.config=config
r.native.CreateThread(core.Runtime.Threads[1])
r.advance(2100)
assert(core.Runtime.State.deathReported,'actual initial AutoMedic worker detects persisted death')
-- Same local Status/PlayerData, not library.framework; policy intentionally excludes laststand alone.
state.PlayerData.metadata={inlaststand=true};r.dead=false;r.health=150
assert(not core.Kernel.IsPlayerDead(),'exact PR normalizer policy retained')
state.PlayerData.metadata={isdead=true,hunger=5,thirst=8};r.dead=true;r.health=100
wire.playerSource=1
local ok,err=r.library.callback.await(config.AutoMedic.Callbacks.saveSettings,10000,{})
assert(not ok and err=='no_permission','actual server Security refuses patient settings')
wire.playerSource=2
assert(core.Menu.Menu.openAutoMedicMenu())
assert(context.api.GetOpenContextMenu()=='forge_core_automedic')
context.api.RegisterContext({id='forge_core_main',title='Parent',options={}})
-- Navigate to bed list using actual PR context callback.
context.api.HandleSelect('forge_core_automedic',1)
assert(context.api.GetOpenContextMenu()=='forge_core_automedic_beds')
context.api.HandleBack();assert(context.api.GetOpenContextMenu()=='forge_core_automedic')
context.api.HandleBack();assert(context.api.GetOpenContextMenu()=='forge_core_main')
wire.playerSource=1
-- Exercise server approval -> cash debit -> revive network -> actual local Status handler -> native/cache.
server.clock(server.clock()+20)
local approved,treatment=r.library.callback.await(config.AutoMedic.Callbacks.requestTreatment,10000,'gunshot')
assert(approved)
server.clock(server.clock()+10)
local completed,result=r.library.callback.await(config.AutoMedic.Callbacks.completeTreatment,10000,treatment.token)
assert(completed and result.chargedAmount==100 and player.PlayerData.money.cash==300)
r.advance(10)
assert(r.health==110 and state.Status.health==10,'same local Status refreshed from revived native health')
assert(state.PlayerData.citizenid=='PATIENT'and state.PlayerData.metadata.isdead==false)
assert(next(server.inventory.records[1].items)==nil,'server whole installed OX Clear executes only virtual items')
-- Hospital route uses same Player/prison/beds, then E sends release to the same server reservation.
p.api.SetMetadata(1,'isdead',true);r.dead=true;r.health=100
server.clock(server.clock()+20)
approved,treatment=r.library.callback.await(config.AutoMedic.Callbacks.requestTreatment,10000,'collapse');assert(approved)
completed,result=r.library.callback.await(config.AutoMedic.Callbacks.recoverHospital,10000,treatment.token,'unreachable')
assert(completed);r.advance(10);assert(core.Hospital.Hospital.isRecovering())
assert(core.Hospital.Keybinds[1].onPressed());r.advance(5000)
assert(not core.Hospital.Hospital.isRecovering()and server.core.Service.recoveries[1]==nil)
-- Actual PR adapter -> whole installed OX useItem body. Server consumption acknowledgement is explicitly virtual.
local oxFile=assert(io.open('../../../[ox]/ox_inventory/client.lua','r'));local oxText=oxFile:read('*a'):gsub('\r\n','\n');oxFile:close()
local start=assert(oxText:find('local function useItem(data, cb, noAnim)',1,true))
local finish=assert(oxText:find("\nAddEventHandler('ox_inventory:usedItem'",start,true))
local slot={name='bandage',slot=3,metadata={}}
local oxEnv=setmetatable({PlayerData={inventory={[3]=slot}},canUseItem=function()return true end,
    pr_lib={callback={await=function(name,timeout,...)assert(name=='ox_inventory:useItem'and timeout==10000);return true end},
        Notify=function()error('unexpected inventory rejection')end},Wait=r.native.Wait,
    TriggerEvent=function()end,GetGameTimer=r.native.GetGameTimer,playerPed=11,
    warn=function()error('unexpected OX callback failure')end},{__index=_G})
local useItem=assert(load(oxText:sub(start,finish-1)..'\nreturn useItem','@installed-ox-useItem','t',oxEnv))()
local invEnv=H.environment({ActiveBridges={inventory='ox'},exports={ox_inventory={useItem=function(_,...)return useItem(...)end}}})
r.library.inventory.useItem=H.load('../pr_bridge/bridge/inventories/ox/client.lua',invEnv).useItem
core.Runtime.State.settings.enabled=true
core.Runtime.State.reviveGraceUntil=0
r.health=150;r.dead=false;state.PlayerData.metadata.isdead=false
r.native.CreateThread(function()assert(core.Runtime.Exports.useBandage({name='bandage',slot=3},99))end)
r.advance(600)
assert(r.health==170 and state.Status.health==70,'bandage updates the same canonical local Status')
r.fire('pr_bridge:client:OnPlayerUnloaded',0)
assert(not core.Session.Session.isLoaded()and not core.Hospital.Hospital.isRecovering())
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil)
print('PASS AutoMedic client composition: actual local Player/Status/Session/server Security, PR RPC/context/inventory adapter, installed OX Clear/useItem bodies in memory; money/revive/hospital/release/bandage/unload, no real NUI/SQL/items/money/boot')
