local F=dofile('tests/kernel_finance_harness.lua')
local count=0
local function case(label,action,options)F.case('payments',label,action,options);count=count+1 end
case('defaults snapshot',function(r)return r.api.getSettings()end)
case('load missing',function(r)return r.api.load()end)
for i,settings in ipairs({
    {},{enabled=false,notify=false},{enabled='sim',interval=0,society='yes',societyPercent=38.5},
    {intervalMinutes=1441,account='invalid',payOffDuty='1'},
    {intervalMinutes=-2,account='CASH',societySalaryPercent=-1},
    {intervalMinutes='3.9',account='crypto',societySalaryPercent=101},
    {mei={enabled=false,openingCost=-2,monthlyCost='2.9',paymentAccount='invalid',governmentAccount='  Treasury '}},
    {enabled=false,openingCost=12,meiEnabled='true',governmentAccount=''},
    {enabled=true,mei={meiEnabled=false,enabledMei=true,enabled=false}},
    {enabled='TRUE',useSociety=false,society=true,notify='nao'},
    {intervalMinutes='bad',societySalaryPercent='bad',mei={openingCost='bad'}},
})do
    case('save normalized '..i,function(r)return r.api.save(settings),r.api.getSettings()end)
    case('load stored '..i,function(r)r.memory.seed(r.config.Payments.file,settings);return r.api.load()end)
end
case('failed save no deadline commit',function(r)
    r.api.load();local before=r.api.settings;local deadline=r.api.nextPaymentAt
    r.memory.onWrite=function()return false end
    assert(not r.api.save({enabled=false}));assert(r.api.settings==before and r.api.nextPaymentAt==deadline)
end)
case('corrupt load throws',function(r)r.memory.files[r.config.Payments.file]='broken';return r.api.load()end)
case('scalar JSON inherited error',function(r)r.memory.seed(r.config.Payments.file,4);return r.api.load()end)
case('getSettings mei reference inherited',function(r)
    r.api.load();local copy=r.api.getSettings();copy.mei.openingCost=123;copy.enabled=false
    assert(r.api.settings.mei.openingCost==123 and r.api.settings.enabled==true);return r.api.getSettings()
end)
case('update denied',function(r)r.allowed=false;return r.api.update(1,{})end)
case('updateMei denied',function(r)r.allowed=false;return r.api.updateMei(1,{})end)
case('update success',function(r)return r.api.update(1,{intervalMinutes=25})end)
case('updateMei success',function(r)r.api.load();return r.api.updateMei(1,{enabled=false,monthlyCost=12})end)
case('update failure',function(r)r.memory.onWrite=function()return false end;return r.api.update(1,{})end)
case('update no Service inherited',function(r)return r.api.update(1,{enabled=false})end,function(r)r.services.JobService=nil end)
print(('PASS finance settings: %d differential cases, full defaults/aliases/clamps/JSON/commit/permissions/reference semantics'):format(count))
