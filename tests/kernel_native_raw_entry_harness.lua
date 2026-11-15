local S=dofile('tests/kernel_core_services_harness.lua');local A=dofile('tests/kernel_consumer_admission_harness.lua');local H=S.H
local T={S=S,A=A,H=H,root='../../../../.planning/migration/staging/125/'}
function T.read(name)local f=io.open(T.root..name,'rb');if not f then return end;local s=f:read('*a');f:close();return s end
function T.raw(side)
    local r=S.new(side);r.wire.close();local base=r.wire[side].env;local env=H.environment()
    for k,v in pairs(base)do env[k]=v end;for k,v in pairs(r.ports.native)do env[k]=v end
    env.Debug=function()end;env.Lang={t=function(_,key)return key end};env.exports=r.external;env.PRCore=r.wire.prs[side];env._ENV=env
    rawset(env,'source',nil);local mt=getmetatable(env);local before=mt.__index;mt.__index=function(t,key)if key=='source'then return base.source end;return before(t,key)end
    env.PRCore.load=function(path,target)
        local name=path:gsub('^@pr_bridge/','');local s=T.read('pr_bridge/'..name..'.lua')
        if s then return assert(load(s,'@@package125/'..name,'t',target or env))()end
        return H.load('../pr_bridge/'..name..'.lua',target or env)
    end
    r.allowClose=true;r.options={isCurrent=function()return r.current end,namespaceAvailable=r.wire.ports[side].available,beforeClose=function()return r.allowClose end}
    r.rawFactory=assert(load(T.read('pr_bridge/bridge/forge_raw_core.lua'),'@@raw_entry125','t',env))()
    function r.enter()r.entry=r.rawFactory(r.options);return r.entry end
    function r.finish()if r.entry then r.allowClose=true;r.entry.Close()end;r.wire.close()end
    return r
end
function T.consumer()
    local r=A.new();r.bindings.Close();local env=H.environment(r.bindingPorts.native);local names=H.load('../pr_bridge/bridge/frameworks/forge/consumer_schema.lua',H.environment())
    local nativeNames=assert(load(T.read('pr_bridge/bridge/frameworks/forge/native_names.lua'),'@@native_names125','t',{}))()
    for _,key in ipairs(nativeNames)do if rawget(env,key)==nil then env[key]=false end end
    r.descriptorSurface={};local proxy={ForgePrDescribe=r.nativeProxy.ForgePrDescribe,ForgePrCall=r.nativeProxy.ForgePrCall,
        ForgePrConsumerState=function(_,...)return r.surface.exports.ForgePrConsumerState(...)end}
    env.exports=setmetatable({['forge-core']=proxy},{__call=function(_,name,fn)assert(not r.descriptorSurface[name]);r.descriptorSurface[name]=fn end})
    r.stopTokens={};env.AddEventHandler=function(name,fn)local t={name=name,fn=fn};r.stopTokens[#r.stopTokens+1]=t;return t end
    env.RemoveEventHandler=function(t)t.removed=true end;env._ENV=env
    r.pr.load=function(path)
        local name=path:gsub('^@pr_bridge/','');local s=T.read('pr_bridge/'..name..'.lua')
        return s and assert(load(s,'@@package125/'..name,'t',env))()or H.load('../pr_bridge/'..name..'.lua',env)
    end
    local activation={instance=r.consumerInstance,isExportAvailable=function(name)return r.descriptorSurface[name]==nil end,
        isCurrent=r.bindingPorts.isCurrent,isReady=r.bindingPorts.isReady,contracts=r.bindingPorts.contracts,
        readDeclarations=r.bindingPorts.readDeclarations,readProviders=r.bindingPorts.getServices}
    r.entry=r.pr.load('@pr_bridge/bridge/frameworks/forge/allocation_entry')(r.pr,r.public,{compatFramework='forge'},activation)
    r.bindings={Progress=function()return r.entry.Progress().binding end,Close=function()return r.entry.Close()end,
        Allocation={IsAttached=function()return r.pr.forgeLateBinding and r.pr.forgeLateBinding.IsAttached()or false end}}
    r.describeHook=function(d)local actual=assert(r.descriptorSurface.ForgePrConsumerDescribe)();for k in pairs(d)do d[k]=nil end;for k,v in pairs(actual or{})do d[k]=v end end
    return r
end
return T
