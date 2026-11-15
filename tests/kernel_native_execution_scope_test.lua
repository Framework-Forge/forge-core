local T=dofile('tests/kernel_native_execution_harness.lua');local count=0
local function case(fn)local r=T.new();fn(r);if r.tasks then r.tasks.Close()end;if r.api then r.api.Close()end;count=count+1 end
case(function(r)r.name='qbx_core';assert(not pcall(r.allocate))end)
case(function(r)r.ports.side='client';assert(not pcall(r.allocate))end)
case(function(r)r.allocate();r.current=false;assert(not pcall(r.api.Native.GetGameTimer))end)
case(function(r)r.allocate();r.native.GetConvar=function()return'qbx'end;assert(not r.api.IsCurrent()and not pcall(r.api.Native.GetGameTimer))end)
case(function(r)r.allocate();assert(not pcall(r.api.Bind,{'AddEventHandler'}));assert(#r.clock.queue==0)end)
case(function(r)r.allocate();local effect=0;r.api.Native.SetTimeout(1,function()effect=1 end);r.api.Close();r.clock.advance(1);assert(effect==0)end)
case(function(r)r.allocate();local effect=0;r.api.Native.CreateThread(function()r.clock.native.Wait(2);effect=1 end);r.clock.advance(0);r.api.Close();assert(not r.api.Progress().complete);r.clock.advance(2);assert(effect==1 and r.api.Progress().complete)end)
case(function(r)r.native.GetResourceState=function()coroutine.yield('accepted129');return nil,false,7 end;r.allocate();local p=r.api.Bind({'GetResourceState'});local co=coroutine.create(function()return p.GetResourceState('x')end);local ok,label=coroutine.resume(co);assert(ok and label=='accepted129');r.api.Close();assert(r.api.Progress().pending==1);local out=table.pack(coroutine.resume(co));assert(out.n==4 and out[1]and out[2]==nil and out[3]==false and out[4]==7 and r.api.Progress().complete)end)
assert(count==8);print('PASS lot129 eight resource/side/current/ref/raw-event/queued/accepted/tuple cases;events borrowed and retained effects not reversed')
