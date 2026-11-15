-- One actual assembly47 plus actual domain factories; fixtures supply external ports only.
local R=dofile('tests/kernel_assembly_harness.lua');local H=R.H
local D={R=R,H=H,P=R.P}
local modules={MultiJob='multijob',Staff='staff',Skills='skill',AutoMedic='automedic',Access='access',Settings='server_settings',World='world',
 Vehicles='vehicles',Vinewood='vinewood',Objects='objects',Npcs='npcs',Spotlights='spotlights',Billboards='billboards',Stores='stores',
 Farms='farms',Starterpack='starterpack',PlayerAdmin='player_admin'}
function D.new()
    local r={central=R.new(),fixtures={},modules={},operational=true};local c=r.central
    for key,name in pairs(modules)do
        local m=dofile('tests/kernel_'..name..'_harness.lua');r.modules[key]=m
        r.fixtures[key]=m.new(true,key=='Vehicles'and true or nil)
    end
    local f=r.fixtures;local config={AdminAce='forge-core.admin',NotifyPos='top-right',Debug=false,
        Job=c.jobConfig,Inventory=c.inventoryConfig,Weapons=c.weaponConfig,
        Vip=H.load('kernel/config/forge_vip.lua',R.env())(),CharacterSlots=R.A.config(true),
        Player=H.load('kernel/config/forge_player.lua',R.env())(),PlayerManagement=H.load('kernel/config/forge_player_management.lua',R.env())(),
        MultiJob=f.MultiJob.config,Staff=f.Staff.config,Skills=f.Skills.config,AutoMedic=f.AutoMedic.config}
    for _,key in ipairs({'Access','Settings','World','Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack'})do
        for name,value in pairs(f[key].config)do if type(value)=='table'then config[name]=value end end
    end
    local function common(v)return{library=v.library,native=v.native,translate=v.translate}end
    local ports={config=config,central=c.ports,domains={},isReady=function()return r.operational end}
    local p=ports.domains
    for key,v in pairs(f)do p[key]=common(v)end
    p.MultiJob.prisonProvider=f.MultiJob.provider;p.MultiJob.time=function()return f.MultiJob.now end
    -- Actual installed PR ACE provider; no active framework lookup is allowed in this fixture.
    local lookup={GetPlayer=function(src)return assert(c.base.PlayerCore).Lookup.GetPlayer(src)end}
    p.Staff.aceIntegration=r.modules.Staff.aceProvider(f.Staff,lookup);f.Staff.forbidLookup=true
    p.Staff.adminAce=config.AdminAce;p.Staff.notifyPosition=config.NotifyPos
    p.Skills.json=f.Skills.m.codec;p.Skills.progression=f.Skills.progression;p.Skills.integrations=f.Skills.integrations
    p.AutoMedic.inventoryIntegration=f.AutoMedic.inventoryIntegration
    p.Access.json=f.Access.m.codec;p.Access.webhookIntegration=f.Access.webhookIntegration
    p.Vehicles.catalogFile=f.Vehicles.catalogFile;p.Vehicles.json=f.Vehicles.json;p.Vehicles.compile=load
    p.Vehicles.vehicleIntegration=f.Vehicles.integration
    p.Stores.inventoryIntegration=f.Stores.inventoryIntegration;p.Stores.clock=f.Stores.clock
    p.Farms.inventoryIntegration=f.Farms.inventoryIntegration;p.Farms.clock=f.Farms.clock;p.Farms.math=f.Farms.math
    p.Starterpack.inventoryIntegration=f.Starterpack.inventoryIntegration;p.Starterpack.clock=f.Starterpack.clock;p.Starterpack.print=f.Starterpack.print
    p.PlayerAdmin.clock=f.PlayerAdmin.clock;p.PlayerAdmin.print=f.PlayerAdmin.print;p.PlayerAdmin.managementIntegration=f.PlayerAdmin.managementIntegration
    p.CharacterAdmin={library=c.library,native={GetPlayerName=c.native.getPlayerName,TriggerClientEvent=c.n.native.TriggerClientEvent,SetTimeout=c.native.setTimeout},clock={date=os.date},print=function()end}
    local helpers=dofile('tests/kernel_helpers_harness.lua');r.helperFixture=helpers.new(true,'server')
    ports.helpers=R.copy(r.helperFixture.ports);ports.helpers.isServer=nil
    for _,v in pairs(f)do
        if v.library then v.library.framework=setmetatable({},{__index=function()error('forbidden live framework/self cycle')end})end
    end
    c.library.framework=setmetatable({},{__index=function()error('forbidden central framework/self cycle')end})
    r.ports,r.config,r.base=ports,config,c.base
    local environment=R.env();environment.print=function(...)c.record('print',...)end
    r.factory=H.load('kernel/server/domain_assembly.lua',environment)
    function r.mount()r.api=r.factory(r.base,r.ports);return r.api end
    function r.snapshot()
        local function effects(trace)local count=0;for _,entry in ipairs(trace or{})do if entry.kind~='translate'then count=count+1 end end;return count end
        local out={central={trace=#c.trace,p=#c.p.trace,l=#c.l.trace,n=#c.n.trace,m=#c.m.trace,hooks=c.hookCount,timers=#c.timers,workers=#c.workers,ox=#c.ox.events},
            helper={trace=#r.helperFixture.trace,callbacks=D.P.snapshot(r.helperFixture.callbacks)}}
        for key,v in pairs(f)do out[key]={trace=effects(v.trace),m=v.m and #v.m.trace or nil,queue=#(v.queue or{}),timers=#(v.timers or v.timerQueue or{}),
            workers=#(v.workers or{}),registrations=v.registrations and #v.registrations or nil}end
        return out
    end
    function r.register()
        for _,d in ipairs(r.api.Callbacks)do r.api.Security.register(d.name,d.handler,d.options)end
    end
    function r.rpc(group,key,source,...)
        local cfg=r.config[group];local list=cfg.Callbacks or cfg.callbacks;local name=assert(list[key],group..'.'..key)
        return assert(c.handlers[name],'unregistered '..name)(source or 2,...)
    end
    return r
end
return D
