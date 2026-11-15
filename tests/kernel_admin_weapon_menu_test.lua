local M=dofile('tests/kernel_admin_menu_harness.lua')
local total=0
local function scenario(options,fn)local p=M.pair(options);fn(p);total=total+p.count end
scenario(nil,function(p)
    p.run('root custom parent',function(r)r.menu.openWeaponsMenu('external_parent');assert(r.last.menu=='external_parent')end)
    p.run('details',function(r)r.select(3);assert(r.last.menu=='forge_core_weapons')end)
    p.run('disabled info no action',function(r)r.select(1);r.select(2);r.select(3)end)
    p.run('deactivate resets caller parent inherited',function(r)r.select(4);r.runTimers(500);assert(r.last.menu=='forge_core_inventory')end)
    p.run('gift self',function(r)r.runTimers(1000);r.menu.openWeaponDetails(r.weapon);r.inputs={{2}};r.select(5)
        local args=r.lastRequest(r.config.Inventory.Callbacks.give);assert(args[3]==2 and args[4]=='weapon'and args[6]==2);r.runTimers(400)
    end)
    p.run('gift canceled',function(r)r.menu.openWeaponDetails(r.weapon);r.select(5);r.runTimers(400)end)
    p.run('edit canceled',function(r)r.menu.openWeaponDetails(r.weapon);r.select(6)end)
    for _,answer in ipairs({'cancel','confirm'})do p.run('remove '..answer,function(r)
        r.runTimers(1000);r.menu.openWeaponDetails(r.weapon);r.alerts={answer};r.select(7);r.runTimers(500)
    end)end
    p.run('create cancel',function(r)r.menu.openWeaponsMenu();r.select(1)end)
end)
for _,case in ipairs({'failed','invalid','empty','disabled'})do
    scenario(nil,function(p)p.run(case,function(r)
        if case=='failed'then r.reply(r.config.Weapons.Callbacks.getAll,false,'error')
        elseif case=='invalid'then r.reply(r.config.Weapons.Callbacks.getAll,true,3)
        elseif case=='empty'then r.weaponPayload.weapons={}else r.weapon.active=false end
        r.menu.openWeaponsMenu('parent')
        if case=='disabled'then r.select(3);assert(r.last.options[5].disabled);r.select(5);r.select(4)end
    end)end)
end
local function fields()return {'entered','New label','Throwable','none','Test damage','ammo-custom','250','0.3','job','police','2'}end
for _,case in ipairs({'new','existing','failed','defaults'})do
    scenario(nil,function(p)p.run('editor '..case,function(r)
        local weapon
        if case~='new'then weapon=r.weapon end
        if weapon then weapon.model='custom_model';weapon.client={custom=true};weapon.active=false end
        if case=='failed'then r.reply(r.config.Weapons.Callbacks.save,false,'save-error')end
        r.inputs={case=='defaults'and{}or fields()};r.menu.openWeaponEditor(weapon)
        local payload=r.lastRequest(r.config.Weapons.Callbacks.save)[3]
        assert(payload.model==nil and payload.client==nil,'existing editor drops non-edited fields')
        if case~='defaults'then assert(payload.throwable and payload.access.grade==2)end
        r.runTimers(500)
    end)end)
end
for _,case in ipairs({'cancel','parse-failed','no-entries','all-failed','partial','success'})do
    scenario(nil,function(p)p.run('paste '..case,function(r)
        r.menu.openWeaponsMenu('custom')
        if case~='cancel'then r.inputs={{'snippet'}}end
        r.awaitHook=function(name,kind)
            if name==r.config.Inventory.Callbacks.parseDefinition then
                if case=='parse-failed'then return false,'error'end
                return true,case=='no-entries'and{}or{entries={{name='good',active=false},{name='bad'}}}
            elseif name==r.config.Weapons.Callbacks.save then return case~='all-failed'and(case~='partial'or kind.name=='good')end
            return true,r.weaponPayload
        end
        r.select(2);r.runTimers(400)
    end)end)
end
-- Action lock release only happens after a returned RPC; a raised transport error permanently locks the installed action.
scenario(nil,function(p)
    p.run('RPC exception keeps lock retained',function(r)
        r.menu.openWeaponDetails(r.weapon);r.reply(r.config.Weapons.Callbacks.setActive)
        r.responses[r.config.Weapons.Callbacks.setActive]='throw'
        local ok=pcall(r.select,4);assert(not ok)
        r.responses[r.config.Weapons.Callbacks.setActive]=nil
        local count=r.count('await');r.select(4);assert(r.count('await')==count)
    end)
end)
print('PASS '..total..' weapon menu differential cases; complete list/details/editor/give/paste, parent routing, disabled controls, errors and retained payload/lock behavior')
