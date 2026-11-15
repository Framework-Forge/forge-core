local B=dofile('tests/kernel_banking_harness.lua');local H=B.H;local r=B.new();local sql=#r.sql;r.mount()
assert(#r.calls==0 and #r.sql==sql,'society constructor inert');assert(r.api.EnsureJobAccount('taxi','Taxi',0)==nil)
assert(r.api.Open()and #r.calls==0 and #r.sql==sql,'Open never reads or writes accounts')
assert(r.api.JobAccountExists('taxi')==false and r.count('insert')==0,'missing account is not zero-balance account')
local ok,status=r.api.EnsureJobAccount('taxi','Taxi',0);assert(ok and status=='created'and r.count('insert')==1)
assert(r.api.JobAccountExists('taxi')and r.api.GetJobAccountBalance('taxi')==0,'zero balance is existing account')
r.api.AddJobAccountBalance('taxi',100,'seed');ok,status=r.api.EnsureJobAccount('taxi','Changed',900)
assert(ok and status=='exists'and r.count('insert')==1 and r.accounts.taxi.amount==100 and r.accounts.taxi.name=='Taxi','existing account never reseeded or renamed')
local payload={title='Sale',amount=25,message="User's \\ message",issuer='Forge Core',receiver='Taxi',type='deposit'}
local before=r.count('execute');local tx=r.api.RecordJobTransaction('taxi',payload)
assert(tx.amount==25 and tx.trans_type=='deposit'and tx.issuer=='Forge Core'and tx.message=="User''s \\\\ message" and r.count('execute')==before+1,'installed transaction mapping/sanitization and one write')
assert(#r.accounts.taxi.transactions==1 and r.calls[#r.calls].args.n==7,'no duplicate transaction ID or write')
local count=0
for _,method in ipairs({'GetJobAccountBalance','AddJobAccountBalance','RemoveJobAccountBalance'})do
    local export=method=='GetJobAccountBalance'and'getAccountMoney'or method=='AddJobAccountBalance'and'addAccountMoney'or'removeAccountMoney'
    for _,mode in ipairs({'normal','false','nil','throw'})do
        local a,b=B.new(),B.new();a.seed('taxi',100);b.seed('taxi',100);a.mount();assert(a.api.Open())
        a.modes[export]=mode;b.modes[export]=mode
        H.same(table.pack(pcall(a.api[method],'taxi',10,'reason')),table.pack(pcall(b.public[method],'taxi',10,'reason')),'installed PR money policy '..method..' '..mode)
        H.same(a.accounts,b.accounts,'same cached balances');H.same(a.sql,b.sql,'same virtual SQL');count=count+1
    end
end
local legacy=B.new();legacy.mount();assert(legacy.api.Open());legacy.modes.addAccountMoney='throw'
assert(legacy.api.AddJobAccountBalance('absent',10)==true and legacy.accounts.absent==nil,'inherited PR false success on export exception remains explicit')
for _,kind in ipairs({'insert','update','execute'})do local f=B.new();f.mount();assert(f.api.Open())
    if kind=='insert'then f.dbFalse='insert';assert(not pcall(f.api.EnsureJobAccount,'new','New',0));assert(f.accounts.new==nil,'installed insert refusal clears cache')
    elseif kind=='update'then f.seed('taxi',100);f.dbError='update';assert(f.api.AddJobAccountBalance('taxi',10)==true and f.accounts.taxi.amount==110,'inherited update error can leave cached money changed')
    else f.seed('taxi',100);f.dbError='execute';assert(not pcall(f.api.RecordJobTransaction,'taxi',payload));assert(#f.accounts.taxi.transactions==1,'transaction cache may change before SQL exception')end
end
assert(not pcall(r.api.JobAccountExists,''),'installed invalid name error preserved')
for _,kind in ipairs({'starting','other_adapter','stale'})do local bad=B.new();bad.mount()
    if kind=='starting'then bad.state='starting'elseif kind=='other_adapter'then bad.selected='framework'else bad.current=false end
    assert(not bad.api.Open()and #bad.calls==0,'bank provider refusal '..kind)
end
assert(count==12)
print('PASS lot64 society:installed account lookup/create/zero/existing/insert failure, transaction mapping and12 PR money-policy cases;false-success/partial cache effects characterized, virtual SQL only')
