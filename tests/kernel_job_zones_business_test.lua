local Z=dofile('tests/kernel_job_zones_harness.lua')
local total=0
local function scenario(options,body)local p=Z.pair('business',options);body(p);total=total+p.count end
scenario(nil,function(p)
    p.run('all business targets',function(r)r.refresh();assert(#r.api.zones==10)end)
    p.run('shop open result',function(r)return r.select('forge_core_shop_open_job')end)
    p.run('shop fallback ID',function(r)r.results[r.config.Callbacks.openShop]=table.pack(true,nil);return r.select('forge_core_shop_open_job')end)
    p.run('shop refused',function(r)r.results[r.config.Callbacks.openShop]=table.pack(false,'permission');return r.select('forge_core_shop_open_job')end)
    p.run('shop no stock',function(r)r.payload.jobs[1].stashes[1].shops[1].items={};return r.select('forge_core_shop_open_job')end)
    p.run('supply no items',function(r)r.results[r.config.Callbacks.getSupplyItems]=table.pack(true,{});return r.select('forge_core_shop_supply_job')end)
    p.run('supply refused',function(r)r.results[r.config.Callbacks.getSupplyItems]=table.pack(false,'denied');return r.select('forge_core_shop_supply_job')end)
    p.run('supply cancel',function(r)r.results[r.config.Callbacks.getSupplyItems]=table.pack(true,{{name='burger',label='Burger',count=5}});return r.select('forge_core_shop_supply_job')end)
    p.run('supply submit',function(r)r.inputs={{'burger',3,20}};return r.select('forge_core_shop_supply_job')end)
    p.run('supply submit refused',function(r)r.inputs={{'burger',3,20}};r.results[r.config.Callbacks.supplyShop]=table.pack(false,'missing');return r.select('forge_core_shop_supply_job')end)
    p.run('alarm success',function(r)return r.select('forge_core_business_alarms_job')end)
    p.run('alarm failure',function(r)r.results[r.config.Callbacks.sendAlarm]=table.pack(false,'cooldown');return r.select('forge_core_business_alarms_job')end)
    p.run('boss absent',function(r)return r.select('forge_core_business_bossMenus_job')end)
    p.run('boss present',function(r)r.client.Menu={openBossPanel=function(...)r.record('boss',...)end};return r.select('forge_core_business_bossMenus_job')end)
    p.run('application cancel',function(r)return r.select('forge_core_business_applications_job')end)
    p.run('application pass',function(r)r.inputs={{'2'}};r.results[r.config.Callbacks.submitApplication]=table.pack(true,{score=80,passed=true});return r.select('forge_core_business_applications_job')end)
    p.run('application not passed',function(r)r.inputs={{'1'}};r.results[r.config.Callbacks.submitApplication]=table.pack(true,{score=20,passed=false});return r.select('forge_core_business_applications_job')end)
    p.run('application failure',function(r)r.inputs={{'1'}};r.results[r.config.Callbacks.submitApplication]=table.pack(false,'duplicate');return r.select('forge_core_business_applications_job')end)
    p.run('application no questions',function(r)r.payload.jobs[1].stashes[1].applications[1].questions={};return r.select('forge_core_business_applications_job')end)
end)
for _,kind in ipairs({'deposit','withdraw'})do
    scenario(function(r)r.results[r.config.Callbacks.getRegisterBalance]=table.pack(true,'100')end,function(p)
        p.run(kind..' menu',function(r)r.refresh();return r.select('forge_core_business_registers_job')end)
        p.run(kind..' cancel reopens',function(r)return r.action('menu.business.'..kind)end)
        p.run(kind..' success refresh',function(r)r.inputs={{5,'pw'}};return r.action('menu.business.'..kind)end)
        p.run(kind..' failure stays',function(r)r.inputs={{5,'bad'}};r.results[r.config.Callbacks.registerAction]=table.pack(false,'password');return r.action('menu.business.'..kind)end)
    end)
end
for _,difficulty in ipairs({'easy','medium','hard','unknown'})do
    for _,outcome in ipairs({'success','false','truthy','stopped','progress-cancel','no-progress'})do
        scenario(function(r)
            r.payload.jobs[1].stashes[1].registers[1].robbery={difficulty=difficulty}
            r.results[r.config.Callbacks.getRegisterBalance]=table.pack(false,'unavailable')
            if outcome=='false'then r.lockpick=false elseif outcome=='truthy'then r.lockpick=1
            elseif outcome=='stopped'then r.state='stopped' elseif outcome=='progress-cancel'then r.progress=false
            elseif outcome=='no-progress'then r.library.progress=nil end
        end,function(p)
            p.run(difficulty..' robbery '..outcome,function(r)
                r.refresh();r.select('forge_core_business_registers_job');return r.action('menu.business.rob_register')
            end)
        end)
    end
end
for _,variant in ipairs({'public-true','public-yes','public-no','low-grade','other-group','password','robbery','disabled','no-coords','gang',
    'shop-supply-grade','application-public','alarm-private','boss-grade','no-menus','no-inventory','no-callback','no-target','no-questions'})do
    scenario(function(r)
        local station=r.payload.jobs[1].stashes[1]
        if variant:find('public-',1,true)then
            r.data={};station.shops[1].public=variant=='public-true'and true or variant=='public-yes'and'sim'or'no'
        elseif variant=='low-grade'then r.data.job.grade=0
        elseif variant=='other-group'then r.data.job.name='taxi'
        elseif variant=='password'then r.data={};station.registers[1].accessMode='password'
        elseif variant=='robbery'then r.data={};station.registers[1].robberyEnabled=true
        elseif variant=='disabled'then station.shops[1].enabled=false;station.registers[1].enabled=false
        elseif variant=='no-coords'then for _,key in ipairs({'shops','registers','alarms','bossMenus','applications'})do station[key][1].coords=nil end
        elseif variant=='gang'then r.payload.jobs={}
        elseif variant=='shop-supply-grade'then station.shops[1].supplyGrade=5
        elseif variant=='application-public'then r.data={};station.applications[1].public='1'
        elseif variant=='alarm-private'then r.data={};station.alarms[1].public=true
        elseif variant=='boss-grade'then station.bossMenus[1].minGrade=5
        elseif variant=='no-menus'then r.library.menus=nil
        elseif variant=='no-inventory'then r.library.inventory=nil
        elseif variant=='no-callback'then r.library.callback=nil
        elseif variant=='no-target'then r.library.target=nil
        elseif variant=='no-questions'then station.applications[1].questions={} end
    end,function(p)
        p.run(variant..' build',function(r)r.refresh();return #r.api.zones end)
    end)
end
scenario(nil,function(p)
    p.run('provider false ignored by context',function(r)r.contextResult=false;r.showResult=false;r.refresh();return r.select('forge_core_business_registers_job')end)
    p.run('captured supply after loss still invokes',function(r)r.data={};r.results[r.config.Callbacks.getSupplyItems]=table.pack(true,{});return r.select('forge_core_shop_supply_job')end)
    p.run('live canInteract loss',function(r)return r.option('forge_core_shop_open_job').canInteract()end)
    p.run('RPC exception propagates',function(r)r.awaitError=true;local ok=pcall(r.select,'forge_core_shop_open_job');return ok end)
end)
print('PASS '..total..' client Business differential cases; shop/supply/register/robbery/alarm/boss/application and public/grade/PR failures')

