local M=dofile('tests/kernel_admin_menu_harness.lua')
local total=0
local function scenario(options,fn)local p=M.pair(options);fn(p);total=total+p.count end
scenario(nil,function(p)
    p.run('inventory root',function(r)r.menu.openInventoryMenu();assert(r.last.menu=='forge_core_server_settings'and #r.last.options==4)end)
    for _,index in ipairs({1,3,4})do p.run('root category '..index,function(r)r.menu.openInventoryMenu();r.select(index)end)end
    p.run('weapons child',function(r)r.menu.openInventoryMenu();r.select(2);assert(r.last.menu=='forge_core_inventory')end)
    for _,kind in ipairs({'item','ammo','component','unknown'})do
        p.run(kind..' list',function(r)r.menu.openInventoryEntries(kind);assert(r.last.menu=='forge_core_inventory')end)
        p.run(kind..' details',function(r)r.menu.openInventoryEntries(kind);r.select(3)end)
        p.run(kind..' create canceled',function(r)r.menu.openInventoryEntries(kind);r.select(1)end)
    end
end)
for _,kind in ipairs({'item','ammo','component'})do
    scenario(nil,function(p)
        p.run(kind..' disable',function(r)
            local entry=kind=='item'and r.item or kind=='ammo'and r.ammo or r.component
            r.menu.openInventoryEntryDetails(kind,entry);r.select(2);r.runTimers(400)
        end)
        p.run(kind..' give self',function(r)
            local entry=kind=='item'and r.item or kind=='ammo'and r.ammo or r.component
            entry.active=true;r.menu.openInventoryEntryDetails(kind,entry);r.runTimers(650);r.inputs={{3}};r.select(3)
            local args=r.lastRequest(r.config.Inventory.Callbacks.give);assert(args[3]==2 and args[4]==kind and args[6]==3);r.runTimers(400)
        end)
        p.run(kind..' edit canceled',function(r)local entry=kind=='item'and r.item or kind=='ammo'and r.ammo or r.component;r.menu.openInventoryEntryDetails(kind,entry);r.select(4)end)
        for _,answer in ipairs({'cancel','confirm'})do
            p.run(kind..' remove '..answer,function(r)
                r.runTimers(650);local entry=kind=='item'and r.item or kind=='ammo'and r.ammo or r.component
                r.menu.openInventoryEntryDetails(kind,entry);r.alerts={answer};r.select(#r.last.options);r.runTimers(400)
            end)
        end
    end)
end
for _,case in ipairs({'missing','invalid','empty'})do
    scenario(nil,function(p)
        p.run('getAll '..case,function(r)
            r.reply(r.config.Inventory.Callbacks.getAll,case~='missing',case=='missing'and'load-error'or case=='invalid'and 3 or {})
            r.menu.openInventoryMenu()
            if case~='missing'then r.menu.openInventoryEntries('item')end
        end)
    end)
end
for _,image in ipairs({'https://fixture/image.png','nui://fixture/a.webp','data:image/png;base64,x','file.png',''})do
    scenario(function(r)r.item.imageUrl=image end,function(p)p.run('image '..image,function(r)r.menu.openInventoryEntries('item')end)end)
end
for _,case in ipairs({'missing','throws','false','empty'})do
    scenario(function(r)
        if case=='missing'then r.library.inventory.GetImagePath=nil elseif case=='throws'then r.imageError=true
        elseif case=='false'then r.imageResult=false else r.imageResult=''end
    end,function(p)p.run('image provider '..case,function(r)r.menu.openInventoryEntries('item');r.menu.openInventoryEntryDetails('item',r.item)end)end)
end
local function input(r,kind)
    if kind=='item'then
        return {'ignored','Edited','55','true','police','2','ballas',1,'false','true','Body','image.webp',
            r.codec.encode({{label='Button'}}),r.codec.encode({event='client'}),r.codec.encode({event='server'}),{'gold','deleted'}}
    end
    return {'new_'..kind,'Edited','4','true','staff',0,'',0,'Description',{'gold'}}
end
for _,kind in ipairs({'item','ammo','component'})do
    scenario(nil,function(p)
        p.run(kind..' complete editor save',function(r)
            local entry=kind=='item'and r.item or kind=='ammo'and r.ammo or r.component
            entry.access={vips={'deleted'},jobs={{name='notlisted',grade=4}},gang={name='ballas',grade=2}}
            r.inputs={input(r,kind)};r.menu.openInventoryEntryEditor(kind,entry)
            local cb=kind=='item'and r.config.Inventory.Callbacks.saveItem or kind=='ammo'and r.config.Inventory.Callbacks.saveAmmo or r.config.Inventory.Callbacks.saveComponent
            local payload=r.lastRequest(cb)[3]
            assert(payload.name==entry.name and payload.access.jobs[1].name==(kind=='item'and'police'or'staff'))
            assert(payload.interaction==nil,'installed editor reconstructs payload and drops existing interaction')
            r.runTimers(400)
        end)
    end)
end
for _,case in ipairs({'jobs-error','gangs-error','stopped','vip-false','vip-invalid','json-failed','encode-failed','save-failed'})do
    scenario(nil,function(p)
        p.run('editor '..case,function(r)
            r.item.access={mode='admin',grade=2,vips={'removed'}}
            if case=='jobs-error'then r.jobsError=true elseif case=='gangs-error'then r.gangsError=true
            elseif case=='stopped'then r.qbxState='stopped'
            elseif case=='vip-false'then r.reply(r.config.Vip.Callbacks.getTiers,false,'no_permission')
            elseif case=='vip-invalid'then r.reply(r.config.Vip.Callbacks.getTiers,true,42)
            elseif case=='json-failed'then r.decodeError=true
            elseif case=='encode-failed'then r.encodeError=true;r.item.buttons={{x=1}}
            elseif case=='save-failed'then r.reply(r.config.Inventory.Callbacks.saveItem,false,'failed')end
            r.inputs={input(r,'item')};r.menu.openInventoryEntryEditor('item',r.item);r.runTimers(400)
        end)
    end)
end
-- Paste is independent of the action lock and commits successful entries even if another entry fails.
for _,case in ipairs({'cancel','parse-failed','no-entries','all-failed','partial','success'})do
    scenario(nil,function(p)
        p.run('paste '..case,function(r)
            r.menu.openInventoryEntries('item')
            if case~='cancel'then r.inputs={{'snippet'}}end
            r.awaitHook=function(name,kind)
                if name==r.config.Inventory.Callbacks.parseDefinition then
                    if case=='parse-failed'then return false,'parse-error'end
                    return true,case=='no-entries'and{}or{entries={{name='good'},{name='bad'}}}
                elseif name==r.config.Inventory.Callbacks.saveItem then return case~='all-failed'and(case~='partial'or kind.name=='good')
                elseif name==r.config.Vip.Callbacks.getTiers then return true,{}end
                return true,r.payload
            end
            r.select(2);r.runTimers(400)
        end)
    end)
end
print('PASS '..total..' inventory menu differential cases; categories/details/actions/images, full editors/access/VIP/JSON schemas, cancel/failure and partial paste semantics')
