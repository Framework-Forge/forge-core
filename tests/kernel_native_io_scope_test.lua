local T=dofile('tests/kernel_native_io_harness.lua');local count=0
local function case(fn)local r=T.new();fn(r);if r.api then r.api.Close()end;count=count+1 end
case(function(r)r.name='qbx_core';assert(not pcall(r.allocate))end)
case(function(r)r.core.context='client';assert(not pcall(r.allocate))end)
case(function(r)r.allocate();r.current=false;assert(not pcall(r.api.JSON.loadJson,'data/x'))end)
case(function(r)r.allocate();r.core.loadJson=function()return{}end;assert(not pcall(r.api.JSON.loadJson,'data/x'))end)
case(function(r)r.allocate();assert(not pcall(r.api.JSON.loadJson,'../escape')and #r.writes==0)end)
case(function(r)r.allocate();local co=coroutine.create(function()return r.api.Files.LoadResourceFile('forge-core','data/virtual127.json')end)
    r.readHook=function()coroutine.yield('accepted127')end;local ok,v=coroutine.resume(co);assert(ok and v=='accepted127'and not r.api.Close());assert(coroutine.resume(co));assert(r.api.Progress().complete)end)
case(function(r)r.allocate();r.saveResult=0;assert(not r.api.JSON.saveJson('data/virtual127.json',{value=1}))end)
case(function(r)r.allocate();r.files['forge-core/data/virtual127.json']='broken';r.files['forge-core/data/virtual127.json.bak']='broken';assert(not pcall(r.api.JSON.loadJsonRecovery,'data/virtual127.json')and #r.writes==0)end)
assert(count==8);print('PASS lot127 eight native identity/side/current/refs/path/accepted-read/BOOL0/corruption cases;no operational writes')
