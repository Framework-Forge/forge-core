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
assert(core.Base==base and core.PlayerCore==pcGuard and core.Groups==groups)
assert(core.Security==transport.Security and catalog.Dependencies.SkillService==core.Service)
assert(not core.Service.started and not core.Service.schemaReady and #writes==0 and #workers==0)
assert(not pcall(H.load('kernel/server/skill/skill_core.lua',Q.env()),base,ports))
local separate={Groups=groups,PlayerCore=pcGuard,JobCatalog=catalog,Callbacks={}}
assert(not pcall(H.load('kernel/server/skill/skill_core.lua',Q.env()),separate,ports))
-- Duplicate service is already refused; standalone service separately refuses a missing PR integration.
assert(not pcall(H.load('kernel/server/skill/service.lua',Q.env()),{config=configSkills,registry=core.Registry,
    storage=core.Storage,services={},library=library,json=m.codec,translate=function(k)return k end,native=sn,kernel={},
    integrations={}}))
for _,entry in ipairs(core.Callbacks)do transport.Security.register(entry.name,entry.handler,entry.options)end
p.api.CheckPlayerData(2,{citizenid='UIADMIN',license='license:admin',userId=102,charinfo={firstname='UI',lastname='Admin'}})
p.api.CheckPlayerData(1,{citizenid='PLAYER',license='license:player',userId=101,charinfo={firstname='Player',lastname='One'}})
local player=p.lookup.GetPlayer(1)
wire.playerSource=1
local function rpc(key,...)return wire.client.api.request(configSkills.Callbacks[key],nil,nil,10000,...)end
local ok,reason=rpc('addXp','a',5)
assert(not ok and reason=='no_permission','actual Security denies client self-award')
local payload,canManage=rpc('getAll');assert(type(payload)=='table'and not canManage)
assert(core.Service.start());assert(#workers==1);workers[1]();workers={}
local fetched,data=rpc('fetchPlayer');assert(fetched and data.values.a==10)
local vip=finance.Vip
vip.tiers.test={id='test',xpMultiplier=2,principal='',slots=0,weight=0}
player.Functions.SetMetaData(finance.VipConfig.metadataKey,{tier='test',assignedAt=clock,expiresAt=clock+100000})
assert(vip.get(1).config.xpMultiplier==2)
assert(core.Service.addXp(1,'a',5))
assert(core.Service.getCurrentSkill(1,'a')==20,'real canonical VIP multiplies award')
assert(core.Service.addXp(1,'a',5,{normalizedXp=true}))
assert(core.Service.getCurrentSkill(1,'a')==25)
wire.playerSource=2
assert(rpc('saveSkill',{name='a',maxXp=100,clientGain=true,maxDeltaPerMinute=20,
    integration={resource='forge-gym',export='updateSkill',identifier='strength',multiplier=2}}))
assert(core.Service.addXp(1,'a',2))
assert(routes[#routes][1]=='forge-gym'and routes[#routes][4]=='strength'and routes[#routes][5]==8)
assert(core.Service.getCurrentSkill(1,'a')==29 and p.lookup.GetPlayer(1)==player)
assert(rpc('addXp','a',3));assert(core.Service.getCurrentSkill(2,'a')==3)
-- The PR callback quota remains active, not replaced by handler-only tests.
transport.Security.buckets={}
wire.playerSource=1
for i=1,15 do local v=rpc('getAll');assert(type(v)=='table')end
ok,reason=rpc('getAll');assert(not ok and reason=='rate_limited')
clock=clock+5000
local handlers={}
for _,entry in ipairs(core.Boundary.NetEvents)do handlers[entry.name]=entry.handler end
for _,entry in ipairs(core.Boundary.Listeners)do handlers[entry.name]=entry.handler end
handlers['forge-core:server:skills:initialize']()
local packet=packets[#packets].packet
handlers['qbx_core:server:statusExtensions'](1,{forgeSkills={token=packet.token,counters={a={gain=2,loss=0}}}})
assert(core.Service.getCurrentSkill(1,'a')==31)
handlers['qbx_core:server:progressionCheckpoint'](1,'PLAYER')
assert(#writes>0 and writes[#writes][2]=='PLAYER'and m.codec.decode(writes[#writes][1]).a==31)
-- Saved player entity and independent progression column are not silently merged.
assert(player.PlayerData.skills==nil)
handlers['QBCore:Server:OnPlayerUnload'](1);assert(cache['forge-core:skills:1']==nil)
assert(core.Service.fetchPlayer(1))
assert(core.Service.getCurrentSkill(1,'a')==31)
assert(next(wire.server.api.getPending())==nil and next(wire.client.api.getPending())==nil)
print('PASS skill composition: canonical Player/Lookup/JobService/VIP/Security, real PR RPC/persistence/progression, admin denial/quota, awards/export/ack/checkpoint/unload/reload; native SQL/cache/network/time simulated, PR integration binder still pending')

