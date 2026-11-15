local T=dofile('tests/kernel_native_registration_harness.lua');local H=T.H
local create=H.load('kernel/entry/native_registration_input.lua',H.environment())
for _,side in ipairs({'server','client'})do
 for _,value in ipairs({false,0,1,'ignored'})do
  local r=T.new(side);local calls=0
  r.native.RegisterCommand=function(name,fn,restricted)calls=calls+1;r.commands[name]={handler=fn,restricted=restricted};return value end
  local inputs=create({side=side,native=r.native,isCurrent=function()return r.current end,running=coroutine.running,
   getSource=r.native.source,publishExport=r.native.publishExport,available=r.ports.available,
   prCommand=function()return false end,oxCommand=function()return false end})
  local a=r.factory(r.spec,inputs.Input);assert(a.Open());assert(a.Public.nativeCommand('cmd',function()return'run'end,true)==true)
  assert(calls==1 and r.commands.cmd.restricted==true and r.commands.cmd.handler()=='run')
  assert(not a.Public.nativeCommand('cmd',function()end)and calls==1,'duplicate blocked before void native')
  assert(a.Public.prCommand('pr',{},function()end)==false and a.Public.oxCommand('ox',{},function()end)==false,'real provider refusal is not normalized')
  assert(a.Close());assert(r.commands.cmd.handler()==nil)
 end
 local r=T.new(side);r.native.RegisterCommand=function()error('native registration threw',0)end
 local inputs=create({side=side,native=r.native,isCurrent=function()return r.current end,running=coroutine.running,getSource=r.native.source,
  publishExport=r.native.publishExport,available=r.ports.available,prCommand=r.ports.prCommand,oxCommand=r.ports.oxCommand})
 local a=r.factory(r.spec,inputs.Input);assert(a.Open());local ok,why=pcall(a.Public.nativeCommand,'throws',function()end)
 assert(not ok and tostring(why):find('native registration threw',1,true));assert(not a.Public.nativeCommand('throws',function()end),'uncertain registration not reused')
 assert(a.Close())
end
print('PASS native void contract on server/client: residual values ignored, ACL/payload preserved, duplicates/exceptions/closed scopes and PR/OX rejection preserved')
