local T=dofile('tests/kernel_native_seed_harness.lua');local count=0
local function case(fn)local r=T.unit();fn(r);r.finishSeed();count=count+1 end
for _,side in ipairs({'server','client'})do local r=T.unit(side);local before=r.wire[side].active();r.allocateSeed();assert(r.seed.Prepare())
    assert(r.wire[side].active()==before and r.seed.IO.Codec.decode(r.seed.IO.Files.LoadResourceFile('forge-core','kernel/locales/pt-br.json')))
    assert(r.seed.Close()and r.wire.scopes[side].Owners.native.IsReady()and #r.ioFixture.writes==0);r.finishSeed()
end
case(function(r)r.seedPorts.rpc={};assert(not pcall(r.allocateSeed)and r.ioFixture.core.forgeNativeSeed==nil)end)
case(function(r)local foreign={};r.ioFixture.core.forgeNativeSeed=foreign;assert(not pcall(r.allocateSeed)and r.ioFixture.core.forgeNativeSeed==foreign);r.ioFixture.core.forgeNativeSeed=nil end)
case(function(r)r.seedPorts.native.IsDuplicityVersion=function()return false end;assert(not pcall(r.allocateSeed)and r.ioFixture.core.forgeNativeSeed==nil)end)
case(function(r)local foreign={};r.public.cache=foreign;assert(not pcall(r.allocateSeed)and r.public.cache==foreign and r.ioFixture.core.forgeNativeSeed==nil)end)
case(function(r)r.allocateSeed();r.seedLoadHook=function(path)if path:find('library/init',1,true)then r.seed.Close()end end;assert(not r.seed.Prepare()and r.seed.Progress().complete and r.public.cache==nil)end)
case(function(r)r.allocateSeed();assert(r.seed.Prepare());r.wire.scopes.server.Close();assert(not r.seed.IsCurrent());assert(r.seed.Close())end)
assert(count==6);print('PASS lot130 seed both sides/no extra listeners/actual127 locale,plus six RPC-owner/occupied/side/partial-construction/Close/borrowed-owner cases')
