local T=dofile('tests/kernel_native_ui_harness.lua');local count=0
local function case(fn)local r=T.new();fn(r);r.finish();count=count+1 end
case(function(r)r.pr.context='server';assert(not pcall(r.allocate))end)
case(function(r)r.pr.forgeClientUI={};assert(not pcall(r.allocate))end)
case(function(r)r.allocate();r.current=false;assert(not r.api.Open()and #r.scope.bus==0)end)
case(function(r)r.allocate();r.scope.api.Close();assert(not r.api.Open()and r.api.Progress().uncertain)end)
case(function(r)r.allocate();assert(r.api.Open());local held=r.api.Library.showContext;r.api.Close();assert(not pcall(held,'x'))end)
case(function(r)r.allocate();assert(r.api.Open());local token=r.scope.bus[1];r.scope.removeHook=function(t)if t==token then return false end end;assert(not r.api.Close()and not r.api.Progress().complete);r.scope.removeHook=nil;assert(r.api.Close()and r.api.Progress().complete)end)
case(function(r)r.allocate();assert(r.api.Open());local co=coroutine.create(function()return r.api.Library.inputDialog('Pending',{{type='input',label='x'}})end);assert(select(2,coroutine.resume(co))=='ui133');assert(not r.api.Close()and r.api.Progress().pending==1);assert(coroutine.resume(co));assert(r.api.Close()and r.api.Progress().complete)end)
assert(count==7);print('PASS lot133 seven side/owner/stale/closed-registry/closed-method/removal-retry/dialog-drain cases;no default UI or second host')
