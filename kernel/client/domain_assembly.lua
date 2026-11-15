-- Private client-domain attachment over assembly49; no runtime installation or service startup.
local createJobs=require 'kernel.client.job.job_core'
local createZones=require 'kernel.client.job.zones_core'
local createAdmin=require 'kernel.client.menu.administration_core'
local createWork=require 'kernel.client.menu.work_core'
local createMultiJob=require 'kernel.client.menu.multijob_core'
local createStaff=require 'kernel.client.menu.staff_core'
local createSkills=require 'kernel.client.skill.skill_core'
local createSkillMenus=require 'kernel.client.menu.skills_core'
local createAutoMedic=require 'kernel.client.automedic.automedic_core'
local createAccess=require 'kernel.client.access_core'
local createSettings=require 'kernel.client.menu.server_settings_core'
local createWorld=require 'kernel.client.world_core'
local createVehicles=require 'kernel.client.menu.vehicles_core'
local createVinewood=require 'kernel.client.vinewood_core'
local createObjects=require 'kernel.client.objects_core'
local createNpcs=require 'kernel.client.npcs_core'
local createSpotlights=require 'kernel.client.spotlights_core'
local createBillboards=require 'kernel.client.billboards_core'
local createStores=require 'kernel.client.stores_core'
local createFarms=require 'kernel.client.farms_core'
local createStarterpack=require 'kernel.client.starterpack_core'
local createPlayerAdmin=require 'kernel.client.menu.player_admin_core'
local createCharacterAdmin=require 'kernel.client.menu.character_admin_core'
local names={'Jobs','Zones','Administration','Work','MultiJob','Staff','Skills','SkillMenus','AutoMedic','Access','Settings','World',
    'Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','PlayerAdmin','CharacterAdmin'}
local configNames={'Job','Inventory','Weapons','Vip','MultiJob','Staff','Skills','AutoMedic','Whitelist','Afk','Password','DatabaseBackup',
    'Weather','Density','Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','Player','PlayerManagement','CharacterSlots'}
local slots={'JobClientCore','JobZoneCore','AdministrationMenus','WorkMenus','MultiJobMenus','StaffMenus','SkillClientCore','SkillMenus',
    'AutoMedicClientCore','AccessClientCore','ServerSettingsMenus','WorldClientCore','VehicleMenus','VinewoodClientCore','ObjectsClientCore',
    'NpcsClientCore','SpotlightsClientCore','BillboardsClientCore','StoresClientCore','FarmsClientCore','StarterpackClientCore','PlayerAdminMenus','CharacterAdminMenus'}
local function copy(t)assert(type(t)=='table','explicit domain ports required');local out={};for k,v in pairs(t)do out[k]=v end;return out end
return function(state,ports)
    assert(type(state)=='table'and type(ports)=='table','canonical state/domain ports required')
    local central=assert(state.ClientAssembly,'central client49 required')
    assert(central.Core==state and central.State=='prepared-inactive'and central.IsCanonical(),'prepared canonical client49 required')
    assert(state.ClientDomainAssembly==nil,'client domain assembly already attached')
    for _,key in ipairs(slots)do assert(state[key]==nil,'client domain already attached: '..key)end
    local config,domains,client=copy(ports.config),assert(ports.domains),assert(ports.client)
    assert(type(client)=='table'and next(client)==nil,'fresh client holder required')
    for _,name in ipairs(configNames)do assert(type(config[name])=='table','complete local config required: '..name)end
    assert(config.Inventory==central.Config.Inventory,'canonical Inventory config49 required')
    for _,name in ipairs(names)do
        assert(type(domains[name])=='table','domain ports required: '..name)
        for _,key in ipairs({'client','menu','config','shared','world','session','playerAccess','groups','isReady','notifyPosition','debugEnabled'})do
            assert(domains[name][key]==nil,'assembly owns '..name..'.'..key)
        end
    end
    local api={Core=state,Central=central,Client=client,Config=config,State='constructing',Parts={},Order={},Callbacks={},Unbound=true}
    state.ClientDomainAssembly=api
    local menu={};client.Menu=menu;api.Menu=menu
    local function canonical()
        local valid=api.State=='prepared-inactive'and state.ClientDomainAssembly==api and state.ClientAssembly==central
            and central.IsCanonical()and client.Menu==menu and state.WorkMenus==api.Parts.Work
            and state.ServerSettingsMenus==api.Parts.Settings and state.WorldClientCore==api.Parts.World
            and client.WorldState==api.Parts.World.WorldState and client.ForgeSession==api.Parts.AutoMedic.Session.Session
            and client.JobState==api.Parts.Jobs.JobState and api.Shared==api.Parts.Work.Shared
            and api.Shared==api.Parts.Administration.Shared and menu.openServerSettingsMenu==api.SettingsMethod
        if not valid then return false end
        for index,key in ipairs(slots)do if state[key]~=api.Parts[names[index]]then return false end end
        return true
    end
    local function parent(...)
        assert(canonical(),'settings parent unavailable during construction/failure/replacement')
        return assert(api.Parts.Settings.Menu.openServerSettingsMenu)(...)
    end
    api.SettingsParent=parent;menu.openServerSettingsMenu=parent
    local function bind(name,ctor,direct)
        local p=copy(domains[name]);p.client,p.config=client,direct and config[direct]or config
        p.notifyPosition,p.debugEnabled=config.NotifyPos,config.Debug
        if name=='Administration'then p.menu=menu end
        local value=ctor(state,p);api.Parts[name]=value;api.Order[#api.Order+1]=name;return value
    end
    local ok,problem=pcall(function()
        bind('Jobs',createJobs,'Job');bind('Zones',createZones,'Job')
        bind('Administration',createAdmin);bind('Work',createWork)
        bind('MultiJob',createMultiJob);bind('Staff',createStaff)
        bind('Skills',createSkills,'Skills');bind('SkillMenus',createSkillMenus)
        bind('AutoMedic',createAutoMedic);bind('Access',createAccess)
        -- Release only our owned forward reference. The unchanged Settings34 guard requires absence.
        assert(menu.openServerSettingsMenu==parent,'settings parent ownership changed')
        menu.openServerSettingsMenu=nil
        bind('Settings',createSettings)
        assert(type(menu.openServerSettingsMenu)=='function'and menu.openServerSettingsMenu~=parent,'real settings parent not attached')
        assert(api.Parts.Settings.Menu==menu,'settings parent/controller identity changed')
        api.SettingsMethod=menu.openServerSettingsMenu
        bind('World',createWorld);bind('Vehicles',createVehicles);bind('Vinewood',createVinewood)
        bind('Objects',createObjects);bind('Npcs',createNpcs);bind('Spotlights',createSpotlights);bind('Billboards',createBillboards)
        bind('Stores',createStores);bind('Farms',createFarms);bind('Starterpack',createStarterpack)
        bind('PlayerAdmin',createPlayerAdmin);bind('CharacterAdmin',createCharacterAdmin)
        api.Shared=api.Parts.Administration.Shared
        local seen={}
        local function collect(owner,list)
            for name,handler in pairs(list or{})do
                assert(type(name)=='string'and type(handler)=='function','invalid raw callback descriptor')
                assert(not seen[name],'duplicate raw callback: '..name);seen[name]=true
                api.Callbacks[#api.Callbacks+1]={name=name,handler=handler,owner=owner}
            end
        end
        for _,entry in ipairs(central.Callbacks)do collect('Central.'..entry.owner,{[entry.name]=entry.handler})end
        collect('Jobs.Main',api.Parts.Jobs.Main.Callbacks)
        for _,name in ipairs(names)do if name~='Jobs'then collect(name,api.Parts[name].Callbacks)end end
        api.State='prepared-inactive'
    end)
    if not ok then api.State='construction-failed';error(problem,0)end
    api.IsCanonical=canonical
    return api
end
