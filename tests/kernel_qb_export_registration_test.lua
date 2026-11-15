local T=dofile('tests/kernel_qb_export_registration_harness.lua');local H=T.H;local n=0
for _,side in ipairs({'client','server'})do
    local old,new=T.new(side,true),T.new(side)
    assert(new.bus.active()==0 and next(new.surface.exports)==nil,'constructor must not publish')
    new.install();local count=0
    for name in pairs(old.bridge.api.Exports)do
        local a,ca=old.lookup(name);local b,cb=new.lookup(name)
        assert(type(a)=='function'and type(b)=='function'and ca==1 and cb==1,name)
        count=count+1
    end
    assert(count==(side=='client'and 5 or 14))
    assert(next(new.bus.marks)==nil,'export lookup must stay local')
    local a=old.lookup('GetCoreObject');local b=new.lookup('GetCoreObject')
    assert(a()==old.bridge.object and b()==new.bridge.object)
    assert(a({'Functions'})==old.bridge.object and b({'Functions'})==new.bridge.object);n=n+1
    -- Exercise every callback with its real signatures, not only name presence.
    if side=='client'then
        old.bridge.trace={};new.bridge.trace={}
        for _,r in ipairs({old,new})do
            r.lookup('DrawText')('Text','left');r.lookup('ChangeText')('Changed','top')
            r.lookup('KeyPressed')();r.bridge.runTask();r.lookup('HideText')()
        end
        H.same(old.bridge.trace,new.bridge.trace);n=n+4
    else
        for _,case in ipairs({{'AddItem',false,{}},{'UpdateItem',false,{}},{'RemoveItem',false},{'AddItems',{}},
            {'AddJob','newjob',{}},{'AddJobs',{newjobs={}}},{'UpdateJob','taxi',{}},{'RemoveJob','taxi'},
            {'AddGang','newgang',{}},{'AddGangs',{newgangs={}}},{'UpdateGang','ballas',{}},{'RemoveGang','ballas'},
            {'SetMethod','injected',function()return'new'end}})do
            local a,b=old.lookup(case[1]),new.lookup(case[1]);old.bridge.trace={};new.bridge.trace={}
            H.same(old.bridge.capture(a,table.unpack(case,2)),new.bridge.capture(b,table.unpack(case,2)),case[1])
            H.same(old.bridge.trace,new.bridge.trace);n=n+1
        end
        assert(new.surface.exports.SetField);new.surface.exports.SetField('field93',{value=1})
        assert(new.bridge.state.field93.value==1);n=n+1
    end
    local retained=new.lookup('GetCoreObject')
    assert(new.api.Dispose());assert(new.bus.active()==0 and retained()==nil and new.api.Progress().complete)
    assert(new.bridge.api.IsCurrent(),'disposing exports must not close bridge/core')
    assert(not new.api.Install());new.bridge.api.Close()
end
print('PASS lot93 installed QB export helper/bridges:'..n..' comparisons;all14 server/5 client callbacks,local lookup/nil tuples/SetField/identity,owned revoke without core shutdown')
