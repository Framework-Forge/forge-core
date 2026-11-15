local createIngress=require 'kernel.entry.ingress_ports'
return function(barrier,registration,callbacks)
    local native,rpc=createIngress(barrier,registration,callbacks)
    local publish=native.native.publishExport
    native.native.publishExport=function(name,fn)
        if name=='ForgePrConsumerState'then return registration.native.publishExport(name,fn)end
        return publish(name,fn)
    end
    return native,rpc
end
