local R=dofile('tests/kernel_qbx_relay_harness.lua');local D=dofile('tests/kernel_consumer_delivery_harness.lua');local H=R.H
local T={R=R,D=D,H=H}
function T.new(side)
    local r=R.new(side);r.deliver=D.new(side);r.reads={};r.packageCurrent=true
    local env=H.environment();env.require=function(name)assert(name=='kernel.imports.consumer_delivery');return H.load('kernel/imports/consumer_delivery.lua',H.environment())end
    r.packagePorts={isCurrent=function()return r.packageCurrent end,
        readFile=function(path)r.reads[#r.reads+1]=path;if r.readPackageHook then r.readPackageHook(path)end
            local file=assert(io.open(path,'rb'));local text=file:read('*a');file:close();return text
        end,
        compile=function(...)if r.compilePackageHook then r.compilePackageHook()end;return load(...)end,
        relayEnvironment=function()return H.environment()end}
    r.package=H.load('kernel/compat/qbx/delivery_package.lua',env)(side,r.packagePorts)
    return r
end
return T
