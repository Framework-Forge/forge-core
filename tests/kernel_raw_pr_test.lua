local T=dofile('tests/kernel_raw_pr_harness.lua');local r=T.new();r.ports.profile[#r.ports.profile+1]={field='notify',path='bridge/notifications/default/server'}
r.allocate();assert(#r.loads==0 and #r.effects==0);assert(r.raw.Prepare()and #r.effects==0)
assert(r.public.banking.GetResourceName()=='Renewed-Banking');assert(r.public.banking.GetJobAccountBalance('police')==23)
assert(r.public.banking.AddJobAccountBalance('police',5,'test')==true and r.public.banking.RemoveJobAccountBalance('police',5)==false)
assert(r.public.banking.AddAccountBalance==r.public.banking.AddPlayerAccountBalance)
assert(r.public.notify.Notify(2,{description='test121'})and r.effects[#r.effects][1]=='notify')
for _,name in ipairs(r.loads)do assert(not name:find('framework',1,true)and not name:find('callback',1,true))end
local held=r.public.banking.GetJobAccountBalance;assert(r.raw.Close()and r.raw.Progress().complete and next(r.public)==nil and r.pr.forgeRawCore==nil)
assert(not pcall(held,'police'));print('PASS lot121 raw PR actual Renewed factory/math,aliases/provider semantics preserved;no framework/callback engine/core lookup during preparation')
