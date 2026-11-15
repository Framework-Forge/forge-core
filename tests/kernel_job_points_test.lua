local B=dofile('tests/kernel_business_harness.lua')
local n=0
local function case(label,action,options)n=n+1;B.case('points',label,action,options)end
local id='forge_core_stash:job:police:main_desk'
case('full registration and replacement',function(r)
    assert(r.api.registerAll());assert(r.api.registered[id]);local old=r.api.hookId
    assert(r.api.registerAll());assert(r.api.hookId~=old and not r.hooks[old])
end)
for _,variant in ipairs({'point-off','stash-off','label','defaults','bad-coords','v2','v4','override','gang','empty'})do
    case('registration '..variant,function(r)
        B.edit(r,function(g,p)
            if variant=='point-off'then p.enabled=false elseif variant=='stash-off'then p.stash.enabled=false
            elseif variant=='label'then p.stash.label='  Custom  '
            elseif variant=='defaults'then p.stash={enabled=true};p.title=''
            elseif variant=='bad-coords'then p.coords='invalid'
            elseif variant=='v2'then p.coords={x=1,y=2}
            elseif variant=='v4'then p.coords={x=1,y=2,z=3,w=4}
            elseif variant=='override'then p.stash.coords={x=4,y=5,z=6}
            elseif variant=='gang'then g.name='ballas';g.type='gang'
            elseif variant=='empty'then g.stashes={}end
        end,variant=='gang'and'gang'or'job')
        assert(r.api.registerAll())
    end)
end
case('inventory unavailable',function(r)local ok,err=r.api.registerAll();B.expect(ok,err,'inventory_unavailable')end,
    function(r)r.library.inventory.RegisterStash=nil end)
for _,variant in ipairs({'no-player','wrong-group','case-sensitive','low-grade','password','item','item-api','disabled','unknown','group-unknown'})do
    local errors={['no-player']='invalid_player',['wrong-group']='wrong_group',['case-sensitive']='wrong_group',
        ['low-grade']='low_grade',password='wrong_password',item='missing_item',['item-api']='item_check_failed',
        disabled='stash_not_found',unknown='stash_not_found',['group-unknown']='stash_not_found'}
    case('stash '..variant,function(r)
        local group,point='police','Main Desk'
        if variant=='no-player'then r.players[1]=nil elseif variant=='wrong-group'then r.players[1].job.name='taxi'
        elseif variant=='case-sensitive'then r.players[1].job.name='POLICE'
        elseif variant=='low-grade'then r.players[1].job.grade=0 elseif variant=='item'then r.items[1].key=0
        elseif variant=='item-api'then r.library.inventory.HasItem=nil
        elseif variant=='disabled'then B.edit(r,function(g,p)p.enabled=false end)
        elseif variant=='unknown'then point='missing'elseif variant=='group-unknown'then group='missing'end
        local ok,err=r.api.openStash(1,'job',group,point,variant=='password'and'wrong'or'pw');B.expect(ok,err,errors[variant])
    end)
end
for _,grade in ipairs({4,'4',{level='4'},{grade=4},{value=4}})do
    case('grade representations',function(r)r.players[1].job.grade=grade;assert(r.api.openStash(1,'job','police',' Main  Desk! ','pw'))end)
end
case('blank item and password',function(r)B.edit(r,function(g,p)p.stash.password='';p.stash.item=''end);assert(r.api.openStash(1,'other','police','main_desk'))end)
case('force open false ignored inherited',function(r)r.results.forceOpenInventory=table.pack(false);assert(r.api.openStash(1,'job','police','main_desk','pw'))end)
case('gang stash',function(r)B.edit(r,function()end,'gang');assert(r.api.openStash(1,'gang','ballas','main_desk','pw'))end)
case('duty roundtrip',function(r)local ok,on=r.api.toggleDuty(1,'police','main_desk');assert(ok and on);ok,on=r.api.toggleDuty(1,'police','main_desk');assert(ok and not on)end)
for _,variant in ipairs({'missing','disabled','no-setter','setter-false','setter-nil','wrong-group'})do
    case('duty '..variant,function(r)
        local point='main_desk'
        if variant=='missing'then point='none'elseif variant=='disabled'then B.edit(r,function(g,p)p.duty.enabled=false end)
        elseif variant=='no-setter'then r.playerAccess.SetPlayerDuty=nil
        elseif variant=='wrong-group'then r.players[1].job.name='taxi'
        else r.results.SetPlayerDuty=variant=='setter-nil'and table.pack(nil)or table.pack(false,'denied')end
        local ok,err=r.api.toggleDuty(1,'police',point);assert(ok==false and err~=nil)
    end)
end
for _,variant in ipairs({'add','remove','untracked','empty-url','bad-slot','no-native-name','not-player'})do
    case('webhook '..variant,function(r)
        if variant=='empty-url'then B.edit(r,function(g,p)p.stash.webhook=''end)end
        assert(r.api.registerAll())
        if variant=='no-native-name'then r.native.getPlayerName=function()return nil end;r.env.GetPlayerName=r.native.getPlayerName end
        local payload={source=1,fromInventory=1,toInventory=id,fromType='player',toType='stash',fromSlot={name='burger',count=2,metadata={quality=3}}}
        if variant=='remove'then payload.fromInventory=id;payload.toInventory=1;payload.toType='player';payload.fromType='stash'
        elseif variant=='untracked'then payload.toInventory='other'elseif variant=='bad-slot'then payload.fromSlot=4
        elseif variant=='not-player'then payload.fromType='stash'end
        r.hook('swapItems',payload)
    end)
end
case('inventory stopped preserves old hook',function(r)assert(r.api.registerAll());local old=r.api.hookId;r.inventoryReady=false;assert(r.api.registerAll());assert(r.api.hookId==old)end)
case('failed hook removal leaves old installed hook',function(r)assert(r.api.registerAll());local old=r.api.hookId;r.removeHookError=true;assert(r.api.registerAll());assert(r.hooks[old]and r.api.hookId~=old)end)
print('PASS '..n..' Points differential cases; access, duty, vectors, registration and webhook contracts; all effects simulated')
