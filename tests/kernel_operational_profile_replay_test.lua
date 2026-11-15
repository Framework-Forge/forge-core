local R=dofile('tests/kernel_runtime_consumer_replay_harness.lua');local H=R.H
local create=H.load('kernel/pr_integration/activation_remote_control.lua',H.environment({PRCore={load=function(path,e)
 assert(path=='@pr_bridge/bridge/runtime/forge/control_client');return H.load('../pr_bridge/bridge/runtime/forge/control_client.lua',e)
end}}))
local data=H.load('kernel/pr_integration/operational_profile_data.lua',H.environment())
data.generation='profile-replay';data.qbEnabled=true
local profile=H.load('kernel/pr_integration/activation_profile.lua',H.environment())(data)
local total=0
for _,side in ipairs({'server','client'})do
 for _,spec in ipairs(profile.Consumers(side))do
  local calls,canAttach,claims=0,false,{}
  local expected=H.load('../pr_bridge/bridge/runtime/forge/activation_api_expectations.lua',H.environment())(side,true)
  local r
  local core={ForgePrDescribe=function()
   calls=calls+1;assert(canAttach,'core call before Attach')
   return{protocol='forge-pr-native/1',authority='forge-core',side=side,generation=profile.Generation,groups=expected}
  end,ForgePrConsumerState=function(_,epoch,instance,phase)
   assert(canAttach and epoch==profile.Generation and instance==spec.instance)
   claims[#claims+1]=phase;return true
  end,ForgePrCall=function(_,epoch,group,name,...)
   assert(canAttach and epoch==profile.Generation)
   local api=r.Fixture.boundAPI
   if group=='native'and name=='GetCoreObject'then return assert(api.getCoreObject)(...)end
   return assert(assert(api[group])[name])(...)
  end}
  r=R.new(side,spec.name,core,function()return{generation=profile.Generation,stage=canAttach and 4 or 0}end,profile.Generation)
  assert(calls==0 and r.PR.forgeRuntimeConsumer==nil,'construction must remain passive')
  r.Caller('intruder');assert(r.Control('Describe')==nil and not r.PR.forgeRuntimeConsumer)
  r.Caller('forge-core');assert(r.Control('Describe','old-generation')==nil and not r.PR.forgeRuntimeConsumer)
  assert(r.Control('Describe',nil,'wrong-instance')==nil and not r.PR.forgeRuntimeConsumer)
  local d=r.Control('Describe');assert(d.phase=='prepared'and d.providersReady and not d.proxyReady)
  local runtime,host=r.PR.forgeRuntimeConsumer,r.PR.forgeActivationHost
  local proxy=create({native={GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return side=='server'and 1 or false end},
   resource=spec.name,generation=profile.Generation,instance=spec.instance,isCurrent=function()return true end,
   external={[spec.name]={ForgePrActivationControl=function(_,...)return r.Control(...)end}}})
  assert(proxy.Prepare(),'prepared consumer must be recognized: '..spec.name..':'..side)
  assert(proxy.Progress().phase=='prepared'and proxy.Describe().phase=='prepared')
  assert(runtime==r.PR.forgeRuntimeConsumer and host==r.PR.forgeActivationHost,'preparation must not allocate a second host')
  assert(calls==0,'preparation must not invoke the Forge native API')
  canAttach=true
  assert(proxy.Attach(),'attach failed: '..spec.name..':'..side)
  assert(calls==1 and table.concat(claims,',')=='attaching,committed','one handshake and admission sequence required')
  assert(r.PR.forgeNormalizedFacade.GetResourceName()=='forge-core')
  local catalog=side=='server'and r.PR.forgeNormalizedFacade.GetFrameworkJobs()or r.PR.forgeNormalizedFacade.GetVehiclesByHash()
  assert(type(catalog)=='table','native side catalog must resolve after attach')
  assert(proxy.Close()and proxy.Progress().complete);r.Finish();total=total+1
 end
end
print('PASS installed operational profile: '..total..' real PR entries on server/client; passive construction, early preparation, owner/epoch/instance gates, one host, late handshake/attach/admission/catalogs and cleanup; Cfx/native endpoints simulated')
