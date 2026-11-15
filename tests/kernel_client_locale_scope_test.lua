local T=dofile('tests/kernel_client_locale_harness.lua');local r=T.new();r.prepareLocale();assert(r.installLocale())
r.locales.readHook=function()coroutine.yield()end
local co=coroutine.create(function()r.emit('ox_lib:setLocale','pt-br')end)
assert(coroutine.resume(co));assert(not r.api.Stop());assert(#r.fixture.state.ClientMediaContext.Sequence.Progress().ledger==0,'pending before58')
r.locales.readHook=nil;assert(coroutine.resume(co));assert(r.api.Poll()and r.api.Progress().complete)
local cancel=T.new();cancel.allocate();cancel.locales.readHook=function()coroutine.yield()end
local c=coroutine.create(function()assert(not cancel.api.Prepare())end);assert(coroutine.resume(c));cancel.api.Stop()
cancel.locales.readHook=nil;assert(coroutine.resume(c));assert(cancel.api.Graph==nil and cancel.api.Progress().complete)
for _,change in ipairs({'owner','locale','graph'})do
    local stale=T.new();stale.prepareLocale();assert(stale.installLocale());local fn=stale.api.Context.Imports.Translate
    if change=='owner'then stale.fixture.state.ClientLocaleContext={}
    elseif change=='locale'then stale.api.Locale.Translate=function()return'x'end
    else stale.fixture.state.ClientDomainAssembly={}end
    assert(not stale.api.IsCurrent()and stale.surface.exports.GetPlayerData()==nil and not pcall(fn,'x'))
    assert(not stale.api.Stop()and not stale.api.Progress().complete)
end
local bad=T.new();bad.locales.override={en='{bad'};bad.allocate();assert(not pcall(bad.api.Prepare)and bad.api.Graph==nil)
local collision=T.new();collision.prepareLocale();collision.surface.exports.getLocale=function()return'foreign'end
assert(not collision.installLocale()and collision.surface.exports.getLocale()=='foreign')
local late=T.new();late.prepareLocale();late.onListen=function(entry)if entry.name=='ox_lib:setLocale'then late.api.Stop()end end
assert(not late.installLocale()and late.active('ox_lib:setLocale')==0)
print('PASS lot75 scope:pending load/drain,preparation cancellation,stale closures,malformed local data,foreign export and interrupted listener receipt;virtual only')
