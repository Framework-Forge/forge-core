local P=dofile('tests/kernel_inventory_provider_harness.lua');local H=P.H
local r=P.new();local before=#r.items.events;r.mount();assert(#r.items.events==before and #r.refs==0,'provider construction inert')
assert(r.api.SetItemDefinition('burger',{})==nil and #r.items.events==before,'prepared calls inert');assert(r.api.Open())
local direct=P.new()
local cases={
 {'SetItemDefinition','Burger meal',{label='Meal',weight='100',client={status={hunger=25},prop={model='burger'}}},true},
 {'DisableItemDefinition','Burger meal',{label='Blocked'}},
 {'HasItemDefinition','Burger meal'},
 {'SetItemDefinition','Burger meal',{label='Unblocked'},true},
 {'RemoveItemDefinition','Burger meal'},
 {'SetWeaponItem','pistol',{label='Pistol',ammotype='AMMO_PISTOL',access={police=1}},true},
 {'HasWeaponItem','pistol'},
 {'DisableWeaponItem','pistol',{label='Disabled weapon'}},
 {'HasWeaponItem','pistol'},
 {'SetWeaponItem','pistol',{label='Restored',ammotype='none'},true},
 {'RemoveWeaponItem','pistol'},
}
for _,c in ipairs(cases)do local name=c[1]
    local a=table.pack(r.api[name](table.unpack(c,2,#c)));local b=table.pack(direct.proxy[name](direct.proxy,table.unpack(c,2,#c)))
    H.same(a,b,'installed custom OX exact returns '..name)
    H.same(r.items.definitions,direct.items.definitions,'installed custom OX definitions '..name)
    H.same(r.items.events,direct.items.events,'installed custom OX publications '..name)
end
assert(r.api.Close());before=#r.items.events;assert(r.api.SetItemDefinition('burger',{})==nil and #r.items.events==before)
local q=P.new();q.proxy.HasWeaponItem=function(_,...)assert(select('#',...)==3);return true,nil,false,'WEAPON_X',nil end
q.mount();assert(q.api.Open());local result=table.pack(q.api.HasWeaponItem('x',nil,3));assert(result.n==5 and result[3]==false and result[4]=='WEAPON_X','nil tuple preserved')
local e=P.new();e.proxy.SetItemDefinition=function()error('custom export failure')end;e.mount();assert(e.api.Open());assert(not pcall(e.api.SetItemDefinition,'burger',{}));assert(e.api.Progress().entered==0)
for _,kind in ipairs({'executing','ready','current'})do local s=P.new();s.mount();if kind=='executing'then s.executing='pr_bridge'else s[kind]=false end
    assert(not s.api.Open()and #s.refs==0,'invalid provider refuses before publication '..kind)
end
local y=P.new();y.proxy.SetItemDefinition=function()coroutine.yield();return true end;y.mount();assert(y.api.Open())
local co=coroutine.create(function()assert(y.api.SetItemDefinition('burger',{}))end);assert(coroutine.resume(co));y.api.Close()
assert(y.api.Progress().pending==1 and not y.api.Progress().complete,'awaited definition still pending after Close');assert(coroutine.resume(co));assert(y.api.Progress().complete)
print('PASS lot62 PR custom inventory:11 installed OX parity cases, exact nil tuples/errors,3 readiness refusals, inert constructor and pending definition await;virtual effects only')
