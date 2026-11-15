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
local counts={ui=#ui.trace,files=#m.trace,wire=#wire.trace,zones=zoneId}
local work=A.compose(sr.core,{client=holder,library=ui.library,translate=ui.translate,config=ui.config,native=ui.native,integrations=ui.integrations})
assert(work.Menu==administration.Menu and work.Shared==sharedBefore and clientCore.Client.Menu==work.Menu and zoneCore.Client.Menu==work.Menu)
assert(holder.JobCreator==work.Creator and sr.core.WorkMenus==work and work.State==sr.core)
assert(#ui.trace==counts.ui and #m.trace==counts.files and #wire.trace==counts.wire and zoneId==counts.zones)
assert(not pcall(A.compose,sr.core,{}),'duplicate menu attachment refused')
local foreign={ProducerCore=producer,LegacyCore=legacy,JobClientCore=clientCore,JobZoneCore=zoneCore,AdministrationMenus=administration}
assert(not pcall(A.compose,foreign,{}),'foreign canonical state refused')
for name,handler in pairs(clientCore.Main.Callbacks)do wire.client.api.register(name,handler)end
for name,handler in pairs(work.Callbacks)do wire.client.api.register(name,handler)end
finance.Payments.load()
wire.playerSource=2
clientCore.JobState.request()
p.api.CheckPlayerData(2,{citizenid='UIADMIN',license='license:admin',userId=102,charinfo={firstname='UI',lastname='Admin'}})
p.api.CheckPlayerData(1,{citizenid='DENIED',license='license:denied',userId=101,charinfo={firstname='No',lastname='Admin'}})
assert(p.api.SetJob(2,'police',4))
local adminPlayer=p.lookup.GetPlayer(2)
sr.core.PlayerData=H.copy(adminPlayer.PlayerData)
local function current()
    local frame=context.frames[#context.frames];assert(frame and frame.name=='context:open','PR context must be open')
    return frame.data.id
end
local function selectMenu(index)context.api.HandleSelect(current(),index)end
local function back()context.api.HandleBack(current())end
-- Actual server command -> PR callback -> actual central menu -> replica RPC -> actual Points/Business.
local command
for _,entry in ipairs(transport.Commands.Commands)do if entry.name==config.Commands.jobs then command=entry.handler end end
command(2)
assert(current()=='forge_core_main'and clientCore.JobState.canManage)
assert(#zoneCore.Points.zones==2 and #zoneCore.Business.zones==5)
selectMenu(1);assert(current()=='forge_core_jobs')
selectMenu(1);assert(current()=='forge_core_group_list_job')
selectMenu(2);assert(current()=='forge_core_group_details_job_police')
ui.inputs={{'Edited by UI','none','false','true'}}
selectMenu(1)
assert(catalog.Registry.get('job','police').label=='Edited by UI'and groups.GetJob('police').label=='Edited by UI')
ui.runTimers(500);assert(current()=='forge_core_group_list_job')
back();assert(current()=='forge_core_jobs')
work.Menu.openMain()
selectMenu(8)
local panel
for _,event in ipairs(ui.trace)do if event.kind=='external-client'then panel=event.args end end
H.same(panel,table.pack('forge-loadscreen:client:openAdminMenu','forge_core_main','forge-core'),'future PR integration preserves loadscreen parent/resource')
work.Menu.openMain();selectMenu(9)
panel=ui.trace[#ui.trace].args
H.same(panel,table.pack('forge-pause:client:openAdminMenu','forge_core_main','forge-core'),'future pause parent/resource')
-- Real Creator calls actual group editor and server service, not a UI stub.
ui.inputs={{'Created via UI','ui_job',1,'none'},{'Owner',30}}
work.Creator.openJob()
local newGrades=catalog.Registry.get('job','ui_job').grades
assert(groups.GetJob('ui_job')and(newGrades[0]or newGrades['0']).payment==30)
local groupBefore=catalog.Registry.get('job','police')
local point=groupBefore.stashes[1]
ui.inputs={{2,'Recruiter changed',200,'false','false'}}
work.Menu.openGradeEditor('job',groupBefore,2,groupBefore.grades[2]and 2 or '2',false)
local editedGrades=catalog.Registry.get('job','police').grades
assert((editedGrades[2]or editedGrades['2']).isrecruiter==nil,'inherited rebuild omits recruiter field')
-- Editing an item proves exact payload loss through protected RPC and real in-memory persistence.
groupBefore=catalog.Registry.get('job','police');point=groupBefore.stashes[1]
local shop=point.shops[1]
ui.inputs={{'newburger','New Burger',25}}
work.Menu.openStationShopItemEditor('job',groupBefore,point,shop,shop.items[1],1)
local saved=catalog.Registry.get('job','police')
assert(saved.stashes[1].shops[1].items[1].name=='newburger'and saved.stashes[1].shops[1].items[1].metadata==nil)
local replicaPolice
for _,entry in ipairs(clientCore.JobState.jobs)do if entry.name=='police'then replicaPolice=entry end end
assert(replicaPolice.stashes[1].shops[1].items[1].name=='newburger','replica refreshed after full save')
-- Whole stale editor payload can overwrite a newer catalog; preserved rather than silently merged.
ui.inputs={{'Old snapshot wins','none','false','false'}}
work.Menu.openGroupEditor('job',groupBefore)
assert(catalog.Registry.get('job','police').stashes[1].shops[1].items[1].name=='burger','old snapshot overwrites newer item')
-- Actual Business target now opens the actual boss controller in this composition, not a sentinel.
local bossOption
for _,zone in pairs(targetZones)do for _,option in ipairs(zone.options)do
    if option.name:find('forge_core_business_bossMenus_job',1,true)then bossOption=option end
end end
assert(bossOption);bossOption.onSelect();assert(current()=='forge_core_boss_panel_job_police')
selectMenu(1);assert(context.api.GetOpenContextMenu(),table.concat(diagnostics,'\n'))
assert(current()=='forge_core_boss_employees_job_police')
ui.inputs={{'UIADMIN',4}}
selectMenu(1)
assert(adminPlayer.PlayerData.jobs.police==4)
-- Payment and MEI routes reach actual finance/catalog services and use only simulated storage/money.
ui.inputs={{'true',5,'bank','false','false',100,'true'}}
work.Menu.openPaymentEditor({})
assert(finance.Payments.getSettings().intervalMinutes==5)
ui.runTimers(1000)
ui.inputs={{'true',0,0,'government','bank'}}
work.Menu.openMeiSettingsEditor({})
assert(finance.Payments.getSettings().mei.enabled and finance.Payments.getSettings().mei.openingCost==0)
ui.runTimers(1000)
ui.inputs={{'UI Company',1},{'Owner',0}}
local created,company=work.Exports.OpenMeiCreator()
assert(created and company.name and groups.GetJob(company.name),'same actual MEI/Player/Registry services')
ui.runTimers(1000)
-- False flag does not hide admin UI in legacy code, but the protected real server write rejects the source.
wire.playerSource=1
work.Menu.openMain();assert(not clientCore.JobState.canManage and current()=='forge_core_main')
ui.inputs={{'Denied','denied_ui',1,'none'},{'Owner',0}}
work.Creator.openJob()
assert(not catalog.Registry.get('job','denied_ui'))
assert(#workers==0 and #timers==0 and next(wire.server.api.getPending())==nil and next(wire.client.api.getPending())==nil)
assert(sr.core.ProducerCore==producer and sr.core.LegacyCore==legacy and sr.core.WorkMenus.Menu==holder.Menu)
print('PASS work menus composition: same 22 Shared/controller + 23 replica/24 real consumers, actual local server catalog/Player/finance/business/protection and installed PR RPC/context; hierarchy/back/create/edit/grade/boss/MEI/denial and inherited stale payload/field loss in memory, future panel providers explicit; no real NUI/SQL/resource effects')

