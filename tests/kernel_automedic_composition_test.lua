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
library.notify={NotifyPlayer=function()end};library.database={query=function()return {}end,transaction=function()return true end,
    single=function()return {charinfo=m.codec.encode({firstname='Fixture',lastname='Member'})}end}
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


local A=dofile('tests/kernel_automedic_harness.lua')
local N=dofile('tests/kernel_multijob_harness.lua')
local store={}
library.cache={get=function(k)return store[k]end,set=function(k,v)store[k]=H.copy(v)end}
H.load('../pr_bridge/bridge/cache/resources.lua',H.environment())(library.cache)
local function listenEntries(entries)
    for _,entry in ipairs(entries)do p.platform.on(entry.name,entry.handler)end
end
-- Actual local status/session/cache producers share the already-created Player core.
local writer=H.load('kernel/shared/bridge_cache.lua',H.environment())({
    getResourceState=function()return'started'end,
    writeCache=function(mode,key,value)
        if mode=='set'then store[key]=H.copy(value)else for k,v in pairs(value)do store[key][k]=H.copy(v)end end
    end,emit=p.platform.emitServer},'qbx_core:server:cacheChanged')
local cacheProducer=H.load('kernel/server/bridge_cache.lua',H.environment())({core=p.core,emit=p.platform.emitServer,writer=writer})
p.core.BridgeCache=cacheProducer.Producer
local statusProducer=H.load('kernel/server/status.lua',H.environment())({core=p.core,config={checkpointMinutes=15},
    emit=p.platform.emitServer,emitClient=p.platform.emitClient,getInvokingResource=p.platform.getInvokingResource,
    wait=p.platform.wait,awaitSnapshot=function()return{}end,save=p.api.Save})
p.core.Status=statusProducer.Status
local sessionProducer=H.load('kernel/server/session.lua',H.environment())({core=p.core,getPlayer=p.lookup.GetPlayer,
    getBucket=function()return 0 end,emit=p.platform.emitServer})
p.core.Session=sessionProducer.Session
base.PlayerCore.Producers={Cache=cacheProducer,Status=statusProducer,Session=sessionProducer}
for _,module in ipairs({cacheProducer,statusProducer,sessionProducer})do
    for _,entry in ipairs(module.Events)do p.platform.on(entry.name,function(...)return entry.handler(wire.server.source or 0,...)end)end
end
local prisonState={prisonState='stopped',prisonStatus={jailed=false,status='free'},prisonResult=table.pack(true),record=function()end}
local multi=H.load('kernel/server/multijob/multijob_core.lua',A.env())(base,{library=library,native=native,
    translate=function(k)return k end,time=function()return clock end,prisonProvider=N.provider(prisonState)})
local configAuto=A.config(true)
m.seed(configAuto.Storage.file,{cooldown=0,treatmentPrice=100,beds={A.bed('civil',0),A.bed('prison',10,true)}})
local inventory=A.oxClear()
-- Deliberately unsafe existing bridge must never be selected by the new service.
library.inventory.ClearInventory=function()error('unsafe dropped-result bridge')end
library.framework={getPlayerMoney=function()error('forbidden PR framework cycle')end}
local raw={ready=true,refuse=false}
local inventoryIntegration={isReady=function()return raw.ready end,
    clearInventoryRaw=function(src)
        if raw.refuse then return false end
        return inventory.clear(src)
    end}
local an={resourceName=function()return'forge-core'end,time=function()return clock end,
    source=function()return wire.server.source end,isAceAllowed=native.isAceAllowed,
    ped=function(src)return tonumber(src)end,exists=function(ped)return ped~=0 end,
    health=function()return 100 end,coords=function()return{x=1,y=0,z=0}end,bucket=function()return 0 end,
    emitClient=function(name,src,data)flow[#flow+1]={name=name,src=src,data=H.copy(data)}end}
local ports={config=configAuto,library=library,native=an,inventoryIntegration=inventoryIntegration}
local core=H.load('kernel/server/automedic/automedic_core.lua',A.env())(base,ports)
assert(core.Base==base and core.PlayerCore==base.PlayerCore and core.Groups==groups and core.Security==transport.Security)
assert(base.ForgeSession==core.Session and catalog.Dependencies.AutoMedicService==core.Service)
assert(not core.Service.started and #m.trace==0,'constructor cannot load settings')
assert(not pcall(H.load('kernel/server/automedic/automedic_core.lua',A.env()),base,ports))
local fake={PlayerCore=base.PlayerCore,Groups=groups,JobCatalog=catalog,Callbacks={}}
assert(not pcall(H.load('kernel/server/automedic/automedic_core.lua',A.env()),fake,ports))
for _,entry in ipairs(core.Callbacks)do transport.Security.register(entry.name,entry.handler,entry.options)end
listenEntries(core.Session.Events);listenEntries(core.Boundary.Events)
wire.playerSource=1
p.api.CheckPlayerData(1,{citizenid='PATIENT',license='license:patient',userId=101,
    money={cash=200,bank=50},metadata={isdead=true,hunger=5,thirst=8}})
p.api.CheckPlayerData(2,{citizenid='ADMIN',license='license:admin',userId=102})
local player=p.lookup.GetPlayer(1);assert(core.Session.Session.character(1)=='PATIENT')
assert(not p.core.Session.isLoaded(1),'producer readiness differs from inherited Forge view policy')
core.Service.start()
local function rpc(key,...)return wire.client.api.request(configAuto.Callbacks[key],nil,nil,10000,...)end
local ok,err=rpc('saveSettings',{})
assert(not ok and err=='no_permission','actual Security denies settings save')
ok,err=rpc('saveBed',A.bed('forbidden',1))
assert(not ok and err=='no_permission','bed callback retains player class but service denies')
local read,status=rpc('getStatus');assert(read and status.dead)
inventory.seed(1)
local approved,payload=rpc('requestTreatment','gunshot');assert(approved)
local token=payload.token
clock=clock+10
local completed,result=rpc('completeTreatment',token)
assert(completed and result.chargedAmount==100 and result.paymentAccount=='cash')
assert(player.PlayerData.money.cash==100 and next(inventory.records[1].items)==nil and inventory.records[1].weapon==nil)
assert(player.PlayerData.metadata.isdead==false and player.PlayerData.metadata.inlaststand==false)
assert(p.core.Status.Get(1,'hunger')==5,'server SetStatus only authorizes client effect, not instant server mutation')
local needs=0
for _,event in ipairs(p.trace)do
    if event.kind=='client'and event.args[1]=='qbx_core:client:setStatus'and(event.args[3]=='hunger'or event.args[3]=='thirst')then needs=needs+1 end
end
assert(needs==2,'same actual Status emits both minimum need effects')
ok,err=rpc('completeTreatment',token);assert(not ok and err=='invalid_treatment','replay cannot debit twice')
-- Failed clear refunds through real local Player money and keeps the treatment retryable.
p.api.SetMetadata(1,'isdead',true)
clock=clock+20
approved,payload=rpc('requestTreatment','gunshot');assert(approved);clock=clock+10;raw.refuse=true
local before=player.PlayerData.money.cash
ok,err=rpc('completeTreatment',payload.token)
assert(not ok and err=='inventory_clear_failed'and player.PlayerData.money.cash==before)
raw.refuse=false
-- Prison policy selects only prison beds; cash insufficient -> full bank debit, including negative balance.
assert(core.Service.cancelTreatment(1,payload.token))
p.api.SetMetadata(1,'injail',20)
player.PlayerData.money.cash=30
clock=clock+20;approved,payload=rpc('requestTreatment','collapse');assert(approved)
completed,result=rpc('recoverHospital',payload.token,'unreachable')
assert(completed and result.paymentAccount=='bank'and player.PlayerData.money.bank==-50 and player.PlayerData.money.cash==30)
assert(core.Service.recoveries[1].bed.id=='prison')
wire.server.source=1
p.platform.emitServer(configAuto.Events.leaveHospital,payload.token);assert(core.Service.recoveries[1]==nil)
wire.playerSource=2
local settings=core.Service.getSettings();settings.reviveHealthPercent=25
assert(rpc('saveSettings',settings))
assert(m.codec.decode(m.files[configAuto.Storage.file]).reviveHealthPercent==25)
-- Actual passive delivery blocks a stale pre-unload character record even while the Player object remains.
p.platform.emitServer('QBCore:Server:OnPlayerUnload',1)
assert(core.Session.Session.character(1)==nil)
assert(library.cache.GetResourceState('qbx_core','session:1').connected==false)
p.platform.emitServer('pr_bridge:server:OnPlayerLoaded',1)
assert(core.Session.Session.character(1)==nil,'loaded flag cannot override disconnected passive record')
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil)
print('PASS AutoMedic composition: canonical Player/Status/cache/session/Prison/JobService/Security, actual PR RPC/JSON/passive cache and whole installed OX Clear in memory; denied admin actions, debit/refund/raw nil acknowledgement, replay/prison/bank/needs/unload gates; PR raw binder still pending, no real items/money/SQL/natives/boot')

