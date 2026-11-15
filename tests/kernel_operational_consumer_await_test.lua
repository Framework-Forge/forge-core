local H=dofile('tests/kernel_native_foundation_harness.lua').H
local await=H.load('../pr_bridge/bridge/frameworks/forge/operational_consumer_await.lua',H.environment())
local now,phase,waits=0,'waiting',0;local resource='ps-housing'
local e={GetCurrentResourceName=function()return resource end,GetGameTimer=function()return now end,
 GetConvarInt=function(_,d)return d end,Wait=function()waits=waits+1;now=now+25;phase='running'end,
 exports={['forge-core']={ForgeRuntimeStatus=function()return{generation='g279',phase=phase,ingressOpen=phase=='running'}end}}}
local owner={Generation='g279',Progress=function()return{complete=false}end}
assert(await({environment=e,owner=owner})and waits==1)
resource='Renewed-Banking';phase='waiting';assert(await({environment=e,owner=owner})and waits==1)
resource='forge-loadscreen';assert(await({environment=e,owner=owner})and waits==1)
resource='ps-housing';phase='failed';assert(not pcall(await,{environment=e,owner=owner}))
print('PASS279 non-bootstrap consumer waits after declaration;bank bootstrap is not delayed;activation failure refuses startup')
