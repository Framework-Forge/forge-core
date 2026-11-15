local bind=require 'kernel.entry.client_pr_ports'
local create=require 'kernel.entry.native_profile'
return function(base,ports)
    assert(ports.side=='client','client profile required')
    local rpc=assert(ports.prCore.forgeOwnedCallbacks);local p={};for k,v in pairs(ports)do p[k]=v end
    p.bootstrap={};for k,v in pairs(ports.bootstrap)do p.bootstrap[k]=v end;p.bootstrap.context=bind(p.bootstrap.context,rpc)
    return create(base,p)
end
