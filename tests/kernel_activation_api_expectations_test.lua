local T=dofile('tests/kernel_pr_native_api_harness.lua');local H=T.H
local expected=H.load('../pr_bridge/bridge/frameworks/forge/activation_api_expectations.lua',H.environment())
for _,side in ipairs({'server','client'})do
 local r=T.new(side);assert(r.nativeAPI.Install())
 local d=r.surface.exports.ForgePrDescribe();local q=expected(side,side=='server')
 for group,names in pairs(q)do
  local actual=d.groups[group];assert(actual and #actual==#names)
  local found={};for _,name in ipairs(actual)do found[name]=true end;for _,name in ipairs(names)do assert(found[name],name)end
 end
 for group in pairs(d.groups)do assert(q[group])end
 local proxy=H.load('../pr_bridge/bridge/frameworks/forge/native_api_factory.lua',H.environment())({
 side=side,isCurrent=r.api.IsCurrent,proxy=r.nativeProxy,expected=q})
 assert(proxy.Prepare());assert(proxy.Close());r.finish()
end
local disabled=expected('server',false);assert(#disabled.native==0 and #disabled.framework==19)
disabled.core[1]='foreign';assert(expected('server',false).core[1]~='foreign')
assert(not pcall(expected,'server',nil))
print('PASS262 expected groups match actual API on both sides;real proxy handshake;explicit disabled QB shape and copy isolation')
