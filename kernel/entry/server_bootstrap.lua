local createBootstrap=require 'kernel.entry.bootstrap_context'
local createContext=require 'kernel.server.runtime_import_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
local function public(p,n)
    local out=copy(p);for _,key in ipairs({'available','publishExport','nativeCommand','prCommand','oxCommand'})do out[key]=n.Public[key]end;return out
end
return function(base,ports)
    local function bind(input,n)
        local p=copy(input);p.localeBinding=copy(p.localeBinding)
        p.localeBinding.listen,p.localeBinding.remove=n.Events.listen,n.Events.remove
        p.localeBinding.available,p.localeBinding.publishExport=n.Public.available,n.Public.publishExport
        p.deliveryContext=copy(p.deliveryContext);local out=p.deliveryContext
        for _,key in ipairs({'mediaContext','supportContext'})do out[key]=copy(out[key]);out=out[key]end
        out.public=public(out.public,n)
        for _,key in ipairs({'configurationContext','vehicleContext','bankingContext','operationsContext','inventoryContext','startup','lifecycle'})do
            out[key]=copy(out[key]);out=out[key]
        end
        out.events=n.Events;out.public=public(out.public,n)
        return p
    end
    return createBootstrap(base,'server',createContext,bind,ports)
end
