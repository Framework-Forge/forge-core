-- Client request/registration transports are the already open122 owner;no new engine.
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(input,rpc)
    assert(rpc.Side=='client'and rpc.Owners.native.IsReady()and rpc.Owners.ox.IsReady(),'prepared client RPC owner required')
    local root=copy(input);root.runtimeContext=copy(root.runtimeContext);local r=root.runtimeContext
    r.deliveryContext=copy(r.deliveryContext);r.deliveryContext.configurationContext=copy(r.deliveryContext.configurationContext)
    local c=r.deliveryContext.configurationContext;c.mediaContext=copy(c.mediaContext);local m=c.mediaContext
    m.shutdown=copy(m.shutdown);m.shutdown.callbacks={native=rpc.Owners.native,ox=rpc.Owners.ox}
    m.worker=copy(m.worker);local w=m.worker;w.central=copy(w.central)
    w.central.library=copy(w.central.library);w.central.library.callback=rpc.Ox
    w.central.character=copy(w.central.character);w.central.character.callbacks=rpc.Ox
    w.domains=copy(w.domains);w.domains.domains=copy(w.domains.domains)
    for name,part in pairs(w.domains.domains)do if part.library then
        local p=copy(part);p.library=copy(part.library);p.library.callback=rpc.Native;w.domains.domains[name]=p
    end end
    return root
end
