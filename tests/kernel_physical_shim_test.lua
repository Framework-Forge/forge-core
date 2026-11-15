local T=dofile('tests/kernel_physical_shim_harness.lua')
local manifest=T.read('fxmanifest.lua');assert(manifest:find("name 'forge_qbx_compat'",1,true)and manifest:find("version '0.1.0'",1,true))
assert(not manifest:find('1.23.0',1,true)and not manifest:find('qbx_core.sql',1,true))
for _,side in ipairs({'server','client'})do
    local r=T.new(side);r.loadPhysical();local n=0;for _ in pairs(r.published)do n=n+1 end;assert(n==(side=='server'and 105 or 24))
    assert(r.published.GetJobs()==r.catalog.Resolve('GetJobs')())
    assert(#r.physicalEvents==1 and r.physicalEvents[1].name=='onResourceStop'and #r.readPhysical==2)
    r.stopPhysical();assert(not pcall(r.published.GetJobs));assert(r.physicalEvents[1].removed and r.api.IsCurrent(),'physical stop leaves Forge alive');r.finish()
end
print('PASS lot105 physical candidate entry/manifest:separate shim identity/version,105 server/24 client exports from real graphs,local factory files,one owned stop,no original core service;virtual FiveM/IO only')
