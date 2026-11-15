-- Apply a shared Forge-local invocation scope before constructing a server graph. Caller ports are preserved.
local function copy(value)local out={};for k,v in pairs(assert(value))do out[k]=v end;return out end
return function(input,origin)
    assert(type(origin.GetInvokingResource)=='function','local origin scope required')
    local p=copy(input);p.deliveryContext=copy(p.deliveryContext);local node=p.deliveryContext
    for _,key in ipairs({'mediaContext','supportContext','configurationContext','vehicleContext','bankingContext','operationsContext','inventoryContext','startup','lifecycle','worker','graph','central'})do
        node[key]=copy(node[key]);node=node[key]
    end
    node.runtime=copy(node.runtime);node.runtime.native=copy(node.runtime.native);node.runtime.native.GetInvokingResource=origin.GetInvokingResource
    node.session=copy(node.session);node.session.player=copy(node.session.player);node.session.player.platform=copy(node.session.player.platform)
    node.session.player.platform.getInvokingResource=origin.GetInvokingResource
    node.lifecycle=copy(node.lifecycle);node.lifecycle.native=copy(node.lifecycle.native);node.lifecycle.native.getInvokingResource=origin.GetInvokingResource
    return p
end
