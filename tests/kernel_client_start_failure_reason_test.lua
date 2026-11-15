local T=dofile('tests/kernel_keybind_profile_harness.lua')
for _,mode in ipairs({'refused','thrown','cancelled'})do
 local r=T.new('client');local p=r.allocate166();assert(p.Prepare('pt-br'));r.surface.Open();assert(p.Install());r.runtimeImports.pollNative()
 p.Bootstrap.Start=function()
  if mode=='thrown' then error('original-client-start-error',0)end
  if mode=='cancelled' then p.Stop();return true end
  return false,'original-client-start-error',nil,73
 end
 local result=table.pack(pcall(p.Start))
 if mode=='refused'then assert(result[1]and result[2]==false and result[3]=='original-client-start-error'and result.n==5 and result[5]==73,tostring(result[3]))
 elseif mode=='thrown' then assert(not result[1]and tostring(result[2]):find('original-client-start-error',1,true))
 else assert(result[1]and result[2]==false and tostring(result[3]):find('cancelled',1,true))end
 assert(r.seed.IsCurrent());r.finishProfile()
end
print('PASS client Start refusal tuple, thrown cause and cancellation through installed profiles; borrowed seed retained')
