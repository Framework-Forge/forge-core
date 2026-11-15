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

local sr=U.new(true,'client')
local replica
local originalEmit=sr.native.TriggerEvent
sr.native.TriggerEvent=function(name,...)
    originalEmit(name,...)
    if replica then for _,e in ipairs(replica.Events)do if e.name==name then e.handler(...)end end end
end
local producer=H.load('kernel/client/session_core.lua',env())(sr.core,{native=sr.native,delivery=sr.delivery,statusConfig=sr.clientConfig})
local lf=V.new(true,'client');local queries=V.client(true)
local lb={};for key,value in pairs(lf.bindings)do lb[key]=value end
lb.membership,lb.notify=queries.membership,queries.bindings.notify
lb.jobs,lb.gangs=groups.GetJobs(),groups.GetGangs()
local pulls=0
lb.awaitGroups=function()pulls=pulls+1;return{jobs=groups.GetJobs(),gangs=groups.GetGangs()}end
local legacy=H.load('kernel/client/legacy_core.lua',env())(sr.core,lb)
local dataBefore=sr.core.PlayerData


local A=dofile('tests/kernel_work_menu_harness.lua')
local M=dofile('tests/kernel_admin_menu_harness.lua')
local I=dofile('tests/kernel_inventory_harness.lua')
local W=dofile('tests/kernel_weapon_harness.lua')
local ui=A.new(true)
-- The fixture above exposes UI providers only. Drop its already-created menu bodies before canonical attachment.
for _,name in ipairs({"openMain","openJobsMenu","openGroupList","openPaymentSettings","openPaymentEditor","openGroupCreator","openGroupDetails","openGroupEditor","openGroupPointList","openGroupPointDetails","openGroupPointEditor","openGroupStashEditor","openGroupDutyEditor","removeGroupPoint","openGradeList","openGradeDetails","openGradeEditor","removeGrade","openBossPanel","openBossEmployees","openBossEmployeeActions","openStationBusinessList","openStationBusinessPointDetails","openStationBusinessPointEditor","openStationShopItems","openStationShopItemEditor","openStationApplicationQuestions","openStationQuestionEditor","openStationCandidates","openStationCandidateActions","openBossApplications","openMeiSettingsEditor","openMeiCreator"})do ui.menu[name]=nil end
local holder={Menu=ui.menu}
ui.config.Job=config
ui.config.Inventory,ui.config.Weapons=I.config(true),W.config(true)
ui.config.Vip=H.load('kernel/config/forge_vip.lua',H.environment())()
ui.library.callback.await=function(name,timeout,...)
    ui.record('await',name,timeout,...)
    return wire.client.api.request(name,nil,nil,timeout,...)
end
local context=M.context()
ui.registerHook=context.api.RegisterContext;ui.showHook=context.api.ShowContext
local targetZones,zoneId={},0
ui.library.target={addBoxZone=function(data)zoneId=zoneId+1;targetZones[zoneId]=data;return zoneId end,
    removeZone=function(id)targetZones[id]=nil end}
ui.native.vector=B.vector
local clientPorts={client=holder,config=config,library=ui.library,translate=ui.translate,wait=function(ms)return coroutine.yield(ms)end}
clientCore=C.compose(sr.core,clientPorts)
local zoneCore=Z.compose(sr.core,{client=holder,config=config,library=ui.library,translate=ui.translate,native=ui.native,
    integrations={lockpickState=function()return'stopped'end,startLockpick=function()error('Unused minigame route')end}})
local administration=H.load('kernel/client/menu/administration_core.lua',env())(sr.core,{
    menu=holder.Menu,library=ui.library,translate=ui.translate,native=ui.native,config=ui.config,json=m.codec})
local sharedBefore=administration.Shared

local Q=dofile('tests/kernel_skill_harness.lua')
local configSkills=H.load('kernel/config/forge_skills.lua',Q.env())()
local definitions={settings={enabled=true},skills={a={name='a',maxXp=100,clientGain=true,maxDeltaPerMinute=20}},
    reputations={r={name='r',maxXp=50}}}
m.seed(configSkills.Storage.file,definitions)
local values={PLAYER=m.codec.encode({a=10,r=2}),UIADMIN=m.codec.encode({a=0})}
local writes,cache,packets,routes={},{},{},{}
library.db={isReady=function()return true end,
    scalar=function(sql,params)
        if sql:find('information_schema',1,true)then return 1 end
        assert(sql=='SELECT `skills` FROM `players` WHERE `citizenid` = ?')
        return values[params[1]]
    end,
    update=function(sql,params)
        assert(sql=='UPDATE `players` SET `skills` = ? WHERE `citizenid` = ?')
        writes[#writes+1]=H.copy(params);values[params[2]]=params[1];return 1
    end}
library.cache={set=function(k,v)cache[k]=H.copy(v)end,clear=function(k)cache[k]=nil end}
library.framework={GetPlayer=function()error('forbidden framework self-cycle')end}
local sn={source=function()return wire.server.source end,time=function()return clock end,
    resource=function()return'forge-core'end,resourceState=function(name)assert(name=='forge-gym');return'started'end,
    isAceAllowed=native.isAceAllowed,spawn=function(fn)workers[#workers+1]=fn end,wait=native.wait,print=native.print,
    emitClient=function(name,src,packet)
        assert(name=='forge-core:client:skills:sync')
        packets[#packets+1]={source=src,packet=H.copy(packet)}
    end,
    promise=function()local p={};function p:resolve(v)self.done=true;self.value=v end;return p end,
    await=function(p)assert(p.done);return p.value end}
local calls={invoke=function(resource,export,src,name,delta,context)
    routes[#routes+1]={resource,export,src,name,delta,H.copy(context)};return true
end}
local progressionEnv=H.environment({PRProgression={}})
H.load('../pr_bridge/shared/progression.lua',progressionEnv)
local ports={config=configSkills,library=library,json=m.codec,progression=progressionEnv.PRProgression,
    native=sn,integrations=calls,translate=function(k)return k end}
local pcGuard=base.PlayerCore
ports.isReady=function()return base.PlayerCore==pcGuard and base.JobCatalog==catalog end

local core=H.load('kernel/server/skill/skill_core.lua',Q.env())(base,ports)
local work=A.compose(sr.core,{client=holder,library=ui.library,translate=ui.translate,config=ui.config,native=ui.native,integrations=ui.integrations})
-- Remove only the fixture's documented future-consumer double.
holder.Menu.openSkillsMenu=nil
ui.config.Skills=configSkills
-- Real PR library cache behavior is passive; this is only an in-memory delivery double.
local clientCache={}
ui.library.cache={set=function(k,v)clientCache[k]=H.copy(v)end,
    get=function(k)return clientCache[k]end,clear=function(k)clientCache[k]=nil end}
ui.library.framework={GetPlayer=function()error('forbidden framework self-cycle')end}
local handlers={}
for _,entry in ipairs(core.Boundary.NetEvents)do handlers[entry.name]=entry.handler end
for _,entry in ipairs(core.Boundary.Listeners)do handlers[entry.name]=entry.handler end
local progressionClient=H.environment({PRProgression={}})
H.load('../pr_bridge/shared/progression.lua',progressionClient)
local cn={time=function()return clock end,wait=function(ms)return coroutine.yield(ms)end,
    emit=sr.native.TriggerEvent,emitServer=function(name,...)
        local previous=wire.server.source
        wire.server.source=wire.playerSource
        local result=table.pack(pcall(assert(handlers[name],'unknown simulated server route'),...))
        wire.server.source=previous
        assert(result[1],result[2])
        return table.unpack(result,2,result.n)
    end}
replica=H.load('kernel/client/skill/skill_core.lua',Q.env())(sr.core,{client=holder,config=configSkills,
    library=ui.library,native=cn,progression=progressionClient.PRProgression})
local menus=H.load('kernel/client/menu/skills_core.lua',Q.env())(sr.core,{client=holder,config=ui.config,library=ui.library,native=ui.native})
assert(replica.Producer==producer and replica.State==sr.core and holder.SkillReplica==replica.Runtime)
assert(menus.Menu==work.Menu and menus.Shared==sharedBefore and work.Shared==sharedBefore)
assert(sr.core.PlayerData==dataBefore and #workers==0 and #timers==0 and #writes==0)
assert(not pcall(H.load('kernel/client/skill/skill_core.lua',Q.env()),sr.core,{}))
assert(not pcall(H.load('kernel/client/menu/skills_core.lua',Q.env()),sr.core,{}))
local foreign={ProducerCore=producer,PlayerData={}}
assert(not pcall(H.load('kernel/client/skill/skill_core.lua',Q.env()),foreign,{client=holder}))
for _,entry in ipairs(core.Callbacks)do transport.Security.register(entry.name,entry.handler,entry.options)end
for name,handler in pairs(menus.Callbacks)do wire.client.api.register(name,handler)end
sn.emitClient=function(name,src,packet)
    packets[#packets+1]={source=src,packet=H.copy(packet)}
    if src==wire.playerSource then
        for _,entry in ipairs(replica.Events)do if entry.name==name then entry.handler(H.copy(packet))end end
    end
end
local function event(name,...)
    for _,entry in ipairs(replica.Events)do if entry.name==name then entry.handler(...)end end
end
p.api.CheckPlayerData(2,{citizenid='UIADMIN',license='license:admin',userId=102,charinfo={firstname='UI',lastname='Admin'}})
p.api.CheckPlayerData(1,{citizenid='PLAYER',license='license:player',userId=101,charinfo={firstname='Player',lastname='One'}})
wire.playerSource=1
sr.core.PlayerData.citizenid='PLAYER'
assert(core.Service.start());assert(#workers==1);workers[1]();workers={}
event('QBCore:Client:OnPlayerLoaded')
local exports=replica.Exports
assert(exports.getCurrentSkill('a')==10 and clientCache['forge-core:skills'].values.a==10)
local ok,reason=wire.client.api.request(configSkills.Callbacks.addXp,nil,nil,10000,'a',5)
assert(not ok and reason=='no_permission','actual Security refuses self-award')
assert(exports.updateSkill('a',3))
assert(core.Service.getCurrentSkill(1,'a')==10 and exports.getCurrentSkill('a')==13)
local snapshot=producer.Status.Callbacks['qbx_core:client:getStatusSnapshot']()
assert(snapshot.extensions.forgeSkills.counters.a.gain==3,'actual status producer collects the same ledger')
handlers['qbx_core:server:statusExtensions'](1,snapshot.extensions)
assert(core.Service.getCurrentSkill(1,'a')==13 and exports.getCurrentSkill('a')==13)
local ack={};event('qbx_core:client:collectStatusExtensions',ack);assert(ack.forgeSkills.counters.a.gain==3)
-- Explicit worker launch simulates the scheduler; no actual thread installation.
local worker=coroutine.create(replica.Threads[1]);assert(coroutine.resume(worker));assert(coroutine.resume(worker))
assert(core.Service.getCurrentSkill(1,'a')==13,'mirror retry is idempotent after status acknowledgement')
handlers['qbx_core:server:progressionCheckpoint'](1,'PLAYER')
assert(m.codec.decode(values.PLAYER).a==13 and #writes==1)
work.Menu.openMain()
menus.Menu.openPlayerSkillsMenu('forge_core_main')
local function current()local frame=context.frames[#context.frames];assert(frame.name=='context:open');return frame.data.id end
assert(current()=='forge_core_player_skills')
context.api.HandleSelect(current(),1);assert(current()=='forge_core_player_skill_details_a')
context.api.HandleBack(current());assert(current()=='forge_core_player_skills')
context.api.HandleBack(current());assert(current()=='forge_core_main')
event('QBCore:Client:OnPlayerUnload');assert(clientCache['forge-core:skills']==nil)
wire.playerSource=2;sr.core.PlayerData.citizenid='UIADMIN'
event('QBCore:Client:OnPlayerLoaded')
-- server command -> actual PR RPC -> real client callback -> canonical context tree.
core.Commands[1].handler(2);assert(current()=='forge_core_skills')
context.api.HandleSelect(current(),1);assert(current()=='forge_core_skill_list')
context.api.HandleSelect(current(),1) -- new skill dialog cancelled; return to list
assert(current()=='forge_core_skill_list')
ui.inputs={{'new_skill','New skill','book','direct',100,'','', '',1,true,true,false,0,300,true,20}}
menus.Menu.openSkillEditor(nil,true)
assert(core.Registry.getSkill('new_skill')and m.codec.decode(m.files[configSkills.Storage.file]).skills.new_skill)
ui.runTimers(500);assert(current()=='forge_core_skill_list');ui.runTimers(1000)
-- A stale server-provided definition can overwrite a concurrently changed field, inherited full-save semantics.
local stale=core.Registry.getSkill('new_skill')
assert(core.Service.upsertSkill(2,{name='new_skill',label='Concurrent',maxXp=100,levels={{title='Concurrent',from=0,to=20}}}))
ui.inputs={{'Edited','book','direct',100,'','', '',1,true,true,false,0,300,true,20}}
menus.Menu.openSkillEditor(stale,false)
assert(core.Registry.getSkill('new_skill').levels==nil,'stale menu save overwrites concurrent levels')
ui.runTimers(1000)
-- UI forms still cross the same protected callback boundary.
admin=false;ui.inputs={{'Denied','book','direct',100}}
menus.Menu.openSkillEditor(stale,false)
assert(core.Registry.getSkill('new_skill').label=='Edited')
admin=true;ui.runTimers(1000)
menus.Menu.openSkillDetails(core.Registry.getSkill('new_skill'))
ui.alerts={'confirm'};context.api.HandleSelect(current(),4)
assert(core.Registry.getSkill('new_skill')==nil)
-- Player reconnection loads the persisted column and obtains a fresh runtime snapshot.
event('QBCore:Client:OnPlayerUnload');wire.playerSource=1;sr.core.PlayerData.citizenid='PLAYER'
handlers['QBCore:Server:OnPlayerUnload'](1)
clock=clock+2000;event('QBCore:Client:OnPlayerLoaded')
assert(exports.getCurrentSkill('a')==13)
assert(next(wire.server.api.getPending())==nil and next(wire.client.api.getPending())==nil)
assert(sr.core.PlayerData==dataBefore and menus.Shared==work.Shared and p.lookup.GetPlayer(1).PlayerData.citizenid=='PLAYER')
print('PASS skill client composition: canonical producer/status/replica/Menu/Shared and server Player/Service28/Security, actual PR ledger/RPC/context/persistence; command/create/edit/delete/back/ACL, predicted XP/status ack/mirror retry/checkpoint/reconnect and inherited stale full-save; natives/network/SQL/IO/scheduler/UI simulated, no boot')

