-- Real command providers/graph/callback engine. Public native registry/ACL/IO/time are virtual.
local R=dofile('tests/kernel_callback_registration_harness.lua')
local T={R=R,H=R.H,P=R.P,env=R.env}
function T.surface(side)
    local e={side=side,exports={},commands={},trace={},timers={},events={},allowed={[2]=true},whitelist={}}
    local function record(kind,...)e.trace[#e.trace+1]={kind=kind,args=table.pack(...)}end
    local function native(name,fn,restricted)
        e.published=(e.published or 0)+1
        if e.failAt==e.published then error('virtual native registration failure',0)end
        assert(e.commands[name:lower()]==nil,'native command overwrite')
        e.commands[name:lower()]={handler=fn,restricted=restricted};record('native-command',name,restricted)
        if e.onPublish then e.onPublish(fn)end
    end
    local env=T.H.environment({PRAce=false,source=0,
        RegisterCommand=native,SetTimeout=function(ms,fn)e.timers[#e.timers+1]={ms=ms,fn=fn}end,
        AddEventHandler=function(name,fn)e.events[name]=fn;return #e.trace end,
        DoesPlayerExist=function(src)return tonumber(src)and tonumber(src)>0 end,
        GetPlayers=function()return{'1','2'}end,IsPrincipalAceAllowed=function()return false end,
        IsPlayerAceAllowed=function(src)return e.allowed[tonumber(src)]==true end,
        ExecuteCommand=function(...)record('execute',...)end,
        TriggerClientEvent=function(...)record('client',...)end,TriggerEvent=function(...)record('event',...)end,
        GetPlayerServerId=function()return 2 end,PlayerId=function()return 0 end,
        print=function(...)record('print',...)end,
        Bridge={debug={warn=function(...)record('warn',...)end},ace={
            isPlayerAceAllowed=function(src)return e.allowed[tonumber(src)]==true end,
            isAdminWhitelisted=function(src)return e.whitelist[src]==true end,
            isWhitelisted=function()return false end,hasFrameworkAccess=function()error('forbidden framework cycle')end,
            ensureAce=function(...)record('ace',...)end}}})
    e.ports={available=function(kind,name)
        if kind=='export'then return e.exports[name]==nil end;return e.commands[name:lower()]==nil
    end,publishExport=function(name,fn)
        e.published=(e.published or 0)+1
        if e.failAt==e.published then error('virtual export publication failure',0)end
        assert(e.exports[name]==nil,'export overwrite');e.exports[name]=fn;record('export',name)
        if e.onPublish then e.onPublish(fn)end
    end,nativeCommand=native,
        prCommand=function(...)assert(e.pr,'explicit PR provider opening required');return e.pr(...)end,
        oxCommand=function(...)assert(e.ox,'explicit ox provider opening required');return e.ox(...)end}
    function e.Open()
        e.pr=T.H.load('../pr_bridge/bridge/addCommand/'..side..'.lua',env)
        e.ox=T.H.load('../pr_bridge/bridge/compat/ox_lib/ox_command.lua',env)(e.pr)
    end
    function e.run(name,source,args,raw)
        local command=assert(e.commands[name:lower()],'unregistered command '..name)
        if command.restricted and source~=0 and not e.allowed[source]then record('native-denied',name,source);return end
        return command.handler(source,args or{},raw or name)
    end
    return e
end
function T.new()
    local r=R.new();r.surfaces={server=T.surface('server'),client=T.surface('client')}
    -- Correct explicit mock-driver result shape for Storage.doesTableExist; no real schema query.
    local single=r.server.central.db.single.await
    r.server.central.db.single.await=function(sql,params)
        local value=single(sql,params)
        if sql:find('information_schema.TABLES',1,true)then return {['COUNT(*)']=1}end
        return value
    end
    r.surfaces.server.ports.rpc=r.transport.server.owners.ox
    local function environment(side)
        local env=T.env();local requireModule=env.require
        env.require=function(name)
            local module=requireModule(name)
            if name=='kernel.shared.public_registration'then return function(spec,ports)
                r[side..'Entries'],r[side..'Callbacks']=spec.entries,spec.callbacks
                return module(spec,ports)
            end end
            return module
        end
        return env
    end
    r.publicServerFactory=T.H.load('kernel/server/public_registration.lua',environment('server'))
    r.publicClientFactory=T.H.load('kernel/client/public_registration.lua',environment('client'))
    function r.preparePublic()
        r.publicServer=r.publicServerFactory(r.serverGraph,r.surfaces.server.ports)
        r.publicClient=r.publicClientFactory(r.clientGraph,r.surfaces.client.ports)
        return r.publicServer,r.publicClient
    end
    function r.installPublic()
        r.surfaces.server.Open();r.surfaces.client.Open()
        assert(r.publicServer.Install());assert(r.publicClient.Install())
    end
    return r
end
function T.callbacks(graph)
    local names,seen={},{}
    local function visit(value)
        if type(value)~='table'or seen[value]then return end;seen[value]=true
        for key,d in pairs(value.Callbacks or{})do
            if type(key)=='string'and type(d)=='function'then names[key]=d
            elseif type(d)=='table'and type(d.name)=='string'and type(d.handler)=='function'then
                assert(names[d.name]==nil or names[d.name]==d.handler,'different callback owners '..d.name);names[d.name]=d.handler
            end
        end
        for key,child in pairs(value)do if type(child)=='table'and key~='Config'and key~='Base'and key~='State'then visit(child)end end
    end
    visit(graph);return names
end
return T
