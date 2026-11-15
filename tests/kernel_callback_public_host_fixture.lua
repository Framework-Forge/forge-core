-- Actual PR ox_host/registry/adapters; only resource boundaries, natives and IO are virtual.
return function(H,endpoint,side,backup)
 local base=endpoint.env;local published={};local caller
 local root=backup and '../../[backup]/pr_bridge/' or '../pr_bridge/'
 local function read(path)local f=assert(io.open(root..path,'rb'));local s=f:read('*a');f:close();return s end
 local e=setmetatable({GetCurrentResourceName=function()return 'pr_bridge'end,
  GetInvokingResource=function()return caller end,Config={compatOx_lib=true},
  GetResourceState=function()return 'missing'end,GetResourceMetadata=function()end,
  GetNumResourceMetadata=function()return 0 end,GetConvar=function(_,v)return v end,
  GetConvarBool=function(_,v)return v end,GetResourceKvpString=function()end,SetResourceKvp=function()end,
  RegisterCommand=function()end,RegisterKeyMapping=function()end,AddStateBagChangeHandler=function()end,
  GetGameBuildNumber=function()return 3258 end,IsNuiFocusKeepingInput=function()return false end,
  LocalPlayer={state={}},json={decode=function()return{cancel_progress='Cancel',open_radial_menu='Radial'}end},
  LoadResourceFile=function(resource,path)assert(resource=='pr_bridge');return read(path)end,
  Bridge={cache={resource='pr_bridge',game=side=='server'and'fxserver'or'fivem',ped=123,playerId=1},onCache=function()end},
  PRCore={context=side}}, {__index=function(_,key)
   if key=='source'then return base.source end
   local value=rawget(base,key);if value~=nil then return value end
   return _G[key]
  end})
 e._G=e
 e.table=H.copy(table);e.table.wipe=function(t)for k in pairs(t)do t[k]=nil end end
 e.table.clone=H.copy;e.table.type=H.tableType
 e.exports=setmetatable({}, {__call=function(_,name,fn)published[name]=fn end})
 e.PRCore.load=function(path,scope)
  if path=='bridge.targets.native.api'then return{_collections=function()return{global={}}end}end
  local file=path:sub(1,1)=='@'and path:match('^@pr_bridge/(.*)')or path:gsub('%.','/')
  return H.load(root..file..'.lua',scope or e)
 end
 e.Bridge.github=e.PRCore.load('bridge.github.'..side)
 e.Bridge.fivem={vehicleProperties={get=function()end,set=function()end,queue=function()end,applyQueue=function()end},
  ace={addAce=function()end,removeAce=function()end,addPrincipal=function()end,removePrincipal=function()end,isPlayerAceAllowed=function()end},
  state={requestSet=function()end},net={},streaming={}}
 e.Bridge.progressProps={publish=function()end,render=function()end}
 e.Bridge.nativeProgress={progressActive=function()return false end,cancelProgress=function()end,progressBar=function()end,progressCircle=function()end}
 e.PRCore.load('bridge.compat.ox_lib.ox_host')
 local api={env=e,registry=e.Bridge.callbackRegistry}
 function api.Service(owner,name,...)
  local previous=caller;caller=owner;local out=table.pack(pcall(published.oxService,name,...));caller=previous
  assert(out[1],out[2]);return table.unpack(out,2,out.n)
 end
 api.proxy={oxService=function(_,...)return api.Service('forge-core',...)end}
 return api
end
