local W=dofile('tests/kernel_weapon_harness.lua')
local H=W.H
local a,b=W.config(false),W.config(true);H.same(b,a,'complete config')
for _,seed in ipairs({{}, {extra={1,2},Defaults={name='seed'}}, {Callbacks={extra='extra'},Storage={file='old'}}})do H.same(W.config(true,seed),W.config(false,seed),'config seed')end
local total=4
local p=W.pair('registry')
for _,input in ipairs({false,1,'bad',{}, {name=''}, {name='PISTOL',label=' Pistol ',active=false,ammotype='nil'},
    {name='gadget_parachute',label='',weapontype='Throwable',throwable=false,extra={nested=true}},
    {name='! a% B - ',ammotype='none',damagereason=' '}, {name='rifle',weapontype='Assault Rifle',throwable=true,access={mode='job',name=' Police ',grade='3.9'}},
    {name='weapon_test',access={mode='admin',name='weapon_Admin',grade=-3}},
    {name='weapon_none',access={mode='unknown',name='gadget_x'}},
    {name='weapon_test',access={mode='gang',name=' ballas ',grade=2}}})do
    p.run('normalize',function(r)return r.api.normalizeWeapon(input)end)
end
p.run('set all drops key-only missing name inherited',function(r)
    r.api.setAll({weapon_missing={label='Missing'},weapon_pistol={name='weapon_pistol',label='Pistol'},
        {name='knife',label='Knife'},{name='smg',active=false},'bad'})
    assert(r.api.getWeapons().weapon_missing==nil);return r.api.payload(),r.api.getActiveWeapons()
end)
p.run('upsert',function(r)return r.api.upsert({name='test',label='Test',access={mode='admin'}})end)
p.run('upsert invalid',function(r)return r.api.upsert(false)end)
p.run('copy isolation',function(r)local copy=r.api.getWeapons();copy.weapon_test.label='Copy';return r.api.getWeapons().weapon_test.label end)
p.run('external draft',function(r)local draft={weapons=H.copy(r.api.weapons),revision=r.api.revision};local ok,value=r.api.upsert({name='draft'},draft);return ok,value,draft,r.api.weapons.weapon_draft end)
p.run('disable',function(r)return r.api.setActive(' TEST ',false)end)
p.run('active nonfalse',function(r)return r.api.setActive('test',0)end)
p.run('missing active',function(r)return r.api.setActive('unknown',false)end)
p.run('remove',function(r)return r.api.remove('test')end)
p.run('missing remove',function(r)return r.api.remove('test')end)
p.run('lists sorted and deep copies',function(r)local list=r.api.list();if list[1]then list[1].label='mutated'end;return r.api.list(),r.api.getActiveWeapons()end)
total=total+p.count
p=W.pair('storage')
p.run('load recovery',function(r)return r.api.load()end)
p.run('save empty',function(r)return r.api.save(nil)end)
p.run('load empty',function(r)return r.api.load()end)
p.run('save complete',function(r)return r.api.save({weapon_test={name='weapon_test',label='Test',active=false}})end)
p.run('failed write',function(r)r.memory.onWrite=function()return false end;return r.api.save({weapon_failed={name='weapon_failed'}})end)
p.run('retained data after failed write',function(r)r.memory.onWrite=nil;return r.api.load()end)
total=total+p.count
print('PASS '..total..' weapon config/registry/storage differential cases; complete defaults/access/throwable/drafts/revisions/copies and PR recovery, including inherited key-fallback behavior')
