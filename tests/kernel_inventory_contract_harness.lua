local I=dofile('tests/kernel_compat_identity_harness.lua');local H=I.H;local T={I=I,H=H}
function T.new()
    local r=I.new('server');r.inventoryReady=true;r.coreContract={}
    for _,name in ipairs({'GetPlayer','GetPlayersData','CanUseItem','GetGroups','IsGradeBoss'})do r.coreContract[name]=r.catalog.Resolve(name)end
    r.contractPorts={consumer='ox_inventory',identity=r.identity,core=r.coreContract,
        isCurrent=function()return r.api.IsCurrent()end,isReady=function()return r.inventoryReady end}
    r.contractFactory=H.load('../pr_bridge/bridge/frameworks/forge/inventory_core_factory.lua',H.environment())
    r.contract=r.contractFactory(r.contractPorts);local finish=r.finish
    function r.finish()r.contract.Close();return finish()end
    return r
end
return T
