local T=dofile('tests/kernel_native_execution_harness.lua')
for _,side in ipairs({'server','client'})do local r=T.new(side);r.allocate();local n=r.api.Native
    assert(#r.clock.queue==0 and #r.calls==0 and r.api.Events==r.events and n.wait==n.Wait and n.spawn==n.CreateThread)
    assert(n.GetConvar('inventory:framework','qbx')=='forge'and n.GetConvarInt('x',31)==31)
    assert(r.api.GetSource()==1);r.source=28;assert(r.api.GetSource()==28)
    local selected=r.api.Bind({'GetResourceState'});local result=table.pack(selected.GetResourceState('ox_inventory'));assert(result.n==3 and result[1]=='started'and result[2]==nil and result[3]==2)
    local managed=r.manage();local effect=0
    r.tasks.Launch(managed,function()effect=effect+1;managed.Wait(9);effect=effect+1 end)
    managed.SetTimeout(12,function()effect=effect+100 end);r.clock.advance(0);assert(effect==1)
    r.tasks.Close();r.api.Close();r.clock.advance(12)
    assert(effect==1 and r.tasks.Snapshot().quiescent and r.api.Progress().complete)
end
print('PASS lot129 native time/convar/source aliases and tuples both sides;installed57 owns cooperative cancellation and queue remains virtual')
