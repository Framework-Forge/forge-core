local T=dofile('tests/kernel_native_ui_harness.lua');local H=T.H;local r=T.new()
local f={Side='client',IsCurrent=function()return r.current end}
local a=H.load('../pr_bridge/bridge/delivery/forge_streaming_ports.lua',H.environment())({prCore=r.pr,foundation=f})
assert(not pcall(a.Streaming.requestModel,123)and r.pr.forgeClientUI==nil)
r.allocate();assert(not pcall(a.Streaming.requestModel,123));assert(r.api.Open())
local out=table.pack(a.Streaming.requestModel(123));assert(out.n==2 and out[1]==true and out[2]==123)
r.media.loaded=false;local continued=false
local co=coroutine.create(function()a.Streaming.requestModel(456,1000);continued=true end)
assert(coroutine.resume(co));assert(a.Progress().pending==1 and not a.Close())
r.media.loaded=true;local ok,reason=coroutine.resume(co);assert(not ok and tostring(reason):find('expired',1,true))
assert(not continued and a.Close());assert(r.pr.forgeClientUI==r.api,'borrowed UI must remain owned')
r.finish()
print('PASS195 canonical133 streaming borrowed without new host/collector;exact tuple,pending drain,late return fenced,UI owner retained')
