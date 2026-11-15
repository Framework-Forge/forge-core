local T=dofile('tests/kernel_state_input_harness.lua');local checks=0
local function test(label,fn)fn();checks=checks+1 end
local function fresh()
    local r=T.ports();r.calls={}
    local s={owner={},bags={{key='raw',handler=function(...)r.calls[#r.calls+1]=table.pack(...);return nil,8,nil end},
        {key='entity',entity=true,handler=function(...)r.calls[#r.calls+1]=table.pack(...);return'ignored'end}},
        keys={{name='owned',defaultKey='H',onPressed=function(...)r.calls[#r.calls+1]=table.pack(...)end,
            onReleased=function()r.releases=(r.releases or 0)+1 end}},isCurrent=function()return not r.replaced end}
    r.common(s);return r
end
test('inert constructor',function()local r=fresh();assert(r.adds==0 and next(r.provider.list)==nil and next(r.commands)==nil)end)
test('explicit single install',function()local r=fresh();assert(r.api.Install()and not r.api.Install()and r.adds==2)end)
test('copies descriptors/provider mutation isolated',function()local r=fresh();r.api.Install();assert(r.spec.keys[1].combos==nil and r.provider.get('owned')~=r.spec.keys[1])end)
test('raw preserves nil arguments and returns',function()local r=fresh();r.api.Install();local v=r.emit('raw','global',false,nil,true);assert(v.n==3 and v[1]==nil and v[2]==8 and v[3]==nil);assert(r.calls[1].n==5 and r.calls[1][3]==false and r.calls[1][5]==true)end)
test('entity adapter drops returns and preserves source',function()local r=fresh();r.api.Install();local v=r.emit('entity','entity:31',true);assert(v.n==0);assert(r.calls[1][1]==20 and r.calls[1][2]==31 and r.calls[1][4]=='entity:31')end)
test('zero remains truthy as original helper wrapper',function()local r=fresh();r.ports.resolveEntity=function()return 0,0 end;r.spec.owner.StateInputRegistration=nil;r.common(r.spec);r.api.Install();r.emit('entity','entity:0',true);assert(r.calls[1][1]==0)end)
test('same PR key pressed and released once',function()local r=fresh();r.api.Install();r.key('owned');r.key('owned');r.key('owned',false);assert(#r.calls==1 and r.releases==1 and r.calls[1][1]==r.provider.get('owned'))end)
test('PR pause gating unchanged',function()local r=fresh();r.api.Install();r.paused=true;r.key('owned');assert(#r.calls==0)end)
test('source descriptors changed cannot alter installed closure',function()local r=fresh();r.api.Install();r.spec.keys[1].onPressed=function()error('mutated')end;r.key('owned');assert(#r.calls==1)end)
test('public phase cannot resurrect after dispose',function()local r=fresh();r.api.Install();local bind=r.provider.get('owned');r.api.Dispose();r.api.State='installed';bind.onPressed();bind.onReleased();r.key('owned');r.key('owned',false);assert(#r.calls==0 and not r.releases and not r.api.Install())end)
test('inverse cookies and retained native mapping',function()local r=fresh();r.api.Install();assert(r.api.Dispose());assert(r.removed[1]==2 and r.removed[2]==1 and next(r.provider.list)==nil and r.commands['+owned']and #r.mappings==1 and r.api.PhysicalKeyUnregistration==false)end)
test('foreign statebag never removed',function()local r=fresh();r.bags[99]={key='foreign'};r.api.Install();r.api.Dispose();assert(r.bags[99])end)
test('foreign keybind replacement survives',function()
    local r=fresh();r.api.Install();local old=r.provider.get('owned');r.provider.list.owned={foreign=true};r.api.Dispose()
    assert(r.provider.get('owned').foreign and old.disabled and not old.isPressed)
    local renamed=fresh();renamed.api.Install();local bind=renamed.provider.get('owned');bind.name='foreign54'
    local foreign={foreign=true};renamed.provider.list.foreign54=foreign
    assert(not renamed.api.Dispose()and renamed.provider.get('foreign54')==foreign and bind.disabled,'mutated owned name cannot destroy foreign registry entry')
    bind.name='owned';assert(renamed.api.Dispose()and renamed.provider.get('foreign54')==foreign)
end)
test('missing namespace refuses before native install',function()local r=fresh();r.occupied=true;assert(not pcall(r.api.Install)and r.adds==0 and not r.api.Install())end)
test('existing provider name is not adopted',function()local r=fresh();local foreign={foreign=true};r.provider.list.owned=foreign;assert(not pcall(r.api.Install)and r.provider.get('owned')==foreign and r.adds==0)end)
test('duplicate bag keys refused',function()local r=fresh();r.spec.owner.StateInputRegistration=nil;r.spec.bags[2]={key='raw',handler=function()end};r.common(r.spec);assert(not pcall(r.api.Install)and r.adds==0)end)
test('normalized entity filter collision refused',function()local r=fresh();r.spec.owner.StateInputRegistration=nil;r.spec.bags[1]={key='entity',filter='',handler=function()end};r.common(r.spec);assert(not pcall(r.api.Install))end)
test('duplicate key names refused',function()local r=fresh();r.spec.owner.StateInputRegistration=nil;r.spec.keys[2]=r.spec.keys[1];r.common(r.spec);assert(not pcall(r.api.Install)and r.adds==0)end)
test('noncanonical alias refused rather than renamed',function()local r=fresh();r.spec.owner.StateInputRegistration=nil;r.spec.keys[1].name=' Owned ';r.common(r.spec);assert(not pcall(r.api.Install)and r.adds==0)end)
test('partial bag failure clears known cookies only',function()local r=fresh();r.failAdd=2;assert(not pcall(r.api.Install)and next(r.bags)==nil and #r.removed==1 and not r.api.Install())end)
test('partial PR registration recovered by exact input identity',function()local r=fresh();r.commandFailure='+owned';assert(not pcall(r.api.Install)and r.commands['+owned']and next(r.provider.list)==nil and next(r.bags)==nil);r.key('owned');assert(#r.calls==0)end)
test('retry only failed owned cleanup',function()local r=fresh();r.api.Install();r.failRemove=2;local ok,err=r.api.Dispose();assert(not ok and err and #r.removed==1 and r.bags[2]);r.failRemove=nil;assert(r.api.Dispose()and #r.removed==2 and not r.api.Dispose())end)
test('failed key cleanup remains revoked for retry',function()local r=fresh();r.api.Install();r.failKeyRemove='owned';assert(not r.api.Dispose());r.key('owned');assert(#r.calls==0);r.failKeyRemove=nil;assert(r.api.Dispose()and next(r.provider.list)==nil)end)
test('replacement prevents dispatch without global source changes',function()local r=fresh();r.api.Install();r.replaced=true;r.emit('raw','global',true);r.key('owned');assert(#r.calls==0)end)
test('awaited entity rechecks private phase after dispose',function()local r=fresh();r.ports.resolveEntity=function()coroutine.yield('entity');return 20,4 end;r.spec.owner.StateInputRegistration=nil;r.common(r.spec);r.api.Install();local co=coroutine.create(function()r.emit('entity','entity:4',true)end);assert(coroutine.resume(co));r.api.Dispose();assert(coroutine.resume(co)and #r.calls==0)end)
test('already entered raw body may finish after revoke',function()local r=fresh();r.spec.owner.StateInputRegistration=nil;r.spec.bags[1].handler=function()coroutine.yield('body');r.finished=true end;r.common(r.spec);r.api.Install();local co=coroutine.create(function()r.emit('raw','global',true)end);assert(coroutine.resume(co));r.api.Dispose();assert(coroutine.resume(co)and r.finished)end)
test('preflight replacement no publication',function()local r=fresh();r.preflight=function()r.replaced=true end;assert(not pcall(r.api.Install)and r.adds==0)end)
test('replacement during add cleans returned cookie',function()local r=fresh();r.onAdd=function()r.replaced=true end;assert(not pcall(r.api.Install)and next(r.bags)==nil)end)
test('actual PR combo/secondary mapping retained',function()
    local r=fresh();r.spec.owner.StateInputRegistration=nil;r.spec.keys[1].keys='CTRL+H';r.spec.keys[1].secondaryKey='J';r.common(r.spec);r.api.Install()
    local b=r.provider.get('owned');assert(b.combos[1].keys[1]=='LCONTROL'and b.combos[1].keys[2]=='H'and b.combos[2].keys[1]=='J'and #r.mappings==3)
    r.commands[r.mappings[1][1]]();assert(#r.calls==0);r.commands[r.mappings[2][1]]();assert(#r.calls==1)
    r.api.Dispose();r.commands[r.mappings[3][1]]();assert(#r.calls==1)
end)
test('ports snapshot cannot redirect cleanup or resolver',function()
    local r=fresh();r.api.Install();r.ports.removeBag=function()error('mutated port')end;r.ports.resolveEntity=function()error('mutated resolver')end
    r.emit('entity','entity:6',true);assert(r.calls[1][1]==20 and r.api.Dispose())
end)
test('reentrant stop during bag publication cleans returned cookie',function()
    local r=fresh();r.onAdd=function()r.api.Dispose()end
    assert(not pcall(r.api.Install)and next(r.bags)==nil and #r.removed==1 and not r.api.Install())
end)
test('reentrant stop during key publication cannot reactivate',function()
    local r=fresh();r.commandHook=function(name)if name=='+owned'then r.api.Dispose()end end
    assert(not pcall(r.api.Install)and next(r.bags)==nil and r.provider.get('owned')==nil)
    r.key('owned');assert(#r.calls==0 and not r.api.Install())
end)
test('reentrant removal never cleans the same cookie twice',function()
    local r=fresh();r.api.Install();local reentries=0
    r.removeHook=function()reentries=reentries+1;assert(not r.api.Dispose())end
    assert(r.api.Dispose()and reentries==2 and #r.removed==2)
end)
test('reentrant stop during preparation cannot publish',function()
    local r=fresh();r.spec.owner.StateInputRegistration=nil;r.spec.prepare=function()r.api.Dispose();return{}end;r.common(r.spec)
    assert(not pcall(r.api.Install)and r.adds==0 and next(r.commands)==nil)
end)
print('PASS lot54 state/input ownership: '..checks..' checks; real PR provider, private revocation, exact cookies/objects, no real platform')
