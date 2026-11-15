local B=dofile('tests/kernel_business_harness.lua')
local S=dofile('tests/kernel_job_service_harness.lua')
local L=dofile('tests/kernel_lifecycle_harness.lua')
local H,P,J=B.H,B.P,B.J
local p=P.new(true)
local groups=H.load('kernel/server/groups.lua',H.environment())({jobs=p.groupData.jobs,gangs=p.groupData.gangs,
    emitServer=p.platform.emitServer,emitClient=p.platform.emitClient,
    saveGroups=function()error('No legacy Lua writes')end,logError=function()error('Unexpected Groups error')end})
local m=J.persistence();local library={};for k,v in pairs(m.api)do library[k]=v end
local sql={}
local db={query={await=function(query,args)
    sql[#sql+1]={query,args};return {{citizenid='BIZ',grade=4},{citizenid='OFFLINE',grade='2'}}
end}}
local storage=H.load('kernel/server/storage.lua',H.environment())({db=db,json=m.codec,vec4=P.vector,
    characterDataTables={},defaultSpawn=P.vector(0,0,0,0),log={},warn=function()end,emitServer=p.platform.emitServer,
    addPlayerToJob=p.api.AddPlayerToJob,addPlayerToGang=p.api.AddPlayerToGang,
    groups={GetJob=groups.GetJob,GetGang=groups.GetGang,GroupType={JOB='job',GANG='gang'}},date=function()return'fixture'end})
local lifecycle=L.new(true)
p.core.Player_Buckets,p.core.Entity_Buckets,p.core.UsableItems={},{},{}
local bindings=lifecycle.bindings
bindings.core,bindings.storage,bindings.lookup,bindings.players,bindings.groups=p.core,storage,p.lookup,p.api,groups
local functions=H.load('kernel/server/functions.lua',H.environment())(bindings)
local base={Groups=groups,PlayerCore={Groups=groups,State=p.core,Lookup=p.lookup,Players=p.api,
    Lifecycle={Functions=functions},Storage=storage}}
library.utils=H.load('../pr_bridge/bridge/utils/shared.lua',H.environment())
library.table=H.load('../pr_bridge/bridge/utils/tables.lua',H.environment())
library.math=H.load('../pr_bridge/bridge/utils/numbers.lua',B.environment())
library.notify={NotifyPlayer=function()end}
local bank,money,stock=0,1000,20
local shops,stashes,listeners,timers,exported={},{},{},{},{}
local owner,rejectBuy='forge-core',false
local function listen(name,fn)listeners[name]=listeners[name]or{};table.insert(listeners[name],fn)end
local function emit(name,...)for _,fn in ipairs(listeners[name]or{})do fn(...)end end
-- Exact installed custom OX hooks. Callable tables simulate only the Cfx function-reference representation.
local trigger=H.load('../../../[ox]/ox_inventory/modules/hooks/server.lua',H.environment({
    pr_lib={cache={resource='forge-core'}},os={microtime=function()return 1 end},
    shared={info=function()end},server={loghookrejection=false},warn=function()end,
    exports=function(name,fn)exported[name]=fn end,GetInvokingResource=function()return owner end,
    AddEventHandler=listen,TriggerEvent=emit,SetTimeout=function(ms,fn)assert(ms==50);timers[#timers+1]=fn end}))
local function register(event,callback,options)
    local ref=setmetatable({},{__call=function(_,payload)
        if event=='buyItem'and rejectBuy then return false end
        return callback(payload)
    end})
    return exported.registerHook(event,ref,options)
end
library.inventory={RegisterHook=register,
    RegisterStash=function(id,...)stashes[id]=table.pack(...)end,
    RegisterShop=function(id,data)shops[id]=data;return true end,
    HasItem=function()return true end,forceOpenInventory=function()return false end,
    GetItemLabel=function(name)return name end,GetItemCount=function()return stock end,
    GetInventoryItems=function()return {{name='burger',count=stock}}end,
    RemoveItem=function(_,name,count)if name=='money'then money=money-count else stock=stock-count end;return true end,
    AddItem=function(_,name,count)assert(name=='money');money=money+count;return true end}
library.banking={EnsureJobAccount=function()return true end,
    AddJobAccountBalance=function(_,amount)bank=bank+amount;return true end,RecordJobTransaction=function()return true end}
library.database={single=function(query,args)
    assert(query=='SELECT charinfo FROM players WHERE citizenid = ?'and args[1]=='OFFLINE')
    sql[#sql+1]={query,args};return {charinfo=m.codec.encode({firstname='Off',lastname='Line'})}
    end,query=function()return {}end,transaction=function()return true end}
local config=J.config(true).config
local catalog=J.composition(base,{config=config,library=library,translate=function(key)return key end})
local native={getPlayers=function()return {'1'}end,isAceAllowed=function()return true end,
    emitClient=p.platform.emitClient,getSource=function()return 1 end,setTimeout=function()error('No scheduling expected')end,
    getPlayerName=function()return'Test'end,getIdentifier=function()return'discord:1'end,
    getPed=function(src)return src end,getCoords=function()return B.vector(1,2,3)end,
    emit=emit,listen=listen,print=function()end}
local service=S.compose(base,{library=library,translate=function(key)return key end,dependencies={},native=native,time=function()return 1000 end})
local before=#p.trace
local business=B.compose(base,{library=library,json=m.codec,translate=function(key)return key end,native=native,
    integrations={inventoryReady=function()return true end,removeInventoryHooks=exported.removeHooks,
        httpRequest=function()error('No webhook request expected')end},time=function()return 1000 end})
assert(#p.trace==before and #sql==0 and #m.trace==0 and next(shops)==nil and next(stashes)==nil and #timers==0)
assert(catalog.Dependencies.JobBusiness==business.Business and catalog.Dependencies.JobPoints==business.Points)
assert(not pcall(B.compose,base,{}),'duplicate attachment refused')
local group=B.group();group.stashes[1].stash.webhook=''
assert(service.upsert(0,group,'job'));assert(groups.GetJob('police')and shops.forge_core_job_police_main_desk_supplies_group)
p.api.CheckPlayerData(1,{citizenid='BIZ',license='license:test',userId=101,charinfo={firstname='Ana',lastname='Teste'}})
assert(p.api.SetJob(1,'police',4));local online=p.lookup.GetPlayer(1)
local duty=online.PlayerData.job.onduty
local ok,newDuty=business.Points.toggleDuty(1,'police','main_desk');assert(ok and newDuty==(not duty)and online.PlayerData.job.onduty==(not duty))
assert(business.Points.openStash(1,'job','police','main_desk','pw')) -- inherited false force-open result ignored
assert(business.Business.hirePlayer(0,'job','police','BIZ',2));assert(online.PlayerData.jobs.police==2)
assert(business.Business.setEmployeeGrade(0,'job','police','BIZ',4));assert(online.PlayerData.jobs.police==4)
local members;ok,members=business.Business.getEmployees(0,'job','police')
assert(ok and #members==2 and members[1].name=='Ana Teste'and members[2].name=='Off Line')
assert(sql[1][1]=='SELECT citizenid, grade FROM player_groups WHERE `group` = ? AND `type` = ?')
assert(sql[1][2][1]=='police'and sql[1][2][2]=='job'and #sql==2,'local Functions -> Storage query, narrow offline name query')
local setter=p.api.SetJobDuty
p.api.SetJobDuty=function()return false end;ok=business.Points.toggleDuty(1,'police','main_desk');assert(ok==false);p.api.SetJobDuty=setter
local function finish(success,errorAfter)
    local payload={source=1,shopType='forge_core_job_police_main_desk_supplies_group',itemName='burger',count=2,totalPrice=30}
    local ran=pcall(function()
        local result <close> = trigger('buyItem',payload)
        assert((result.success==true)==success)
        if errorAfter then error('fixture purchase abort')end
    end)
    assert(ran~=errorAfter)
    local pending=timers;timers={};for _,fn in ipairs(pending)do fn()end
    assert(payload.hookId==nil,'custom post event clears hookId')
end
rejectBuy=true;finish(false,false);assert(bank==0 and catalog.Registry.get('job','police').stashes[1].shops[1].stock.burger==10)
rejectBuy=false;finish(true,true);assert(bank==0,'unwind abort reports failure, not revenue')
finish(true,false);assert(bank==30 and catalog.Registry.get('job','police').stashes[1].shops[1].stock.burger==8)
assert(m.codec.decode(m.files[config.Storage.jobsFile]).police.stashes[1].shops[1].stock.burger==8)
local hook=business.Business.purchaseHookId;owner='other-resource';exported.removeHooks(hook);owner='forge-core'
finish(true,false);assert(bank==60)
exported.removeHooks(hook);local old=bank;finish(true,false);assert(bank==old)
local oldBytes=m.files[config.Storage.jobsFile]
m.onWrite=function(path,bytes)if path==config.Storage.jobsFile and bytes~=oldBytes then return false end;return true end
ok=business.Business.supplyShop(1,'job','police','main_desk','supplies','burger',3,15)
assert(ok==false and stock==17 and catalog.Registry.get('job','police').stashes[1].shops[1].stock.burger==6)
assert(not business.Business.registerAction(1,'job','police','main_desk','cash','withdraw',25))
assert(money==1025 and catalog.Registry.get('job','police').stashes[1].registers[1].balance==100)
emit('onResourceStop','forge-core');finish(true,false);assert(bank==old)
m.onWrite=nil
assert(service.upsert(0,B.group('ballas','gang'),'gang'))
assert(business.Business.hirePlayer(0,'gang','ballas','BIZ',2));assert(online.PlayerData.gangs.ballas==2)
assert(business.Business.setEmployeeGrade(0,'gang','ballas','BIZ',4));assert(online.PlayerData.gangs.ballas==4)
assert(business.Business.fireEmployee(0,'gang','ballas','BIZ'));assert(online.PlayerData.gangs.ballas==nil)
assert(business.Business.fireEmployee(0,'job','police','BIZ'));assert(online.PlayerData.jobs.police==nil)
assert(base.PlayerCore.State.Players[1]==online and catalog.Registry==base.JobCatalog.Registry)
-- Narrow wrapper contract checks: strict success and pcall exceptions, without loading another Player service.
for _,variant in ipairs({'nil','false','throw','true'})do
    local localGroups={};local localRegistry=J.new(true,'registry').api;localRegistry.setAll({police=B.group()}, {})
    local localPlayers={SetJobDuty=function()return nil end}
    for _,name in ipairs({'AddPlayerToJob','AddPlayerToGang','RemovePlayerFromJob','RemovePlayerFromGang'})do
        localPlayers[name]=function(id,groupName,grade)
            assert(id=='C'and groupName=='police'and (not name:match('^Add')or grade==2))
            if variant=='throw'then error({code='denied'},0)end
            if variant=='nil'then return nil elseif variant=='false'then return false,{code='denied'}end
            return true
        end
    end
    local localBase={Groups=localGroups,PlayerCore={Groups=localGroups,Lookup={GetPlayer=function()return nil end,
        GetPlayerByCitizenId=function()return nil end},Players=localPlayers,Lifecycle={Functions={GetGroupMembers=function()return {}end}}},
        JobCatalog={Groups=localGroups,Registry=localRegistry,Config=config,Dependencies={},Service={canManage=function()return true end}}}
    local attached=B.compose(localBase,{library=library,json=m.codec,native=native,integrations={},translate=function(key)return key end,time=function()return 1 end})
    local accepted=attached.Business.hirePlayer(0,'job','police','C','2');assert(accepted==(variant=='true'))
    accepted=attached.Business.fireEmployee(0,'job','police','C');assert(accepted==(variant=='true'))
end
print('PASS business composition: canonical Player/Groups/Service/Registry, local membership/duty/Functions/Storage, exact custom OX hook close/post/ownership/stop protocol, PR persistence failure paths; external effects simulated')
