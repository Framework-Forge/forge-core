local C=dofile('tests/kernel_consumer_context_harness.lua');local H,P=C.H,C.P
local T={C=C,H=H,P=P,provider='../pr_bridge/imports/require/shared.lua'}
function T.new(side,mode)
    local r=C.new(side);local contextMount=r.mount;r.reads={};r.nativeCalls=0;r.files={}
    local env=H.environment({lib={},cache={resource='consumer78'},noop=function()end,load=load,
        debug={getinfo=function()return nil end},require=function(name)r.nativeCalls=r.nativeCalls+1;error('native miss '..name,0)end,
        LoadResourceFile=function(resource,path)r.reads[#r.reads+1]={resource,path};return r.files[resource..'/'..path]end})
    env._ENV=env;env.table.wipe=function(t)for k in pairs(t)do t[k]=nil end end
    for key,value in pairs(r.target)do env[key]=value end
    if mode=='ox'then
        local f=assert(io.open(H.qbx..'../../[ox]/ox_lib/imports/require/shared.lua','rb'));local source=f:read('*a');f:close()
        -- One exact Cfx optional-access syntax rewrite; whole original ox engine remains unchanged on disk.
        source=P.lua54(source:gsub("debug.getinfo%(idx, 'S'%)%?%.source","(debug.getinfo(idx, 'S') or {}).source"))
        env.require=assert(load(source,'@@ox_lib/imports/require/shared.lua','t',env))()
    else
        local api={cache=env.cache,originalRequire=env.require}
        env.PRCore={loadFile=function(resource,path,target)
            return assert(load(assert(r.files[resource..'/'..path..'.lua']),'@@'..resource..'/'..path..'.lua','t',target))
        end}
        H.load('../pr_bridge/bridge/files/loader.lua',env)(api)
        env.lib.__native=function(path)assert(path=='bridge/library/init');return api end
        env.require=H.load(T.provider,env)
    end
    r.target=env;r.env=env;r.ports.environment=env;r.ports.package=env.package;r.ports.requireFunction=env.require
    local factory=H.load('kernel/imports/require_binding.lua',H.environment({require=function(name)
        assert(name=='kernel.imports.consumer_context');return function(ports)assert(ports==r.ports);return contextMount()end
    end}))
    function r.mount()r.api=factory(r.ports);return r.api end
    function r.require(name)return env.require(name)end
    return r
end
return T
