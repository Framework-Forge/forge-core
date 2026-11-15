-- Inactive logical leases over the installed World.onChange contract. See NOTICE-55.md.
local function leaseFor(handler,guard)
    local lease={handler=handler,guard=guard,active=false}
    local function dispatch(...)
        if not lease.active then return end
        local fn,check=lease.handler,lease.guard
        if check()and lease.active and lease.handler==fn and lease.guard==check then return fn(...)end
    end
    return lease,dispatch
end
return function(spec)
    assert(type(spec)=='table'and type(spec.owner)=='table','explicit subscription owner required')
    local owner,current,subscribe=spec.owner,spec.isCurrent,spec.subscribe
    assert(type(current)=='function'and type(subscribe)=='function','explicit subscription ports required')
    assert(current(),'canonical subscription graph required')
    assert(owner.WorldSubscriptionRegistration==nil,'world subscriptions already owned')
    local entries,seen={},{}
    for _,d in ipairs(assert(spec.entries))do
        assert(type(d.key)=='string'and d.key~=''and type(d.handler)=='function'and type(d.owner)=='string','invalid subscription descriptor')
        seen[d.key]=seen[d.key]or{}
        assert(not seen[d.key][d.handler],'duplicate subscription key/handler: '..d.key)
        seen[d.key][d.handler]=true
        entries[#entries+1]={key=d.key,handler=d.handler,owner=d.owner}
    end
    local phase='prepared-inactive'
    local api={State=phase,PhysicalUnregistration=false}
    local leases={}
    owner.WorldSubscriptionRegistration=api
    local function setPhase(value)phase=value;api.State=value end
    local function canonical()return owner.WorldSubscriptionRegistration==api and current()end
    local function active()return canonical()and phase=='installed'end
    function api.Describe()
        local out={};for i,d in ipairs(entries)do out[i]={key=d.key,handler=d.handler,owner=d.owner}end;return out
    end
    function api.Dispose()
        if phase=='disposed'then return false end
        setPhase('revoking')
        for _,lease in ipairs(leases)do
            lease.active=false;lease.handler=nil;lease.guard=nil
        end
        -- World.onChange has no removal handle; leave only inert shells in that registry.
        setPhase('disposed');return true
    end
    function api.Install()
        if phase~='prepared-inactive'then return false end
        setPhase('installing')
        local ok,problem=pcall(function()
            for _,d in ipairs(entries)do
                assert(canonical()and phase=='installing','subscription graph revoked/replaced during installation')
                local lease,handler=leaseFor(d.handler,active)
                leases[#leases+1]=lease -- Own before publication, including a throwing or reentrant provider.
                subscribe(d.key,handler)
                assert(canonical()and phase=='installing','subscription graph revoked/replaced during publication')
            end
            assert(canonical()and phase=='installing','subscription graph revoked/replaced before activation')
            for _,lease in ipairs(leases)do lease.active=true end
            setPhase('installed')
        end)
        if not ok then
            api.Dispose()
            error(problem,0)
        end
        return true
    end
    return api
end
