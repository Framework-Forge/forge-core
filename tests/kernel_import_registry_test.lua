local T=dofile('tests/kernel_import_registry_harness.lua');local H=T.H
for _,side in ipairs({'client','server'})do
    local r=T.new(side);local target=r.target;local old=target.qbx;local sm,mm=target.string,target.math;r.mount()
    assert(target.qbx==old and #r.legacy.trace==0,'76 constructor does not import or register')
    assert(r.api.Require('modules.lib')==true and target.qbx~=old);local lib=target.qbx
    assert(lib.string.trim(' x ')=='x'and r.api.Require('@qbx_core/modules/lib.lua')and target.qbx==lib,'relative/legacy aliases share cache')
    assert(r.api.Require('modules.utils')and target.qbx==lib and sm==target.string and mm==target.math)
    assert(target.GetPlate and target.math.round(12.24,1)==12.2 and target.string.firstToUpper('test')=='Test')
    local n=#r.legacy.trace;assert(r.api.Require('modules/utils.lua')and #r.legacy.trace==n,'cached utils never reruns warnings')
    assert(r.api.Require('shared.locale'));local instance=target.Locale:new({phrases={x='Hi %{name}'}})
    assert(instance:t('x',{name='A'})=='Hi A'and not r.api.Has('modules.playerdata'))
    local fn=lib.string.trim;r.api.Close();assert(target.qbx==old and target.GetPlate==nil and not pcall(fn,'x'))
    assert(not pcall(instance.t,instance,'x')and r.api.Progress().complete)
end
local implicit=T.new();implicit.mount();local original=implicit.target.qbx
implicit.api.Require('modules.utils');assert(implicit.target.qbx==original)
assert(implicit.api.Require('modules.lib')and implicit.target.qbx==original,'installed temporary import cache quirk retained')
local a,b=T.new(),T.new();a.mount();b.mount();a.api.Require('modules.lib');b.api.Require('modules.lib')
assert(a.target.qbx~=b.target.qbx,'each consumer has its own helper closures/cache')
a.target.qbx={foreignAfter=true};a.api.Close();assert(a.target.qbx.foreignAfter and b.target.qbx.string.trim(' y ')=='y','foreign replacement and other consumer preserved')
assert(not pcall(b.api.Require,'@qb-core/not-an-installed-module.lua'))
print('PASS lot76 registry:client/server original aliases,resource-local namespaces,utils warnings/cache quirk/string-math identity,QB Locale class,foreign replacements and close;virtual only')
