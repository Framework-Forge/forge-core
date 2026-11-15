local W=dofile('tests/kernel_weapon_harness.lua')
local total=0
local p=W.pair('transport')
p.run('four callbacks/two commands',function(r)
    assert(#r.callbacks==4 and #r.commands==2 and r.commands[1].restricted==false)
    return r.commands[1].name,r.commands[2].name
end)
p.run('getAll denies non-admin',function(r)return r.callback(1,1)end)
p.run('getAll admin',function(r)r.api.start();return r.callback(1,2)end)
p.run('save',function(r)return r.callback(2,2,{name='test',label='Test'})end)
p.run('setActive',function(r)return r.callback(4,2,'test',false)end)
p.run('delete',function(r)return r.callback(3,2,'test')end)
p.run('command denied',function(r)return r.command(1,1,{'pistol'})end)
p.run('command missing args',function(r)return r.command(1,2,{})end)
p.run('command active',function(r)return r.command(1,2,{'PISTOL'})end)
p.run('console alias',function(r)return r.command(2,0,{'gadget_parachute'})end)
p.run('normalization retains punctuation inherited',function(r)return r.command(1,2,{' Pi!STOL '})end)
total=total+p.count
for _,case in ipairs({'qbx-missing','qbx-error','ox-missing','ox-disabled','ox-error','both-stopped','starting','notify-missing'})do
    p=W.pair('transport',function(r)
        if case=='qbx-missing'then r.results.HasWeapon=table.pack(false)
        elseif case=='qbx-error'then r.results.HasWeapon='throw'
        elseif case=='ox-missing'then r.results.HasWeaponItem=table.pack(false)
        elseif case=='ox-disabled'then r.results.HasWeaponItem=table.pack(true,{label='Disabled'},false)
        elseif case=='ox-error'then r.results.HasWeaponItem='throw'
        elseif case=='both-stopped'then r.qbxState='stopped';r.oxState='stopped'
        elseif case=='starting'then r.qbxState='starting';r.oxState='starting'
        elseif case=='notify-missing'then r.library.notify=nil end
    end)
    p.run(case,function(r)return r.command(1,2,{'weapon_pistol'})end)
    p.run(case..' console',function(r)return r.command(2,0,{'weapon_pistol'})end)
    total=total+p.count
end
print('PASS '..total..' weapon callback/command differential cases; exact four routes/two names, permission/failure/status/console and unchanged legacy diagnostic text')
