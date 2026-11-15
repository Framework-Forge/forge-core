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
local group=B.group();group.stashes[1].stash.webhook='';group.grades['4'].payment=100
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
local refresh={points=0,business=0}
local holder={}
-- Full client Points/Business and central menu openMain remain future modules: explicit consumers only.
holder.JobPoints={refresh=function(payload)assert(type(payload.jobs)=='table');refresh.points=refresh.points+1;flow[#flow+1]='points'end}
holder.JobBusiness={refresh=function(payload)assert(type(payload.gangs)=='table');refresh.business=refresh.business+1;flow[#flow+1]='business'end}
local opens,openReturn=0,false
local controller={openMain=function()opens=opens+1;flow[#flow+1]='open';return openReturn end}
holder.Menu=controller
local clientLibrary={debug={info=function()end,setEnabled=function(enabled)assert(enabled==true)end},
    callback={await=function(name,timeout,...)return wire.client.api.request(name,nil,nil,timeout,...)end}}
local ports={client=holder,config=config,library=clientLibrary,translate=function(key)return key end,
    wait=function(ms)return coroutine.yield(ms)end,debugEnabled=true}
local before={files=#m.trace,trace=#p.trace,wire=#wire.trace,timers=#wire.timers,flow=#flow}
clientCore=C.compose(sr.core,ports)
assert(clientCore.State==sr.core and sr.core.JobClientCore==clientCore and holder.JobState==clientCore.JobState)
assert(sr.core.ProducerCore==producer and sr.core.LegacyCore==legacy and sr.core.PlayerData==dataBefore)
assert(#m.trace==before.files and #p.trace==before.trace and #wire.trace==before.wire and #wire.timers==before.timers and #flow==before.flow)
assert(pulls==0 and not service.started and refresh.points==0 and refresh.business==0 and opens==0)
assert(not pcall(C.compose,sr.core,ports),'duplicate replica refused')
local foreign={ProducerCore={State=sr.core},LegacyCore=legacy}
assert(not pcall(C.compose,foreign,ports),'foreign canonical state refused')
local foreignMenus={ProducerCore={},LegacyCore={},AdministrationMenus={Menu={}}}
foreignMenus.ProducerCore.State,foreignMenus.LegacyCore.State=foreignMenus,foreignMenus
assert(not pcall(C.compose,foreignMenus,ports),'foreign menu controller refused')
for name,handler in pairs(clientCore.Main.Callbacks)do wire.client.api.register(name,handler)end
finance.Payments.load()
-- First worker is a declaration, not automatic initialization. Real PR RPC invokes the private server handlers.
local co=coroutine.create(clientCore.Bootstrap.Threads[1])
local ok,ms=coroutine.resume(co);assert(ok and ms==1500 and not service.started and #wire.trace==before.wire)
assert(coroutine.resume(co));assert(coroutine.status(co)=='dead')
assert(service.started and groups.GetJob('police')and clientCore.JobState.jobs[1],table.concat(diagnostics,'\n'))
assert(clientCore.JobState.jobs[1].name=='police')
assert(clientCore.JobState.canManage==false and refresh.points>0 and refresh.points==refresh.business)
assert(clientCore.JobState.jobs[1].stashes[1].stash.password=='pw','inherited non-admin getAll reveals private point data')
assert(sr.core.PlayerData==dataBefore and dataBefore.job.name=='taxi','replica is not PlayerData authority')
assert(pulls==0 and sr.core.LegacyCore.Groups==legacy.Groups,'separate static group bootstrap not silently requested')
assert(#wire.server.api.getPending()==0 and next(wire.client.api.getPending())==nil)
-- Client request receives payload,canManage, not bool,payload. No endpoint installation occurs in production.
wire.playerSource=2
assert(clientCore.JobState.request()==clientCore.JobState and clientCore.JobState.canManage)
local function command()
    for _,entry in ipairs(transport.Commands.Commands)do if entry.name==config.Commands.jobs then return entry.handler end end
    error('Missing jobs command')
end
flow={};local openBefore=opens
command()(2)
H.same(flow,{'sync','points','business','request-menu','open'},'command sends replica before menu callback')
assert(opens==openBefore+1 and wire.timers[#wire.timers].ms==5000)
assert(wire.trace[#wire.trace].kind=='reply')
local ack=wire.server.api.request(config.Callbacks.openMenu,2,nil,5000)
assert(ack==true and openReturn==false,'legacy callback acknowledges despite openMain returning false')
-- Admin save callback and server services are real private bodies; all storage/providers below are in memory.
wire.playerSource=2
local saved=wire.client.api.request(config.Callbacks.saveGroup,nil,nil,10000,
    {type='job',name='client_job',label='Client Job',grades={['0']={name='Member'}}})
assert(saved and groups.GetJob('client_job')and catalog.Registry.get('job','client_job'))
local found=false
for _,job in ipairs(clientCore.JobState.jobs)do if job.name=='client_job'then found=true end end
assert(found and clientCore.JobState.canManage,'broadcast keeps previous administrative flag')
admin=false;flow={};openBefore=opens
command()(2);assert(opens==openBefore and #flow==0,'server permission check denies command before sync/request')
service.sendTo(2);assert(clientCore.JobState.canManage,'ordinary sync does not revoke obsolete admin flag')
clientCore.JobState.request();assert(not clientCore.JobState.canManage,'only explicit request refreshes permission')
holder.Menu=nil
assert(wire.server.api.request(config.Callbacks.openMenu,2,nil,5000)==false,'missing central controller yields false')
holder.Menu=controller
assert(wire.server.api.request(config.Callbacks.openMenu,2,nil,5000)==true,'dynamic late controller binding')
assert(base.PlayerCore.State==p.core and catalog.Dependencies.JobPayments==finance.Payments
    and catalog.Dependencies.JobBusiness==business.Business and catalog.Dependencies.JobPoints==business.Points)
assert(#workers==0 and #timers==0,'no real server workers or timers started')
assert(sr.core.PlayerData==dataBefore and next(wire.server.api.getPending())==nil and next(wire.client.api.getPending())==nil)
print('PASS client jobs composition: canonical producer/legacy/replica, full service/catalog/payments/business and installed PR RPC under simulated wire; bootstrap1500, payload/permission, sync-before-menu, denied command, stale-admin and sensitive payload retained; future central menu/Points/Business consumers explicit doubles')

