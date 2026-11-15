-- Export-boundary fixture for older isolated activation tests. Uses actual registry.
-- Full host + validation/network events are exercised by kernel_callback_public_host_test.
return function(H)
 local registry=H.load('../pr_bridge/bridge/callback/registry.lua',H.environment({
  GetCurrentResourceName=function()return 'pr_bridge'end,GetInvokingResource=function()return 'forge-core'end,
  AddEventHandler=function()end}))
 return {oxService=function(_,name,...)
  local fn=({setValidCallback=registry.set,isCallbackValid=registry.valid})[name]
  assert(fn,'unexpected host service: '..tostring(name));return fn(...)
 end}
end
