local H=dofile('tests/kernel_harness.lua')
local tasks=H.load('../pr_bridge/bridge/runtime/owned_tasks.lua',H.environment())
local create=H.load('../pr_bridge/bridge/delivery/forge_client_engine_scope.lua',H.environment())
local messages={};local current=true
local env={CreateThread=function()end,SetTimeout=function()end,Wait=function()end,
 SendNUIMessage=function()error('Forge has no local UI frame')end,
 TriggerEvent=function(name,action,data)messages[#messages+1]={name,action,data}end}
local scope=create({foundation={IsCurrent=function()return current end,Events={}},prCore={},environment=env,
 createTasks=tasks,running=coroutine.running,onError=error})
assert(not pcall(scope.Environment.SendNUIMessage,{action='gizmo:hide'}))
local payload={visible=true}
assert(scope.Open(function(e)
 e.SendNUIMessage({action='gizmo:show',data=payload})
 scope.AddCleanup('gizmo',function()e.SendNUIMessage({action='gizmo:hide'})end)
end))
assert(#messages==1 and messages[1][1]=='pr_bridge:ui:send'and messages[1][2]=='gizmo:show'and messages[1][3]==payload)
assert(scope.Close());assert(#messages==2 and messages[2][2]=='gizmo:hide')
assert(not pcall(scope.Environment.SendNUIMessage,{action='gizmo:show'}));assert(#messages==2)
print('PASS private tool messages use existing PR NUI host, preserve payload and cleanup, no focus claim, closed scope refused')
