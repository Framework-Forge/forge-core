local T=dofile('tests/kernel_consumer_delivery_harness.lua')
for _,side in ipairs({'client','server'})do
    local r=T.new(side);r.mount();assert(#r.deliveryReads==0 and r.gets==0,'79 constructor inert')
    local description=r.api.Describe();assert(#description.files==13 and not description.manifestApplied and not description.publicAliasChosen)
    description.files[1]='foreign';assert(r.api.Describe().files[1]~='foreign')
    assert(r.api.Prepare()and #r.deliveryReads==8 and not r.api.Prepare())
    assert(r.gets==0 and r.target.qbx.foreign and r.active()==0,'all factory sources compiled without consumer initialization')
    local prepared={};for _,path in ipairs(r.deliveryReads)do assert(not prepared[path]);prepared[path]=true end
    assert(r.api.Install());for _,name in ipairs({'modules.lib','modules.utils','shared.locale','modules.playerdata'})do assert(r.api.ExecuteEntry(name)==true)end
    assert(#r.deliveryReads==12 and #r.reads==0 and r.nativeCalls==0,'local delivery independent from QBX public loader')
    assert(r.target.qbx.string.trim(' yes ')=='yes'and r.target.GetPlate and r.target.Locale)
    if side=='client'then assert(r.target.QBX.PlayerData==r.data and r.gets==1 and r.active()==2)
    else assert(r.target.QBX==r.oldQBX and r.gets==0 and r.active()==0)end
    assert(r.require('@qbx_core.modules.lib')and not pcall(r.api.ExecuteEntry,'kernel.server.player'))
    assert(not pcall(r.moduleEnv.require,'kernel.server.player'),'private closure rejects unrestricted modules')
    assert(r.api.Close()and r.api.Progress().complete and r.target.qbx.foreign and r.target.QBX==r.oldQBX)
end
local a,b=T.new(),T.new();a.mount();b.mount();a.api.Prepare();b.api.Prepare();a.api.Install();b.api.Install()
a.api.ExecuteEntry('modules.lib');b.api.ExecuteEntry('modules.lib');assert(a.target.qbx~=b.target.qbx)
a.api.Close();assert(b.target.qbx.string.trim(' b ')=='b');b.api.Close()
print('PASS lot79 delivery:13 exact prepared files,eight private factories/four entries,client/server complete imports,no QBX IO/public private-dependency fallback,consumer-local namespaces and closure;virtual only')
