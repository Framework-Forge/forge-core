local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local calls=0;local p={side='client',inspectFunction=function()return{source='@native/virtual.lua'}end,
 providers={},createRaw=function()calls=calls+1;error('unapproved construction')end}
local a=req('kernel.entry.owned_boot_preparation')(p)
assert(not a.Inspect().accepted and not a.Prepare()and calls==0)
assert(a.GetPreparedEntry()==nil and a.GetPreparedRaw()==nil)
assert(a.Stop()and a.Progress().complete)
assert(a.GetPreparedEntry()==nil and a.GetPreparedRaw()==nil)
p.side='server';local b=req('kernel.entry.owned_boot_preparation')(p);assert(not b.Prepare()and b.GetPreparedEntry()==nil and calls==0)
assert(b.Stop())
print('PASS228 original169 gates on both sides;canonical entry/raw access unavailable before preparation/after close;no unapproved effects')
