-- Extends the existing management45 controller. No UI/timer/RPC is started by attachment.
local createVip=require 'kernel.client.menu.vip'
local createSlots=require 'kernel.client.menu.character_slots'
return function(state,ports)
    local parent=assert(state.PlayerAdminMenus,'management45 required')
    local client,config=assert(ports.client),assert(ports.config)
    assert(parent.State==state and parent.Client==client and parent.Menu==client.Menu and parent.Shared==assert(state.WorkMenus).Shared,'canonical management menu required')
    assert(parent.Session==client.ForgeSession and parent.World==state.WorldClientCore,'canonical session/world required')
    assert(config.CharacterSlots and config.Vip,'local configuration required')
    assert(state.CharacterAdminMenus==nil,'character admin menus already attached')
    for _,name in ipairs({'openVipClassesMenu','openPlayerVipAdmin','openVipMenu','openCharacterSlotSettings',
        'openCharacterPreviewSettings','openCharacterCreationSettings','openPlayerCharacterSlots'})do
        assert(parent.Menu[name]==nil,'character/VIP menu already attached')
    end
    local bindings={config=config,menu=parent.Menu,shared=parent.Shared,native=assert(ports.native),library=assert(ports.library)}
    local api={State=state,Client=client,Config=config,Menu=parent.Menu,Shared=parent.Shared,Session=parent.Session,
        World=parent.World,Vip=createVip(bindings),Slots=createSlots(bindings)}
    state.CharacterAdminMenus=api
    return api
end
