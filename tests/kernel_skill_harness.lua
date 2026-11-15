-- Test-only: full installed sources and PR progression/persistence with virtual IO/SQL/time.
local J=dofile('tests/kernel_job_catalog_harness.lua')
local H,P=J.H,J.P
local Q={H=H,P=P,J=J}
function Q.env()
    local e=H.environment()
    e.require=function(name)assert(name:match('^kernel%.'));return H.load(name:gsub('%.','/')..'.lua',Q.env())end
    return e
end
function Q.new(ported,options)
    options=options or {}
    local r={trace={},events={},listeners={},exports={},commands={},time=1000,source=1,manage=true,
        cid='cid1',state='started',externalState='started',columnExists=1,dbReady=true,updateResult=table.pack(1),
        multiplier=1,cache={},packets={},workers={},stored={},integrationResult=table.pack(true)}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    r.m=J.persistence();r.library=r.m.api
    r.library.debug={};for _,level in ipairs({'info','warn','error','success'})do
        r.library.debug[level]=function(...)r.record('log-'..level,...)end
    end
    r.translate=function(key,params)r.record('translate',key,params);return key end
    r.library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    r.library.cache={set=function(k,v)r.record('cache-set',k,v);r.cache[k]=H.copy(v)end,
        clear=function(k)r.record('cache-clear',k);r.cache[k]=nil end}
    r.library.db={isReady=function()r.record('db-ready');return r.dbReady end,
        scalar=function(sql,params)
            r.record('scalar',sql,params)
            if r.scalarHook then local result=r.scalarHook(sql,params);if result then return table.unpack(result,1,result.n)end end
            if sql:find('information_schema',1,true)then return r.columnExists end
            return r.stored[params[1]]
        end,
        update=function(sql,params)
            r.record('update',sql,params)
            if r.updateHook then r.updateHook(sql,params)end
            if r.updateError then error(r.updateError,0)end
            return table.unpack(r.updateResult,1,r.updateResult.n)
        end}
    local function command(name,props,fn)r.commands[#r.commands+1]={name=name,options=props,handler=fn,mode='library'}end
    r.library.command=options.nativeCommand and nil or command
    if options.nativeCommand then r.library.command=nil end
    r.library.callback={await=function(...)r.record('await-menu',...);return true end}
    r.library.callback.awaitClient=r.library.callback.await
    r.services={JobService={canManage=function(src)r.record('manage',src);return r.manage end},
        VipService={get=function(src)r.record('vip',src);return {config={xpMultiplier=r.multiplier}}end}}
    r.native={
        source=function()return r.source end,time=function()return r.time end,
        resource=function()return 'forge-core'end,
        resourceState=function(name)r.record('resource-state',name);return r.externalState end,
        isAceAllowed=function(...)r.record('ace',...);return r.manage end,
        emitClient=function(name,src,packet)r.record('emit',name,src,packet);r.packets[#r.packets+1]=H.copy(packet)end,
        spawn=function(fn)r.workers[#r.workers+1]=fn;r.record('thread')end,
        wait=function(ms)r.record('wait',ms);if r.onWait then r.onWait(ms)end end,
        print=function(...)r.record('print',...)end,
        promise=function()
            local pending={}
            function pending:resolve(value)self.done=true;self.value=value end
            return pending
        end,
        await=function(pending)if not pending.done then return coroutine.yield('await',pending)end;return pending.value end}
    r.kernel={isReady=function()r.record('ready');return r.state=='started'or r.state=='starting'end,
        GetPlayer=function(src)
            r.record('lookup',src)
            if r.lookupError then error(r.lookupError,0)end
            if not r.cid then return nil end
            if r.player then return r.player end
            return {PlayerData={citizenid=r.cid,source=src}}
        end}
    r.integrations={invoke=function(resource,name,src,target,delta,context)
        r.record('external',resource,name,src,target,delta,context)
        if r.integrationHook then return r.integrationHook(resource,name,src,target,delta,context)end
        if r.integrationError then error(r.integrationError,0)end
        return table.unpack(r.integrationResult,1,r.integrationResult.n)
    end}
    r.stored.cid1=r.m.codec.encode({a=10,r=5,unknown={legacy=42}})
    local progressionEnv=H.environment({PRProgression={}})
    H.load('../pr_bridge/shared/progression.lua',progressionEnv)
    r.progression=progressionEnv.PRProgression
    local e=H.environment()
    e.math.random=function()return 123456 end
    r.env=e
    if ported then
        r.config=H.load('kernel/config/forge_skills.lua',e)()
        r.registry=H.load('kernel/server/skill/registry.lua',e)(r.config)
        r.storage=H.load('kernel/server/skill/storage.lua',e)({config=r.config,library=r.library})
    else
        e.PR={};e.ForgeCore={t=r.translate};e.pr_lib=r.library
        H.load('shared/skills.lua',e);r.config=e.PR.Skills
        H.load('server/skill/registry.lua',e);r.registry=e.ForgeCore.SkillRegistry
        H.load('server/skill/storage.lua',e);r.storage=e.ForgeCore.SkillStorage
    end
    r.definitions={settings={enabled=true},skills={
        a={name='a',maxXp=100,clientGain=true,maxDeltaPerMinute=20},
        total={name='total',calculation='sum_reputations',maxXp=50}},
        reputations={r={name='r',skill='total',clientGain=true,maxXp=80,maxDeltaPerMinute=30}}}
    r.registry.setAll(H.copy(r.definitions))
    r.m.seed(r.config.Storage.file,r.definitions)
    if options.prepare then options.prepare(r)end
    r.ports={config=r.config,registry=r.registry,storage=r.storage,services=r.services,library=r.library,
        json=r.m.codec,progression=r.progression,translate=r.translate,native=r.native,
        kernel=r.kernel,integrations=r.integrations,adminAce='forge-core.admin',notifyPosition='top'}
    if ported then
        r.boundary=H.load('kernel/server/skill/service.lua',e)(r.ports)
        r.api=r.boundary.Service
        for _,entry in ipairs(r.boundary.NetEvents)do r.events[entry.name]=entry.handler end
        for _,entry in ipairs(r.boundary.Listeners)do r.listeners[entry.name]=entry.handler end
        for _,entry in ipairs(r.boundary.Exports)do r.exports[entry.name]=entry.handler end
    else
        e.PR.AdminAce='forge-core.admin';e.PR.NotifyPos='top'
        e.ForgeCore.JobService=r.services.JobService;e.ForgeCore.VipService=r.services.VipService
        e.PRProgression=r.progression;e.json=r.m.codec;e.promise={new=r.native.promise};e.Citizen={Await=r.native.await}
        e.GetResourceState=function(name)
            if name=='qbx_core'then r.record('ready');return r.state end
            return r.native.resourceState(name)
        end
        e.GetGameTimer=r.native.time;e.GetCurrentResourceName=r.native.resource
        e.IsPlayerAceAllowed=r.native.isAceAllowed;e.TriggerClientEvent=r.native.emitClient
        e.CreateThread=r.native.spawn;e.Wait=r.native.wait;e.print=r.native.print;e.source=r.source
        e.RegisterNetEvent=function(name,fn)r.events[name]=fn end
        e.AddEventHandler=function(name,fn)r.listeners[name]=fn end
        local exports={qbx_core={GetPlayer=function(_,src)return r.kernel.GetPlayer(src)end}}
        setmetatable(exports,{__call=function(_,name,fn)r.exports[name]=fn end,
            __index=function(_,resource)
                local api={}
                setmetatable(api,{__index=function(_,name)return function(self,...)
                    assert(self==api,'invalid export self');return r.integrations.invoke(resource,name,...)
                end end})
                return api
            end})
        e.exports=exports
        H.load('server/skill/service.lua',e);r.api=e.ForgeCore.SkillService
    end
    function r.event(name,...)
        e.source=r.source
        local fn=assert(r.events[name]or r.listeners[name],'unknown test event')
        return fn(...)
    end
    function r.packet(counters)
        local packet=r.packets[#r.packets]
        return {token=assert(packet and packet.token),counters=counters}
    end
    function r.attachBoundaries()
        if ported then
            r.callbacks=H.load('kernel/server/skill/callbacks.lua',e)({config=r.config,service=r.api})
            local commands=H.load('kernel/server/skill/commands.lua',e)({config=r.config,service=r.api,library=r.library,translate=r.translate})
            r.commands=commands.Commands
        else
            r.callbacks={}
            e.ForgeCore.Callbacks={register=function(name,fn)r.callbacks[#r.callbacks+1]={name=name,handler=fn}end}
            H.load('server/skill/callbacks.lua',e)
            e.RegisterCommand=function(name,handler,restricted)r.commands[#r.commands+1]={name=name,handler=handler,restricted=restricted,mode='native'}end
            H.load('server/skill/commands.lua',e)
        end
    end
    return r
end
function Q.outcome(action,r)
    local result=table.pack(pcall(action,r))
    if not result[1]then
        local msg=tostring(result[2])
        assert(not msg:find('assertion failed',1,true)and not msg:find('Unbound test boundary',1,true)
            and not msg:match('^[^\n]*tests/[^\n]-%.lua:'),msg)
        result[2]=msg:gsub('[^\n]-:%d+: ',''):gsub('stack traceback:[%s%S]*','')
    end
    return P.snapshot(result)
end
function Q.case(label,action,options)
    local a,b=Q.new(false,options),Q.new(true,options)
    H.same(Q.outcome(action,b),Q.outcome(action,a),label..': outcome')
    H.same(b.trace,a.trace,label..': trace')
    H.same(b.registry.export(),a.registry.export(),label..': registry')
    H.same(b.registry.revision,a.registry.revision,label..': revision')
    H.same(b.m.trace,a.m.trace,label..': PR persistence trace')
    H.same(b.m.files,a.m.files,label..': virtual files')
    H.same(b.cache,a.cache,label..': cache')
    H.same(b.api.started,a.api.started,label..': started')
    H.same(b.api.schemaReady,a.api.schemaReady,label..': schemaReady')
end
return Q

