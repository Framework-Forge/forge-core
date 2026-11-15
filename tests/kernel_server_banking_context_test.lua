local B=dofile('tests/kernel_banking_harness.lua');local r=B.context();local f=r.fixture;local before=f.snapshot();local sql=#r.bank.sql;r.prepareBanking()
B.H.same(f.snapshot(),before,'context64 construction inert');assert(#r.bank.calls==0 and #r.bank.sql==sql)
assert(r.bankingInstall());assert(#r.bank.calls==0 and #r.bank.sql==sql,'Install never creates bank accounts')
r.emit('onResourceStart','forge-core');r.begin();assert(#r.sqlTrace==2);r.resume();assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[2]))
assert(r.api.Progress().phase=='running'and r.graph.PlayerCore==f.base.PlayerCore)
local jobs=f.base.JobCatalog.Service;local ok,status=r.api.Banking.EnsureJobAccount('taxi','Taxi',0)
assert(ok and status=='created'and r.bank.accounts.taxi,'society creation reaches installed Renewed through PR')
assert(r.api.Banking.EnsureJobAccount('taxi','Taxi',0));assert(r.bank.count('insert')==1,'existing job account not inserted again')
assert(jobs.upsert(2,{name='taxi',label='Taxi',defaultDuty=true,grades={['0']={name='Worker',payment=30}}},'job'))
local pc=r.graph.PlayerCore;pc.Players.CheckPlayerData(1,{citizenid='BANK',license='license:test',userId=101,money={cash=10,bank=0},job={name='taxi',grade={level=0},onduty=true}})
local deps=f.base.JobCatalog.Dependencies;local player=assert(pc.Lookup.GetPlayer(1));local salary=30
local pay=deps.JobPayments;pay.settings.mei.enabled=true;pay.settings.mei.openingCost=0
local made,company=jobs.createMei(1,{label='Test MEI',grades={['0']={name='Owner',payment=0,isboss=true,bankAuth=true}}})
assert(made,tostring(company));assert(r.bank.accounts[company.name],'JobService MEI creation reaches installed Renewed through PR')
assert(pc.Players.SetJob(1,'taxi',0));pc.Players.SetJobDuty(1,true);assert(player.PlayerData.job.onduty);player.PlayerData.metadata.prCompatPaycheckEnabled=true
pay.settings.useSociety=true;pay.settings.societySalaryPercent=100;pay.settings.payOffDuty=true;pay.settings.account='bank'
assert(r.api.Banking.AddJobAccountBalance('taxi',100,'test'))
local bankBefore=player.PlayerData.money.bank;local paid=pay.processAll('force')
assert(paid==1 and player.PlayerData.money.bank==bankBefore+salary and r.bank.accounts.taxi.amount==100-salary,'real payroll debits society through PR and credits canonical Player locally')
r.api.Stop();r.clock.advance(120000);r.api.Poll();assert(r.api.Progress().complete,'context64 drain includes banking and63')
local n=#r.bank.calls;assert(r.api.Banking.EnsureJobAccount('late','Late',0)==nil and #r.bank.calls==n,'banking closure revoked after Stop')
assert(#r.errors==0 and r.surface.exports.GetJobs()==nil)
local fail=B.context();fail.prepareBanking();fail.bank.state='starting';assert(not fail.bankingInstall()and #fail.bank.calls==0,'unready bank refuses before publication')
local dbFail=B.context();dbFail.prepareBanking();dbFail.dbReady=false;assert(not dbFail.bankingInstall()and dbFail.api.Progress().banking.complete,'failed preflight closes bank scope')
local stop=B.context();stop.prepareBanking();assert(stop.bankingInstall());stop.begin();stop.emit('onResourceStop','forge-core');stop.resume();stop.clock.advance(120000);stop.api.Poll()
assert(stop.api.Progress().phase=='closed'and stop.api.Progress().banking.complete,'native stop closes banking during startup')
local stale=B.context();stale.prepareBanking();assert(stale.bankingInstall());stale.fixture.base.Callbacks={}
assert(stale.api.Banking.AddJobAccountBalance('taxi',20)==nil and #stale.bank.calls==0,'replaced Security refuses stale bank mutation');stale.api.Stop()
print('PASS lot64 actual63/62/61/60/48:JobService Ensure/Exists bridge, payroll society debit and same local Player money, schema/start order, owned close/native stop/preflight failure;whole installed bank with virtual SQL')
