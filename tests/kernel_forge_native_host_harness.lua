local P=dofile('tests/kernel_player_harness.lua');local H=P.H;local T={H=H,P=P,path='../pr_bridge/bridge/frameworks/forge/native_host_factory.lua'}
function T.new(ported)
    local r={current=true,ready=true,setting='true',nativeOwner='forge-core',calls={},object={Functions={GetPlayer=function()end},Shared={Jobs={}}}}
    r.getter=function(filters)
        r.calls[#r.calls+1]=filters or'<none>';if r.getterHook then r.getterHook()end
        if filters then local out={};for _,key in ipairs(filters)do out[key]=r.object[key]end;return out end;return r.object
    end
    if ported then
        local route=H.load('../pr_bridge/bridge/frameworks/forge/routing_factory.lua',H.environment())({active={frameworks='forge'},config={},contracts={qb=true},
            isCurrent=function()return r.current end,readDeclarations=function()error('native host never reads facade declarations')end})
        r.ports={resourceName='forge-core',isCurrent=function()return r.current end,isReady=function()if r.readyHook then r.readyHook()end;return r.ready end,
            getNativeOwner=function()return r.nativeOwner end,getBridgeSetting=function()return r.setting end,contracts={qb=true},routing=route,getCoreObject=r.getter}
        r.api=H.load(T.path,H.environment())(r.ports);r.get=r.api.GetCoreObject
    else
        local exported={};local proxy={GetCoreObject=function(_,filters)return r.getter(filters)end}
        local env=H.environment({Config={compatFramework='on',compatQBCore=true},PRCore={context='server'},ActiveBridges={frameworks='qbx'},
            GetConvar=function(key,default)assert(key=='qbx:enablebridge'and default=='true');return r.setting end,
            exports=setmetatable({['qb-core']=proxy},{__call=function(_,name,fn)exported[name]=fn end})})
        H.load('../pr_bridge/bridge/compat/qb/host.lua',env);r.get=assert(exported.getQBCoreObject)
    end
    return r
end
return T
