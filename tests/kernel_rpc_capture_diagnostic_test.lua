local T=dofile('tests/kernel_owned_rpc_harness.lua');local load=T.H.load
T.H.load=function(path,env)if path==T.path then env.debug=debug end;return load(path,env)end
local w=T.new();T.H.load=load;w.open()
for _,side in ipairs({'server','client'})do
 for _,protocol in ipairs({'native','ox'})do
  local scope=w.scopes[side].Owners[protocol];local before=w.scopes[side].Progress().leases
  local name='diagnostic:'..side..':'..protocol
  local ok,why=pcall(scope.CaptureRegister,name,function()return'forbidden'end)
  assert(not ok and tostring(why):find(name,1,true)and tostring(why):find('stack traceback',1,true),'late registration must identify callback and caller stack: '..tostring(why))
  assert(w.scopes[side].Progress().leases==before,'diagnostic must not allocate a callback lease')
  local handler=scope.Capture(name,function()scope.CaptureRegister(name,function()return'allowed'end)end)
  assert(handler()=='allowed','valid owned capture must remain usable')
 end
end
w.close()
print('PASS owned capture diagnostic server/client/native/ox: late registration denied with name/stack and no lease; legitimate capture retained')
