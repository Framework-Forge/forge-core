local T=dofile('tests/kernel_pr_native_api_harness.lua');local count=0
local function case(fn)local r=T.new('server');r.makeProxy();assert(r.nativeAPI.Install());fn(r);r.finish();count=count+1 end
for _,caller in ipairs({'forge-core','qbx_core','foreign',''})do case(function(r)r.nativeCaller=caller;assert(not r.proxy.Prepare())end)end
case(function(r)r.nativeCaller=nil;assert(not r.proxy.Prepare())end)
case(function(r)r.apiReady=false;assert(not r.proxy.Prepare())end)
case(function(r)assert(r.proxy.Prepare());r.callAllowed=false;assert(not pcall(r.proxy.API.framework.GetPlayer,2))end)
case(function(r)assert(r.proxy.Prepare());assert(not pcall(r.surface.exports.ForgePrCall,'stale','core','GetJobs'))end)
case(function(r)assert(r.proxy.Prepare());assert(not pcall(r.surface.exports.ForgePrCall,'native118-server','core','Unknown'))end)
case(function(r)r.handshakeHook=function(d)d.groups.core[#d.groups.core+1]='Extra'end;assert(not r.proxy.Prepare())end)
case(function(r)r.handshakeHook=function()r.proxy.Close()end;assert(not r.proxy.Prepare()and r.proxy.Progress().complete)end)
case(function(r)
    assert(r.proxy.Prepare());local accepted=function()coroutine.yield('pending118');return true,nil,'tail'end
    r.proxy.API.framework.CreateUseableItem('slow118',accepted)
    local held=r.proxy.API.inventory.CanUseItem('slow118');assert(held==accepted)
    local co=coroutine.create(function()return held()end);local ok,v=coroutine.resume(co);assert(ok and v=='pending118')
    assert(r.nativeAPI.Close());local result=table.pack(coroutine.resume(co));assert(result[1]and result[2]==true and result[3]==nil and result[4]=='tail')
    assert(r.proxy.API.framework.GetPlayer(2)==nil)
end)
assert(count==12)
print('PASS lot118 twelve refusal/lifecycle cases;native caller,admission,generation,method,capacity,handshake Close;accepted legacy callback preserved')
