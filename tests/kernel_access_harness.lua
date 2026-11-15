-- Full installed whitelist/AFK references, actual PR persistence/DB/identifiers, all effects virtual.
local Q=dofile('tests/kernel_skill_harness.lua')
local H,P,J=Q.H,Q.P,Q.J
local A={Q=Q,H=H,P=P,J=J,env=Q.env}
function A.vector(x,y,z)
    return setmetatable({x=x,y=y,z=z},{__sub=function(a,b)return A.vector(a.x-b.x,a.y-b.y,a.z-b.z)end,
        __len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end})
end
function A.config(ported)
    if ported then return {Whitelist=H.load('kernel/config/forge_whitelist.lua',H.environment())(),Afk=H.load('kernel/config/forge_afk.lua',H.environment())(),
        AdminAce='forge-core.admin',NotifyPos='top-right'}end
    local e=H.environment({PR={}});H.load('shared/whitelist.lua',e);H.load('shared/afk.lua',e)
    e.PR.AdminAce='forge-core.admin';e.PR.NotifyPos='top-right';return e.PR
end
function A.new(ported,options)
    local r={trace={},workers={},events={},callbacks={},buckets={},drops={},source=1,now=10000,time=1792400000,
        ready=true,manage=true,aces={},records={},answers={},bans={},columns=1,legacyTables={},legacyPlayers={},offline={},
        updateResult=1,players={},coords={[1]=A.vector(0,0,0),[2]=A.vector(5,0,0),[3]=A.vector(10,0,0)},lookups={}}
    function r.record(k,...)r.trace[#r.trace+1]={kind=k,args=P.snapshot(table.pack(...))}end
    r.config=A.config(ported);r.m=J.persistence();r.library=r.m.api
    r.translate=function(key,params)r.record('translate',key,params);return key end
    r.library.debug={}
    for _,level in ipairs({'success','error','info','warn'})do r.library.debug[level]=function(...)r.record('log-'..level,...)end end
    r.library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    r.library.callback={await=function(...)r.record('client-rpc',...);if r.rpcHook then return r.rpcHook(...)end;return r.rpcResult end,
        register=function(name,fn)r.callbacks[name]=fn end}
    r.native={GetCurrentResourceName=function()return'forge-core'end,source=function()return r.source end,
        time=function()return r.time end,date=function(format)return'20/10/2026 12:00:00'end,
        GetGameTimer=function()return r.now end,GetPlayers=function()return r.online or{'1','2','3'}end,
        GetPlayerPed=function(src)return r.pedMissing and 0 or tonumber(src)end,
        GetEntityCoords=function(src)return r.coords[src]end,
        IsPlayerAceAllowed=function(src,ace)r.record('ace',src,ace);return r.aces[ace]==true end,
        DropPlayer=function(src,why)r.record('drop',src,why);r.drops[#r.drops+1]={src,why}end,
        GetPlayerName=function(src)return'Player '..src end,
        GetPlayerIdentifierByType=function(src,kind)r.record('identifier',src,kind)
            if r.identifierHook then r.identifierHook(src,kind)end
            return ({license='license:'..src,license2='license2:'..src,discord='discord:'..src,fivem='fivem:'..src,ip='127.0.0.'..src})[kind]
        end,
        CreateThread=function(fn)r.workers[#r.workers+1]=fn end,
        Wait=function(ms)r.record('wait',ms);if r.waitHook then r.waitHook(ms)end;return coroutine.yield(ms)end}
    for src=1,3 do r.players[src]={PlayerData={source=src,citizenid='C'..src,license='player-license:'..src,
        charinfo={firstname='Test',lastname=tostring(src)},metadata={}}}end
    local function lookup(src)
        r.lookups[#r.lookups+1]={'source',src}
        if r.lookupHook then return r.lookupHook(src)end
        if r.lookupError then error('fixture-lookup',0)end
        return r.players[src]
    end
    r.kernel={GetPlayer=lookup,GetPlayerByCitizenId=function(cid)
        r.lookups[#r.lookups+1]={'citizen',cid}
        for _,p in pairs(r.players)do if p.PlayerData.citizenid==cid then return p end end
        if r.citizenError then error('fixture-citizen',0)end
    end,SetPlayerBucket=function(src,bucket)r.record('bucket',src,bucket);r.buckets[src]=bucket;return r.bucketResult end}
    r.services={JobService={canManage=function(src)r.record('manage',src);return r.manage end}}
    local idsEnv=H.environment({GetPlayerIdentifierByType=r.native.GetPlayerIdentifierByType,GetPlayerIdentifiers=function()return{}end})
    r.library.identifiers=H.load('../pr_bridge/bridge/fivem/identifiers/server.lua',idsEnv)
    r.cache={}
    r.library.cache={get=function(k)return r.cache[k]end,set=function(k,v)r.cache[k]=H.copy(v)end,GetPlayer=lookup}
    H.load('../pr_bridge/bridge/cache/resources.lua',H.environment())(r.library.cache)
    function r.dbScalar(sql,params)
        r.record('scalar',sql,params)
        if r.scalarHook then local value=r.scalarHook(sql,params);if value then return table.unpack(value,1,value.n)end end
        if sql:find('information_schema.COLUMNS',1,true)then return r.columns end
        if sql:find('information_schema.TABLES',1,true)then return r.legacyTables[params[1]]and 1 or 0 end
        if sql:find('mri_qwhitelistcfg',1,true)then return r.legacyConfig end
        if sql:find('SELECT `config`',1,true)then return r.dbConfig end
        if sql:find('INNER JOIN',1,true)then
            local p=r.offline[params[1]]
            for _,row in pairs(r.records)do if row.citizen==params[1]or(p and row.license and row.license==p.license)then return row.citizen end end
            return nil
        end
        for _,row in pairs(r.records)do
            if row.citizen==params[1]then return row.citizen end
            for i=2,5 do if row.license and row.license==params[i]then return row.citizen end end
            if row.discord and row.discord==params[6]or row.fivem and row.fivem==params[7]then return row.citizen end
        end
    end
    function r.dbQuery(sql,params)
        r.record('query',sql,params)
        if r.queryHook then local value=r.queryHook(sql,params);if value then return table.unpack(value,1,value.n)end end
        if sql:find('LEFT JOIN',1,true)then return r.listRows or{}end
        if sql:find('FROM players',1,true)then
            for _,v in pairs(r.offline)do if v.citizenid==params[1]or v.license==params[2]then return {H.copy(v)}end end
            return {}
        end
        if sql:find('SELECT `answers`',1,true)then return r.answers[params[1]]and{H.copy(r.answers[params[1]])}or{}end
        return r.records[params[1]]and{H.copy(r.records[params[1]])}or{}
    end
    function r.dbExecute(sql,params)
        r.record('update',sql,params)
        if r.updateHook then r.updateHook(sql,params)end
        if r.updateError then error('fixture-update',0)end
        if not r.noApply then
            if sql:find('INSERT INTO bans',1,true)then r.bans[#r.bans+1]=H.copy(params)
            elseif sql:find('answers',1,true)and sql:find('INSERT INTO',1,true)then
                r.answers[params[1]]={answers=params[2],submitted_at=params[3]}
            elseif sql:find('INSERT IGNORE',1,true)then for _,cid in ipairs(r.legacyPlayers)do r.records[cid]=r.records[cid]or{citizen=cid}end
            elseif sql:find('ON DUPLICATE KEY',1,true)then
                r.records[params[1]]={citizen=params[1],license=params[2],discord=params[3],fivem=params[4],name=params[5],
                    whitelisted_at=params[6],added_by=params[7]}
            elseif sql:find('DELETE FROM',1,true)then r.records[params[1]]=nil
            elseif sql:find('COALESCE',1,true)then local row=r.records[params[5]]
                if row then for i,k in ipairs({'license','discord','fivem','name'})do if params[i]~=nil then row[k]=params[i]end end end
            end
        end
        return r.updateResult
    end
    local dbEnv=H.environment({ActiveBridges={database='oxmysql'},GetResourceState=function()return r.ready and'started'or'stopped'end,
        promise={new=function()return{resolve=function(self,v)self.value=v end}end},Citizen={Await=function(p)return p.value end},
        Debug=function(...)r.record('driver-error',...)end,
        exports={oxmysql={scalar=function(_,sql,params,cb)cb(r.dbScalar(sql,params))end,
            query=function(_,sql,params,cb)cb(r.dbQuery(sql,params))end,
            execute=function(_,sql,params,cb)cb(r.dbExecute(sql,params))end}}})
    r.db=H.load('../pr_bridge/bridge/database/oxmysql/server.lua',dbEnv);r.library.db=r.db
    r.webhookIntegration={request=function(...)r.record('http',...);if r.httpError then error('fixture-http',0)end;return r.httpResult end}
    r.m.seed(r.config.Whitelist.Storage.configFile,H.copy(r.config.Whitelist.Defaults))
    r.m.seed(r.config.Afk.Storage.file,H.copy(r.config.Afk.Defaults))
    if options then options(r)end
    local e=H.environment({PR=r.config,pr_lib=r.library,ForgeCore={JobService=r.services.JobService,t=r.translate},json=r.m.codec,
        os={time=r.native.time,date=r.native.date},IsDuplicityVersion=function()return true end,print=function(...)r.record('print',...)end})
    for n,fn in pairs(r.native)do if n~='source'and n~='time'and n~='date'then e[n]=fn end end
    r.env=e
    function r.event(name,...)
        e.source=r.source
        for _,entry in ipairs(r.events)do if entry.name==name then entry.handler(...)end end
    end
    e.AddEventHandler=function(name,fn)r.events[#r.events+1]={name=name,handler=fn}end
    e.RegisterNetEvent=e.AddEventHandler
    e.GetPlayerPing=function()return 50 end
    e.PerformHttpRequest=r.webhookIntegration.request
    e.exports={qbx_core={GetPlayer=function(_,...)return r.kernel.GetPlayer(...)end,
        GetPlayerByCitizenId=function(_,...)return r.kernel.GetPlayerByCitizenId(...)end,
        SetPlayerBucket=function(_,...)return r.kernel.SetPlayerBucket(...)end}}
    if ported then
        r.session=H.load('kernel/server/forge_session.lua',Q.env())({kernel=r.kernel,cache=r.library.cache,
            native={source=r.native.source,resourceName=r.native.GetCurrentResourceName}})
        r.services.Session=r.session.Session
        for _,v in ipairs(r.session.Events)do r.events[#r.events+1]=v end
        local ports={config=r.config,library=r.library,native=r.native,services=r.services,json=r.m.codec,translate=r.translate,
            kernel=r.kernel,webhookIntegration=r.webhookIntegration}
        r.whitelist=H.load('kernel/server/whitelist/service.lua',Q.env())(ports)
        r.afk=H.load('kernel/server/afk/service.lua',Q.env())(ports)
        for _,v in ipairs(r.afk.Events)do r.events[#r.events+1]=v end
    else
        H.load('shared/session.lua',e);r.services.Session=e.ForgeCore.Session
        H.load('server/whitelist/service.lua',e);H.load('server/afk/service.lua',e)
        r.whitelist={Service=e.ForgeCore.WhitelistService};r.afk={Service=e.ForgeCore.AfkService}
    end
    r.w,r.a=r.whitelist.Service,r.afk.Service
    -- Actual installed Security derives default access; prepared descriptors must preserve it.
    H.load('server/callback_security.lua',e)
    if ported then
        local wc=H.load('kernel/server/whitelist/callbacks.lua',Q.env())({config=r.config.Whitelist,service=r.w})
        local ac=H.load('kernel/server/afk/callbacks.lua',Q.env())({config=r.config.Afk,service=r.a})
        for _,list in ipairs({wc,ac})do for _,v in ipairs(list)do e.ForgeCore.Callbacks.register(v.name,v.handler,v.options)end end
    else
        H.load('server/whitelist/callbacks.lua',e);H.load('server/afk/callbacks.lua',e)
    end
    r.security=e.ForgeCore.Callbacks
    r.trace={};r.m.trace={}
    function r.runWorker(index)
        local co=coroutine.create(assert(r.workers[index or 1]));local ok,delay=coroutine.resume(co);assert(ok,delay);return co,delay
    end
    function r.tick(co,elapsed)r.now=r.now+(elapsed or 1000);local ok,delay=coroutine.resume(co);assert(ok,delay);return delay end
    return r
end
function A.outcome(fn,r)
    local result=table.pack(pcall(fn,r))
    if not result[1]then
        local message=tostring(result[2])
        assert(not message:find('assertion failed',1,true)and not message:find('Unbound test boundary',1,true),message)
        assert(message:find('fixture-',1,true),'Unexpected test error: '..message)
        result[2]=message:gsub('[^\n]-:%d+: ',''):gsub('stack traceback:[%s%S]*','')
    end
    return P.snapshot(result)
end
function A.case(name,fn,options)
    local a,b=A.new(false,options),A.new(true,options)
    H.same(A.outcome(fn,b),A.outcome(fn,a),name..': returns')
    H.same(b.trace,a.trace,name..': effects');H.same(b.m.trace,a.m.trace,name..': persistence')
    H.same(P.snapshot({b.w,b.a,b.records,b.answers,b.bans,b.buckets,b.drops,b.security.registrations,b.lookups}),
        P.snapshot({a.w,a.a,a.records,a.answers,a.bans,a.buckets,a.drops,a.security.registrations,a.lookups}),name..': state')
    H.same(b.m.files,a.m.files,name..': files')
end
return A
