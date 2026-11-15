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
local taxi=H.copy(group);taxi.name='taxi';taxi.label='Taxi';taxi.defaultDuty=true
m.seed(config.Storage.jobsFile,{police=group,taxi=taxi});m.seed(config.Storage.gangsFile,{})
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

local N=dofile('tests/kernel_multijob_harness.lua')
local work=A.compose(sr.core,{client=holder,library=ui.library,translate=ui.translate,config=ui.config,native=ui.native,integrations=ui.integrations})
-- Remove the explicit future consumer double from the fixture, not a production implementation.
holder.Menu.openMultiJobAdminMenu=nil
local prisonState={prisonState='stopped',prisonStatus={status='free',jailed=false},prisonResult=table.pack(true,'done'),record=ui.record}
local provider=N.provider(prisonState)
local multiConfig=N.config(true);ui.config.MultiJob=multiConfig
local before={ui=#ui.trace,files=#m.trace,wire=#wire.trace}
local multi=H.load('kernel/server/multijob/multijob_core.lua',N.env())(base,{config=multiConfig,library=library,native=native,
    translate=function(key)return key end,time=function()return clock end,prisonProvider=provider,notifyPosition='top-right'})
local menus=H.load('kernel/client/menu/multijob_core.lua',N.env())(sr.core,{client=holder,config=ui.config,native=ui.native})
assert(menus.Menu==work.Menu and menus.Shared==work.Shared and menus.Config==multi.Config)
assert(#ui.trace==before.ui and #m.trace==before.files and #wire.trace==before.wire,'no constructor effects')
assert(base.MultiJobCore==multi and catalog.Dependencies.MultiJobService==multi.Service and catalog.Dependencies.PrisonService==multi.PrisonService)
assert(not pcall(H.load('kernel/server/multijob/multijob_core.lua',N.env()),base,{}))
assert(not pcall(H.load('kernel/client/menu/multijob_core.lua',N.env()),sr.core,{}))
local alien={WorkMenus=work,AdministrationMenus=administration,JobClientCore=clientCore}
assert(not pcall(H.load('kernel/client/menu/multijob_core.lua',N.env()),alien,{}))
for _,entry in ipairs(multi.Callbacks)do transport.Security.register(entry.name,entry.handler,entry.options)end
-- Existing Security was built before MultiJob in this fixture; explicit descriptors must preserve all five admin guards.
local registrations=transport.Security.getRegistrations()
for _,key in ipairs({'getSettings','saveSettings','addJob','removeJob','getTargetJobs'})do assert(registrations[multiConfig.Callbacks[key]].access=='admin')end
assert(multi.Service.Initialize()and not multi.Service.Initialize())
multi.Service.start();catalog.Service.start()
p.api.CheckPlayerData(2,{citizenid='UIADMIN',license='license:admin',userId=102,charinfo={firstname='UI',lastname='Admin'}})
p.api.CheckPlayerData(1,{citizenid='PLAYER',license='license:player',userId=101,charinfo={firstname='Not',lastname='Admin'}})
assert(p.api.SetJob(2,'police',4));assert(p.api.SetJob(1,'police',0))
local player=p.lookup.GetPlayer(1)
wire.playerSource=1
sr.core.PlayerData=H.copy(player.PlayerData)
clientCore.JobState.request()
-- Actual client runtime data receiver + producer refresh, not a table assignment masquerading as integration.
local receiver=H.load('kernel/client/events.lua',N.env())({core=sr.core,native={GetInvokingResource=function()return nil end},
    cache={resource='forge-core'},config={},helpers={},library=ui.library,globalState={},notify=function()end,locale=function(k)return k end})
local oldEmit=p.platform.emitClient
local function receive(name,...)
    for _,event in ipairs(receiver.Events)do if event.name==name then event.handler(...)end end
    for _,event in ipairs(zoneCore.Events)do if event.name==name then event.handler(...)end end
end
p.platform.emitClient=function(name,target,...)
    oldEmit(name,target,...)
    if target==1 or target==-1 then receive(name,H.copy(...))end
end
local previousEmit=native.emitClient
native.emitClient=function(name,target,...)
    previousEmit(name,target,...)
    if target==1 or target==-1 then receive(name,...)end
end
local function rpc(key,...)
    return wire.client.api.request(multiConfig.Callbacks[key],nil,nil,10000,...)
end
local function current()
    local frame=context.frames[#context.frames];assert(frame and frame.name=='context:open');return frame.data.id
end
local function choose(index)context.api.HandleSelect(current(),index)end
local function findOption(title)
    local ctx=ui.contexts[current()]
    for index,option in ipairs(ctx.options)do if option.title==title then return index end end
    error('Missing option '..title)
end
local ok,reason=rpc('addJob',1,'taxi',4)
assert(not ok and reason=='no_permission'and next(player.PlayerData.metadata.multijob or{})==nil,'network self-grant denied by actual Security')
ok,reason=rpc('getTargetJobs',2);assert(not ok and reason=='no_permission')
-- Local service contract still allows self, deliberately not changed into the network/admin policy.
assert(multi.Service.addJob(1,1,'taxi',4))
assert(player.PlayerData.metadata.multijob[1].name=='taxi'and player.PlayerData.jobs.taxi==nil,'metadata distinct from native memberships')
assert(sr.core.PlayerData.metadata.multijob[1].name=='taxi','actual runtime receiver updates same client producer data')
menus.Menu.openMultiJobMenu('fixture_parent')
assert(current()=='forge_core_multijob_player')
choose(2);assert(current()=='forge_core_multijob_details_taxi')
prisonState.prisonState='started';prisonState.prisonStatus={status='jailed',jailed=true}
choose(1);assert(player.PlayerData.job.name=='police','actual PR prison guard refuses')
ui.runTimers(500)
prisonState.prisonStatus=nil
ok,reason=rpc('setActiveJob','taxi');assert(not ok and reason=='prison.jobs_locked','transitioning provider fails closed')
prisonState.prisonStatus={status='free',jailed=false}
menus.Menu.openMultiJobMenu('fixture_parent');choose(2);choose(1)
assert(player.PlayerData.job.name=='taxi'and player.PlayerData.job.grade.level==4)
assert(player.PlayerData.jobs.police==nil and player.PlayerData.jobs.taxi==4,'actual SetJob replacement semantics kept')
assert(sr.core.PlayerData.job.name=='taxi'and sr.core.PlayerData.job.grade.level==4,'runtime data receiver + canonical Legacy query')
assert(legacy.Functions.GetPlayerData()==sr.core.PlayerData and zoneCore.PlayerAccess.GetJobInfo().jobName=='taxi')
-- Actual native catalog projection lacks stashes: original duty-point probe never sees configured admin points.
assert(groups.GetJob('taxi').stashes==nil and catalog.Registry.get('job','taxi').stashes[1].duty.enabled)
assert(player.PlayerData.job.onduty==true,'inherited projection means enabled duty point does not force off here')
ui.runTimers(500);ui.runTimers(250)
local pointsWithTaxi=0
for _,zone in pairs(targetZones)do for _,option in ipairs(zone.options)do if option.name:find('_taxi_',1,true)then pointsWithTaxi=pointsWithTaxi+1 end end end
assert(pointsWithTaxi>0,'same actual Points/Business consumers refresh to active job')
-- UI removes inactive only; direct player callback can remove active metadata without clearing native membership.
ok,reason=rpc('removeOwnJob','taxi');assert(ok)
assert(#player.PlayerData.metadata.multijob==0 and player.PlayerData.job.name=='taxi'and player.PlayerData.jobs.taxi==4)
local _,payload=rpc('getPlayerJobs');assert(#payload.jobs==1 and payload.jobs[1].active,'current job reappears')
wire.playerSource=2
assert(rpc('addJob',1,'police',0))
ui.inputs={{'true',1,'false','unemployed'}}
menus.Menu.openMultiJobSettingsEditor({includeCurrentJob=false})
assert(multi.Service.getSettings().includeCurrentJob==true and not multi.Service.getSettings().allowPlayerRemove)
ui.runTimers(500)
menus.Menu.openMultiJobAdminMenu();assert(current()=='forge_core_multijob_admin')
ui.inputs={{'1'}};menus.Menu.openMultiJobAdminView();assert(current()=='forge_core_multijob_admin_view')
context.api.HandleBack(current());assert(current()=='forge_core_multijob_admin')
-- Existing Jobs controller now calls the real MultiJob menu on the same controller.
work.Menu.openJobsMenu();choose(findOption('menu.multijob.admin_title'));assert(current()=='forge_core_multijob_admin')
wire.playerSource=1
ok,reason=rpc('removeOwnJob','police');assert(not ok and reason=='remove_disabled')
-- Provider jail/release are exercised only through PR with a simulated xt-prison, never actual state.
assert(multi.PrisonService.setSentence(2,1,{time=1})and multi.PrisonService.release(2,1))
clock=clock+5001
local limited
for i=1,16 do local allowed,err=rpc('getPlayerJobs');if not allowed then limited=err end end
assert(limited=='rate_limited','same Security quota')
assert(next(wire.server.api.getPending())==nil and next(wire.client.api.getPending())==nil)
assert(#workers==0 and #timers==0)
assert(base.PlayerCore.Lookup.GetPlayer(1)==player and base.Groups==multi.Groups and sr.core.WorkMenus.Menu==menus.Menu)
print('PASS multijob composition: actual Player/Groups/replacement/metadata, 25 menus/23 replica/24 points, runtime data receiver, installed PR RPC/context/prison provider and actual Security; admin/player/prison/quota denied, activate/remove/settings/back and inherited metadata-membership/duty projection differences; in-memory only')

