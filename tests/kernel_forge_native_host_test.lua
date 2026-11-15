local T=dofile('tests/kernel_forge_native_host_harness.lua');local H,P=T.H,T.P;local count=0
for _,setting in ipairs({'true','false','1',false})do
    for _,filters in ipairs({{}, {'Functions'}, {'Shared'}, {'Missing'}})do
        local a,b=T.new(true),T.new(false);a.setting,b.setting=setting,setting
        local aa,bb=table.pack(pcall(a.get,filters)),table.pack(pcall(b.get,filters))
        if not aa[1]and not bb[1]then aa[2]=aa[2]:gsub('^.-:%d+: ','');bb[2]=bb[2]:gsub('^.-:%d+: ','')end
        H.same(P.snapshot(aa),P.snapshot(bb),'native host contract');H.same(a.calls,b.calls,'getter filters/receiver contract');count=count+1
    end
end
local a,b=T.new(true),T.new(false);assert(a.get()==a.object and b.get()==b.object,'whole native object reference preserved')
assert(a.api.Exports.getQBCoreObject==a.api.GetCoreObject);a.api.Close();assert(a.api.Progress().complete and not pcall(a.get))
for _,mode in ipairs({'unready','conflict','no-contract','no-getter','no-route'})do
    local r=T.new(true)
    if mode=='unready'then r.ready=false elseif mode=='conflict'then r.nativeOwner='qbx_core'
    elseif mode=='no-contract'then r.ports.contracts.qb=false
    elseif mode=='no-getter'then r.api.Close();r.ports.getCoreObject=nil;r.api=H.load(T.path,H.environment())(r.ports);r.get=r.api.GetCoreObject
    else r.ports.routing.isNative=function()return false end end
    assert(not pcall(r.get)and #r.calls==0,'explicit native host refusal '..mode);r.api.Close()
end
print('PASS lot86 native host:'..count..' whole installed native-branch comparisons,filters/reference/string bridge setting,explicit readiness/owner/contract/getter/route refusals;no QBX fallback or second lifecycle')
