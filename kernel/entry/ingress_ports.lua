-- Decorate resource-local native/RPC ports before construction. Does not open transports or mutate providers.
return function(barrier,registration,callbacks)
    assert(type(barrier.WrapIngress)=='function'and type(barrier.IsIngressOpen)=='function','activation barrier required')
    local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
    local function props(value,seen)
        if type(value)=='function'then return barrier.WrapIngress(value)end
        if type(value)~='table'then return value end
        seen=seen or{};if seen[value]then return seen[value]end;local out={};seen[value]=out
        for k,v in pairs(value)do out[k]=props(v,seen)end;return out
    end
    local result=copy(registration);local n=copy(registration.native);result.native=n
    local control={onResourceStop=true,onClientResourceStop=true,onResourceStart=true,onClientResourceStart=true}
    n.AddEventHandler=function(name,fn)return registration.native.AddEventHandler(name,control[name]and fn or barrier.WrapIngress(fn))end
    n.RegisterCommand=function(name,fn,restricted)return registration.native.RegisterCommand(name,barrier.WrapIngress(fn),restricted)end
    n.publishExport=function(name,fn)
        -- These two local endpoints independently enforce native identity,epoch and119 admission.
        local bootstrap=name=='ForgePrDescribe'or name=='ForgePrCall'
        return registration.native.publishExport(name,bootstrap and fn or barrier.WrapIngress(fn))
    end
    for _,key in ipairs({'prCommand','oxCommand'})do result[key]=function(name,options,fn)
        return registration[key](name,props(options),barrier.WrapIngress(fn))
    end end
    local rpc={};for key,provider in pairs(callbacks or{})do
        local scoped=copy(provider);local bind=assert(provider.Bind)
        scoped.Bind=function(lease,fn)return bind(lease,barrier.WrapIngress(fn))end;rpc[key]=scoped
    end
    return result,rpc
end
