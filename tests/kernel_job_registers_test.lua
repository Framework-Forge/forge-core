local B=dofile('tests/kernel_business_harness.lua')
local n=0
local function case(label,action)n=n+1;B.case('business',label,action)end
local function balance(r)return r.registry.get('job','police').stashes[1].registers[1].balance end
case('balance',function(r)local ok,b=r.api.getRegisterBalance(1,'job','police','main_desk','cash');assert(ok and b==100)end)
for _,action in ipairs({'deposit','withdraw'})do
    case(action,function(r)local ok,b=r.api.registerAction(1,'job','police','main_desk','cash',action,25.9);assert(ok and b==(action=='deposit'and 125 or 75));assert(r.items[1].money==(action=='deposit'and 975 or 1025))end)
    case(action..' save failed',function(r)r.saveResult=false;local ok,err=r.api.registerAction(1,'job','police','main_desk','cash',action,25);B.expect(ok,err,'save_failed');assert(balance(r)==100 and r.items[1].money==(action=='deposit'and 975 or 1025),'inherited missing compensation')end)
end
for _,variant in ipairs({'password-pass','password-fail','no-group','no-register','disabled','low-grade','wrong-group','no-player','zero','negative','bad-action','too-much','remove-failed','add-failed'})do
    case('register '..variant,function(r)
        local group,point,action,amount,password='police','cash','withdraw',25,'pw'
        if variant:match('^password')then B.edit(r,function(g,p)p.registers[1].accessMode='password'end);r.players[1].job.name='taxi';if variant=='password-fail'then password='bad'end
        elseif variant=='no-group'then group='missing'elseif variant=='no-register'then point='missing'
        elseif variant=='disabled'then B.edit(r,function(g,p)p.registers[1].enabled=false end)
        elseif variant=='low-grade'then r.players[1].job.grade=0 elseif variant=='wrong-group'then r.players[1].job.name='taxi'
        elseif variant=='no-player'then r.players[1]=nil elseif variant=='zero'then amount=0 elseif variant=='negative'then amount=-1
        elseif variant=='bad-action'then action='other'elseif variant=='too-much'then amount=101
        elseif variant=='remove-failed'then action='deposit';r.results.RemoveItem=table.pack(false)
        elseif variant=='add-failed'then r.results.AddItem=table.pack(false)end
        local ok=r.api.registerAction(1,'job',group,'main_desk',point,action,amount,password);assert(ok==(variant=='password-pass'))
    end)
end
for _,variant in ipairs({'normal','no-member','no-alert','missed-alert','empty','disabled','max-balance','requested-fallback','add-failed','save-failed','repeat-save-failed'})do
    case('robbery '..variant,function(r)
        local amount=15
        if variant=='no-member'then r.players[1].job.name='taxi'
        elseif variant=='no-alert'then B.edit(r,function(g,p)p.registers[1].robberyAlertChance=0 end)
        elseif variant=='missed-alert'then r.random=100;B.edit(r,function(g,p)p.registers[1].robberyAlertChance=10 end)
        elseif variant=='empty'then B.edit(r,function(g,p)p.registers[1].balance=0 end)
        elseif variant=='disabled'then B.edit(r,function(g,p)p.registers[1].robberyEnabled=false end)
        elseif variant=='max-balance'then B.edit(r,function(g,p)p.registers[1].robberyAmount=1000 end)
        elseif variant=='requested-fallback'then B.edit(r,function(g,p)p.registers[1].robberyAmount=nil end)
        elseif variant=='add-failed'then r.results.AddItem=table.pack(false)
        elseif variant:match('save%-failed')then r.saveResult=false end
        local ok=r.api.robRegister(1,'job','police','main_desk','cash',amount)
        if variant=='repeat-save-failed'then assert(not ok);assert(not r.api.robRegister(1,'job','police','main_desk','cash',amount));assert(balance(r)==100 and r.items[1].money==1060)
        elseif variant=='save-failed'then assert(not ok and balance(r)==100 and r.items[1].money==1030)
        elseif variant=='empty'or variant=='disabled'or variant=='add-failed'then assert(not ok)
        else assert(ok)end
    end)
end
for _,variant in ipairs({'normal','disabled','wrong-group','low-grade','missing'})do
    case('alarm '..variant,function(r)
        local id='panic'
        if variant=='disabled'then B.edit(r,function(g,p)p.alarms[1].enabled=false end)
        elseif variant=='wrong-group'then r.players[1].job.name='taxi'elseif variant=='low-grade'then r.players[1].job.grade=0
        elseif variant=='missing'then id='other'end
        local ok=r.api.sendAlarm(1,'job','police','main_desk',id);assert(ok==(variant=='normal'))
    end)
end
print('PASS '..n..' Business register/alarm differential cases; inventory-money and persistence failures reproduced, no real balances touched')
