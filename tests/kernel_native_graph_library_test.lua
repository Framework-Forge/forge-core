local H=dofile('tests/kernel_harness.lua');local f=H.load('kernel/entry/native_graph_library.lua',H.environment())
local C=dofile('tests/kernel_native_library_harness.lua');local r=C.new('client');r.allocate();assert(r.api.Prepare())
local library=r.api.Library;local touched=false;local mt=getmetatable(library);local prior=mt.__index
mt.__index=function(t,k)if k=='callback'then touched=true;error('legacy RPC must not load')end;return prior(t,k)end
local alive=true;local rpc=r.wire.scopes.client.Native;local count=0
local a=f({library=library,callback=rpc,isCurrent=function()return alive end,fields={'table','math'},extensions={notify=function(...)count=count+1;return ...end},
 required={'table.clone','notify'}})
assert(not touched and a.Library.callback==rpc and a.Library.table.clone({x=2}).x==2)
local values=table.pack(a.Library.notify(nil,false,4));assert(values.n==3 and values[2]==false and count==1)
local p={library=library,callback=rpc,isCurrent=function()return true end,fields={'framework'},extensions={}}
assert(not pcall(f,p));p.fields={'absent'};assert(not pcall(f,p));p.fields={};p.extensions.callback={};assert(not pcall(f,p))
a.Close();assert(not pcall(a.Library.notify,1));r.finish()
print('PASS184 installed PR graph library projection;owned122 callback identity,no legacy init,forbidden framework/loader fields,exact returns and revocation')
