local T=dofile('tests/kernel_keybind_harness.lua');local r=T.new(false);local current=true
r.ports.isCleanupCurrent=function()return current end
local api=T.H.load('../pr_bridge/bridge/delivery/forge_client_keybinds_cleanup.lua',T.H.environment())(r.ports)
assert(api.Open());local key=api.Keybind({name='x',defaultKey='e'})
assert(api.CloseIngress()and api.Keybind.get('x')==key and key.disabled)
assert(not pcall(api.Keybind,{name='y',defaultKey='f'}));assert(api.Keybind.remove('x')and api.Keybind.get('x')==nil)
current=false;assert(not pcall(api.Keybind.get,'x'));current=true;assert(api.Close()and not pcall(api.Keybind.get,'x'))
print('PASS166 owned get/remove available only for cleanup;creation/command ingress closed;stale cleanup and closed getter refused')
