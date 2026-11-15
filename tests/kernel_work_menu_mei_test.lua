local A=dofile('tests/kernel_work_menu_harness.lua')
local total=0
local function scenario(options,body)local p=A.pair(options);body(p);total=total+p.count end
scenario(nil,function(p)
    p.run('settings cancel',function(r)return r.menu.openMeiSettingsEditor(r.state.payments.mei)end)
    p.run('settings save',function(r)r.inputs={{'true',100,20,'government','bank'}};r.menu.openMeiSettingsEditor({});return r.lastRequest()end)
    p.run('settings lock duplicate',function(r)r.inputs={{'true',200,30,'new','cash'}};r.menu.openMeiSettingsEditor({});return r.lastRequest()end)
    p.run('settings timers',function(r)r.runTimers(500);r.runTimers(1000)end)
    p.run('creator cancel',function(r)return r.menu.openMeiCreator()end)
    p.run('creator grade cancel',function(r)r.inputs={{'Company',2},{'Member',10}};return r.menu.openMeiCreator()end)
    p.run('creator save',function(r)r.inputs={{'Company',1},{'Owner',200}};return r.menu.openMeiCreator()end)
    p.run('creator lock',function(r)r.inputs={{'Company',1},{'Owner',200}};return r.menu.openMeiCreator()end)
    p.run('unlock timer',function(r)r.runTimers(1000)end)
    for _,key in ipairs({'OpenMeiCreator','OpenMEICreator'})do p.run(key,function(r)return r.exports[key]()end)end
    p.run('callback ack ignores cancel',function(r)return r.callbacks[r.config.Job.Callbacks.openMei]()end)
end)
scenario(function(r)r.state.payments.mei.enabled=false end,function(p)
    p.run('MEI disabled',function(r)return r.menu.openMeiCreator()end)
    p.run('callback ack despite disabled',function(r)assert(r.callbacks[r.config.Job.Callbacks.openMei]()==true)end)
end)
scenario(nil,function(p)
    p.run('payment edit',function(r)r.inputs={{'true',5,'cash','false','true',80,'false'}};r.menu.openPaymentEditor({});return r.lastRequest()end)
    p.run('payment duplicate',function(r)r.inputs={{'true',10,'bank','true','false',100,'true'}};return r.menu.openPaymentEditor({})end)
    p.run('payment timer500 and unlock1000',function(r)r.runTimers(500);r.runTimers(1000)end)
    p.run('force payment cancel',function(r)r.menu.openPaymentSettings();return r.select(2)end)
    p.run('force payment confirmed',function(r)r.alerts={'confirm'};r.menu.openPaymentSettings();return r.select(2)end)
    p.run('force payment duplicate',function(r)r.alerts={'confirm'};r.menu.openPaymentSettings();return r.select(2)end)
    p.run('force payment timer',function(r)r.runTimers(500);r.runTimers(1000)end)
end)
for _,kind in ipairs({'payment','mei-settings','mei-create'})do
    scenario(nil,function(p)
        p.run(kind..' error sticks lock',function(r)
            r.awaitError=true
            r.inputs={kind=='payment'and{'true',5,'cash','false','false',100,'true'}
                or kind=='mei-settings'and{'true',100,20,'gov','bank'}or{'Company',1},{'Owner',10}}
            local fn=kind=='payment'and r.menu.openPaymentEditor or kind=='mei-settings'and r.menu.openMeiSettingsEditor or r.menu.openMeiCreator
            local ok=pcall(fn,{});assert(not ok);r.awaitError=false
            return ok
        end)
        p.run(kind..' next attempt still locked',function(r)
            r.inputs={kind=='payment'and{'true',5,'cash','false','false',100,'true'}
                or kind=='mei-settings'and{'true',100,20,'gov','bank'}or{'Company',1},{'Owner',10}}
            local fn=kind=='payment'and r.menu.openPaymentEditor or kind=='mei-settings'and r.menu.openMeiSettingsEditor or r.menu.openMeiCreator
            return fn({})
        end)
    end)
end
print('PASS '..total..' payment/MEI differential cases; full settings/creation/grade forms, descriptors/aliases, timers/locks and error stickiness')

