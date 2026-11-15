local T=dofile('tests/kernel_native_database_harness.lua');local count=0
local function case(fn)local r=T.new();r.mount();fn(r);r.api.Close();count=count+1 end
case(function(r)r.current=false;assert(not pcall(r.db.query.await,'SELECT x')and #r.calls==0)end)
case(function(r)r.provider.query=function()end;assert(not pcall(r.db.query.await,'SELECT x'))end)
case(function(r)r.api.Close();assert(not pcall(r.api.IsReady)and not pcall(r.db.query,'SELECT x'))end)
case(function(r)r.state='stopped';assert(r.api.IsReady()==false and #r.calls==0)end)
case(function(r)r.fail=true;assert(r.db.query.await('SELECT error')==nil and r.api.Progress().pending==0)end)
case(function(r)r.fail=true;local delivered=false;r.db.query('SELECT error',function(v)assert(v==nil);delivered=true end);assert(delivered and r.api.Progress().pending==0)end)
case(function(r)r.defer=true;local co=coroutine.create(function()return r.db.query.await('SELECT waiting')end);assert(select(2,coroutine.resume(co))=='database132');assert(not r.api.Close());r.deliver();local ok,value=coroutine.resume(co);assert(ok and value==r.result and r.api.Progress().complete)end)
assert(count==7);print('PASS lot132 seven current/ref/Close/readiness/provider-failure/callback-failure/accepted-await cases;no SQL or retries at construction')
