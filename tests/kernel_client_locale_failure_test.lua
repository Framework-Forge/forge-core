local T=dofile('tests/kernel_client_locale_harness.lua');local r=T.new();local remove=r.localePorts.localeBinding.remove
r.localePorts.localeBinding.remove=function(token)if r.refuse then return false end;return remove(token)end
r.prepareLocale();assert(r.installLocale());r.refuse=true
r.api.Stop();r.clock.advance(120000);r.api.Poll();assert(not r.api.Progress().complete and r.api.Progress().localeListenerRemaining)
r.refuse=false;r.api.Poll();assert(r.api.Progress().complete,'failed physical removal stays diagnostic until retry')
local fail=T.new();fail.prepareLocale();fail.surface.failAt=1
assert(not fail.installLocale()and fail.api.Progress().locale.complete)
local start=T.new();start.prepareLocale();assert(start.installLocale());start.readyHook=function()start.emit('onResourceStop','forge-core')end
local ok,value=pcall(start.api.Start);assert(ok and value==false and start.api.Progress().complete)
print('PASS lot75 failures:physical removal retry,partial installation and Stop during Start cannot reopen client locale')
