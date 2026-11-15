local M=dofile('tests/kernel_admin_menu_harness.lua')
local total=0
local function scenario(options,fn)local p=M.pair(options);fn(p);total=total+p.count end
local function values(animation)return {'true','interact','food','Progress','0','false','0','full',animation,
    -1,5,2,8,3,9,4,10,-10,-5,6,12,'2.5','adrenaline','2500','1.3'}end
for _,case in ipairs({'json','lua','empty','invalid','scalar-json','defaults','canceled','save-failed','encode-failed'})do
    scenario(nil,function(p)
        p.run(case..' interaction editor',function(r)
            r.item.interaction={enabled=true,kind='interact',duration=0,animation={dict='old',anim='old',props={{model='old'}}},
                effects={health={1,2},armor={min=3,max=4},hunger={min='5'},oxygen=false}}
            local animation=case=='empty'and''or(case=='json'and r.codec.encode({dict='new',clip='clip',flag='7',props={{model='test'}}})or'snippet')
            if case=='scalar-json'then animation=r.codec.encode(42)end
            if case=='encode-failed'then r.encodeError=true end
            if case=='save-failed'then r.reply(r.config.Inventory.Callbacks.saveItem,false,'error')end
            if case=='invalid'then r.reply(r.config.Inventory.Callbacks.parseDefinition,false,'error')
            else r.reply(r.config.Inventory.Callbacks.parseDefinition,true,{dict='lua',clip='lua_clip',flag=9})end
            if case~='canceled'then r.inputs={case=='defaults'and{}or values(animation)}end
            r.menu.openInventoryInteractionEditor(r.item)
            local req=r.lastRequest(r.config.Inventory.Callbacks.saveItem)
            if req then
                local payload=req[3];assert(payload.name=='burger'and payload.interaction and r.item.interaction.animation.dict=='old')
                if case~='defaults'then assert(payload.interaction.duration==0 and payload.interaction.remove==0 and not payload.interaction.canCancel)end
            end
            r.runTimers(400)
        end)
    end)
end
scenario(nil,function(p)
    p.run('details opens interaction editor',function(r)
        r.menu.openInventoryEntryDetails('item',r.item);r.select(5)
    end)
    p.run('cooldown suppresses a second action',function(r)
        r.menu.openInventoryEntryDetails('item',r.item);r.select(2)
        local count=r.count('await');r.select(2);assert(r.count('await')==count)
    end)
    p.run('timer can reopen closed menu retained',function(r)
        r.last=nil;r.runTimers(400);assert(r.last and r.last.id=='forge_core_inventory_item')
    end)
    p.run('unlock after 650ms',function(r)
        r.runTimers(650);r.menu.openInventoryEntryDetails('item',r.item)
        local count=r.count('await');r.select(2);assert(r.count('await')==count+1)
    end)
end)
scenario(nil,function(p)
    p.run('inventory transport exception keeps lock',function(r)
        r.menu.openInventoryEntryDetails('item',r.item);r.responses[r.config.Inventory.Callbacks.setItemActive]='throw'
        assert(not pcall(r.select,2));r.responses[r.config.Inventory.Callbacks.setItemActive]=nil
        local count=r.count('await');r.select(2);assert(r.count('await')==count)
    end)
end)
-- Suspended action belongs to a source-agnostic UI closure. No unload/identity cancellation is installed here.
scenario(nil,function(p)
    p.run('old input may save after identity change retained',function(r)
        r.inputHook=function()coroutine.yield('input');return values('')end
        local co=coroutine.create(function()r.menu.openInventoryInteractionEditor(r.item)end)
        local ok,value=coroutine.resume(co);assert(ok and value=='input')
        r.source=3;assert(coroutine.resume(co))
        assert(r.lastRequest(r.config.Inventory.Callbacks.saveItem),'baseline still submits stale edit')
    end)
end)
print('PASS '..total..' interaction/editor/timing differential cases; 25 fields, six effect ranges, JSON/Lua props/flags, clones/cancel and inherited stale form/timer/lock failures')
