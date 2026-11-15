local T=dofile('tests/kernel_qb_event_binding_harness.lua');local H=T.H;local n=0
for _,side in ipairs({'client','server'})do
    local r=T.new(side);r.prepare();assert(r.bus.active()==0)
    assert(not r.events.Install());r.installCore();local coreCount=r.bus.active();r.install()
    assert(r.bus.active()==coreCount+10 and r.events.Count==10)
    local overlaps=0;local sourceFirst=0
    for _,d in ipairs(r.events.Describe())do
        if d.coreHandlers>0 then overlaps=overlaps+1 end
        if d.sourceFirst then sourceFirst=sourceFirst+1 end
    end
    assert(overlaps==2 and sourceFirst==(side=='server'and 7 or 0))
    assert(not r.events.Install());assert(not pcall(r.factory,r.bridge.api,r.core,r.eventPorts));n=n+1
    r.bus.emit(r.jobEvent,2,'job94',{label='New'})
    assert(r.coreJobCalls==1 and r.bridge.object.Shared.Jobs.job94==r.coreJobs.job94)
    local old=r.bridge.object.Shared.Jobs;r.coreJobs={newcore={}}
    local update={label='Updated'}
    r.bus.emit(r.jobEvent,2,'fresh94',update)
    assert(r.coreJobCalls==2 and r.coreJobs.fresh94==update and old.fresh94==update and old~=r.coreJobs);n=n+1
    if side=='client'then assert(r.bus.marks[r.jobEvent]==1,'no second network marking')end
    assert(r.events.Dispose()and r.bus.active()==coreCount and r.core.State=='installed'and r.bridge.api.IsCurrent())
    assert(r.events.Progress().complete)
    r.bus.emit(r.jobEvent,2,'after94',{label='After'});assert(r.coreJobCalls==3 and old.after94==nil)
    r.core.Dispose();r.bridge.api.Close();n=n+1
end
print('PASS lot94 event reconciliation:'..n..' cases;core then10 QB handlers once per bridge,distinct group reference updates preserved,network marking reused,core/bridge not stopped')
