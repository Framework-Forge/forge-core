-- Actual client/server factories and PR wire/context; platform/IO/providers are virtual only.
local A=dofile('tests/kernel_client_assembly_harness.lua')
local D=dofile('tests/kernel_domains_harness.lua')
local H,P=A.H,A.P
local T={H=H,P=P,A=A,D=D}
local function copy(t)local out={};for k,v in pairs(t or{})do out[k]=v end;return out end
function T.new()
    local r={central=A.new(),server=D.new(),fixtures={},modules={},client={}}
    local f=r.fixtures
    local function fixture(key,name,method,...)
        local m=dofile('tests/kernel_'..name..'_harness.lua');r.modules[key]=m
        f[key]=m[method or'new'](...);return f[key]
    end
    local work=fixture('Work','work_menu','new',true)
    local admin=fixture('Administration','admin_menu','new',true)
    fixture('Jobs','client_jobs','new',true);fixture('Zones','job_zones','new',true,'points')
    fixture('Skills','skill_client','new',true)
    fixture('AutoMedic','automedic_client','new',true);fixture('Access','access_client','new',true)
    fixture('Settings','server_settings','menu',true);fixture('World','world','client',true)
    fixture('Vehicles','vehicles','menu',true)
    for _,name in ipairs({'Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms'})do fixture(name,name:lower(),'client',true)end
    fixture('PlayerAdmin','player_admin','menu',true);fixture('CharacterAdmin','character_admin','menu',true)
    local st=dofile('tests/kernel_starterpack_harness.lua');r.modules.Starterpack=st
    local scene,e=st.sceneFixture(false);f.Starterpack=scene;scene.native=e;scene.library=e.pr_lib
    scene.print=function()end;scene.json=e.json
    r.wire=r.modules.Jobs.wire();r.wire.playerSource=2
    r.context=r.modules.Administration.context()
    work.registerHook=r.context.api.RegisterContext;work.showHook=r.context.api.ShowContext
    work.library.inventory=admin.library.inventory
    work.library.callback.await=function(name,timeout,...)return r.wire.client.api.request(name,nil,nil,timeout,...)end
    local function ports(v)
        local n=copy(v.native)
        -- Menu natives use the same explicit UI scheduler/player facade; renderer natives remain owned doubles.
        for k,value in pairs(work.native)do if n[k]==nil then n[k]=value end end
        n.getPlayerServerId=n.getPlayerServerId or work.native.serverId
        n.GetCurrentResourceName=n.GetCurrentResourceName or work.native.resourceName
        n.SetTimeout=n.SetTimeout or work.native.setTimeout
        n.PlayerId=n.PlayerId or work.native.playerId
        n.GetPlayerServerId=n.GetPlayerServerId or work.native.serverId
        return{library=v.library,native=n,translate=v.translate or work.translate}
    end
    local p={}
    for key,v in pairs(f)do p[key]=ports(v)end
    for _,key in ipairs({'Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms'})do
        local view=r.modules[key].menu(true);f[key..'MenuPorts']=view
        for name,fn in pairs(view.native)do if p[key].native[name]==nil then p[key].native[name]=fn end end
        if f[key].math or view.math then p[key].math=f[key].math or view.math end
    end
    p.Jobs.library=work.library;p.Jobs.wait=f.Jobs.wait
    p.Zones.integrations=f.Zones.integrations;p.Zones.library.callback=work.library.callback
    p.Administration.library=work.library;p.Administration.json=admin.json
    p.Work.integrations=work.integrations
    p.MultiJob=ports(work);p.Staff=ports(work);p.SkillMenus=ports(work)
    p.Skills.progression=f.Skills.progression
    p.AutoMedic.library.callback=work.library.callback
    p.Access.characterIntegration=f.Access.integration;p.Access.library.callback=work.library.callback
    p.Settings.panelIntegration=f.Settings.panelIntegration
    local wm=r.modules.World.menu(true);r.worldMenuFixture=wm
    p.World.weatherAdminIntegration=wm.weatherIntegration
    p.Npcs.integration=f.Npcs.integration
    p.Vehicles.random=f.Vehicles.random;p.Vehicles.library.callback=work.library.callback
    p.Starterpack.print=scene.print;p.Starterpack.json=scene.json
    for _,v in pairs(p)do v.library.callback=work.library.callback end
    -- The real services below own the world/session/player views; fixture views are never passed as services.
    for _,v in pairs(f)do if v.library then v.library.framework=setmetatable({},{__index=function()error('forbidden framework/self cycle')end})end end
    local config=copy(r.server.config);config.Garage,config.Rental=work.config.Garage,work.config.Rental
    r.central.ports.config.Inventory=config.Inventory
    r.central.ports.legacy.jobs=r.server.base.Groups.GetJobs();r.central.ports.legacy.gangs=r.server.base.Groups.GetGangs()
    r.central.mount()
    r.state=r.central.state;r.ports={client=r.client,config=config,domains=p};r.config=config
    r.factory=H.load('kernel/client/domain_assembly.lua',A.E.env())
    function r.mount()r.api=r.factory(r.state,r.ports);return r.api end
    function r.snapshot()
        local out={central=r.central.snapshot(),wire=#r.wire.trace,frames=#r.context.frames,contextTimers=#r.context.timers}
        for key,v in pairs(f)do
            local effects=0;for _,item in ipairs(v.trace or{})do if item.kind~='translate'then effects=effects+1 end end
            out[key]={trace=effects,queue=#(v.queue or{}),timers=#(v.timers or{}),threads=#(v.initialThreads or v.initial or v.threads or{}),
                workers=#(v.workers or{}),events=#(v.eventsList or{}),targets=v.nextId}
        end
        return out
    end
    function r.connect()
        local c=r.server.central;local old=c.library.callback.register
        c.library.callback.register=function(name,fn)old(name,fn);r.wire.server.api.register(name,fn)end
        local s=r.server.mount();r.server.register()
        for name,fn in pairs(s.RawCallbacks.Character)do r.wire.server.api.register(name,fn)end
        for _,entry in ipairs(s.RawCallbacks.World)do r.wire.server.api.register(entry.name,entry.handler)end
        for _,entry in ipairs(r.api.Callbacks)do r.wire.client.api.register(entry.name,entry.handler)end
        return s
    end
    function r.rpc(group,key,...)local cfg=config[group];return work.library.callback.await((cfg.Callbacks or cfg.callbacks)[key],10000,...)end
    return r
end
return T
