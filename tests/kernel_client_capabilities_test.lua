local U=dofile('tests/kernel_native_ui_harness.lua');local K=dofile('tests/kernel_keybind_harness.lua')
local r=U.new();local H=U.H;r.factory=H.load('../pr_bridge/bridge/delivery/forge_native_client_ui_v2.lua',H.environment());r.allocate();assert(r.api.Open())
local key=K.new(true);r.pr.forgeKeybindScope=key.api
local e=r.ports.environment;e.GetGameBuildNumber=function()return 3258 end
e.vec2=function(x,y)return{x=x,y=y}end
e.GetHashKey=function()return 123 end
for _,name in ipairs({'SendNUIMessage','SetNuiFocus','SetNuiFocusKeepInput'})do e[name]=function()end end
local calls=0;local proxy={};for _,name in ipairs({'addBoxZone','removeZone','addLocalEntity','removeLocalEntity','disableTargeting'})do
 proxy[name]=function(self,...)assert(self==proxy);calls=calls+1;return name=='addBoxZone'and 8 or nil end
end
e.exports={pr_bridge=proxy};e.DoesPickupExist=function()return false end
for _,name in ipairs({'GetPickupObject','GetEntityType','GetPickupCoords','GetPickupHash','NetworkGetEntityIsNetworked','NetworkGetNetworkIdFromEntity','GetEntityModel'})do e[name]=function()error('unexercised native:'..name)end end
local f={IsCurrent=function()return r.current end,Public=r.public,NativeCache={Cache={}},Events=r.scope.api.Events}
local a=H.load('../pr_bridge/bridge/delivery/forge_client_capabilities.lua',H.environment())({
 foundation=f,prCore=r.pr,environment=e,loadPR=r.ports.load,createTasks=r.ports.createTasks,running=coroutine.running,onError=error,targetSelection='native',debug={}})
assert(not a.IsReady()and calls==0);local ok,why=a.Open();assert(ok,tostring(why));assert(a.IsReady())
assert(a.Capabilities.fivem.blips.getPropImageUrl('prop_test'))
assert(a.Capabilities.target.addBoxZone({options={{name='mine'}}})==8)
local closed=a.Close();assert(closed,tostring(a.Scope.Progress().lastError));assert(a.Progress().complete and calls==2)
assert(r.pr.forgeClientUI==r.api and r.api.Progress().phase=='open'and key.api.Progress().phase=='open')
assert(not pcall(a.Capabilities.fivem.blips.getPropImageUrl,'x'))
key.api.Close();r.finish()
print('PASS224 actual installed client tools/vehicle/proximity/target modules;one UI/keybind borrowed;four tool listeners and selective drain')
