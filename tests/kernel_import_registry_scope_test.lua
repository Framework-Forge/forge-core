local T=dofile('tests/kernel_import_registry_harness.lua');local r=T.new();r.mount()
local warn=r.ports.utils.library.print.warn;r.ports.utils.library.print.warn=function(...)coroutine.yield();return warn(...)end
local co=coroutine.create(function()local ok=pcall(r.api.Require,'modules.utils');assert(not ok)end)
assert(coroutine.resume(co));assert(r.api.Progress().pending==1);r.api.Close();assert(not r.api.Progress().complete)
assert(coroutine.resume(co));assert(coroutine.resume(co));assert(r.api.Progress().complete,'pending import unwinds without reopening namespace')
local stale=T.new();stale.mount();stale.api.Require('modules.lib');local fn=stale.target.qbx.string.trim
stale.current=false;assert(not pcall(fn,'x')and not pcall(stale.api.Require,'shared.locale'))
local failure=T.new();failure.mount();failure.ports.utils.library.print.warn=function()error('warning transport failed',0)end
assert(not pcall(failure.api.Require,'modules.utils')and failure.target.GetPlate==nil and failure.target.qbx.foreign,'warning failure precedes namespace mutation')
local target={};stale.current=true;stale.api.OwnField(target,'x',1);target.x=2;stale.api.Close();assert(target.x==2)
print('PASS lot76 scope:pending require/late warning error unwinds,closed/stale calls,warning-prefix failure,identity-owned field restoration;no ambient/core writes')
