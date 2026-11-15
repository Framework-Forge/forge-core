local T=dofile('tests/kernel_transport_harness.lua')
local S=dofile('tests/kernel_job_service_harness.lua')
local F=dofile('tests/kernel_finance_harness.lua')
local L=dofile('tests/kernel_lifecycle_harness.lua')
local H,P,J,B=T.H,T.P,T.J,T.B
local p=P.new(true)
p.core.Player_Buckets,p.core.Entity_Buckets,p.core.UsableItems={},{},{}
local groups=H.load('kernel/server/groups.lua',H.environment())({jobs=p.groupData.jobs,gangs=p.groupData.gangs,
    emitServer=p.platform.emitServer,emitClient=p.platform.emitClient,saveGroups=function()error('No legacy writes')end,logError=function()end})
local l=L.new(true);l.bindings.core,l.bindings.lookup,l.bindings.players,l.bindings.groups=p.core,p.lookup,p.api,groups
l.bindings.native.isAceAllowed=function(src)return tonumber(src)==2 end
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
local clock,ping,caller=1000,50,'pr_bridge'
local timers,workers,events,replies,sent={},{},{},{},{}
local sequence=0
local function addEvent(name,handler)
    sequence=sequence+1;local entry={id=sequence,handler=handler,name=name};events[#events+1]=entry;return sequence
end
local rpcEnv=H.environment({source=0,GetCurrentResourceName=function()return'forge-core'end,
    GetGameTimer=function()return clock end,RegisterNetEvent=function(name,handler)if handler then return addEvent(name,handler)end end,
    AddEventHandler=addEvent,RemoveEventHandler=function(id)for _,v in ipairs(events)do if v.id==id then v.removed=true end end end,
    SetTimeout=function(ms,fn)timers[#timers+1]={ms=ms,fn=fn}end,promise={new=function()
        local pending={};function pending:resolve(value)self.value=value end;function pending:reject(reason)self.error=reason end;return pending
    end},Citizen={Await=function(promise)
        while promise.value==nil and promise.error==nil do coroutine.yield('await-rpc')end
        if promise.error then error(promise.error,0)end;return promise.value
    end}})
local rpc=H.load('../pr_bridge/bridge/callback/transport.lua',rpcEnv)({server=true,timeout=5000,rejectErrors=false,
    responseEvent='fixture:response',requestEvent=function(name)return'fixture:request:'..name end,
    acceptResponse=function(src,target)return tonumber(src)==tonumber(target)end,
    parseRequest=function(owner,key,...)return owner,key,table.pack(...)end,
    acceptRequest=function(src,owner,key)return tonumber(src)>0 and owner=='fixture-client'and type(key)=='string'end,
    reply=function(src,owner,key,...)replies[#replies+1]={source=src,owner=owner,key=key,values=table.pack(...)}end,
    send=function(name,target,key,...)sent[#sent+1]={name=name,target=target,key=key,args=table.pack(...)}end})
library.callback={register=rpc.register,await=function(src,name,timeout,...)return rpc.request(name,src,nil,timeout,...)end}
local native={getPlayers=function()return {'1'}end,isAceAllowed=function(src)return tonumber(src)==2 end,
    isPlayerAceAllowed=function(src)return tonumber(src)==2 end,getInvokingResource=function()return caller end,
    isPrincipalAceAllowed=function(principal,ace)return principal=='resource.allowed'and ace=='forge-core.compat'end,
    emitClient=p.platform.emitClient,getSource=function()return rpcEnv.source end,
    setTimeout=function(ms,fn)timers[#timers+1]={ms=ms,fn=fn}end,spawn=function(fn)workers[#workers+1]=fn end,
    wait=function()error('No workers should be run')end,getIdentifier=function()return'license:test'end,
    execute=function()error('No ACE mutation expected')end,print=function()end,getGameTimer=function()return clock end,
    getPlayerPing=function()return ping end,getPlayerName=function()return'Test'end,getPed=function(src)return src end,
    getCoords=function()return B.vector(1,2,3)end,emit=function()end,listen=addEvent}
local config=J.config(true).config
local group=B.group();group.stashes[1].stash.webhook='';group.grades['4'].payment=100
m.seed(config.Storage.jobsFile,{police=group});m.seed(config.Storage.gangsFile,{})
local catalog=J.composition(base,{config=config,library=library,translate=function(key)return key end})
local service=S.compose(base,{library=library,translate=function(key)return key end,dependencies={},native=native,time=function()return clock end})
local integrations={inventoryReady=function()return true end,removeInventoryHooks=function()end,
    httpRequest=function()error('No real HTTP')end,applyPlayerInventoryBonus=function()return true end}
local finance=F.compose(base,{library=library,translate=function(key)return key end,native=native,integrations=integrations,time=function()return clock end,resource='forge-core'})
local business=B.compose(base,{library=library,json=m.codec,translate=function(key)return key end,native=native,integrations=integrations,time=function()return clock end})
local customCalls=0
catalog.Dependencies.InventoryService={addCompatibilityItems=function()customCalls=customCalls+1;return true,1 end,reload=function()customCalls=customCalls+1;return true end}
local counts={events=#events,trace=#p.trace,files=#m.trace,timers=#timers,workers=#workers}
local ports={library=library,native=native,json=m.codec,config={AdminAce='forge-core.admin'},translate=function(key)return key end,time=function()return clock end}
local transport=T.compose(base,ports)
assert(#events==counts.events and #p.trace==counts.trace and #m.trace==counts.files and #timers==counts.timers and #workers==counts.workers)
assert(base.Callbacks==transport.Security and catalog.Transport==transport and #transport.Callbacks==23 and #transport.Commands.Commands==3)
assert(not pcall(T.compose,base,ports),'duplicate attachment must fail')
-- Explicit isolated registration only after the constructor checks; real PR RPC engine, simulated network.
for _,entry in ipairs(transport.Callbacks)do transport.Security.register(entry.name,entry.handler,entry.options)end
for _,entry in ipairs(transport.Security.Events)do addEvent(entry.name,entry.handler)end
local function dispatch(name,src,...)
    rpcEnv.source=src;local snapshot={};for _,v in ipairs(events)do snapshot[#snapshot+1]=v end
    for _,v in ipairs(snapshot)do if not v.removed and v.name==name then v.handler(...)end end
end
local requestId=0
local function request(key,src,...)
    requestId=requestId+1;local before=#replies
    dispatch('fixture:request:'..config.Callbacks[key],src,'fixture-client','request:'..requestId,...)
    assert(#replies==before+1,'one RPC reply');local reply=replies[#replies];assert(reply.source==src)
    return table.unpack(reply.values,1,reply.values.n)
end
finance.Payments.load()
local payload,allowed=request('getAll',1)
assert(allowed==false and payload.jobs[1].stashes[1].stash.password=='pw','inherited public sensitive payload reproduced')
assert(service.started and groups.GetJob('police'))
p.api.CheckPlayerData(1,{citizenid='WIRE',license='license:test',userId=101,charinfo={firstname='Wire',lastname='Test'}})
assert(p.api.SetJob(1,'police',4));local online=p.lookup.GetPlayer(1)
local ok,err=request('saveGroup',1,{name='denied',grades={}});assert(not ok and err=='no_permission'and not catalog.Registry.jobs.denied)
ok=request('saveGroup',2,{name='admin_job',label='Admin',grades={['0']={name='Member'}}});assert(ok and groups.GetJob('admin_job'))
assert(request('openStash',1,'job','police','main_desk','pw'))
local duty=online.PlayerData.job.onduty
assert(request('toggleDuty',1,'police','main_desk'));assert(online.PlayerData.job.onduty==(not duty))
p.api.SetJobDuty(1,true)
assert(request('supplyShop',1,'job','police','main_desk','supplies','burger',3,20));assert(items.burger==17)
ok,err=request('registerAction',1,'job','police','main_desk','cash','withdraw',200);assert(not ok and err=='register_money_missing')
assert(request('submitApplication',1,'job','police','main_desk','join',{'yes',2}))
assert(request('hirePlayer',1,'job','police','WIRE',2));assert(online.PlayerData.jobs.police==2)
assert(request('setEmployeeGrade',2,'job','police','WIRE',4));assert(online.PlayerData.jobs.police==4)
for i=1,15 do request('getAll',3)end;ok,err=request('getAll',3);assert(not ok and err=='rate_limited')
ping=0;ok,err=request('getAll',1);assert(not ok and err=='invalid_player');ping=50
local oldBytes=m.files[config.Storage.jobsFile]
m.onWrite=function(path,bytes)if path==config.Storage.jobsFile and bytes~=oldBytes then return false end;return true end
ok=request('supplyShop',1,'job','police','main_desk','supplies','burger',2,20);assert(ok==false and items.burger==15)
assert(catalog.Registry.get('job','police').stashes[1].shops[1].stock.burger==13,'inherited item loss, catalog unchanged')
m.onWrite=nil
local facade=transport.Compat
caller='denied';assert(not pcall(facade.CompatTogglePaycheck,1,false));caller='allowed';assert(facade.CompatTogglePaycheck(1,false))
p.api.SetJobDuty(1,true) -- changing primary job grade reapplies the installed off-duty default
local paid=finance.Payments.processAll('test');assert(paid==0,'same local Player paycheck metadata gate')
assert(facade.CompatTogglePaycheck(1,true));paid=finance.Payments.processAll('test');assert(paid==1,
    'payroll fixture state: '..tostring(online.PlayerData.job.name)..'/'..tostring(online.PlayerData.job.grade.level)..'/'..tostring(online.PlayerData.job.onduty)..'/'..tostring(finance.Payments.getSettings().enabled))
caller='pr_bridge';assert(facade.CompatCreateJob({name='police',label='Ignored',grades={{grade=5,name='Chief+',salary=100}}}))
assert(groups.GetJob('police').grades[5]and catalog.Registry.get('job','police').stashes[1].stash.password=='pw')
assert(facade.CompatAddItems({{name='fixture'}}));assert(facade.CompatRefreshItems()==2 and customCalls==2,'custom inventory service remains explicit double')
-- Actual PR RPC preserves captured player ownership: a response from a different target is ignored.
local function menuCommand()
    for _,v in ipairs(transport.Commands.Commands)do if v.name==config.Commands.jobs then return v end end
end
local co=coroutine.create(function()return menuCommand().handler(2)end)
local resumed,value=coroutine.resume(co);assert(resumed and value=='await-rpc')
local outgoing=sent[#sent];assert(outgoing.target==2 and outgoing.name==config.Callbacks.openMenu and timers[#timers].ms==5000)
dispatch('fixture:response',1,outgoing.key,true);assert(rpc.getPending()[outgoing.key])
dispatch('fixture:response',2,outgoing.key,nil,false,'done',nil);assert(not rpc.getPending()[outgoing.key]);assert(coroutine.resume(co))
local a,b,c,d
co=coroutine.create(function()a,b,c,d=rpc.request('nil-slots',1,nil,25)end);assert(coroutine.resume(co));outgoing=sent[#sent]
dispatch('fixture:response',1,outgoing.key,nil,false,'tail',nil);assert(coroutine.resume(co));assert(a==nil and b==false and c=='tail'and d==nil)
co=coroutine.create(function()a,b=rpc.request('timeout',1,nil,25)end);assert(coroutine.resume(co));timers[#timers].fn();assert(coroutine.resume(co));assert(a==nil and b=='timeout')
local before=#replies;dispatch('fixture:request:'..config.Callbacks.getAll,1,'wrong-owner','forged');assert(#replies==before)
dispatch('playerDropped',1);assert(not transport.Security.buckets['1:'..config.Callbacks.getAll])
dispatch('onResourceStop',0,'forge-core');before=#replies
dispatch('fixture:request:'..config.Callbacks.getAll,1,'fixture-client','after-stop');assert(#replies==before)
assert(base.PlayerCore.State.Players[1]==online and catalog.Dependencies.JobPayments==finance.Payments and catalog.Dependencies.JobBusiness==business.Business)
assert(#workers==0,'no payroll/expiry worker activation')
print('PASS transport composition: canonical services/Player/paycheck and PR persistence, exact PR RPC ownership/nil/timeout/drop/stop under simulated wire; protected callbacks/commands/compat not installed in live runtime, sensitive payload and item-loss risks retained')
