local T=dofile('tests/kernel_native_foundation_harness.lua');local req=T.loader()
local H=dofile('tests/kernel_native_registration_harness.lua');local f=req('kernel.entry.native_registration_input')
for _,side in ipairs({'client','server'})do
 local r=H.new(side);local p={side=side,native=r.native,isCurrent=r.spec.isCurrent,running=coroutine.running,
 getSource=r.native.source,publishExport=r.native.publishExport,available=r.ports.available,prCommand=r.ports.prCommand,oxCommand=r.ports.oxCommand}
 local a=f(p);assert(r.calls==0 and not a.IsBound())
 assert(not pcall(a.Events.listen,'test',function()end))
 local transport=r.factory(r.spec,a.Input);assert(a.Bind(transport));assert(not pcall(a.Bind,transport))
 assert(a.Close()==false);assert(transport.Open())
 local source;local token=a.Events.listen('test',function()source=a.Events.source()end)
 r.fire('test',44);assert(source==44);a.Events.markNetwork('test');assert(r.marked.test)
 assert(a.Events.remove(token));assert(transport.Public.publishExport('native_test',function()return 77 end)~=false)
 assert(r.published.native_test()==77);assert(transport.Close());assert(a.Close())
 assert(not pcall(a.Events.source));assert(r.published.native_test()==nil)
 p.available=nil;assert(not pcall(f,p))
end
print('PASS176 native registration input;zero construction effects,deferred transport,source capture,owned removal,public revocation,missing arbiter rejected')
