local T=dofile('tests/kernel_engine_profile_harness.lua');local count=0
for _,which in ipairs({'engine','domain','native'})do
 for _,mode in ipairs({'refused','thrown','cancelled'})do
  local r=T.new('server');local p=r.allocate149();assert(p.Prepare('pt-br'));r.surface.Open()
  local child=which=='engine'and p.Delegate or which=='domain'and p.Delegate.Delegate or p.Bootstrap
  local marker='isolated-install-'..which..'-'..mode
  child.Install=function()
   if mode=='thrown'then error(marker,0)end
   if mode=='cancelled'then p.Stop();return true end
   return false,marker,nil,73
  end
  local out=table.pack(pcall(p.Install))
  if mode=='thrown'then assert(out[1]==false and tostring(out[2]):find(marker,1,true))
  elseif mode=='cancelled'then
   local expected=({engine='engine_profile_cancelled',domain='domain_profile_cancelled',native='profile_operation_cancelled'})[which]
   assert(out[1]and out[2]==false and out[3]==expected,which..' cancellation: '..tostring(out[3]))
  else assert(out[1]and out.n==5 and out[2]==false and out[3]==marker and out[4]==nil and out[5]==73,
   which..' must retain the explicit failure tuple')end
  assert(r.seed.IsCurrent(),'borrowed seed must not be closed by the profile')
  r.finishProfile();count=count+1
 end
end
local r=T.new('server');local p=r.allocate149();assert(p.Prepare('pt-br'));r.surface.Open()
p.Bootstrap.Install=function()return false end
local ok,why=p.Install();assert(ok==false and why=='profile_operation_cancelled','retain a fallback for missing reasons')
r.finishProfile();count=count+1
assert(count==10)
print('PASS ten profile Install refusal/tuple/exception/cancellation/fallback cases through actual Forge wrappers; borrowed seed retained')
