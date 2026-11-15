local R=dofile('tests/kernel_server_runtime_harness.lua')
local H,count=R.H,0
local function test(name,fn) R.compare('commands',name,fn);count=count+1 end
local names={'tp','tpm','togglepvp','addpermission','removepermission','openserver','closeserver','car','dv',
    'givemoney','setmoney','job','setjob','changejob','addjob','removejob','gang','setgang','ooc','me','id','logout','deletechar','optin'}
local values={tp={x='2'},addpermission={id=2,permission='admin'},removepermission={id=2,permission='admin'},
    car={model='car'},givemoney={id=2,moneytype='cash',amount=25},setmoney={id=2,moneytype='bank',amount=70},
    setjob={id=2,job='taxi',grade=1},changejob={id=2,job='taxi'},addjob={id=2,job='taxi',grade=1},
    removejob={id=2,job='taxi'},setgang={id=2,gang='ballas',grade=1},me={message='<b>Hi</b> ~r~text'}}
local function args(name)
    if name=='ooc' then return {'hello','city'} elseif name=='deletechar' then return {id=2} end
    return R.args(name,values[name])
end
test('complete registration metadata',function(r)
    local all={};for _,name in ipairs(names) do all[#all+1]=r.commands[name].options end
    local total=0;for _ in pairs(r.commands) do total=total+1 end;assert(total==24)
    return all
end)
for _,name in ipairs(names) do test('command '..name,function(r) r.command(name,args(name)) end) end
local guarded={'tp','tpm','togglepvp','addpermission','removepermission','openserver','closeserver','car','dv',
    'givemoney','setmoney','setjob','changejob','addjob','removejob','setgang','deletechar'}
for _,name in ipairs(guarded) do test('optin denial '..name,function(r)
    r.optin=false;local before=#r.trace;r.command(name,args(name));assert(#r.trace==before+2 and r.trace[#r.trace].kind=='notify')
end) end
for _,name in ipairs({'addpermission','removepermission','givemoney','setmoney','setjob','changejob','addjob','removejob','setgang','deletechar'}) do
    test('player missing '..name,function(r) r.core.Players[2]=nil;r.command(name,args(name)) end)
end
for _,name in ipairs({'setjob','changejob','addjob','removejob','setgang'}) do test('group error '..name,function(r)
    r.actionSuccess=false;assert(not pcall(r.command,name,args(name)));assert(r.trace[#r.trace].kind=='encode')
end) end
for _,name in ipairs({'setjob','addjob','setgang'}) do test('default grade '..name,function(r)
    local a=args(name);a['command.'..name..'.params.grade.name']=nil;r.command(name,a)
end) end
for _,name in ipairs({'job','gang'}) do
    test('nil player legacy error '..name,function(r) r.core.Players[1]=nil;return pcall(r.command,name) and true or false end)
    test('nil job/gang optional '..name,function(r) r.core.Players[1].PlayerData[name]=nil;r.command(name) end)
    test('missing grade legacy error '..name,function(r) r.core.Players[1].PlayerData[name].grade=nil;return pcall(r.command,name) and true or false end)
end
test('tp player missing',function(r) r.command('tp',R.args('tp',{x='999'})) end)
test('tp missing args',function(r) r.command('tp',R.args('tp',{x='5',y='8'})) end)
test('tp coordinates commas',function(r) r.command('tp',R.args('tp',{x='1,000',y='5',z='7'})) end)
test('tp zero wrong format',function(r) r.command('tp',R.args('tp',{x='0',y='5',z='7'})) end)
test('tp invalid numeric legacy error',function(r) return pcall(r.command,'tp',R.args('tp',{x='bad',y='5',z='7'})) and true or false end)
test('tp wrong argument type legacy error',function(r) return pcall(r.command,'tp',R.args('tp',{x=3,y=5,z=7})) and true or false end)
for _,allow in ipairs({false,true}) do
    test('open closed '..tostring(allow),function(r) r.config.server.closed=true;r.aces[1]={admin=allow};r.command('openserver') end)
    test('close open '..tostring(allow),function(r)
        r.aces[1]={admin=allow};r.aces[2]={admin=true};r.command('closeserver',R.args('closeserver',{reason='Maintenance'}))
    end)
end
test('close already closed',function(r) r.config.server.closed=true;r.command('closeserver') end)
test('close default reason',function(r) r.aces[1]={admin=true};r.command('closeserver') end)
for _,keep in ipairs({false,true,'false'}) do test('spawn keep '..tostring(keep),function(r)
    r.command('car',R.args('car',{model='car',keepCurrentVehicle=keep}))
end) end
test('spawn no current vehicle',function(r) r.pedVehicle=0;r.command('car',args('car')) end)
test('spawn nil args returns',function(r) r.commands.car.handler(1,nil) end)
for _,state in ipairs({'started','starting','stopped','uninitialized'}) do test('delete keys resource '..state,function(r)
    r.keysState=state;r.command('dv')
end) end
test('delete plate absent',function(r) r.plate=nil;r.command('dv') end)
test('delete key provider throws',function(r) r.keyError=true;r.command('dv') end)
test('delete radius explicitly zero',function(r) r.command('dv',R.args('dv',{radius=0})) end)
test('delete radius',function(r) r.command('dv',R.args('dv',{radius=20})) end)
test('delete on foot callback',function(r) r.pedVehicle=0;r.command('dv') end)
test('delete callback empty',function(r) r.pedVehicle=0;r.nearby={};r.command('dv') end)
test('delete entity missing',function(r) r.entityExists=false;r.command('dv') end)
test('delete callback nil legacy error',function(r) r.pedVehicle=0;r.awaitHook=function() return nil end;return pcall(r.command,'dv') and true or false end)
test('ooc no player',function(r) r.core.Players[1]=nil;r.command('ooc',{'hello'}) end)
test('ooc string source own branch',function(r) r.command('ooc',{'hello'},'1') end)
test('ooc distant admin optin',function(r) r.aces[3]={admin=true};r.command('ooc',{'hello'}) end)
test('ooc distant admin optout',function(r) r.aces[3]={admin=true};r.optins={[1]=true,[2]=true,[3]=false};r.command('ooc',{'hello'}) end)
test('ooc strict distance 20',function(r) r.coords[11]=R.V.vector(20,0,0);r.command('ooc',{'hello'}) end)
test('ooc chat failure propagates',function(r) r.chatError=true;return pcall(r.command,'ooc',{'hello'}) and true or false end)
test('me empty warns',function(r) r.command('me') end)
test('me sanitization and immediate reset',function(r)
    local a=R.args('me',{message='<b>Hello</b> ~r~city'});r.command('me',a)
    assert(a[1]=='<b>Hello</b> ~r~city' and a['command.me.params.message.name']==nil)
    local set,reset=r.trace[#r.trace-1],r.trace[#r.trace]
    assert(set.kind=='state' and set.args[3]=='Hello city' and reset.args[3]==nil and reset.args[4]==true)
end)
test('optin toggles back',function(r) r.command('optin');r.command('optin') end)
local port=R.new(true,'commands');assert(port.initialize() and not port.initialize() and port.globalState.PVPEnabled)
for _,name in ipairs(guarded) do assert(port.commands[name].options.restricted=='group.admin') end
assert(port.commands.logout.options.restricted=='group.admin' and port.commands.logout.handler==port.services.Logout)
assert(not port.commands.job.options.restricted and not port.commands.gang.options.restricted and not port.commands.me.options.restricted)
print('PASS server commands: '..count..' differential cases; all 24 descriptors/metadata, optin/ACL/refusals, internal player/group/money actions, PR chat/key boundaries and retained invalid-input errors')
