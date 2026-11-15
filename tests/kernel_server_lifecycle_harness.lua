-- Actual48/51-53/57-60; virtual platform, schema, RPC transport, inventory and JSON only.
local W=dofile('tests/kernel_server_worker_harness.lua')
local C=dofile('tests/kernel_callback_registration_harness.lua')
local P=dofile('tests/kernel_public_registration_harness.lua')
local T={W=W,H=W.H,C=C,P=P}
function T.new()
    local r=W.new();local f=r.fixture
    r.bus,r.marked,r.schema={},{},{}
    r.events={listen=function(name,fn)
        local t={name=name,handler=fn};r.bus[#r.bus+1]=t;if r.onListen then r.onListen(t)end;return t
    end,remove=function(t)
        if r.failRemove==t then return false end
        assert(not t.removed,'only live owned listener removed');t.removed=true;return true
    end,markNetwork=function(name)r.marked[name]=true end,source=function()return r.source or 2 end}
    r.wire=C.wire();r.surface=P.surface('server');r.surface.ports.rpc=r.wire.server.owners.ox
    f.central.library.callback.register=r.wire.server.owners.native.CaptureRegister
    r.wire.server.owners.securityLibrary=f.central.library
    local query=f.central.db.query.await
    local function virtualQuery(sql,params)
        if sql:find('CREATE TABLE',1,true)or sql:find('ALTER TABLE',1,true)then r.schema[#r.schema+1]=sql;return{}end
        return query(sql,params)
    end
    f.central.db.query=setmetatable({await=virtualQuery},{__call=function(_,...)return virtualQuery(...)end})
    local schema=f.ports.central.lifecycle.querySchema
    f.ports.central.lifecycle.querySchema=function(sql)r.schema[#r.schema+1]=sql;return schema(sql)end
    r.lifePorts={resource='forge-core',events=r.events,worker=r.ports,callbacks=r.wire.server.owners,public=r.surface.ports}
    local env=W.D.R.env();env.print=function(...)f.central.record('print',...)end
    r.lifeFactory=T.H.load('kernel/server/lifecycle_context.lua',env)
    function r.prepareLifecycle()r.api=r.lifeFactory(f.base,r.lifePorts);r.graph=r.api.Graph;return r.api end
    function r.install()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    function r.emit(name,...)
        local list={};for _,t in ipairs(r.bus)do list[#list+1]=t end
        for _,t in ipairs(list)do if not t.removed and t.name==name then t.handler(...)end end
    end
    function r.active(name)local n=0;for _,t in ipairs(r.bus)do if not t.removed and(not name or t.name==name)then n=n+1 end end;return n end
    return r
end
return T
