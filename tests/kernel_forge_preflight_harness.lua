local S=dofile('tests/kernel_server_startup_harness.lua');local H=S.H;local T={S=S,H=H}
function T.probe()
    local r={current=true,selection='forge',states={pr_bridge='started',oxmysql='started',ox_inventory='started'},version=true,db=true,pings=0,describes=0}
    r.descriptor={protocol='forge-pr-consumer/1',resource='ox_inventory',side='server',instance='prepared126',current=true,phase='prepared'}
    r.ports={isCurrent=function()return r.current end,resourceState=function(n)return r.states[n]end,checkDependency=function()return r.version end,
        getConvar=function(k)assert(k=='inventory:framework');return r.selection end,getConvarInt=function()return r.onesync or 1 end,
        databaseReady=function()return r.db end,ping=function()r.pings=r.pings+1;if r.pingHook then r.pingHook()end;return r.ping~=false end,
        inventoryBridgeProbe=function()r.describes=r.describes+1;if r.describeHook then r.describeHook()end;return r.descriptor end}
    r.api=H.load('kernel/server/startup_preflight_forge.lua',H.environment())(r.ports);return r
end
function T.context()
    local r=S.new();r.selected='forge';local native=r.startPorts.lifecycle.worker.graph.central.runtime.native;local get=native.GetConvar
    native.GetConvar=function(k,...)if k=='inventory:framework'then return r.selected end;return get(k,...)end
    r.startPorts.inventoryBridgeProbe=function()return{protocol='forge-pr-consumer/1',resource='ox_inventory',side='server',instance='context126',current=true,phase='prepared'}end
    local env=S.T.W.D.R.env();env.print=function()end;local modules={}
    env.require=function(name)
        if name=='kernel.server.main'then name='kernel.server.main_forge'end
        if not modules[name]then modules[name]=H.load(name:gsub('%.','/')..'.lua',env)end;return modules[name]
    end
    r.forgeFactory=H.load('kernel/server/startup_forge_context.lua',env)
    function r.prepareForge()r.api=r.forgeFactory(r.fixture.base,r.startPorts);r.graph=r.api.Graph;return r.api end
    return r
end
return T
