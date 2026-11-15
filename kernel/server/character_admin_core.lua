-- Consumer of the SAME character policy, Player and public world; no installation/start here.
local createConfig=require 'kernel.config.forge_character_slots'
local createService=require 'kernel.server.character_admin'
local createCallbacks=require 'kernel.server.character_admin_callbacks'
local createVipCallbacks=require 'kernel.server.vip.callbacks'
local createUsable=require 'kernel.server.inventory.usable_registry'
return function(base,ports)
    local pc,catalog=assert(base.PlayerCore),assert(base.JobCatalog)
    local characters,finance,deps=assert(pc.Characters),assert(catalog.Finance),assert(catalog.Dependencies)
    local slots=assert(characters.Slots).Service
    assert(characters.State==pc.State and ports.slotPolicy==slots,'canonical character policy required')
    assert(pc.Groups==base.Groups and catalog.Groups==base.Groups and catalog.Transport.Security==base.Callbacks,'canonical Player/Job/Security required')
    assert(deps.VipService==finance.Vip,'canonical VIP required')
    local world=assert(deps.State,'canonical public world required')
    assert(base.WorldCore==nil or base.WorldCore.State==world,'canonical world identity required')
    assert(base.CharacterAdminCore==nil and deps.CharacterSlotService==nil,'character administration already attached')
    assert(base.InventoryCore==nil or base.InventoryCore.Service==deps.InventoryService,'canonical optional inventory required')
    local config={};for k,v in pairs(assert(ports.config))do config[k]=v end
    config.CharacterSlots=config.CharacterSlots or createConfig()
    assert(config.Vip==finance.VipConfig,'canonical VIP configuration required')
    local internal={GetCharacterSlotSettings=slots.getSettings,SetCharacterSlotSettings=slots.saveSettings,
        GetCharacterSlotState=slots.getState,CanUnlockCharacterSlots=slots.hasAvailableSlot,
        UnlockCharacterSlots=slots.unlock,SetCharacterSlotUnlocked=slots.setSpecificSlot,
        GetPlayer=assert(pc.Lookup).GetPlayer,Logout=assert(pc.Players).Logout}
    local services=setmetatable({},{__index=function(_,key)return deps[key]end})
    local usable
    if base.InventoryCore then
        usable=assert(base.InventoryCore.Consumption,'canonical consumption20 required').Usable
    else
        -- Same Lifecycle registry; this is a dispatch adapter, not another usable authority.
        local registerLocal=assert(assert(pc.Lifecycle).Functions.Exports.CreateUseableItem)
        usable=createUsable({library=ports.library,native={print=ports.print,setTimeout=assert(ports.native).SetTimeout},
            debug=ports.debug,frameworkLabel=ports.frameworkLabel,registerLocal=function(name,cb)registerLocal(name,cb)end})
    end
    local module=createService({config=config,services=services,library=ports.library,world=world,
        internal=internal,isReady=assert(ports.isReady),native=ports.native,print=ports.print,usable=assert(usable)})
    local api={Base=base,PlayerCore=pc,Slots=characters.Slots,SlotPolicy=slots,State=world,Config=config,
        Vip=finance.Vip,Service=module.Service,Usable=usable,Security=base.Callbacks,Callbacks={},Events=module.Events,Exports=module.Exports}
    for _,list in ipairs({createCallbacks({config=config,service=api.Service,library=ports.library}),
        createVipCallbacks({config=config,service=finance.Vip,clock=ports.clock})})do
        for _,entry in ipairs(list)do api.Callbacks[#api.Callbacks+1]=entry end
    end
    deps.CharacterSlotService,base.CharacterAdminCore=api.Service,api
    return api
end
