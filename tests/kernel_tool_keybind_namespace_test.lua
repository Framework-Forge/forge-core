local K=dofile('tests/kernel_keybind_harness.lua');local H=K.H
for _,collision in ipairs({false,true})do
 local r=K.new(false);local env=r.environment;local rawCommands=r.commands
 local foreign=function()error('foreign PR handler invoked')end
 rawCommands['+pr_bridge_gizmo_confirm']=foreign;rawCommands['-pr_bridge_gizmo_confirm']=foreign
 if collision then rawCommands['+forge-core_pr_bridge_gizmo_confirm']=foreign end
 local public={};env.pr_lib=public;r.core.forgeCoreBootstrap={Public=public};env.PRCore=r.core
 r.core.load=function(path,target)
  local prefix=path:sub(1,12)=='@forge-core/'and''or'../pr_bridge/'
  return H.load(prefix..path:gsub('^@[^/]+/','')..'.lua',target or env)
 end
 env.IsDuplicityVersion=function()return false end;env.GetNumResourceMetadata=function()return 0 end
 env.GetResourceMetadata=function(_,key)if key=='forge_kernel_bootstrap'then return'owned/1'end end
 env.GetRegisteredCommands=function()local result={};for name in pairs(rawCommands)do result[#result+1]={name=name,resource='pr_bridge'}end;return result end
 env.exports=setmetatable({}, {__call=function()end})
 local config=H.load('kernel/pr_integration/core_runtime_configuration.lua',H.environment())({environment=env,
  profile={Generation='keys29',Get=function()return{instance='ox_inventory:server'}end},getCandidate=function()end})
 local tokens={};env.AddEventHandler=function(name,fn)tokens[#tokens+1]=fn;return #tokens end
 env.RemoveEventHandler=function()return true end;env.RegisterNetEvent=function()end;env.CreateThread=function()end;env.Citizen={}
 local input=H.load('kernel/entry/native_registration_input.lua',H.environment())({side='client',native=env,
  isCurrent=function()return r.current end,running=coroutine.running,getSource=function()return 0 end,
  available=config.PhysicalOptions.registration.available,publishExport=function()end,prCommand=function()end,oxCommand=function()end})
 local transport=H.load('kernel/entry/native_registration.lua',H.environment())({side='client',isCurrent=function()return r.current end,isReady=function()return true end},input.Input)
 assert(input.Bind(transport));assert(transport.Open())
 r.ports.public=transport.Public;r.ports.isCleanupCurrent=function()return r.current end
 local keys=H.load('../pr_bridge/bridge/delivery/forge_client_keybinds_cleanup.lua',H.environment())(r.ports)
 assert(keys.Open())
 local scope=H.load('../pr_bridge/bridge/delivery/forge_client_engine_scope.lua',H.environment())({
  foundation={IsCurrent=function()return r.current end,Events=transport.Events},prCore=r.core,environment=env,
  createTasks=r.ports.createTasks,running=coroutine.running,onError=error})
 local pressed,released=0,0
 local spec={name='pr_bridge_gizmo_confirm',description='Confirmar',defaultKey='RETURN',
  onPressed=function()pressed=pressed+1 end,onReleased=function()released=released+1 end}
 local binding;local ok,err=scope.Open(function(e)binding=e.PRAddKeybind(spec)end)
 if collision then
  assert(not ok and tostring(err):find('keybind command namespace refused:+forge-core_pr_bridge_gizmo_confirm',1,true),tostring(err))
  assert(rawCommands['+forge-core_pr_bridge_gizmo_confirm']==foreign,'collision overwrote foreign command')
 else
  assert(ok,tostring(err));assert(binding.name=='forge-core_pr_bridge_gizmo_confirm')
  assert(spec.name=='pr_bridge_gizmo_confirm'and spec.safeName==nil,'caller input mutated')
  assert(rawCommands['+pr_bridge_gizmo_confirm']==foreign and rawCommands['-pr_bridge_gizmo_confirm']==foreign)
  assert(r.mappings[1][1]=='+forge-core_pr_bridge_gizmo_confirm'and r.mappings[1][4]=='RETURN')
  r.fire('+forge-core_pr_bridge_gizmo_confirm');r.fire('+forge-core_pr_bridge_gizmo_confirm');assert(pressed==1)
  r.fire('-forge-core_pr_bridge_gizmo_confirm');assert(released==1)
  assert(scope.Close());r.fire('+forge-core_pr_bridge_gizmo_confirm');assert(pressed==1)
  r.flush();assert(keys.Close());r.fire('+forge-core_pr_bridge_gizmo_confirm');assert(pressed==1)
  assert(transport.Close());assert(input.Close());assert(config.Close())
 end
end
print('PASS tool names isolated from PR, original spec/key preserved, press/release/cleanup fenced, foreign Forge name still refused')
