-- Installed PR QB/QBX hosts and transport; Cfx dispatch is a virtual resource boundary.
return function(core,readStatus,invokeAsPR)
 local events={};local caller='illenium-appearance';local exports={['forge-core']={ForgeRuntimeStatus=readStatus}}
 for name,fn in pairs(core)do
  exports['forge-core'][name]=function(_,...)return invokeAsPR(fn,...)end
 end
 local e=setmetatable({PRCore={context='client'},
  GetCurrentResourceName=function()return'pr_bridge'end,IsDuplicityVersion=function()return false end,
  GetInvokingResource=function()return caller end,GetConvar=function(_,v)return v end,GetConvarInt=function(_,v)return v end,
  GetGameTimer=function()return 0 end,Wait=function()coroutine.yield('legacy-await')end,
  AddEventHandler=function(name,fn)events[name]=events[name]or{};table.insert(events[name],fn)end,
  exports=setmetatable(exports,{__call=function(_,name,fn)exports[name]=fn end}),
  LoadResourceFile=function(resource,path)
   assert(resource=='pr_bridge');local f=assert(io.open('../pr_bridge/'..path,'rb'));local s=f:read('*a');f:close();return s
  end},{__index=_G})
 e.PRCore.load=function(path,target)
  local file=path:gsub('^@pr_bridge/','')..'.lua'
  return assert(load(e.LoadResourceFile('pr_bridge',file),'@@pr_bridge/'..file,'t',target or e))()
 end
 e.PRCore.load('@pr_bridge/bridge/compat/qbx/host')
 e.PRCore.load('@pr_bridge/bridge/compat/qb/forge_host')()
 local function get(resource,name)
  local result;for _,fn in ipairs(events['__cfx_export_'..resource..'_'..name]or{})do fn(function(value)result=value end)end
  return assert(result,'missing actual legacy export:'..resource..':'..name)
 end
 return{Get=get,Caller=function(value)caller=value end,Stop=function()
  for _,fn in ipairs(events.onClientResourceStop or{})do fn('forge-core')end
 end}
end
