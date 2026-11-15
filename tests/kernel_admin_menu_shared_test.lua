local M=dofile('tests/kernel_admin_menu_harness.lua')
local total=0
local function scenario(options,fn)local p=M.pair(options);fn(p);total=total+p.count end
scenario(nil,function(p)
    p.run('translation',function(r)return r.shared.t('test',{value=1})end)
    p.run('notification',function(r)return r.shared.notify({description='Body',type='success'})end)
    p.run('failure unknown default',function(r)return r.shared.notifyFailure('error')end)
    p.run('context provider return ignored',function(r)r.contextReturn=false;return r.shared.showContext({id='one',title='One',options={}})end)
    p.run('input rows/options',function(r)r.inputs={{'value'}};return r.shared.inputDialog('Title',{{type='input'}},{allowCancel=false})end)
    p.run('alert',function(r)r.alerts={'confirm'};return r.shared.alertDialog({header='Confirm'})end)
    p.run('await exact timeout/multiple results',function(r)r.reply('test',false,'error',nil,4);return r.shared.awaitServer('test',1,'two')end)
    for _,value in ipairs({true,false,1,0,'TRUE','sim','false','Yes',{}})do p.run('bool value',function(r)return r.shared.boolValue(value),r.shared.boolDefault(value)end)end
    p.run('bool nil/default/options',function(r)return r.shared.boolValue(nil),r.shared.boolDefault(nil),r.shared.boolOptions()end)
end)
for _,missing in ipairs({'menus','RegisterContext','ShowContext','InputDialog','AlertDialog','callback','await','Notify'})do
    scenario(nil,function(p)
        p.run('missing '..missing,function(r)
            if missing=='menus'or missing=='callback'or missing=='Notify'then r.library[missing]=nil
            elseif missing=='await'then r.library.callback.await=nil
            else r.library.menus[missing]=nil end
            return r.shared.showContext({id='x',title='X'}),r.shared.inputDialog('Input',{}),r.shared.alertDialog({}),r.shared.awaitServer('test')
        end)
    end)
end
print('PASS '..total..' administrative shared-boundary differential cases; ten installed helpers, exact PR request timeout, booleans, fallbacks and inherited ignored UI returns')
