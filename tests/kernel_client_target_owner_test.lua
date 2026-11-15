local H=dofile('tests/kernel_harness.lua');local calls={};local callback;local external={}
for _,name in ipairs({'addBoxZone','removeZone','addLocalEntity','removeLocalEntity','disableTargeting'})do
 external[name]=function(self,...)assert(self==external);calls[#calls+1]={name,table.pack(...)}
  if name=='addBoxZone'then callback=(...).options[1].onSelect;return 17 end
 end
end
local e=H.environment({exports={pr_bridge=external}})
local function loadPR(path,env)return H.load('../pr_bridge/'..path:sub(12)..'.lua',env)end
local create=loadPR('@pr_bridge/bridge/delivery/forge_client_target_owner',e)
local p={selected='native',environment=e,loadPR=loadPR,isCurrent=function()return true end}
local a=create(p);assert(#calls==0 and not pcall(a.Target.addBoxZone,{}));assert(a.Open())
local touched=0;local input={options={{name='mine',onSelect=function()touched=touched+1 end}}}
assert(a.Target.addBoxZone(input)==17);callback();assert(touched==1 and input.options[1].onSelect~=callback)
a.Target.addLocalEntity(12,{{name='npc'}});a.BeginDrain();callback();assert(touched==1)
assert(a.Close());assert(calls[3][1]=='removeZone'and calls[3][2][1]==17 and calls[4][1]=='removeLocalEntity')
assert(not pcall(a.Target.addBoxZone,input));p.selected='ox';assert(not pcall(create,p))
print('PASS221 installed PR native target;receiver/returns;selective cleanup;retained callbacks revoked;selection refused')
