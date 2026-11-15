local T=dofile('tests/kernel_native_ui_harness.lua');local r=T.new();local H=T.H
r.factory=H.load('../pr_bridge/bridge/delivery/forge_native_client_ui_v2.lua',H.environment())
r.allocate();assert(not pcall(r.api.Library.openVisualAdminMenu,'parent'));local checks=0
r.public.callback.await=function(name)assert(name=='pr_bridge:ui:isAdmin');checks=checks+1;return false end
local ok,reason=r.api.Open();assert(ok,reason);assert(r.api.Progress().listeners==10)
assert(type(r.api.Streaming.playAnim)=='function')
r.api.Library.openVisualAdminMenu('forge_core_main');r.clock.advance(0);assert(checks==1)
assert(r.pr.forgeClientUI==r.api and r.api.Library.callback==r.public.callback)
assert(r.api.Close());assert(not pcall(r.api.Library.openVisualAdminMenu,'parent'));r.finish()
print('PASS222 same owned UI/ten listeners;visual admin preserves ACL callback;installed playAnim borrowed;closed methods refused')
