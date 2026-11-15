--249: bind caller identity before constructing the one graph;preserve closed226 contract.
local capture=require 'kernel.entry.physical_client_capture_v2'
return function(p)
 local build=capture(p);local origin=assert(p.originOwner)
 return function(side)return origin.Bind(build(side))end
end
