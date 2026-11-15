local H=dofile('tests/kernel_harness.lua');local make=H.load('kernel/pr_integration/operational_profile.lua',H.environment())
for _,side in ipairs({'server','client'})do
 for _,resource in ipairs({'forge-core','pinel-admin'})do
  for _,state in ipairs({'started','starting','uninitialized','missing','stopped','stopping','unknown'})do
   local current=state;local calls=0;local replicated='entry29';local pr={}
   local e=H.environment({PRCore=pr,os={time=function()return 1 end},IsDuplicityVersion=function()return side=='server'end,
    GetCurrentResourceName=function()return resource end,GetGameTimer=function()return 2 end,
    SetConvarReplicated=function(_,v)replicated=v end,
    GetConvar=function(key,default)return key=='forge:bootGeneration'and replicated or default end,
    GetResourceState=function(name)assert(name=='forge-loadscreen','other consumers must never become optional');calls=calls+1;return current end})
   pr.load=function(path,target)return H.load(path:gsub('^@forge%-core/','')..'.lua',target)end
   local profile=make(e);assert(calls==0,'reading framework configuration must not probe resources')
   local list=profile.Consumers(side)
   local omitted=resource=='forge-core'and(state=='missing'or state=='stopped'or state=='stopping')
   assert(#list==(omitted and 43 or 44),'optional loadscreen selection: '..side..':'..resource..':'..state)
   local found=false;for _,row in ipairs(list)do if row.name=='forge-loadscreen'then found=true end end
   assert(found~=omitted and profile.Get('forge-loadscreen',side).instance=='forge-loadscreen:'..side)
   assert(profile.Get('ox_inventory','server').inventory==true and profile.QBEnabled==true)
   local initialCalls=calls;current=state=='started'and'missing'or'started'
   assert(#profile.Consumers(side)==#list and calls==initialCalls,'selection must not drift within an activation')
   list[1].name='tamper';assert(profile.Consumers(side)[1].name~='tamper','profile remains copy based')
   assert(#profile.Consumers(side=='server'and'client'or'server')==44,'only own core side selects a boot set')
  end
 end
end
print('PASS operational 44-consumer profile on both sides: inactive loadscreen omitted from core boot only; native library catalog/epoch/identities preserved; mandatory OX retained; stable copies')
