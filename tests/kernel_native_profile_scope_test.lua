local M=dofile('tests/kernel_native_profile_harness.lua');local count=0
local function server(fn)local r=M.server();fn(r);r.finishProfile();count=count+1 end
server(function(r)r.profilePorts.side='bad';assert(not pcall(r.allocateProfile))end)
server(function(r)r.profilePorts.prCore={forgeOwnedCallbacks={Side='client'}};assert(not pcall(r.allocateProfile))end)
server(function(r)r.allocateProfile();assert(not r.profile.Start()and not r.profile.Install()and #r.databaseCalls==0)end)
server(function(r)r.allocateProfile();r.nativeCurrent=false;assert(not r.profile.Prepare('en'));r.nativeCurrent=true end)
server(function(r)r.allocateProfile();assert(r.profile.Stop()and not r.profile.Prepare('en')and r.seed.IsCurrent())end)
local c=M.client();c.allocateProfile();assert(c.profile.Prepare());c.wire.Initialize();c.surface.Open()
c.nativeReady=false;assert(not c.profile.Install());assert(c.profile.Progress().phase=='closing'or c.profile.Progress().phase=='closed')
c.finishProfile();count=count+1
local d=M.client();d.allocateProfile();assert(d.profile.Prepare());d.wire.Initialize();d.surface.Open();assert(d.profile.Install());d.runtimeImports.pollNative();assert(d.profile.Start())
local co=coroutine.create(function()return d.profile.UI.Library.inputDialog('Pending',{{type='input',label='x'}})end)
assert(select(2,coroutine.resume(co))=='ui133');assert(not d.profile.Stop()and d.seed.IsCurrent());assert(coroutine.resume(co));assert(d.profile.Poll());d.finishProfile();count=count+1
assert(count==7);print('PASS lot135 seven side/RPC/order/stale/Stop/refused-Install/dialog-drain cases;no implicit activation or borrowed seed shutdown')
