-- Inactive server-domain composition over the single central assembly47. No runtime installation/start.
local createCentral=require 'kernel.server.assembly_core'
local createHelpers=require 'kernel.helpers'
local createMultiJob=require 'kernel.server.multijob.multijob_core'
local createStaff=require 'kernel.server.staff.staff_core'
local createSkill=require 'kernel.server.skill.skill_core'
local createAutoMedic=require 'kernel.server.automedic.automedic_core'
local createAccess=require 'kernel.server.access_core'
local createSettings=require 'kernel.server.server_settings_core'
local createWorld=require 'kernel.server.world_core'
local createVehicles=require 'kernel.server.vehicle_core'
local createVinewood=require 'kernel.server.vinewood_core'
local createObjects=require 'kernel.server.objects_core'
local createNpcs=require 'kernel.server.npcs_core'
local createSpotlights=require 'kernel.server.spotlights_core'
local createBillboards=require 'kernel.server.billboards_core'
local createStores=require 'kernel.server.stores_core'
local createFarms=require 'kernel.server.farms_core'
local createStarterpack=require 'kernel.server.starterpack_core'
local createPlayerAdmin=require 'kernel.server.player_admin_core'
local createCharacterAdmin=require 'kernel.server.character_admin_core'

local names={'MultiJob','Staff','Skills','AutoMedic','Access','Settings','World','Vehicles','Vinewood',
    'Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','PlayerAdmin','CharacterAdmin'}
local configNames={'Job','Vip','Inventory','Weapons','CharacterSlots','MultiJob','Staff','Skills','AutoMedic','Whitelist','Afk',
    'Password','DatabaseBackup','Weather','Density','Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','Player','PlayerManagement'}
local function copy(value)local out={};for key,item in pairs(assert(value,'explicit domain ports required'))do out[key]=item end;return out end
return function(base,ports)
    assert(type(base)=='table'and type(ports)=='table','base and domain ports required')
    for _,key in ipairs({'DomainAssembly','ServerAssembly','PlayerCore','JobCatalog','Helpers','Callbacks','WorldCore'})do assert(base[key]==nil,'fresh server base required: '..key)end
    local config,domains=copy(ports.config),assert(ports.domains)
    for _,name in ipairs(configNames)do assert(type(config[name])=='table','complete local config required: '..name)end
    for _,name in ipairs(names)do assert(type(domains[name])=='table','domain ports required: '..name);assert(domains[name].config==nil,'domain assembly owns configuration: '..name)end
    assert(type(ports.isReady)=='function','explicit operational readiness required')
    for _,name in ipairs({'isReady','coreState','slotPolicy'})do
        for _,key in ipairs({'Skills','Vehicles','Farms','CharacterAdmin'})do assert(domains[key][name]==nil,'domain assembly owns '..key..'.'..name)end
    end
    local centralPorts=copy(ports.central)
    for _,key in ipairs({'catalog','finance','inventory','weapons','runtime','transport'})do centralPorts[key]=copy(centralPorts[key])end
    for _,entry in ipairs({{'catalog','config','Job'},{'finance','vipConfig','Vip'},{'inventory','config','Inventory'},{'weapons','config','Weapons'}})do
        local stage,key,name=entry[1],entry[2],entry[3]
        assert(centralPorts[stage][key]==nil or centralPorts[stage][key]==config[name],'canonical central config required: '..name)
        centralPorts[stage][key]=config[name]
    end
    local transportConfig=copy(centralPorts.transport.config)
    for key,value in pairs(config)do assert(transportConfig[key]==nil or transportConfig[key]==value,'canonical callback config required: '..key);transportConfig[key]=value end
    centralPorts.transport.config=transportConfig
    local helperPorts=copy(ports.helpers)
    for _,key in ipairs({'isServer','shared','functions'})do assert(helperPorts[key]==nil,'assembly owns helper '..key)end
    local api={Base=base,State='constructing',Parts={},Order={},Callbacks={},RawCallbacks={},Unbound=true}
    base.DomainAssembly=api
    local central,pc,security
    local function canonical()
        return central and central.State=='prepared-inactive'and api.State=='prepared-inactive'
            and base.DomainAssembly==api and base.ServerAssembly==central and base.PlayerCore==pc and base.Callbacks==security
            and base.Helpers==api.Parts.Helpers
    end
    local function ready()return canonical()and ports.isReady()==true end
    local function localLib()
        assert(canonical(),'canonical helpers unavailable during construction/failure/replacement')
        assert(base.Helpers==api.Parts.Helpers,'canonical helper replaced')
        return base.Helpers.Lib
    end
    local facade=setmetatable({
        math=setmetatable({round=function(...)return localLib().math.round(...)end},{__index=function(_,key)return localLib().math[key]end}),
        table=setmetatable({size=function(...)return localLib().table.size(...)end},{__index=function(_,key)return localLib().table[key]end}),
    },{__index=function(_,key)return localLib()[key]end})
    centralPorts.runtime.helpers=facade
    centralPorts.session=copy(centralPorts.session);centralPorts.session.player=copy(centralPorts.session.player)
    centralPorts.session.player.utils=facade
    local function stage(name,value)api.Parts[name]=value;api.Order[#api.Order+1]=name;return value end
    local function bind(name,ctor,direct)
        local bindings=copy(domains[name]);bindings.config=direct and config[direct]or config
        if name=='Skills'or name=='CharacterAdmin'then bindings.isReady=ready end
        if name=='Vehicles'or name=='Farms'then bindings.coreState=function()return ready()and'started'or'stopped'end end
        if name=='CharacterAdmin'then bindings.slotPolicy=central.Slots.Service end
        return stage(name,ctor(base,bindings))
    end
    local ok,problem=pcall(function()
        central=createCentral(base,centralPorts);pc,security=central.PlayerCore,central.Security
        api.Central,api.PlayerCore,api.Security,api.Config=central,pc,security,central.Config
        -- Every config value was present before Security construction; keep one reference per domain.
        for _,name in ipairs(configNames)do assert(central.Config[name]==config[name],'callback configuration identity changed: '..name)end
        helperPorts.isServer,helperPorts.shared,helperPorts.functions=true,base.Shared,pc.Lifecycle.Functions
        base.Helpers=stage('Helpers',createHelpers(helperPorts))
        bind('MultiJob',createMultiJob,'MultiJob')
        bind('Staff',createStaff,'Staff')
        bind('Skills',createSkill,'Skills')
        bind('AutoMedic',createAutoMedic,'AutoMedic')
        bind('Access',createAccess)
        bind('Settings',createSettings)
        bind('World',createWorld)
        bind('Vehicles',createVehicles)
        bind('Vinewood',createVinewood)
        bind('Objects',createObjects)
        bind('Npcs',createNpcs)
        bind('Spotlights',createSpotlights)
        bind('Billboards',createBillboards)
        bind('Stores',createStores)
        bind('Farms',createFarms)
        bind('Starterpack',createStarterpack)
        bind('PlayerAdmin',createPlayerAdmin)
        bind('CharacterAdmin',createCharacterAdmin)
        local registered={}
        local function validate(entry)
            assert(type(entry.name)=='string'and type(entry.handler)=='function','invalid callback descriptor')
            assert(not registered[entry.name],'duplicate callback: '..entry.name)
            registered[entry.name]=true
        end
        local function collect(list)
            for _,entry in ipairs(list or{})do
                validate(entry);api.Callbacks[#api.Callbacks+1]=entry
            end
        end
        for _,key in ipairs({'Transport','Inventory','Weapons'})do collect(central.Parts[key].Callbacks)end
        for _,key in ipairs(names)do collect(api.Parts[key].Callbacks)end
        -- Preserve distinct transport/return contracts. Do not flatten homonymous cache exports.
        api.RawCallbacks.Character=pc.Characters.Character.Callbacks
        api.RawCallbacks.World=api.Parts.World.RawCallbacks
        for name,handler in pairs(api.RawCallbacks.Character)do validate({name=name,handler=handler})end
        for _,entry in ipairs(api.RawCallbacks.World)do validate(entry)end
        api.State='prepared-inactive'
    end)
    if not ok then api.State='construction-failed';error(problem,0)end
    api.IsReady=ready
    return api
end
