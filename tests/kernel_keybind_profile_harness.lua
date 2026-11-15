local P=dofile('tests/kernel_progress_shutdown_profile_harness.lua');local K=dofile('tests/kernel_keybind_harness.lua');local T={P=P,K=K,H=P.H}
function T.new(side)
 local r=P.new(side);r.keyFixture=K.new(false);r.keyCommands={}
 if side=='client'then
  local n=r.seedUnit.seedPorts.native
  for _,name in ipairs({'RegisterKeyMapping','IsPauseMenuActive','GetControlInstructionalButton','joaat'})do if n[name]==nil then n[name]=r.keyFixture.environment[name]end end
  local original=r.profilePorts.bootstrap.registration.native.RegisterCommand
  r.profilePorts.bootstrap.registration.native.RegisterCommand=function(name,fn,restricted)r.keyCommands[name]=fn;return original(name,fn,restricted)end
 end
 r.factory166=T.H.load('kernel/entry/keybind_native_profile.lua',T.H.environment())
 function r.allocate166()r.profile=r.factory166(side=='server'and r.fixture.base or r.fixture.state,r.profilePorts);r.api=side=='server'and r.profile or r.profile.Bootstrap;return r.profile end
 function r.open166()
  local p=r.allocate166();assert(p.Prepare('pt-br'));r.surface.Open();assert(p.Install())
  if side=='client'then r.runtimeImports.pollNative()end;assert(p.Start());return p
 end
 return r
end
return T
