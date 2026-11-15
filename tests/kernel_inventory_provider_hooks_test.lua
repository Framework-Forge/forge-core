local P=dofile('tests/kernel_inventory_provider_harness.lua');local r=P.new();r.mount();assert(r.api.Open())
local calls,posts=0,0;r.onPost=function()posts=posts+1 end
local foreign=r.foreign('buyItem',function()calls=calls+100 end)
local id=r.api.RegisterHook('buyItem',function(payload)calls=calls+1;return payload.allow end,{itemFilter={burger=true}})
assert(id=='forge-core:buyItem:2','custom string ID and Forge owner preserved')
local result=r.trigger('buyItem',{itemName='burger',allow=false});assert(not result.success and calls==101,'installed veto preserved')
local removed=table.pack(r.api.RemoveHooks(id));assert(removed.n==0,'installed empty removal tuple is success')
local n=#r.removals;r.api.RemoveHooks(id);assert(#r.removals==n,'completed ID removal not repeated')
assert(not r.api.RemoveHooks(foreign)and not r.api.RemoveHooks(nil),'foreign and all-owner removal refused')
assert(r.api.Close()and r.api.Progress().complete);r.flush();assert(posts==2,'post events remain installed50ms result contract')
assert(#r.trigger('buyItem',{itemName='burger'})==1,'foreign resource hook survives cleanup')
assert(r.refs[2]({allow=false})==nil,'revoked hook preserves nil, R01 unchanged')
local late=P.new();late.mount();assert(late.api.Open());late.afterRegister=function()late.api.Close()end
local lateId=late.api.RegisterHook('x',function()error('retired')end);assert(lateId and late.api.Progress().complete and #late.trigger('x',{})==0,'late publication retired')
for _,kind in ipairs({'removeFalse','removeError'})do local f=P.new();f.mount();assert(f.api.Open());f.api.RegisterHook('x',function()return false end);f[kind]=true
    assert(not f.api.Close()and f.api.Progress().residual==1 and f.api.Progress().removeFailed==1,'removal failure visible '..kind)
    assert(f.refs[1]({})==nil);f[kind]=false;assert(f.api.Close()and f.api.Progress().complete,'explicit cleanup retry succeeds')
end
local bad=P.new();bad.proxy.registerHook=function()error('unknown partial publication')end;bad.mount();assert(bad.api.Open())
assert(not pcall(bad.api.RegisterHook,'x',function()end));assert(not bad.api.Close()and bad.api.Progress().unknown==1,'partial publication not declared clean')
local busy=P.new();busy.mount();assert(busy.api.Open());busy.api.RegisterHook('x',function()coroutine.yield();return false end)
local co=coroutine.create(function()busy.refs[1]({})end);assert(coroutine.resume(co));busy.api.Close()
assert(not busy.api.Progress().complete and busy.api.Progress().pending==1,'entered callback not drained by physical removal');assert(coroutine.resume(co));assert(busy.api.Progress().complete)
-- Characterize installed OX limitation, not a promised generation-identity fix.
local collision=P.new();collision.mount();assert(collision.api.Open());local before=collision.foreign('x',function()end,'forge-core')
local owned=collision.api.RegisterHook('x',function()end);collision.hooks.removeHooks(before)
local alias=collision.foreign('x',function()end,'forge-core');assert(alias==owned,'installed OX same-owner ID reuse reproduced')
collision.api.RemoveHooks(owned);assert(#collision.trigger('x',{})==0 and not collision.api.UniqueHookIdentity,'same-string alias cannot be distinguished by installed removeHooks')
print('PASS lot62 installed OX hooks:Forge owner/string ID/filter/veto/post50ms, scoped cleanup/foreign refusal/nil return, late/error/await races and characterized same-owner ID collision;R01 unchanged')
