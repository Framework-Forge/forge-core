local H=dofile('tests/kernel_harness.lua')
local env=H.environment({PRCore={load=function(path,e)
 assert(path=='@pr_bridge/bridge/runtime/forge/control_client');return H.load('../pr_bridge/bridge/runtime/forge/control_client.lua',e)
end}})
local create=H.load('kernel/pr_integration/activation_remote_control.lua',env)
local cases={'allocated','prepared','preparing','attached','attaching','closing','closed','bad-generation','bad-instance','bad-side','bad-resource','not-current','changed-on-observe'}
for _,side in ipairs({'server','client'})do for _,case in ipairs(cases)do
 local remotePhase=case=='allocated'and'allocated'or'prepared';local prepares,attaches,describes=0,0,0
 if case=='preparing'or case=='attached'or case=='attaching'or case=='closing'or case=='closed'then remotePhase=case end
 local current=true
 local proxy=create({native={GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return side=='server'and 1 or false end},
  resource='consumer',generation='g-test',instance='i-test',isCurrent=function()return current end,
  external={consumer={ForgePrActivationControl=function(_,op)
   if op=='Describe'then
    describes=describes+1
    return{protocol='forge-pr-consumer/1',generation=case=='bad-generation'and'old'or'g-test',
     instance=(case=='bad-instance'or case=='changed-on-observe'and describes==2)and'replaced'or'i-test',
     side=case=='bad-side'and'other'or side,resource=case=='bad-resource'and'other'or'consumer',current=case~='not-current',phase=remotePhase,proxyReady=remotePhase=='attached'}
   elseif op=='Prepare'then prepares=prepares+1;assert(remotePhase=='allocated');remotePhase='prepared';return true
   elseif op=='Attach'then attaches=attaches+1;assert(remotePhase=='prepared');remotePhase='attached';return true
   elseif op=='Close'then remotePhase='closed';return true
   elseif op=='Progress'then return{pending=0,phase=remotePhase,complete=remotePhase=='closed'}end
  end}}})
 local ok,why=proxy.Prepare()
 if case=='allocated'or case=='prepared'then
  assert(ok and proxy.Progress().phase=='prepared',tostring(why))
  assert(prepares==(case=='allocated'and 1 or 0),'do not replay preparation')
  assert(proxy.Attach()and attaches==1 and proxy.Describe().proxyReady)
  assert(not proxy.Attach()and attaches==1,'do not replay attachment')
  assert(proxy.Close()and proxy.Close())
 else
  assert(not ok and type(why)=='string','invalid or replaced consumer must be refused')
  assert(prepares==0 and attaches==0)
 end
end end
print('PASS prepared proxy: both sides, allocated/prepared success, no repeated allocations, phase/identity/epoch/instance/owner failures and replacement during observation')
