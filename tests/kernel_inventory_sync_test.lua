local I=dofile('tests/kernel_inventory_harness.lua')
local n=0
local function case(label,fn,options)n=n+1;I.case(label,fn,options)end
for _,method in ipairs({'upsertItem','deleteItem','setItemActive'})do
    for _,failure in ipairs({'save','stopped','false','throw','success'})do
        case(method..' '..failure,function(r)
            if failure=='save'then r.memory.onWrite=function()return false end elseif failure=='stopped'then r.ready=false
            elseif failure=='false'then r.results.setItemDefinition=table.pack(false);r.results.disableItemDefinition=table.pack(false);r.results.removeItemDefinition=table.pack(false)
            elseif failure=='throw'then r.results.setItemDefinition='throw';r.results.disableItemDefinition='throw';r.results.removeItemDefinition='throw'end
            local ok
            if method=='upsertItem'then ok=r.api.upsertItem(1,{name='burger',label='Changed',weight=200})
            elseif method=='deleteItem'then ok=r.api.deleteItem(1,'burger')else ok=r.api.setItemActive(1,'burger',false)end
            assert(ok==(failure~='save'),'source ignores publication false/stopped/errors after save')
            if failure=='save'then assert(r.api.getItem('burger').label=='Burger')end
        end)
    end
end
case('disable and enable preserved',function(r)assert(r.api.setItemActive(1,'burger',false));assert(r.definitions.burger.disabled);assert(r.api.setItemActive(1,'burger',true));assert(not r.definitions.burger.disabled)end)
case('delete restores unknown-item policy inherited',function(r)assert(r.api.setItemActive(1,'burger',false));assert(not r.api.canUseItem(1,'burger'));assert(r.api.deleteItem(1,'burger'));assert(r.api.canUseItem(1,'burger'))end)
for _,kind in ipairs({'Ammo','Component'})do
    for _,op in ipairs({'upsert','delete','set'})do
        for _,saved in ipairs({true,false})do
            case(kind..op..tostring(saved),function(r)
                assert(r.api['upsert'..kind](1,{name='entry',label='Entry'}));if not saved then r.memory.onWrite=function()return false end end
                local ok
                if op=='upsert'then ok=r.api['upsert'..kind](1,{name='entry',label='Changed'})elseif op=='delete'then ok=r.api['delete'..kind](1,'entry')else ok=r.api['set'..kind..'Active'](1,'entry',false)end
                assert(ok==saved)
            end)
        end
    end
end
case('inactive ammo removes definition',function(r)assert(r.api.upsertAmmo(1,{name='ammo'}));assert(r.definitions.ammo.ammo);assert(r.api.setAmmoActive(1,'ammo',false));assert(r.definitions.ammo==nil and r.api.weaponInventory.ammo.ammo.active==false)end)
case('component flags',function(r)assert(r.api.upsertComponent(1,{name='comp'}));assert(r.definitions.comp.component==true and r.definitions.comp.stack==false and r.definitions.comp.close==false)end)
for _,variant in ipairs({'new','existing','save-failed','sync-failed','sync-throw','inventory-stopped','invalid-second','retry'})do
    case('compat batch '..variant,function(r)
        local definitions={{name='water',label='Water',weight=50}}
        if variant=='existing'then r.definitions.water={label='Existing',weight=1}
        elseif variant=='save-failed'then r.memory.onWrite=function()return false end
        elseif variant=='sync-failed'or variant=='retry'then r.results.setItemDefinition=table.pack(false)
        elseif variant=='sync-throw'then r.results.setItemDefinition='throw'
        elseif variant=='inventory-stopped'then r.ready=false
        elseif variant=='invalid-second'then definitions[2]={label='Invalid'}end
        local ok,count=r.api.addCompatibilityItems(definitions)
        assert(ok==(variant=='new'or variant=='existing'))
        if variant=='retry'then
            assert(r.api.getItem('water')and not r.definitions.water)
            r.results.setItemDefinition=nil;ok,count=r.api.addCompatibilityItems(definitions);assert(ok and count==0 and r.definitions.water)
        elseif variant=='invalid-second'then assert(r.api.getItem('water')==nil)end
    end)
end
case('restart sync delayed explicit event',function(r)r.dispatch('onResourceStart','other');assert(#r.timers==0);r.dispatch('onResourceStart','ox_inventory');assert(r.timers[1].ms==1500);r.runTimers()end)
case('reload legacy save failure ignored inherited',function(r)r.seedItems({sandwich={name='sandwich'}});r.memory.onWrite=function()return false end;assert(r.api.reload());assert(r.api.getItem('sandwich').interaction.enabled)end)
case('reload invalid item retained inherited',function(r)r.seedItems({invalid='not-table'});assert(r.api.reload());assert(r.api.items.invalid=='not-table')end)
case('payload clone and sorting',function(r)assert(r.api.upsertItem(1,{name='aaa',label='A'}));local payload=r.api.getPayload();assert(payload.items[1].name=='aaa');payload.items[1].label='Other';assert(r.api.getItem('aaa').label=='A')end)
case('permission denied before persistence',function(r)r.aces[1]={};local ok,err=r.api.upsertItem(1,{name='denied'});assert(not ok and err=='no_permission')end)
print('PASS '..n..' inventory sync/persistence differential cases; custom disable/remove distinction, ammo/component flags, compat acknowledgement/retry, delayed republish and inherited failure behavior')
