-- Attach only menu methods to the existing controller, without replacing PlayerData/Groups or installing UI.
local createShared=require 'kernel.client.menu.shared'
local createInventory=require 'kernel.client.menu.inventory'
local createWeapons=require 'kernel.client.menu.weapons'
return function(state,ports)
    local legacy,producers=assert(state.LegacyCore),assert(state.ProducerCore)
    assert(legacy.State==state and producers.State==state,'canonical client state required')
    assert(state.AdministrationMenus==nil,'administration menus already attached')
    local menu,groups=assert(ports.menu),assert(legacy.Groups)
    assert(type(menu.openServerSettingsMenu)=='function','parent settings menu required')
    for _,name in ipairs({'openInventoryMenu','openInventoryEntries','openInventoryEntryDetails','openInventoryEntryEditor',
        'openInventoryInteractionEditor','openWeaponsMenu','openWeaponDetails','openWeaponEditor'})do
        assert(menu[name]==nil,'menu method already attached: '..name)
    end
    local config=assert(ports.config)
    assert(type(config.Inventory)=='table'and type(config.Weapons)=='table'and type(config.Vip)=='table','local configs required')
    local shared=createShared({library=ports.library,translate=ports.translate,notifyPosition=ports.notifyPosition})
    local function ready()
        return state.LegacyCore==legacy and legacy.State==state and legacy.Groups==groups
            and state.ProducerCore==producers and producers.State==state
    end
    local bindings={menu=menu,shared=shared,config=config,library=ports.library,native=ports.native,
        json=ports.json,groups=groups,isReady=ready}
    createInventory(bindings)
    createWeapons(bindings)
    local api={State=state,Menu=menu,Shared=shared,Groups=groups,Config=config}
    state.AdministrationMenus=api
    return api
end
