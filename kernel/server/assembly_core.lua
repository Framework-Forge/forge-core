-- Inactive central server assembly. Resolves only private factories; never starts or installs them.
local createSlots=require 'kernel.server.character_slots'
local createSession=require 'kernel.server.session_core'
local createLifecycle=require 'kernel.server.lifecycle_core'
local createRuntime=require 'kernel.server.runtime_core'
local createCharacters=require 'kernel.server.character_core'
local createCatalog=require 'kernel.server.jobs.catalog_core'
local createJobs=require 'kernel.server.jobs.service_core'
local createFinance=require 'kernel.server.jobs.payments_core'
local createBusiness=require 'kernel.server.jobs.business_core'
local createInventory=require 'kernel.server.inventory.inventory_core'
local createConsumption=require 'kernel.server.inventory.consumption_core'
local createWeapons=require 'kernel.server.weapon.weapon_core'
local createTransport=require 'kernel.server.jobs.transport_core'
local createSlotConfig=require 'kernel.config.forge_character_slots'

local function copy(value)
    local result={};for key,item in pairs(assert(value,'explicit assembly ports required'))do result[key]=item end;return result
end
return function(base,ports)
    assert(type(base)=='table' and type(ports)=='table','prepared base and explicit ports required')
    assert(base.Shared and base.Membership and base.Groups,'canonical base services required')
    for _,name in ipairs({'PlayerCore','JobCatalog','InventoryCore','WeaponCore','Callbacks','ServerAssembly'})do
        assert(base[name]==nil,'fresh base required: '..name)
    end
    for _,name in ipairs({'session','slots','lifecycle','runtime','character','catalog','jobs','finance','business','inventory','consumption','weapons','transport'})do
        assert(type(ports[name])=='table','assembly ports required: '..name)
    end
    assert(type(ports.session.player)=='table' and ports.session.player.characterSlots==nil,'assembly owns Player slot policy')
    for _,name in ipairs({'service','storage','getPlayer','logout'})do assert(ports.slots[name]==nil,'assembly owns slots '..name)end
    assert(ports.slots.config==nil or ports.slots.config==ports.session.player.config,'canonical slot config required')
    assert(ports.character.config==nil or ports.character.config==ports.session.player.config,'canonical character config required')
    assert(ports.slots.starterItems==nil or ports.slots.starterItems==ports.character.starterItems,'canonical starter items required')
    for _,name in ipairs({'slots','slotPolicy','previewsReady','getPreviews'})do assert(ports.character[name]==nil,'assembly owns character '..name)end
    local deps=ports.jobs.dependencies
    assert(type(deps)=='table','one explicit dependency holder required')
    for _,name in ipairs({'JobPayments','VipService','JobPoints','JobBusiness','InventoryService','ConsumableService',
        'WeaponRegistry','WeaponStorage','WeaponQbxSync','WeaponOxSync','WeaponService','State','CharacterSlotService'})do
        assert(deps[name]==nil,'fresh canonical dependency required: '..name)
    end
    local pc,policy=nil,{}
    local api={Base=base,State='constructing',Parts={},Order={}}
    base.ServerAssembly=api
    local function canonical()
        assert(pc and api.State=='prepared-inactive' and base.ServerAssembly==api and base.PlayerCore==pc and pc.Shared==base.Shared and pc.Groups==base.Groups,
            'canonical Player authority unavailable or replaced')
        return pc
    end
    local function stage(name,value)api.Parts[name]=value;api.Order[#api.Order+1]=name;return value end
    local ok,problem=pcall(function()
        local slotPorts=copy(ports.slots)
        slotPorts.service,slotPorts.config,slotPorts.starterItems=policy,ports.session.player.config,assert(ports.character.starterItems)
        slotPorts.storage={}
        for _,name in ipairs({'fetchUserByIdentifier','fetchAllPlayerEntities'})do
            slotPorts.storage[name]=function(...)return assert(canonical().Storage[name])(...)end
        end
        slotPorts.getPlayer=function(...)return canonical().Lookup.GetPlayer(...)end
        slotPorts.logout=function(...)return canonical().Players.Logout(...)end
        local slots=stage('Slots',createSlots(slotPorts))
        assert(slots.Service==policy,'stable policy required')
        local sessionPorts=copy(ports.session);sessionPorts.player=copy(sessionPorts.player)
        sessionPorts.player.characterSlots=policy
        pc=stage('Player',createSession(base,sessionPorts));api.PlayerCore,api.Slots=pc,slots
        stage('Lifecycle',createLifecycle(base,pc,ports.lifecycle))
        stage('Runtime',createRuntime(base,pc,ports.runtime))
        local characterPorts=copy(ports.character)
        characterPorts.config,characterPorts.slots,characterPorts.slotPolicy=sessionPorts.player.config,slots,policy
        local function previewSource()
            local owner=canonical();local admin=base.CharacterAdminCore
            if not admin then return nil end
            assert(admin.PlayerCore==owner and admin.SlotPolicy==policy and admin.Slots==slots,'canonical preview consumer required')
            assert(base.JobCatalog and admin.State==base.JobCatalog.Dependencies.State,'canonical preview world required')
            return admin
        end
        characterPorts.previewsReady=function()return previewSource()~=nil end
        characterPorts.getPreviews=function()
            local admin=assert(previewSource(),'canonical preview consumer unavailable')
            return admin.Exports.GetCharacterPreviews()
        end
        stage('Characters',createCharacters(base,pc,characterPorts))
        local catalog=stage('Catalog',createCatalog(base,ports.catalog))
        stage('Jobs',createJobs(base,ports.jobs))
        local finance=stage('Finance',createFinance(base,ports.finance))
        stage('Business',createBusiness(base,ports.business))
        local inventory=stage('Inventory',createInventory(base,ports.inventory))
        local consumption=stage('Consumption',createConsumption(base,ports.consumption))
        local weapons=stage('Weapons',createWeapons(base,ports.weapons))
        assert(catalog.Dependencies==deps and deps.InventoryService==inventory.Service and deps.ConsumableService==consumption.Service,
            'canonical inventory/consumption required')
        assert(pc.State.UsableItems and inventory.Consumption==consumption and deps.WeaponService==weapons.Service,'canonical usable/weapons required')
        local transportPorts=copy(ports.transport);local config=copy(transportPorts.config)
        for name,value in pairs({Job=catalog.Config,Vip=finance.VipConfig,Inventory=inventory.Config,Weapons=weapons.Config})do
            assert(config[name]==nil or config[name]==value,'canonical callback configuration required: '..name);config[name]=value
        end
        config.CharacterSlots=config.CharacterSlots or createSlotConfig()
        transportPorts.config=config
        local transport=stage('Transport',createTransport(base,transportPorts))
        api.Config,api.Security=config,transport.Security
        assert(base.Callbacks==api.Security and base.JobCatalog.Transport==transport,'canonical transport required')
        api.State='prepared-inactive'
    end)
    if not ok then api.State='construction-failed';error(problem,0)end
    -- The base stays attached; a failed or successful construction may never be replayed onto it.
    -- Public binding, remaining domains, Initialize/Bootstrap and disposal require a later owner.
    return api
end
