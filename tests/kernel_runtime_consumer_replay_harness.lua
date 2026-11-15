-- Test boundary only: real PR consumer entry/profile/host; Cfx and providers are virtual.
local F=dofile('tests/kernel_native_bindings_harness.lua');local H=F.H
local T={H=H}
function T.new(side,resource,core,readStatus,generation)
 local fixture=F.new(side,side=='server'and resource=='ox_inventory')
 fixture.boundResource=resource
 local services,n=fixture.services,fixture.bindingPorts.native
 local exports,handlers,networks={}, {}, {};local serial=0
 local caller='forge-core';local clock=0
 local e=H.environment({coroutine=coroutine,load=load,debug=debug,json={decode=function(t)return t end},
  GetCurrentResourceName=function()return resource end,IsDuplicityVersion=function()return side=='server'and 1 or false end,
  GetInvokingResource=function()return caller end,GetGameTimer=function()return clock end,
  GetConvarInt=function(_,default)return default end,
  GetConvar=function(key,default)
   if key=='forge:bootGeneration'then return generation end
   if key=='qbx:enablebridge'then return'true'end
   return default
  end,
  GetResourceState=function(name)return name=='qbx_core'and'missing'or'started'end,
  GetResourceMetadata=function(name,key,index)
   if name=='forge-core'and key=='forge_kernel_bootstrap'then return'owned/1'end
   if name==resource and key=='pr_bridge_framework'then return({'forge','qbx','qb'})[index+1]end
  end,
  GetNumResourceMetadata=function(name,key)return name==resource and key=='pr_bridge_framework'and 3 or 0 end,
  AddEventHandler=function(name,fn)serial=serial+1;handlers[serial]={name=name,fn=fn};return serial end,
  RemoveEventHandler=function(id)handlers[id]=nil;return true end,
  SetTimeout=function()end,Wait=function()error('unexpected synchronous boot wait')end})
 for name,value in pairs(n)do if rawget(e,name)==nil then e[name]=value end end
 for _,name in ipairs(H.load('../pr_bridge/bridge/runtime/forge/native_names.lua',H.environment()))do
  if rawget(e,name)==nil then e[name]=function()error('unexercised Cfx boundary: '..name)end end
 end
 e.Entity=function()error('unexercised entity boundary')end
 e.GetVehicleNumberPlateText=function()error('unexercised plate boundary')end
 e.RegisterNetEvent=function(name,fn)networks[name]=true;if fn then return e.AddEventHandler(name,fn)end end
 e.exports=setmetatable({['forge-core']=core},{__call=function(_,name,fn)assert(not exports[name]);exports[name]=fn;return true end})
 e._G=e
 e.LoadResourceFile=function(res,path)
  assert(res=='pr_bridge'or res=='forge-core')
  local file=io.open((res=='pr_bridge'and'../pr_bridge/'or'')..path,'rb')
  if not file then return end;local data=file:read('*a');file:close();return data
 end
 local pr=fixture.pr;e.PRCore=pr;pr.context=side
 pr.load=function(path,target)
  local res,name=path:match('^@([^/]+)/(.+)$');assert(res=='pr_bridge'or res=='forge-core')
  return H.load((res=='pr_bridge'and'../pr_bridge/'or'')..name:gsub('%.lua$','')..'.lua',target or e)
 end
 if side=='server'and resource=='ox_inventory'then
  local inv=assert(services.inventoryBridge);e.server=inv.server
  e.require=function(name)
   if name=='modules.inventory.server'then return inv.Inventory end
   assert(name=='modules.state.server');return{clear=inv.clearState}
  end
 end
 local public={cache=services.cache or{GetResourceState=function()end,get=function()end},inventory=services.inventory,banking=services.banking,
  notify=services.notify,textuiAdapter=services.textui,database=services.db,
  callback={register=function(name,fn)return e.RegisterNetEvent(name,fn)end}}
 local api=pr.load('@pr_bridge/bridge/runtime/forge/operational_consumer_start',e)({environment=e,prCore=pr,public=public,config={compatFramework='forge'}})
 assert(pr.forgeRuntimeConsumer==nil,'consumer import must stay passive')
 assert(api.Complete(public))
 local r={Fixture=fixture,Environment=e,PR=pr,Service=api,Public=public,Exports=exports}
 function r.Control(op,epoch,instance)return assert(exports.ForgePrActivationControl)(op,epoch or generation,instance or(resource..':'..side))end
 function r.Caller(value)caller=value end
 function r.Close()return api.Close()end
 function r.Finish()assert(r.Close());fixture.finish()end
 -- Preserve the true status source used by actual public PR facade waits.
 core.ForgeRuntimeStatus=core.ForgeRuntimeStatus or function()return readStatus()end
 return r
end
return T
