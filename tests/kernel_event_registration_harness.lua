-- Actual factories; event bus, origin, native/IO/providers are test doubles, never Cfx.
local T=dofile('tests/kernel_client_domains_harness.lua')
local R={T=T,H=T.H,env=T.A.E.env}
function R.bus()
    local b={records={},trace={},marks={},origin=0,nextId=0,removals={}}
    b.ports={source=function()return b.origin end}
    function b.ports.markNetwork(name)
        b.trace[#b.trace+1]={'network',name};b.marks[name]=(b.marks[name]or 0)+1
        if b.markError then error('virtual network mark failed')end
    end
    function b.ports.listen(name,fn)
        b.nextId=b.nextId+1;b.trace[#b.trace+1]={'listen',name}
        if b.failAt==b.nextId then error('virtual listener failure')end
        local token={id=b.nextId};b.records[token]={name=name,handler=fn,active=true}
        if b.onListen then b.onListen(token,fn)end
        return token
    end
    function b.ports.remove(token)
        b.trace[#b.trace+1]={'remove',token.id};b.removals[#b.removals+1]=token.id
        if b.onRemove then b.onRemove(token)end
        if b.failRemove==token.id then return false end
        assert(b.records[token]and b.records[token].active,'remove only own active token');b.records[token].active=false
    end
    function b.emit(name,origin,...)
        local old=b.origin;b.origin=origin
        local ordered={};for token,record in pairs(b.records)do if record.active and record.name==name then ordered[#ordered+1]={token,record}end end
        table.sort(ordered,function(a,c)return a[1].id<c[1].id end)
        for _,v in ipairs(ordered)do local ok,e=pcall(v[2].handler,...);if not ok then b.origin=old;error(e,0)end end
        b.origin=old;return #ordered
    end
    function b.active()local n=0;for _,r in pairs(b.records)do if r.active then n=n+1 end end;return n end
    return b
end
function R.new()
    local r=T.new();r.serverBus,r.clientBus=R.bus(),R.bus()
    local sb,cb=r.serverBus,r.clientBus
    -- Explicit test-only ports set BEFORE server construction. Old QBX bodies get source as an argument.
    for _,v in pairs(r.server.ports.domains)do
        if v.native then
            if v.native.source then v.native.source=function()return sb.origin end end
            if v.native.getSource then v.native.getSource=function()return sb.origin end end
        end
    end
    local p=r.server.central.ports.session.player.platform
    p.emitServer=function(name,...)return sb.emit(name,0,...)end
    p.getInvokingResource=function()return r.serverCaller end
    r.clientGraph=r.mount();r.serverGraph=r.server.mount()
    local function environment(side)
        local env=R.env();local loadModule=env.require
        env.require=function(name)
            local module=loadModule(name)
            if name=='kernel.shared.event_registration'then return function(spec,ports)
                r[side..'Entries']=spec.entries;return module(spec,ports)
            end end
            return module
        end
        return env
    end
    r.serverFactory=R.H.load('kernel/server/event_registration.lua',environment('server'))
    r.clientFactory=R.H.load('kernel/client/event_registration.lua',environment('client'))
    function r.prepare()
        r.serverRegistration=r.serverFactory(r.serverGraph,sb.ports)
        r.clientRegistration=r.clientFactory(r.clientGraph,cb.ports)
        return r.serverRegistration,r.clientRegistration
    end
    function r.connectClientEmissions()
        local seen={}
        for _,d in ipairs(r.clientRegistration.Describe())do if not seen[d.name]then
            seen[d.name]=true;r.central.producer.listen(d.name,function(...)return cb.emit(d.name,0,...)end,false)
        end end
    end
    return r
end
function R.coverage(root,entries)
    local visited,expected,actual={},{},{}
    local function add(set,name,fn)
        set[name]=set[name]or{};set[name][fn]=true
    end
    local function visit(value)
        if type(value)~='table'or visited[value]then return end;visited[value]=true
        for _,field in ipairs({'Events','NetEvents','Listeners'})do
            if type(value[field])=='table'then for _,d in ipairs(value[field])do
                if type(d)=='table'and type(d.name)=='string'and type(d.handler)=='function'then add(expected,d.name,d.handler)end
            end end
        end
        for _,v in pairs(value)do visit(v)end
    end
    visit(root)
    for _,d in ipairs(entries)do add(actual,d.name,d.handler)end
    local count=0
    for name,handlers in pairs(expected)do for fn in pairs(handlers)do assert(actual[name]and actual[name][fn],'omitted reachable descriptor '..name);count=count+1 end end
    for name,handlers in pairs(actual)do for fn in pairs(handlers)do assert(expected[name]and expected[name][fn],'foreign event descriptor '..name)end end
    return count
end
return R
