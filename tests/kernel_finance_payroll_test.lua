local F=dofile('tests/kernel_finance_harness.lua')
local count=0
local function case(label,action,options)F.case('payments',label,action,options);count=count+1 end
local function cycle(r,settings)r.api.load();if settings then for k,v in pairs(settings)do r.api.settings[k]=v end end;return r.api.processAll()end
case('regular salary',function(r)return cycle(r)end)
case('disabled cycle',function(r)return cycle(r,{enabled=false})end)
case('forced disabled cycle',function(r)r.api.load();r.api.settings.enabled=false;return r.api.force(0)end)
case('force denied',function(r)r.allowed=false;return r.api.force(1)end)
case('not ready',function(r)r.coreReady=false;return cycle(r)end)
case('players exception',function(r)r.results.GetQBPlayers='throw';return cycle(r)end)
case('invalid players',function(r)r.results.GetQBPlayers=table.pack(4);return cycle(r)end)
case('job exception',function(r)r.results.GetJob='throw';return cycle(r)end)
case('missing job',function(r)r.players[1].PlayerData.job=nil;return cycle(r)end)
case('missing job data',function(r)r.jobs.taxi=nil;return cycle(r)end)
case('missing PlayerData',function(r)r.players[1].PlayerData=nil;return cycle(r)end)
case('individual disabled',function(r)r.players[1].PlayerData.metadata.prCompatPaycheckEnabled=false;return cycle(r)end)
for _,payment in ipairs({0,-1,'bad','25.5'})do
    case('salary '..payment,function(r)r.jobs.taxi.grades[0].payment=payment;return cycle(r)end)
end
case('string grade',function(r)r.jobs.taxi.grades={['0']={payment=30}};return cycle(r)end)
case('numeric grade field',function(r)r.players[1].PlayerData.job.grade=0;return cycle(r)end)
case('job payment fallback',function(r)r.jobs.taxi.grades={};return cycle(r)end)
case('off duty denied',function(r)r.players[1].PlayerData.job.onduty=false;return cycle(r)end)
case('off duty allowed settings',function(r)r.players[1].PlayerData.job.onduty=false;return cycle(r,{payOffDuty=true})end)
case('off duty allowed catalog',function(r)r.players[1].PlayerData.job.onduty=false;r.jobs.taxi.offDutyPay=true;return cycle(r)end)
for _,percent in ipairs({0,0.5,50,100})do
    case('society percent '..percent,function(r)return cycle(r,{useSociety=true,societySalaryPercent=percent})end)
end
case('MEI forces full society',function(r)r.jobs.taxi.type='mei';return cycle(r,{useSociety=false,societySalaryPercent=1})end)
case('MEI legacy jobtype',function(r)r.jobs.taxi.jobtype='mei';return cycle(r)end)
case('society missing',function(r)r.bank.taxi=nil;return cycle(r,{useSociety=true})end)
case('society insufficient',function(r)r.bank.taxi=99;return cycle(r,{useSociety=true})end)
for _,method in ipairs({'JobAccountExists','GetJobAccountBalance','RemoveJobAccountBalance'})do
    for _,result in ipairs({table.pack(false),table.pack(nil),'throw'})do
        case('society '..method..tostring(result),function(r)r.results[method]=result;return cycle(r,{useSociety=true})end)
    end
end
for _,result in ipairs({table.pack(false),table.pack(nil),'throw'})do
    case('AddMoney '..tostring(result),function(r)r.results.AddMoney=result;return cycle(r,{useSociety=true})end)
end
case('salary refund ignored inherited',function(r)
    r.results.AddMoney=table.pack(false);r.results.AddJobAccountBalance=table.pack(false);return cycle(r,{useSociety=true})
end)
local function vip(r,amount,account)r.activeVip[1]={tier='gold',config={label='Gold',salary={enabled=true,amount=amount or 50,account=account or 'bank'}}}end
case('salary plus VIP counted once',function(r)vip(r);local paid,skipped=cycle(r);assert(paid==1 and skipped==0 and r.money[1].bank==10150);return paid,skipped end)
case('VIP independent of job disable flag inherited',function(r)vip(r);r.players[1].PlayerData.metadata.prCompatPaycheckEnabled=false;return cycle(r)end)
case('VIP fractional floor',function(r)vip(r,2.9,'cash');return cycle(r)end)
case('VIP disabled',function(r)vip(r);r.activeVip[1].config.salary.enabled=false;return cycle(r)end)
case('VIP zero',function(r)vip(r,0);return cycle(r)end)
for _,result in ipairs({table.pack(false),table.pack(nil),'throw'})do
    case('VIP money result '..tostring(result),function(r)vip(r);r.results.AddMoney=result;return cycle(r)end)
end
case('VIP inventory stopped',function(r)vip(r);r.results.AddMoney=table.pack(false);r.inventoryReady=false;return cycle(r)end)
case('VIP inventory false',function(r)vip(r);r.results.AddMoney=table.pack(false);r.results.AddItem=table.pack(false);return cycle(r)end)
case('VIP inventory nil accepted inherited',function(r)vip(r);r.results.AddMoney=table.pack(false);r.results.AddItem=table.pack(nil);return cycle(r)end)
case('multiple players',function(r)r.players[2]=r.makePlayer(2);return cycle(r)end)
case('start deadline worker',function(r)
    assert(r.api.start());assert(r.api.start());assert(#r.tasks==1)
    assert(r.step()==5000);r.now=r.api.nextPaymentAt;assert(r.step()==5000)
    r.api.started=false;return r.step()
end)
case('failed start stays started inherited',function(r)
    r.memory.files[r.config.Payments.file]='broken';assert(not pcall(r.api.start));assert(r.api.started);return r.api.start()
end)
case('reentrant cycle pays twice inherited',function(r)
    r.api.load();local entered=false
    r.addHook=function()if not entered then entered=true;r.api.processAll('force')end end
    r.api.processAll();assert(r.money[1].bank==10200)
end)
print(('PASS finance payroll: %d differential cases; salaries/society/duty/VIP/fallback/worker, retained false-success/refund/reentry behavior'):format(count))
