local H=dofile('tests/kernel_harness.lua')
local calls,remotePhase,current={},'allocated',true
local env=H.environment({PRCore={load=function(path,e)
 assert(path=='@pr_bridge/bridge/runtime/forge/control_client')
 return H.load('../pr_bridge/bridge/runtime/forge/control_client.lua',e)
end}})
local create=H.load('kernel/pr_integration/activation_remote_control.lua',env)
local p={native={GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return 1 end},
 resource='ox_inventory',generation='cleanup-test',instance='inventory-test',isCurrent=function()return current end,
 external={ox_inventory={ForgePrActivationControl=function(_,op,g,i)
  assert(g=='cleanup-test'and i=='inventory-test');calls[#calls+1]=op
  if op=='Describe'then return{protocol='forge-pr-consumer/1',generation=g,instance=i,resource='ox_inventory',side='server',
   current=true,phase=remotePhase,proxyReady=remotePhase=='attached'}end
  if op=='Prepare'then remotePhase='prepared';return true end
  if op=='Attach'then remotePhase='attached';return true end
  if op=='Close'then remotePhase='closed';return true end
  assert(op=='Progress');return{phase=remotePhase,pending=0,complete=remotePhase=='closed'}
 end}}}
local owner=create(p);assert(#calls==0,'allocation must be passive')
assert(owner.Prepare());assert(owner.Attach())
assert(owner.Close(),'closing must reach the remote Close and observe its completion')
assert(owner.Progress().complete and remotePhase=='closed')
local count=#calls;assert(owner.Close()and #calls==count,'closed cleanup must be idempotent')
assert(not owner.Prepare()and not owner.Attach()and owner.Describe()==nil)
local stale=create(p);current=false;count=#calls
assert(not stale.Close()and #calls==count,'stale owner must not invoke the remote consumer')
print('PASS remote cleanup: passive allocation, actual Close/Progress, idempotence and stale owner refusal')
