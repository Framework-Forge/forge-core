local S = dofile('tests/kernel_job_service_harness.lua')
local H,P,J=S.H,S.P,S.J
local p=P.new(true)
local groups=H.load('kernel/server/groups.lua',H.environment())({
    jobs=p.groupData.jobs,gangs=p.groupData.gangs,emitServer=p.platform.emitServer,emitClient=p.platform.emitClient,
    saveGroups=function()error('No legacy Lua persistence during Service publication')end,logError=function()error('Groups error')end})
local L=dofile('tests/kernel_lifecycle_harness.lua')
local l=L.new(true)
-- Real Functions factory with the same canonical Player/lookup, not the fixture's map.
local fp={};for k,v in pairs(l.bindings)do fp[k]=v end
fp.core=p.core;fp.lookup=p.lookup;fp.players=p.api;fp.storage=p.storage;fp.groups=groups
p.core.Player_Buckets={};p.core.Entity_Buckets={};p.core.UsableItems={}
local functions=H.load('kernel/server/functions.lua',H.environment())(fp)
local playerCore={State=p.core,Lookup=p.lookup,Players=p.api,Groups=groups,Lifecycle={Functions=functions}}
local base={Groups=groups,PlayerCore=playerCore}
local m=J.persistence();local library={};for k,v in pairs(m.api)do library[k]=v end
library.notify={NotifyPlayer=function(...)p.record('notify',...)end}
library.banking={EnsureJobAccount=function(...)p.record('society',...);return true,'exists'end}
local rows={}
library.database={query=function(sql)p.record('job-query',sql);return H.copy(rows)end,
    transaction=function(queries)p.record('job-tx',queries);return true end}
local config=J.config(true).config
local catalog=J.composition(base,{config=config,library=library,translate=function(key)return key end})
local dependencies={}
local timers={}
local native={getPlayers=function()return {'1','9'}end,
    isAceAllowed=l.native.isAceAllowed,emitClient=p.platform.emitClient,getSource=function()return 1 end,
    setTimeout=function(ms,fn)timers[#timers+1]={ms=ms,fn=fn}end}
local ports={library=library,translate=function(key)return key end,dependencies=dependencies,native=native,time=function()return 1792320000 end}
local before=#p.trace
local service=S.compose(base,ports)
assert(catalog.Service==service and catalog.Dependencies==dependencies)
assert(#p.trace==before and #m.trace==0 and #timers==0,'assembly must not start Service, SQL, JSON IO or timers')
assert(not pcall(S.compose,base,ports),'duplicate attachment refused')
assert(not pcall(S.compose,{JobCatalog=catalog,Groups={},PlayerCore=playerCore},ports))
assert(#service.Events==2 and service.Events[1].network and not service.Events[2].network)
assert(next(p.core.Players)==nil)
p.api.CheckPlayerData(1,{citizenid='SERVICE',license='license:test',userId=101})
assert(p.api.SetJob(1,'taxi',0))
local online=p.core.Players[1]
l.aces[1]={god=true}
assert(service.canManage(1),'local Lifecycle permission')
assert(service.upsert(1,{name='taxi',label='Internal Taxi',defaultDuty=true,
    grades={['0']={name='Driver',payment=75},['2']={name='Chief',payment=150}},
    stashes={{id='duty',duty={enabled=true}}}}))
assert(catalog.Registry.jobs.taxi.defaultDuty==false)
assert(groups.GetJobs().taxi.label=='Internal Taxi' and online.PlayerData.job.label=='Internal Taxi')
assert(online.PlayerData.job.onduty==false and online.PlayerData.job.payment==75)
assert(m.codec.decode(m.files[config.Storage.jobsFile]).taxi.stashes[1].id=='duty')
local txCount=0;for _,e in ipairs(p.trace)do if e.kind=='job-tx'then txCount=txCount+1 end end
assert(txCount==0)
rows={{citizenid='OFFLINE',group='taxi',type='job',grade=1},{citizenid='OLD',group='gone',type='gang',grade=4}}
assert(service.saveAndSync())
local tx;for _,e in ipairs(p.trace)do if e.kind=='job-tx'then tx=e.args[1]end end
assert(tx and #tx==2 and tx[1].values[1]==0 and tx[2].values[1]=='OLD')
assert(online==p.lookup.GetPlayer(1))
-- Failed JSON batch: no registry revision/publication after saveAndSync.
local oldRevision=catalog.Registry.revision
local oldBroadcasts=0
for _,e in ipairs(p.trace)do if e.kind=='client' and e.args[1]==config.Events.sync then oldBroadcasts=oldBroadcasts+1 end end
local originalWrite=m.files[config.Storage.jobsFile]
m.onWrite=function(path,bytes)if path==config.Storage.jobsFile and bytes~=originalWrite then return false end;return true end
local ok,reason=service.upsert(1,{name='police'})
assert(not ok and reason=='save_failed' and catalog.Registry.revision==oldRevision and not groups.GetJobs().police)
local broadcasts=0;for _,e in ipairs(p.trace)do if e.kind=='client' and e.args[1]==config.Events.sync then broadcasts=broadcasts+1 end end
assert(broadcasts==oldBroadcasts)
m.onWrite=nil
-- Dependencies can be attached without a second Service or periodic payment processor.
dependencies.JobPayments={getSettings=function()return {mei={enabled=false}}end}
assert(service.getPayload().payments.mei.enabled==false)
assert(not service.createMei(1,{label='Company'}))
-- Descriptor's timeout uses the same local player map; no runtime event installation.
online.PlayerData.job.onduty=true
service.Events[1].handler()
assert(#timers==1 and timers[1].ms==1500 and online.PlayerData.job.onduty)
timers[1].fn();assert(not online.PlayerData.job.onduty)
assert(catalog.Registry==base.JobCatalog.Registry and groups==base.PlayerCore.Groups)
for _,e in ipairs(p.trace)do assert(e.kind~='drop' and e.kind~='delete')end
print('PASS JobService composition: actual canonical Registry/Storage/Groups/Player/Lookup/Functions, PR JSON rollback in memory, duty/permission/membership, no QBX/self-framework or constructor IO; Payments not activated')
