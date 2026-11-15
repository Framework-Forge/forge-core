local T=dofile('tests/kernel_qb_export_registration_harness.lua');local H=T.H;local n=0
for _,original in ipairs({false,true})do
    local r=T.new('client',original);if not original then r.install()end
    local values=table.pack(r.bus.emit('__cfx_export_qb-core_GetCoreObject',0,function(fn)
        assert(type(fn)=='function'and fn()==r.bridge.object)
        return 'ignored',nil,7
    end))
    assert(values.n==1 and values[1]==1);n=n+1
    assert(not pcall(r.bus.emit,'__cfx_export_qb-core_GetCoreObject',0,false));n=n+1
    if not original then
        assert(r.api.Progress().pending==0)
        local before=r.bus.active()
        local foreign=r.bus.ports.listen('foreign-event',function()end)
        r.api.Dispose();assert(r.bus.active()==1 and r.bus.records[foreign].active and before==5);n=n+1
    end
    r.bridge.api.Close()
end
print('PASS lot93 lookup protocol:'..n..' cases;whole installed helper local setCB ignores callback return,errors preserved,foreign listener untouched')
