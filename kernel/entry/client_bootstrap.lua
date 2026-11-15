local createBootstrap=require 'kernel.entry.bootstrap_context'
local createContext=require 'kernel.client.locale_context'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(state,ports)
    local function bind(input,n)
        local p=copy(input);p.localeBinding=copy(p.localeBinding)
        p.localeBinding.listen,p.localeBinding.remove=n.Events.listen,n.Events.remove
        p.localeBinding.available,p.localeBinding.publishExport=n.Public.available,n.Public.publishExport
        p.runtimeContext=copy(p.runtimeContext);local out=p.runtimeContext
        for _,key in ipairs({'deliveryContext','configurationContext','mediaContext','shutdown'})do out[key]=copy(out[key]);out=out[key]end
        out.events=n.Events;out.public=copy(out.public)
        for _,key in ipairs({'available','publishExport','nativeCommand','prCommand','oxCommand'})do out.public[key]=n.Public[key]end
        return p
    end
    return createBootstrap(state,'client',createContext,bind,ports)
end
