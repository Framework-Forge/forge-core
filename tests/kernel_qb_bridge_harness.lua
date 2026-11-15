local S=dofile('tests/kernel_qb_server_harness.lua');local H,P=S.H,S.P;local T={S=S,H=H,P=P}
function T.environment()
    local env=H.environment();local cache={}
    env.require=function(name)
        assert(name:sub(1,7)=='kernel.','private require required')
        if not cache[name]then cache[name]=H.load(name:gsub('%.','/')..'.lua',env)end
        return cache[name]
    end
    return env
end
function T.new(ported,options)
    local r=S.new(ported,options);r.trace={};r.qbExports={};r.resourceExports={}
    r.current=true;r.ready=true;r.events={}
    local utility=S.T.shared(true,{{name='id',amount=1}})
    r.lib.math=utility.lib.math;r.lib.string=utility.lib.string
    for key,value in pairs(utility.helpers)do if not r.helpers[key]then r.helpers[key]=value end end
    r.shared={Vehicles={},VehicleHashes={},Weapons={},Locations={}}
    r.config={Server={same='server',onlyServer=true},Shared={starterItems={{name='id',amount=1}},same='shared'}}
    r.ports.convertItems=function(...)r.rec('convert',...)end
    r.ports.inventoryItems={};r.ports.legacyItems={bread={label='Bread'}}
    r.ports.isCurrent=function()return r.current end
    r.ports.isReady=function()if r.readyHook then r.readyHook()end;return r.ready end
    r.backend={Core=r.core,State=r.state,Shared=r.shared,Helpers=r.helpers,Config=r.config,IsCurrent=function()return r.current end,
        Close=function()r.backendClosed=true end}
    if ported then
        local env=T.environment();r.api=H.load('kernel/compat/qb/server_main.lua',env)(r.backend,r.ports)
        r.object=r.api.Enabled and r.api.GetCoreObject()or nil
        r.qbExports=r.api.Exports;r.resourceExports=r.api.ResourceExports
        for _,d in ipairs(r.api.Events)do r.events[d.name]=d end
        function r.fire(name,src,...)local d=assert(r.events[name]);if d.sourceFirst then return d.handler(src,...)end;return d.handler(...)end
    else
        local env=r.env;env.GetJobs=r.core.GetJobs;env.GetGangs=r.core.GetGangs;env.GetPlayer=r.core.GetPlayer
        local function listen(name,fn,network)assert(not r.events[name],name);r.events[name]={name=name,handler=fn,network=network}end
        env.RegisterNetEvent=function(name,fn)listen(name,fn,true)end
        env.RegisterServerEvent=env.RegisterNetEvent;env.AddEventHandler=function(name,fn)listen(name,fn,false)end
        local register=function(name,fn)assert(not r.qbExports[name],name);r.qbExports[name]=fn end
        env.require=function(name)
            if name=='bridge.qb.server.debug'or name=='bridge.qb.server.events'then return P.loadOrigin(name:gsub('%.','/')..'.lua',env)
            elseif name=='bridge.qb.shared.compat'then return{convertItems=r.ports.convertItems}
            elseif name=='@ox_inventory.data.items'then return r.ports.inventoryItems
            elseif name=='shared.items'then return r.ports.legacyItems
            elseif name=='config.shared'then return r.config.Shared
            elseif name=='config.server'then return r.config.Server
            elseif name=='shared.main'then return r.shared
            elseif name=='bridge.qb.shared.main'then return P.loadOrigin('bridge/qb/shared/main.lua',env)
            elseif name=='bridge.qb.server.player'then return r.Player
            elseif name=='server.functions'then return true
            elseif name=='bridge.qb.server.functions'then return P.loadOrigin('bridge/qb/server/functions.lua',env)
            elseif name=='bridge.qb.server.commands'then return r.Commands
            elseif name=='bridge.qb.shared.export-function'then return register end
            error(name)
        end
        P.loadOrigin('bridge/qb/server/main.lua',env)
        r.object=r.qbExports.GetCoreObject and r.qbExports.GetCoreObject()or nil
        function r.fire(name,src,...)env.source=src;return assert(r.events[name]).handler(...)end
        r.api={Enabled=r.object~=nil,GetCoreObject=r.qbExports.GetCoreObject}
    end
    return r
end
function T.runtime()
    local K=dofile('tests/kernel_framework_backend_harness.lua');local r=K.new();r.start()
    local stub=S.new(true);local utility=S.T.shared(true,{})
    stub.lib.math=utility.lib.math;stub.lib.string=utility.lib.string
    local p=stub.ports;p.isCurrent=function()return r.current and r.api.IsCurrent()end;p.isReady=function()if r.qbReadyHook then r.qbReadyHook()end;return r.qbReady~=false end
    local backend=H.load('kernel/server/qb_compat_backend.lua',H.environment())(r.graph,p)
    p.convertItems=function(...)stub.rec('convert',...)end;p.inventoryItems={};p.legacyItems={}
    r.qbBackend,r.qbPorts=backend,p
    r.qb=H.load('kernel/compat/qb/server_main.lua',T.environment())(backend,p);r.stub=stub
    return r
end
return T
