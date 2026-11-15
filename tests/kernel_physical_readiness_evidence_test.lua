local req=dofile('tests/kernel_native_foundation_harness.lua').loader()
local names={'Central.Parts.Inventory.Service.Initialize','Central.Parts.Consumption.Service.Initialize','Central.Parts.Weapons.Service.Initialize'}
local phase='prepared';local ledger={};local graph={Base={}};local proofCalls=0;local accepted=false
graph.Base.ServerWorkerContext={Progress=function()return{initialization={phase=phase,ledger=ledger}}end,
 Initialization={Describe=function()local out={};for i,name in ipairs(names)do out[i]={name=name}end;return out end}}
local current=true;local e={Foundation={Side='server'},Bootstrap={Graph=graph},IsCurrent=function()return current end}
local unknown=0;local bank='open'
local r={Services={Progress=function()return{phase='open'}end,
 Inventory={Progress=function()return{phase='open',unknown=unknown,removeFailed=0,publishing=0}end},
 Banking={Progress=function()return{phase=bank}end},Keys={Progress=function()return{phase='open'}end}}}
local proofs={};for _,key in ipairs({'oxHooks','catalogs','banking','keys','decisions','environment'})do
 proofs[key]=function(g,which,raw,entry)assert(g=='255'and which==graph and raw==r and entry==e);proofCalls=proofCalls+1;return accepted end
end
local q=req('kernel.entry.physical_readiness_evidence')({side='server',generation='255',proofs=proofs})
assert(not q.catalogs('255',e,r)and proofCalls==0)
phase='initialized';ledger={completed='unused'};assert(not q.catalogs('255',e,r))
for i=1,3 do ledger[i]='completed'end
assert(not q.catalogs('255',e,r)and proofCalls==1);accepted=true;assert(q.catalogs('255',e,r))
unknown=1;assert(not q.oxHooks('255',e,r));unknown=0;assert(q.oxHooks('255',e,r))
bank='prepared';assert(not q.banking('255',e,r));bank='open';assert(q.banking('255',e,r))
assert(not q.keys('stale',e,r));current=false;assert(not q.environment('255',e,r))
proofs.keys=nil;assert(not pcall(req('kernel.entry.physical_readiness_evidence'),{side='server',generation='255',proofs=proofs}))
print('PASS255 actual receipt contract gates catalog proof;unknown hooks/unopened bank/stale/current false denied;external effect proof still mandatory')
