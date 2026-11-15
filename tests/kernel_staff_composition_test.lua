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

local Q=dofile('tests/kernel_staff_harness.lua')
local work=A.compose(sr.core,{client=holder,library=ui.library,translate=ui.translate,config=ui.config,native=ui.native,integrations=ui.integrations})
-- Only the fixture's documented future-consumer double is removed.
holder.Menu.openStaffMenu=nil
local staffConfig=Q.config(true);ui.config.Staff=staffConfig
local graph={trace={},timers={},ids={[1]={'license:player'},[2]={'license:admin'}},online={'1','2'},
    configFiles={},prCallbacks={},record=ui.record,adminConvar='',catalogConvar=''}
Q.graph(graph)
local ace=Q.aceProvider(graph,p.lookup)
-- A poison legacy field proves the new composition cannot silently pick a framework-cycling provider.
library.ace={isPlayerAceAllowed=function()error('unsafe implicit library.ace binding')end,getPermissionCatalog=function()error('unsafe catalog binding')end}
library.db={query=function(sql)assert(sql=='SELECT citizenid FROM players');return{{citizenid='PLAYER'},{citizenid='UIADMIN'},{citizenid='OFFLINE'}}end}
local serverPorts={config=staffConfig,library=library,aceIntegration=ace,native=graph.native,translate=function(k)return k end,
    adminAce='forge-core.admin',notifyPosition='top-right'}
local core=H.load('kernel/server/staff/staff_core.lua',Q.env())(base,serverPorts)
local menus=H.load('kernel/client/menu/staff_core.lua',Q.env())(sr.core,{client=holder,config=ui.config,native=ui.native})
assert(base.StaffCore==core and catalog.Dependencies.StaffService==core.Service and core.Security==transport.Security)
assert(menus.Menu==work.Menu and menus.Shared==work.Shared and menus.State==sr.core)
for _,event in ipairs(ui.trace)do assert(event.kind~='execute'and event.kind~='timer','constructors cannot change ACL or start timers')end
assert(not pcall(H.load('kernel/server/staff/staff_core.lua',Q.env()),base,serverPorts))
assert(not pcall(H.load('kernel/client/menu/staff_core.lua',Q.env()),sr.core,{}))
local foreign={WorkMenus=work,AdministrationMenus=administration,JobClientCore=clientCore}
assert(not pcall(H.load('kernel/client/menu/staff_core.lua',Q.env()),foreign,{}))
for _,entry in ipairs(core.Callbacks)do
    assert(entry.options.access=='admin')
    transport.Security.register(entry.name,entry.handler,entry.options)
end
for name,handler in pairs(menus.Callbacks)do wire.client.api.register(name,handler)end
native.isAceAllowed=function(src,name)return src==2 or graph.allowed(src,name)end
p.api.CheckPlayerData(2,{citizenid='UIADMIN',license='license:admin',userId=102,charinfo={firstname='UI',lastname='Admin'}})
p.api.CheckPlayerData(1,{citizenid='PLAYER',license='license:player',userId=101,charinfo={firstname='Player',lastname='One'}})
local player=p.lookup.GetPlayer(1)
p.offline.OFFLINE=H.copy(player.PlayerData);p.offline.OFFLINE.source=nil;p.offline.OFFLINE.citizenid='OFFLINE'
wire.playerSource=1
local function rpc(key,...)
    return wire.client.api.request(staffConfig.Callbacks[key],nil,nil,10000,...)
end
local function current()
    local frame=context.frames[#context.frames];assert(frame and frame.name=='context:open');return frame.data.id
end
local function choose(index)context.api.HandleSelect(current(),index)end
local ok,reason=rpc('add',{source=1,permissions={'group.admin'}})
assert(not ok and reason=='no_permission'and player.PlayerData.metadata.staff==nil,'actual Security denies self-grant')
graph.adminConvar='"citizenid:player"'
assert(core.Service.canManage(1),'installed PR ACE identifies the local canonical player')
ok,reason=rpc('getAll');assert(not ok and reason=='no_permission','PR whitelist alone does not bypass existing JobService-based callback policy')
graph.adminConvar=''
-- Actual inherited start applies only the simulated graph; no OS command or permission API is called.
assert(core.Service.start()and core.Service.start())
assert(#graph.timers==1)
local startup=graph.timers;graph.timers={};startup[1].fn()
wire.playerSource=2
local command
for _,entry in ipairs(core.Commands)do if entry.name==staffConfig.Commands.menu then command=entry end end
assert(command and command.options.canAccess(2))
work.Menu.openMain()
command.handler(2)
assert(current()=='forge_core_staff','actual command -> PR RPC -> actual client callback/menu')
-- Root menu grant via actual forms/checkbox -> protected RPC -> same Player + simulated native ACL graph.
choose(1)
-- Use discovered real PR catalog index instead of assuming sorting/provider order.
local actualCatalog=core.Service.getPermissionCatalog()
local answers={1}
local adminIndex
for index,entry in ipairs(actualCatalog)do answers[index+1]=entry.value=='group.admin';if entry.value=='group.admin'then adminIndex=index end end
assert(adminIndex)
ui.inputs={{1},answers}
menus.Menu.openStaffAddById()
assert(player.PlayerData.metadata.staff.version==2 and player.PlayerData.metadata.staff.permissions[1]=='group.admin')
assert(graph.allowed(1,'forge-core.admin')and graph.allowed(1,'command.car'),'grant reaches stable inherited principal graph')
assert(player.PlayerData.metadata.optin==true)
assert(p.saveAttempts>0,'actual Player Save invoked')
ui.runTimers(500);assert(current()=='forge_core_staff_list')
choose(1);assert(current():find('forge_core_staff_details_',1,true))
context.api.HandleBack(current());assert(current()=='forge_core_staff_list')
context.api.HandleBack(current());assert(current()=='forge_core_staff')
context.api.HandleBack(current());assert(current()=='forge_core_main')
-- Actor 1 now has real graph authority and same callback Security sees it.
wire.playerSource=1
ok,reason=rpc('getAll');assert(ok)
wire.playerSource=2
local grantsBefore=graph.allowed(1,'forge-core.admin')
assert(grantsBefore)
ok,reason=rpc('add',{source=1,permissions={'group.mod'}});assert(ok)
assert(not graph.allowed(1,'forge-core.admin')and graph.allowed(1,'group.mod'))
assert(player.PlayerData.metadata.staff.permissions[1]=='group.mod'and player.PlayerData.metadata.optin)
ok=rpc('remove',{source=1});assert(ok)
assert(player.PlayerData.metadata.staff==nil and not graph.allowed(1,'group.mod')and not player.PlayerData.metadata.optin)
-- Offline uses actual GetOfflinePlayer/SaveOffline on the same storage fixture, not a second player cache.
local savedBefore=p.saveAttempts
ok,reason=rpc('add',{citizenid='OFFLINE',permissions={'group.support'}})
assert(ok and reason.offline and p.saveAttempts>savedBefore)
local savedOffline
for _,entry in ipairs(p.trace)do if entry.kind=='upsert'and entry.args[1].playerEntity.citizenid=='OFFLINE'then savedOffline=entry.args[1].playerEntity end end
assert(savedOffline and savedOffline.metadata.staff.permissions[1]=='group.support')
-- New ACL apply failure preserves old metadata while leaving effects partially applied.
assert(core.Service.add(2,{source=1,permissions={'group.mod'}}))
local execute=graph.native.execute
graph.native.execute=function(text)
    if text:find('group.mod',1,true)and text:find('remove_principal',1,true)then return execute(text)end
    ui.record('simulated-refused-execute',text)
end
ok,reason=rpc('add',{source=1,permissions={'pr_bridge.developer'}})
assert(not ok and reason:find('ace_apply_failed',1,true))
assert(player.PlayerData.metadata.staff.permissions[1]=='group.mod'and not graph.allowed(1,'group.mod'),'partial ACL changes do not roll back')
graph.native.execute=execute
-- Explicit login migration keeps the same Player and inherited optin behavior.
player.PlayerData.metadata.staff='group.mod';player.PlayerData.metadata.optin=false
assert(core.Service.applyPlayer(1))
assert(player.PlayerData.metadata.staff.version==2 and player.PlayerData.metadata.optin==false)
local diagnostics=core.Service.permissionDiagnostics(1);assert(#diagnostics>0)
local beforeGraph=P.snapshot({graph.parents,graph.aces})
for _,entry in ipairs(core.Commands)do if entry.name=='forgeace'then entry.handler(2,{'status','1'});entry.handler(2,{'apply','1'})end end
H.same(P.snapshot({graph.parents,graph.aces}),beforeGraph,'forgeace cannot mutate permissions')
assert(next(wire.server.api.getPending())==nil and next(wire.client.api.getPending())==nil)
assert(#workers==0 and #timers==0 and base.PlayerCore.Lookup.GetPlayer(1)==player)
print('PASS staff composition: same Player/Lookup/Groups/JobService/Security/Menu, actual PR RPC/context/ACE catalog+queries with explicitly injected local identity, simulated ACL graph; denied self-grant/whitelist-policy mismatch, command/UI add/change/revoke/offline save/back/login/diagnostics and inherited partial failure; safe PR ACE binder still pending, no real grants/SQL/boot')

