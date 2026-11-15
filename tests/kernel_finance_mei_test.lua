local F=dofile('tests/kernel_finance_harness.lua')
local count=0
local function case(label,action,options)F.case('payments',label,action,options);count=count+1 end
local function settings(r)r.api.load();return r.api.getSettings()end
case('charge balanced',function(r)local s=settings(r);assert(r.api.chargeMeiOpening(r.players[1],s));assert(r.money[1].bank==5000 and r.bank.government==5000)end)
case('zero charge',function(r)local s=settings(r);s.mei.openingCost=0;return r.api.chargeMeiOpening(r.players[1],s)end)
case('negative charge',function(r)local s=settings(r);s.mei.openingCost=-4;return r.api.chargeMeiOpening(r.players[1],s)end)
case('disabled charge',function(r)local s=settings(r);s.mei.enabled=false;return r.api.chargeMeiOpening(r.players[1],s)end)
case('defaults charge',function(r)return r.api.chargeMeiOpening(r.players[1])end)
case('cash charge',function(r)local s=settings(r);s.mei.paymentAccount='cash';return r.api.chargeMeiOpening(r.players[1],s)end)
for _,result in ipairs({table.pack(false),table.pack(nil),'throw'})do
    case('debit '..tostring(result),function(r)r.results.RemoveMoney=result;return r.api.chargeMeiOpening(r.players[1],settings(r))end)
end
for _,result in ipairs({table.pack(false),table.pack(nil),table.pack(1),'throw'})do
    case('government transfer '..tostring(result),function(r)r.results.AddJobAccountBalance=result;return r.api.chargeMeiOpening(r.players[1],settings(r))end)
end
case('charge compensation fails',function(r)
    r.results.AddJobAccountBalance=table.pack(false);r.results.AddMoney=table.pack(false)
    return r.api.chargeMeiOpening(r.players[1],settings(r))
end)
case('charge banking absent returns government failure',function(r)return r.api.chargeMeiOpening(r.players[1],settings(r))end,function(r)r.library.banking=nil end)
case('refund balanced',function(r)
    local s=settings(r);assert(r.api.chargeMeiOpening(r.players[1],s));assert(r.api.refundMeiOpening(r.players[1],s))
    assert(r.money[1].bank==10000 and r.bank.government==0)
end)
case('refund zero',function(r)local s=settings(r);s.mei.openingCost=0;return r.api.refundMeiOpening(r.players[1],s)end)
case('refund without banking',function(r)return r.api.refundMeiOpening(r.players[1],settings(r))end,function(r)r.library.banking=nil end)
for _,result in ipairs({table.pack(false),table.pack(nil),table.pack(1),'throw'})do
    case('refund government '..tostring(result),function(r)r.results.RemoveJobAccountBalance=result;return r.api.refundMeiOpening(r.players[1],settings(r))end)
end
for _,result in ipairs({table.pack(false),table.pack(nil),table.pack(1),'throw'})do
    case('refund credit '..tostring(result),function(r)r.results.AddMoney=result;return r.api.refundMeiOpening(r.players[1],settings(r))end)
end
-- Installed PR factory's unknown-result conversion, tested without contacting Renewed-Banking.
local H=F.H
local calls=0
local factory=H.load('../pr_bridge/bridge/banking/factory.lua',H.environment({
    exports={['Renewed-Banking']={addAccountMoney=function()calls=calls+1;error('bank exception',0)end}},
    Debug=function()end}))
local bridge=factory('Renewed-Banking',{AddJobAccountBalance='addAccountMoney'})
assert(bridge.AddJobAccountBalance('government',5,'fixture')==true and calls==1,
    'installed factory reports true after provider exception; not a confirmed transfer')
assert(bridge.RemoveJobAccountBalance('government',5,'fixture')==true,
    'unmapped operation returns nil and is converted to true')
assert(bridge.JobAccountExists==nil and bridge.EnsureJobAccount==nil)
print(('PASS finance MEI: %d differential cases, charge/refund/unknown/compensation and installed PR banking ambiguity in isolation'):format(count))
