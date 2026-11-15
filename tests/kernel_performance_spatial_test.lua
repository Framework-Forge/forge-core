local S=dofile('tests/kernel_spotlights_harness.lua')
local s=S.client(true);local p=S.seed();p.lights[1].origin.x=999
s.value=p;assert(s.tick()==1000 and s.tick()==1000 and #s.draws==0)
s.positions[11]=S.vector(999,2,3);assert(s.tick()==0 and #s.draws==1,'teleport did not draw')
s.positions[11]=S.vector();assert(s.tick()==1000 and #s.draws==1,'far light still renders')
p=S.seed();s.apply(p);assert(s.tick()==0 and #s.draws==2,'publication invalidation')
p.lights[1].enabled=false;s.apply(p);assert(s.tick()==1000 and #s.draws==2)
s.apply(nil);assert(s.tick()==1000)
-- At rest only nearby entries are read each frame, regardless of distant catalog size.
p=S.seed();for i=2,1001 do local l=S.H.copy(p.lights[1]);l.id=i;l.origin.x=10000+i;p.lights[i]=l end
s.apply(p);assert(s.tick()==0)
local visits=0
for i=2,#s.spotlights.lights do local l=s.spotlights.lights[i];local x=l.origin.x;l.origin.x=nil
    setmetatable(l.origin,{__index=function(_,k)if k=='x'then visits=visits+1;return x end end})end
for i=1,120 do assert(s.tick()==0)end
assert(visits==0,'distant lights traversed every frame')
local B=dofile('tests/kernel_billboards_harness.lua');local b=B.client(true);b.value=B.seed();assert(b.tick()==0)
local initial=#b.polys;b.positions[11]=B.vector(10000,0,0);assert(b.tick()==1000 and #b.polys==initial)
b.positions[11]=B.vector();assert(b.tick()==0 and #b.polys==initial+2)
b.apply(nil);assert(b.tick()==1000 and next(b.duis)==nil,'DUI removal')
print('PASS spatial: far/disabled lights sleep, teleport/publication invalidate, 1000 distant lights not scanned per frame, billboard return and DUI cleanup')
