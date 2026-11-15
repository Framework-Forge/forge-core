local S=dofile('tests/kernel_native_bootstrap_harness.lua');local C=dofile('tests/kernel_native_client_bootstrap_harness.lua');local H=S.H
local function source(path)local f=assert(io.open(H.qbx..path,'rb'));local text=f:read('*a');f:close();return text end
for _,side in ipairs({'server','client'})do
    local r=side=='server'and S.server()or C.new();r.prepareBootstrap()
    local catalog=H.load('kernel/compat/qbx/export_catalog.lua',H.environment())(r.graph,side,{isCurrent=function()return r.api.IsCurrent()end})
    assert(catalog.Count==(side=='server'and 105 or 24));local expected,files={},{}
    for _,e in ipairs(catalog.Describe())do
        assert(not expected[e.name]);expected[e.name]=true;files[e.source]=true
        local target=r.graph;for key in e.path:gmatch('[^.]+')do target=assert(target[key])end
        assert(catalog.Resolve(e.name)==target,'same canonical function '..e.name)
    end
    local names={};for file in pairs(files)do for name in source(file):gmatch('exports%(%s*[\'"]([^\'"]+)[\'"]')do assert(not names[name]);names[name]=true end end
    H.same(expected,names,'whole installed native exports '..side)
    assert(not pcall(catalog.Resolve,'CanUseInventoryItem'),'Forge-specific policy must not leak through generic QBX compat')
    local root=side=='server'and r.graph.PlayerCore.Producers.Session or r.graph.Central.Parts.Producers.Session
    assert(catalog.Resolve('GetCachedState')==root.Exports.GetCachedState,'QBX session only,not combined Forge World cache')
    if side=='server'then
        local old=r.graph.PlayerCore.Players.AddMoney;r.graph.PlayerCore.Players.AddMoney=function()error('replacement')end
        assert(not catalog.IsCurrent()and not pcall(catalog.Resolve,'GetPlayer'));r.graph.PlayerCore.Players.AddMoney=old
    else r.nativeCurrent=false;assert(not catalog.IsCurrent());r.nativeCurrent=true end
    assert(catalog.IsCurrent());catalog.Close();assert(not pcall(catalog.Resolve,'GetJobs'));assert(r.api.IsCurrent(),'catalog Close leaves core alive');r.drain()
end
print('PASS lot102 QBX native catalog:105 server/24 client whole installed export lists,same graph74/75 functions,session cache semantics,foreign names/reference swaps/owned close;virtual only')
