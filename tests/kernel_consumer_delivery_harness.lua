local R=dofile('tests/kernel_require_binding_harness.lua');local H=R.H;local T={R=R,H=H}
function T.new(side)
    local r=R.new(side);r.consumerPorts=r.ports;r.deliveryReads={};r.compiled={};r.overrides={}
    r.deliveryPorts={consumer=r.consumerPorts,isCurrent=function()return r.current end,
        readFile=function(path)
            assert(path:match('^kernel/'),'local Forge source only');r.deliveryReads[#r.deliveryReads+1]=path
            if r.readHook then r.readHook(path)end
            if r.overrides[path]~=nil then return r.overrides[path]end
            local f=assert(io.open(path,'rb'));local source=f:read('*a');f:close();return source
        end,compile=function(source,name,mode,env)
            r.compiled[#r.compiled+1]=name;if r.compileHook then r.compileHook(name)end
            return load(source,name,mode,env)
        end,moduleEnvironment=function(requirePrivate)
            local env=R.C.I.V.T.env();env.require=requirePrivate;r.moduleEnv=env;return env
        end}
    local factory=H.load('kernel/imports/consumer_delivery.lua',H.environment())
    function r.mount()r.api=factory(r.deliveryPorts);return r.api end
    return r
end
return T
