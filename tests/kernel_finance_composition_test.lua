local F=dofile('tests/kernel_finance_harness.lua')
local S=dofile('tests/kernel_job_service_harness.lua')
local H,P,J=F.H,F.P,F.J
-- Full VIP default parity and independent configs (not another authoritative service).
local env=H.environment({PR={}})
H.load('shared/vip.lua',env)
local factory=H.load('kernel/config/forge_vip.lua',H.environment())
H.same(factory(),env.PR.Vip)
local a,b=factory(),factory();a.tiers.gold.salary.amount=3;assert(b.tiers.gold.salary.amount==1000)

local p=P.new(true)
local groups=H.load('kernel/server/groups.lua',H.environment())({jobs=p.groupData.jobs,gangs=p.groupData.gangs,
    emitServer=p.platform.emitServer,emitClient=p.platform.emitClient,
    saveGroups=function()error('No legacy Lua writes')end,logError=function()error('Unexpected Groups error')end})
local base={Groups=groups,PlayerCore={Groups=groups,State=p.core,Lookup=p.lookup,Players=p.api,
    Lifecycle={Functions={HasPermission=function()return true end}}}}
local m=J.persistence();local library={};for k,v in pairs(m.api)do library[k]=v end
local bank={government=0,taxi=10000}
library.banking={
    EnsureJobAccount=function(name)bank[name]=bank[name]or 0;return true,'exists'end,
    JobAccountExists=function(name)return bank[name]~=nil end,GetJobAccountBalance=function(name)return bank[name]end,
    AddJobAccountBalance=function(name,amount)bank[name]=(bank[name]or 0)+amount;return true end,
    RemoveJobAccountBalance=function(name,amount)if(bank[name]or 0)<amount then return false end;bank[name]=bank[name]-amount;return true end}
library.notify={NotifyPlayer=function(...)p.record('finance-notify',...)end}
library.inventory={AddItem=function(...)p.record('finance-item',...);return true end}
library.database={query=function()return {}end,transaction=function()return true end}
local config=J.config(true).config
local catalog=J.composition(base,{config=config,library=library,translate=function(key)return key end})
local now=1000000
local workers,timers,commands={},{},{}
local native={getPlayers=function()return {'1'}end,isAceAllowed=function()return true end,
    emitClient=p.platform.emitClient,getSource=function()return 1 end,
    setTimeout=function(ms,fn)timers[#timers+1]={ms=ms,fn=fn}end,
    spawn=function(fn)workers[#workers+1]=coroutine.create(fn)end,wait=function(ms)coroutine.yield(ms)end,
    getIdentifier=function()return 'license:test'end,execute=function(cmd)commands[#commands+1]=cmd end,print=function()end}
local service=S.compose(base,{library=library,translate=function(key)return key end,dependencies={},native=native,time=function()return now end})
local integrations={inventoryReady=function()return true end,
    applyPlayerInventoryBonus=function(...)p.record('vip-bonus',...);return true,'applied'end}
local before=#p.trace
local finance=F.compose(base,{library=library,translate=function(key)return key end,native=native,
    integrations=integrations,time=function()return now end,resource='forge-core'})
assert(#p.trace==before and #m.trace==0 and #workers==0 and #timers==0 and #commands==0,'attach must have no runtime effects')
assert(catalog.Dependencies.JobPayments==finance.Payments and catalog.Dependencies.VipService==finance.Vip)
assert(not pcall(F.compose,base,{}),'duplicate financial attachment refused')
assert(finance.Vip.Initialize()and not finance.Vip.Initialize())
finance.Payments.load()
p.api.CheckPlayerData(1,{citizenid='FINANCE',license='license:test',userId=101})
local online=p.lookup.GetPlayer(1)
assert(p.api.SetJob(1,'taxi',0))
assert(service.upsert(0,{name='taxi',grades={['0']={name='Driver',payment=100}}}))
assert(p.api.SetJobDuty(1,true)==nil) -- installed setter returns nil; the fixture's initial taxi was off-duty
assert(online.Functions.SetMoney('bank',10000,'fixture'))
assert(finance.Vip.grant(0,1,'gold',1))
local paid,skipped=finance.Payments.processAll('force')
assert(paid==1 and skipped==0 and online.PlayerData.money.bank==11100,'salary + local metadata VIP')
local settings=finance.Payments.getSettings()
assert(finance.Payments.chargeMeiOpening(online,settings))
assert(online.PlayerData.money.bank==6100 and bank.government==5000)
assert(finance.Payments.refundMeiOpening(online,settings))
assert(online.PlayerData.money.bank==11100 and bank.government==0)
-- Complete JobService -> real Payments -> same Player money -> PR banking -> JSON -> Groups -> SetJob.
local ok,company=service.createMei(1,{label='Local Company'})
assert(ok and company.owner=='FINANCE'and company.name=='local_company')
assert(online.PlayerData.money.bank==6100 and bank.government==5000)
assert(online.PlayerData.job.name=='local_company'and groups.GetJob('local_company'))
assert(m.codec.decode(m.files[config.Storage.jobsFile]).local_company.owner=='FINANCE')
assert(catalog.Service==service and p.lookup.GetPlayer(1)==online and base.PlayerCore.State.Players[1]==online)
-- Save failure refunds opening charge with real ported Payments; no group commit.
local beforeMoney,beforeGovernment=online.PlayerData.money.bank,bank.government
local old=m.files[config.Storage.jobsFile]
m.onWrite=function(path,bytes)if path==config.Storage.jobsFile and bytes~=old then return false end;return true end
ok=service.createMei(1,{label='Failed Company'})
assert(not ok and online.PlayerData.money.bank==beforeMoney and bank.government==beforeGovernment)
assert(not catalog.Registry.jobs.failed_company and not groups.GetJob('failed_company'))
assert(#workers==1,'only explicit VIP grant queued inventory work; Payments loop not started')
assert(#finance.Vip.Threads==1 and #finance.Vip.Events==3)
assert(#commands==1 and commands[1]:match('^add_principal'))
print('PASS finance composition: full VIP config, canonical JobService/Registry/Groups/Player and local payroll/MEI/refund; all balances/JSON/SQL/inventory/ACE simulated, no scheduler activation')
