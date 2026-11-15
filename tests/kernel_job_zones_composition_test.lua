local T=dofile('tests/kernel_transport_harness.lua')
local S=dofile('tests/kernel_job_service_harness.lua')
local F=dofile('tests/kernel_finance_harness.lua')
local L=dofile('tests/kernel_lifecycle_harness.lua')
local H,P,J,B=T.H,T.P,T.J,T.B
local p=P.new(true)
p.core.Player_Buckets,p.core.Entity_Buckets,p.core.UsableItems={},{},{}
local groups=H.load('kernel/server/groups.lua',H.environment())({jobs=p.groupData.jobs,gangs=p.groupData.gangs,
    emitServer=p.platform.emitServer,emitClient=p.platform.emitClient,saveGroups=function()error('No legacy writes')end,logError=function()end})
local admin=true
local l=L.new(true);l.bindings.core,l.bindings.lookup,l.bindings.players,l.bindings.groups=p.core,p.lookup,p.api,groups
l.bindings.native.isAceAllowed=function(src)return admin and tonumber(src)==2 end
local functions=H.load('kernel/server/functions.lua',H.environment())(l.bindings)
local base={Groups=groups,PlayerCore={Groups=groups,State=p.core,Lookup=p.lookup,Players=p.api,Lifecycle={Functions=functions}}}
local m=J.persistence();local library={};for k,v in pairs(m.api)do library[k]=v end
library.utils=H.load('../pr_bridge/bridge/utils/shared.lua',H.environment())
library.table=H.load('../pr_bridge/bridge/utils/tables.lua',H.environment())
library.math=H.load('../pr_bridge/bridge/utils/numbers.lua',B.environment())
local helpers=T.helpers();library.load=function(path)assert(path=='@pr_bridge/bridge/frameworks/compat_helpers');return helpers end
local bank={police=10000,government=0};local items={money=1000,burger=20,key=1};local hooks=0
library.banking={EnsureJobAccount=function(name)bank[name]=bank[name]or 0;return true end,
    JobAccountExists=function(name)return bank[name]~=nil end,GetJobAccountBalance=function(name)return bank[name]end,
    AddJobAccountBalance=function(name,amount)bank[name]=(bank[name]or 0)+amount;return true end,
    RemoveJobAccountBalance=function(name,amount)if(bank[name]or 0)<amount then return false end;bank[name]=bank[name]-amount;return true end,
    RecordJobTransaction=function()return true end}
library.inventory={RegisterHook=function(event)hooks=hooks+1;return'forge-core:'..event..':'..hooks end,
    RegisterStash=function()end,RegisterShop=function()return true end,forceOpenInventory=function()return true end,
    HasItem=function(_,name,amount)return(items[name]or 0)>=amount end,GetItemCount=function(_,name)return items[name]or 0 end,
    GetItemLabel=function(name)return name end,Items=function()return {burger={},key={}}end,
    GetInventoryItems=function()return {{name='burger',count=items.burger}}end,
    AddItem=function(_,name,count)items[name]=(items[name]or 0)+count;return true end,
    RemoveItem=function(_,name,count)if(items[name]or 0)<count then return false end;items[name]=items[name]-count;return true end}
library.notify={NotifyPlayer=function()end};library.database={query=function()return {}end,transaction=function()return true end}
library.phone={GetPhoneNumberFromIdentifier=function()return'555'end}
library.command=function()error('Must not install commands during assembly')end

local C=dofile('tests/kernel_client_jobs_harness.lua')
local U=dofile('tests/kernel_session_harness.lua')
local V=dofile('tests/kernel_legacy_harness.lua')
local wire=C.wire()
local clock,ping=1000,50
local workers,timers,flow,diagnostics,listeners={},{},{},{},{}
local clientCore
local config=J.config(true).config
library.callback={register=wire.server.api.register,await=function(src,name,timeout,...)
    flow[#flow+1]='request-menu'
    return wire.server.api.request(name,src,nil,timeout,...)
end}
local native={getPlayers=function()return {'1'}end,
    isAceAllowed=function(src)return admin and tonumber(src)==2 end,
    isPlayerAceAllowed=function(src)return admin and tonumber(src)==2 end,
    getInvokingResource=function()return'pr_bridge'end,isPrincipalAceAllowed=function()return false end,
    emitClient=function(name,target,...)
        p.platform.emitClient(name,target,...)
        if name==config.Events.sync and clientCore and(target==-1 or target==wire.playerSource)then
            flow[#flow+1]='sync'
            local args=H.copy(table.pack(...))
            for _,event in ipairs(clientCore.Replica.Events)do
                if event.name==name then event.handler(table.unpack(args,1,args.n))end
            end
        end
    end,
    getSource=function()return wire.server.source end,getGameTimer=function()return clock end,
    getPlayerPing=function()return ping end,getPlayerName=function()return'Test'end,
    getIdentifier=function()return'license:test'end,getPed=function(src)return src end,
    getCoords=function()return B.vector(1,2,3)end,
    spawn=function(fn)workers[#workers+1]=fn end,wait=function()error('No server worker execution')end,
    setTimeout=function(ms,fn)timers[#timers+1]={ms=ms,fn=fn}end,
    execute=function()error('No real ACE mutation')end,print=function(message)diagnostics[#diagnostics+1]=message end,emit=function()end,
    listen=function(name,fn)listeners[#listeners+1]={name=name,handler=fn};return #listeners end}
local Z=dofile('tests/kernel_job_zones_harness.lua')
local group=Z.payload().jobs[1];group.stashes[1].stash.webhook='';group.grades['4'].payment=100
m.seed(config.Storage.jobsFile,{police=group});m.seed(config.Storage.gangsFile,{})
local catalog=J.composition(base,{config=config,library=library,translate=function(key)return key end})
local service=S.compose(base,{library=library,translate=function(key)return key end,dependencies={},native=native,time=function()return clock end})
local integrations={inventoryReady=function()return true end,removeInventoryHooks=function()end,
    httpRequest=function()error('No real HTTP')end,applyPlayerInventoryBonus=function()return true end}
local finance=F.compose(base,{library=library,translate=function(key)return key end,native=native,
    integrations=integrations,time=function()return clock end,resource='forge-core'})
local business=B.compose(base,{library=library,json=m.codec,translate=function(key)return key end,native=native,
    integrations=integrations,time=function()return clock end})
-- Compatibility item routes are deliberately unused in this client jobs slice.
catalog.Dependencies.InventoryService={addCompatibilityItems=function()error('Unused inventory route')end,reload=function()error('Unused inventory route')end}
local transport=T.compose(base,{library=library,native=native,json=m.codec,config={AdminAce='forge-core.admin'},
    translate=function(key)return key end,time=function()return clock end})
for _,entry in ipairs(transport.Callbacks)do transport.Security.register(entry.name,entry.handler,entry.options)end
local function env()
    local e=H.environment()
    e.require=function(name)assert(name:match('^kernel%.'));return H.load(name:gsub('%.','/')..'.lua',e)end
    return e
end
local sr=U.new(true,'client')
local producer=H.load('kernel/client/session_core.lua',env())(sr.core,{native=sr.native,delivery=sr.delivery,statusConfig=sr.clientConfig})
local lf=V.new(true,'client');local queries=V.client(true)
local lb={};for key,value in pairs(lf.bindings)do lb[key]=value end
lb.membership,lb.notify=queries.membership,queries.bindings.notify
lb.jobs,lb.gangs=groups.GetJobs(),groups.GetGangs()
local pulls=0
lb.awaitGroups=function()pulls=pulls+1;return{jobs=groups.GetJobs(),gangs=groups.GetGangs()}end
local legacy=H.load('kernel/client/legacy_core.lua',env())(sr.core,lb)
local dataBefore=sr.core.PlayerData

local ui=Z.new(true,'points')
local holder={}
local context=dofile('tests/kernel_admin_menu_harness.lua').context()
ui.library.menus.RegisterContext=context.api.RegisterContext
ui.library.menus.ShowContext=context.api.ShowContext
ui.library.debug={info=function()end,setEnabled=function()end}
ui.library.callback.await=function(name,timeout,...)
    return wire.client.api.request(name,nil,nil,timeout,...)
end
-- Installed inventory adapter, no real OX resource. Only the final provider is doubled.
local inventoryOpens={}
ui.library.inventory=H.load('../pr_bridge/bridge/inventories/ox/client.lua',H.environment({
    ActiveBridges={inventory='ox'},exports={ox_inventory={openInventory=function(_,kind,data)
        inventoryOpens[#inventoryOpens+1]={kind=kind,data=data}
    end}}}))
local minigameCalls={}
local minigame=H.load('../pr_bridge/bridge/minigames/glitch/client.lua',H.environment({
    GetResourceState=function(name)return name=='glitch-minigames'and'started'or'stopped'end,
    exports={['glitch-minigames']={StartLockpickGame=function(_,...)minigameCalls[#minigameCalls+1]=table.pack(...);return true end}}
}))
local gamePorts={lockpickState=function()return'started'end,startLockpick=function(a,b,c,d,e)
    return minigame.Start({game='Lockpick',dificultMinigame={vehiCarjack={
        rounds=a,sweetSpotSize=b,maxFailures=c,shakeRange=d,lockTime=e}}})
end}
local jobPorts={client=holder,config=config,library=ui.library,translate=ui.translate,
    wait=function(ms)return coroutine.yield(ms)end,debugEnabled=false}
clientCore=C.compose(sr.core,jobPorts)
local counts={trace=#ui.trace,files=#m.trace,wire=#wire.trace,timers=#ui.timers}
local zones=Z.compose(sr.core,{client=holder,config=config,library=ui.library,translate=ui.translate,
    native=ui.native,integrations=gamePorts})
assert(zones.State==sr.core and holder.JobPoints==zones.Points and holder.JobBusiness==zones.Business)
assert(zones.PlayerAccess.GetPlayerData==legacy.Functions.GetPlayerData)
assert(#ui.trace==counts.trace and #m.trace==counts.files and #wire.trace==counts.wire and #ui.timers==counts.timers)
assert(not pcall(Z.compose,sr.core,{}),'duplicate attachment refused')
local foreign={ProducerCore=producer,LegacyCore=legacy,JobClientCore=clientCore}
assert(not pcall(Z.compose,foreign,{}),'foreign canonical state refused')
ui.api=zones.Points -- target helpers use ui.zones, no substitute for the actual Points/Business bodies
local function dispatch(name,...)
    for _,event in ipairs(zones.Events)do if event.name==name then event.handler(...)end end
end
for _,module in ipairs({producer.Session,producer.Cache})do sr.install(module)end
sr.core.PlayerData=H.copy(ui.data)
local co=coroutine.create(clientCore.Bootstrap.Threads[1])
assert(select(2,coroutine.resume(co))==1500);assert(coroutine.resume(co))
assert(#zones.Points.zones==2 and #zones.Business.zones==5,'actual replica reaches actual zone consumers')
assert(zones.PlayerAccess.GetPlayerData()==sr.core.PlayerData and sr.bridge=='stopped','no passive PR-cache query required')
p.api.CheckPlayerData(1,{citizenid='ZONE',license='license:test',userId=101,charinfo={firstname='Zone',lastname='Test'}})
assert(p.api.SetJob(1,'police',4))
local online=p.lookup.GetPlayer(1)
sr.core.PlayerData=H.copy(online.PlayerData)
local stashOpens=0
library.inventory.forceOpenInventory=function(src,kind,id)assert(src==1 and kind=='stash');stashOpens=stashOpens+1 end
ui.inputs={{'pw'}}
ui.select('forge_core_stash_job');assert(stashOpens==1)
ui.inputs={{'bad'}}
ui.select('forge_core_stash_job');assert(stashOpens==1,'server rejects incorrect stash password')
local duty=online.PlayerData.job.onduty
ui.select('forge_core_duty');assert(online.PlayerData.job.onduty~=duty,'same local Player handles duty callback')
ui.select('forge_core_shop_open_job')
assert(#inventoryOpens==1 and inventoryOpens[1].kind=='shop'and inventoryOpens[1].data.type:find('forge_core_job_police',1,true))
ui.inputs={{'burger',3,20}}
ui.select('forge_core_shop_supply_job');assert(items.burger==17)
assert(catalog.Registry.get('job','police').stashes[1].shops[1].stock.burger==13)
-- Server writes in-memory, broadcasts through real replica and replaces actual client zones after supply.
assert(clientCore.JobState.jobs[1].stashes[1].shops[1].stock.burger==13 and #zones.Business.zones==5)
ui.select('forge_core_business_registers_job')
local function selectRegister(index)
    local frame=context.frames[#context.frames]
    assert(frame and frame.name=='context:open','actual context must be open')
    context.api.HandleSelect(frame.data.id,index)
end
selectRegister(2) -- deposit opens an input; cancelled input rebuilds menu
ui.inputs={{5,'pw'}}
selectRegister(2)
assert(items.money==995 and catalog.Registry.get('job','police').stashes[1].registers[1].balance==105)
ui.inputs={{3,'pw'}}
selectRegister(3)
assert(items.money==998 and catalog.Registry.get('job','police').stashes[1].registers[1].balance==102)
-- Installed PR minigame maps five exact parameters, then progress and server robbery route are exercised.
ui.select('forge_core_business_registers_job')
selectRegister(4)
assert(#minigameCalls==1)
H.same(minigameCalls[1],table.pack(3,30,2,40,500),'exact Glitch arguments through PR')
assert(items.money==1028 and catalog.Registry.get('job','police').stashes[1].registers[1].balance==72)
local alarms=0
native.emit=function(name)assert(name=='forge-core:server:job:alarm');alarms=alarms+1 end
ui.select('forge_core_business_alarms_job');assert(alarms==1)
local boss=0
holder.Menu={openBossPanel=function(kind,job)assert(kind=='job'and job.name=='police');boss=boss+1 end}
ui.select('forge_core_business_bossMenus_job');assert(boss==1,'central boss controller remains explicit future boundary')
ui.inputs={{'1'}}
ui.select('forge_core_business_applications_job')
assert(#catalog.Registry.get('job','police').stashes[1].applications[1].submissions==1)
-- Loss of membership: old closure reaches server but cannot bypass its actual permission gate.
local oldStash=ui.option('forge_core_stash_job')
assert(p.api.SetJob(1,'unemployed',0))
sr.core.PlayerData=H.copy(online.PlayerData)
assert(not oldStash.canInteract())
ui.inputs={{'pw'}};oldStash.onSelect();assert(stashOpens==1)
dispatch('QBCore:Player:SetPlayerData')
assert(#ui.timers==2,'each actual consumer coalesces one refresh')
ui.flush()
assert(#zones.Points.zones==0 and #zones.Business.zones==1,'only public robbery register remains')
-- No unload handler was added: immutable legacy semantics remain visible; stop cleanup and late timer are distinct.
assert(p.api.SetJob(1,'police',4));sr.core.PlayerData=H.copy(online.PlayerData)
dispatch('QBCore:Client:OnJobUpdate');ui.flush()
assert(#zones.Points.zones==2 and #zones.Business.zones==5)
dispatch('QBCore:Client:OnPlayerUnload')
assert(#zones.Points.zones==2,'inherited no unload cleanup')
dispatch('QBCore:Client:OnJobUpdate');dispatch('onResourceStop','forge-core')
assert(#zones.Points.zones==0 and #zones.Business.zones==0)
ui.flush()
assert(#zones.Points.zones==2 and #zones.Business.zones==5,'inherited late timers recreate stopped zones')
assert(#workers==0 and #timers==0 and next(wire.server.api.getPending())==nil and next(wire.client.api.getPending())==nil)
assert(sr.core.ProducerCore==producer and sr.core.LegacyCore==legacy and sr.core.JobClientCore==clientCore and sr.core.JobZoneCore==zones)
print('PASS client zone composition: actual Producer/Legacy/replica/Points/Business + canonical server services/security and installed PR RPC/context/inventory/minigame adapters; stash/duty/shop/supply/register/application/group loss and stop race in memory; UI/targets/providers/network/SQL/JSON simulated, no full OX purchase or boot')

