local H=dofile('tests/cache_harness.lua')
local r=H.new(false);local e=r.env;local zones,removed=0,0
e.ForgeCore.t=function(key) return key end
e.vector3=function(x,y,z) return {x=x,y=y,z=z,__vector=true} end;e.vec3=e.vector3
e.type=function(v) if type(v)=='table' and v.__vector then return 'vector3' end;return type(v) end
e.pr_lib.math={toVector=function(v) return e.vector3(v.x,v.y,v.z) end}
e.pr_lib.target={addBoxZone=function() zones=zones+1;return zones end,removeZone=function() removed=removed+1 end}
r.load('shared/stores.lua');r.load('shared/cache.lua');r.load('client/stores/main.lua')
local payload={settings={enabled=true},stores={{id='test',label='Test',coords={x=1,y=2,z=3},owner='owner',
    enabled=true,stock={water=10},balance=0,sales={}}},revision=1}
e.ForgeCore.Client.Stores.refresh(payload);assert(zones==1, 'initial zones='..zones)
local financial=H.copy(payload);financial.revision=2;financial.stores[1].balance=10;financial.stores[1].stock.water=8
e.ForgeCore.Client.Stores.refresh(financial);assert(zones==1 and removed==0)
local location=H.copy(financial);location.stores[1].coords.x=10
e.ForgeCore.Client.Stores.refresh(location);assert(zones==2 and removed==1)
local access=H.copy(location);access.stores[1].managers={{citizenid='manager'}}
e.ForgeCore.Client.Stores.refresh(access);assert(zones==3 and removed==2)
print('PASS store refresh: financial cache updates preserve targets; location/access changes rebuild')

-- A snapshot accepted before target registration succeeds must remain retryable.
local late=H.new(false);local le=late.env;local calls=0
le.ForgeCore.t=e.ForgeCore.t;le.vector3=e.vector3;le.vec3=e.vec3;le.type=e.type;le.pr_lib.math=e.pr_lib.math
le.pr_lib.target={}
late.load('shared/stores.lua');late.load('shared/cache.lua');late.load('client/stores/main.lua')
le.ForgeCore.Client.Stores.refresh(payload)
le.pr_lib.target={addBoxZone=function() calls=calls+1;return calls end,removeZone=function() end}
le.ForgeCore.Client.Stores.refresh(payload)
assert(calls==1,'Identical snapshot must retry targets which were never registered')
late.fire('onClientResourceStop',nil,'pr_bridge')
assert(#le.ForgeCore.Client.Stores.zones==0,'Target provider stop must invalidate store handles')
late.fire('onClientResourceStart',nil,'pr_bridge');late.advance(0)
assert(calls==2,'Target provider restart must recreate stores from the latest cached payload')
print('PASS store target lifecycle: unavailable provider retry and restart rehydration')
