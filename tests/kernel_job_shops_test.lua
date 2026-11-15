local B=dofile('tests/kernel_business_harness.lua')
local n=0
local function case(label,action,options)n=n+1;B.case('business',label,action,options)end
local shopId='forge_core_job_police_main_desk_supplies_group'
local function stock(r)return r.registry.get('job','police').stashes[1].shops[1].stock.burger end
local function buy(r,success,payload)
    assert(r.api.registerAll());r.post(success,payload or{source=1,shopType=shopId,itemName='burger',count=2,totalPrice=30})
end
case('register once, preserve metadata',function(r)
    assert(r.api.registerAll());assert(r.api.shops[shopId]);local seq=r.hookSequence;assert(r.api.registerAll());assert(r.hookSequence==seq)
end)
case('no inventory',function(r)local ok,err=r.api.registerAll();B.expect(ok,err,'inventory_unavailable')end,function(r)r.library.inventory.RegisterShop=nil end)
for _,public in ipairs({true,false,'sim','yes','1','true','no',0})do
    case('public flag '..tostring(public),function(r)B.edit(r,function(g,p)p.shops[1].public=public end);assert(r.api.registerAll());r.api.openShop(1,'job','police','main_desk','supplies')end)
end
for _,variant in ipairs({'no-player','wrong-group','low-grade','case-insensitive','missing-group','missing-shop','disabled','wrong-kind','disabled-station'})do
    case('shop access '..variant,function(r)
        local group,point='police','supplies'
        if variant=='no-player'then r.players[1]=nil elseif variant=='wrong-group'then r.players[1].job.name='taxi'
        elseif variant=='low-grade'then r.players[1].job.grade=0 elseif variant=='case-insensitive'then r.players[1].job.name='POLICE'
        elseif variant=='missing-group'then group='none'elseif variant=='missing-shop'then point='none'
        elseif variant=='disabled'then B.edit(r,function(g,p)p.shops[1].enabled=false end)
        elseif variant=='wrong-kind'then B.edit(r,function(g,p)p.shops[1].type='other';p.shops[1].kind='other'end)
        elseif variant=='disabled-station'then B.edit(r,function(g,p)p.enabled=false end)end
        local ok=r.api.openShop(1,'job',group,'main_desk',point)
        assert(ok==(variant=='case-insensitive'or variant=='disabled-station'))
    end)
end
case('private prehook refuses outsider',function(r)assert(r.api.registerAll());r.players[1].job.name='taxi';assert(r.hook('openShop',{source=1,shopType=shopId})==false)end)
case('public prehook passes outsider',function(r)B.edit(r,function(g,p)p.shops[1].public=true end);assert(r.api.registerAll());r.players[1].job.name='taxi';assert(r.hook('openShop',{source=1,shopType=shopId:gsub('_group$','_public')})==nil)end)
case('untracked prehook neutral',function(r)assert(r.api.registerAll());assert(r.hook('openShop',{source=999,shopType='other'})==nil)end)
case('successful post event',function(r)buy(r,true);assert(stock(r)==8 and r.bank.police==30)end)
for _,success in ipairs({false,1,'true'})do case('unsuccessful/strict post',function(r)buy(r,success);assert(stock(r)==10 and r.bank.police==0)end)end
for _,variant in ipairs({'untracked','store-owned','empty-name','zero-count','negative-count','fractional','from-slot','zero-price','stock-clamp'})do
    case('purchase payload '..variant,function(r)
        local p={source=1,shopType=shopId,itemName='burger',count=2,totalPrice=30}
        if variant=='untracked'then p.shopType='other'elseif variant=='store-owned'then p.shopType='forge_core_store_other'
        elseif variant=='empty-name'then p.itemName=''elseif variant=='zero-count'then p.count=0
        elseif variant=='negative-count'then p.count=-1 elseif variant=='fractional'then p.count=2.9;p.totalPrice=30.9
        elseif variant=='from-slot'then p.itemName=nil;p.fromSlot={name='burger'}elseif variant=='zero-price'then p.totalPrice=0
        elseif variant=='stock-clamp'then p.count=100 end
        buy(r,true,p)
    end)
end
case('save failure still credits inherited',function(r)r.saveResult=false;buy(r,true);assert(stock(r)==10 and r.bank.police==30)end)
for _,variant in ipairs({'no-banking','no-ensure','ensure-false','ensure-throw','add-false','add-nil','add-throw'})do
    case('revenue '..variant,function(r)
        if variant=='no-banking'then r.library.banking=nil elseif variant=='no-ensure'then r.library.banking.EnsureJobAccount=nil
        elseif variant=='ensure-false'then r.results.EnsureJobAccount=table.pack(false)
        elseif variant=='ensure-throw'then r.results.EnsureJobAccount='throw'
        elseif variant=='add-false'then r.results.AddJobAccountBalance=table.pack(false)
        elseif variant=='add-nil'then r.results.AddJobAccountBalance=table.pack(nil)
        elseif variant=='add-throw'then r.results.AddJobAccountBalance='throw'end
        buy(r,true);assert(stock(r)==8)
    end)
end
case('supply list coalesces aliases',function(r)local ok,items=r.api.getSupplyItems(1,'job','police','main_desk','supplies');assert(ok and #items==2 and items[1].count==5)end)
case('supply existing',function(r)local ok,count=r.api.supplyShop(1,'job','police','main_desk','supplies','burger',3.9,17.8);assert(ok and count==13 and stock(r)==13 and r.items[1].burger==17)end)
case('supply new',function(r)assert(r.api.supplyShop(1,'job','police','main_desk','supplies','key',1,5));assert(r.registry.get('job','police').stashes[1].shops[1].stock.key==1)end)
for _,variant in ipairs({'blank','zero','negative-price','short-stock','remove-failed','save-failed','no-access'})do
    case('supply failure '..variant,function(r)
        local name,amount,price='burger',3,17
        if variant=='blank'then name=''elseif variant=='zero'then amount=0 elseif variant=='negative-price'then price=-1
        elseif variant=='short-stock'then amount=100 elseif variant=='remove-failed'then r.results.RemoveItem=table.pack(false)
        elseif variant=='save-failed'then r.saveResult=false elseif variant=='no-access'then r.players[1].job.name='taxi'end
        local ok=r.api.supplyShop(1,'job','police','main_desk','supplies',name,amount,price);assert(ok==false)
        if variant=='save-failed'then assert(r.items[1].burger==17 and stock(r)==10,'inherited missing compensation')end
    end)
end
print('PASS '..n..' Business shop differential cases; pre/post purchase, stock, supply and PR banking; inherited failures reproduced')
