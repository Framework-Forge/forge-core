-- Isolated money/banking/inventory/ACE/scheduler/JSON fixtures. No real resources or balances.
local J = dofile('tests/kernel_job_catalog_harness.lua')
local H,P=J.H,J.P
local F={H=H,P=P,J=J}
function F.new(ported, mode, options)
    local r={trace={},tasks={},timers={},events={},threads={},exported={},now=1000000,currentSource=1,
        coreReady=true,inventoryReady=true,allowed=true,players={},jobs={},bank={taxi=10000,government=0},
        money={},results={},activeVip={},connected={'1'},bonusResults={},metadataWrites=0}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    r.config=J.config(true).config
    r.vipConfig=H.load('kernel/config/forge_vip.lua',H.environment())()
    r.vipConfig.inventoryRetryAttempts=2;r.vipConfig.inventoryRetryDelay=50
    r.memory=J.persistence();r.library={}
    for k,v in pairs(r.memory.api)do r.library[k]=v end
    r.library.debug={}
    for _,level in ipairs({'info','success','warn','error'})do r.library.debug[level]=function(...)r.record('log-'..level,...)end end
    r.translate=function(key,args)r.record('translate',key,args);return key end
    r.library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    r.library.inventory={AddItem=function(...)r.record('inventory-add',...);return r.result('AddItem',true)end}
    function r.result(method,fallback)
        local result=r.results[method]
        if result=='throw'then error('fixture-'..method,0)end
        if result then return table.unpack(result,1,result.n)end
        return fallback
    end
    function r.makePlayer(src)
        local player={PlayerData={source=src,citizenid='C'..src,metadata={},
            job={name='taxi',grade={level=0},onduty=true,payment=20}}}
        r.money[src]={cash=10000,bank=10000,crypto=0}
        player.Functions={
            AddMoney=function(account,amount,reason)
                r.record('add-money',src,account,amount,reason)
                if r.addHook then r.addHook(player,account,amount)end
                local result=r.result('AddMoney',true)
                if result==true then r.money[src][account]=(r.money[src][account]or 0)+amount end
                return result
            end,
            RemoveMoney=function(account,amount,reason)
                r.record('remove-money',src,account,amount,reason)
                local result=r.result('RemoveMoney',true)
                if result==true then r.money[src][account]=(r.money[src][account]or 0)-amount end
                return result
            end}
        return player
    end
    r.players[1]=r.makePlayer(1)
    r.jobs.taxi={label='Taxi',type='civil',offDutyPay=false,grades={[0]={name='Driver',payment=100}}}
    r.library.banking={
        JobAccountExists=function(name)r.record('bank-exists',name);return r.result('JobAccountExists',r.bank[name]~=nil)end,
        GetJobAccountBalance=function(name)r.record('bank-balance',name);return r.result('GetJobAccountBalance',r.bank[name])end,
        AddJobAccountBalance=function(name,amount,reason)
            r.record('bank-add',name,amount,reason);local result=r.result('AddJobAccountBalance',true)
            if result==true then r.bank[name]=(r.bank[name]or 0)+amount end;return result
        end,
        RemoveJobAccountBalance=function(name,amount,reason)
            r.record('bank-remove',name,amount,reason);local result=r.result('RemoveJobAccountBalance',true)
            if result==true then r.bank[name]=(r.bank[name]or 0)-amount end;return result
        end}
    r.kernel={
        GetQBPlayers=function()r.record('players');return r.result('GetQBPlayers',r.players)end,
        GetJob=function(name)r.record('job',name);return r.result('GetJob',r.jobs[name])end,
        GetPlayer=function(src)r.record('player',src);return r.players[src]end,
        SetMetadata=function(src,key,value)
            r.record('metadata',src,key,value);r.metadataWrites=r.metadataWrites+1
            local p=r.players[src];if p then p.PlayerData.metadata[key]=H.copy(value)end
        end}
    r.storage=H.load('kernel/server/jobs/storage.lua',H.environment())({config=r.config,library=r.library,translate=r.translate})
    r.services={JobStorage=r.storage,JobService={canManage=function(src)r.record('permission',src);return r.allowed end},
        VipService={get=function(src)r.record('vip-get',src);return r.activeVip[src]end}}
    r.native={
        spawn=function(fn)r.record('worker');r.tasks[#r.tasks+1]=coroutine.create(fn)end,
        wait=function(ms)r.record('wait',ms);coroutine.yield(ms)end,
        setTimeout=function(ms,fn)r.record('timer',ms);r.timers[#r.timers+1]={ms=ms,fn=fn}end,
        getSource=function()return r.currentSource end,getPlayers=function()return r.connected end,
        execute=function(cmd)r.record('ace-command',cmd)end,
        getIdentifier=function(src,kind)r.record('identifier',src,kind);return 'license:'..src end,
        print=function(...)r.record('print',...)end}
    r.integrations={
        inventoryReady=function()r.record('inventory-ready');return r.inventoryReady end,
        applyPlayerInventoryBonus=function(src,slots,weight)
            r.record('bonus',src,slots,weight)
            local result=table.remove(r.bonusResults,1)
            if result=='throw'then error('bonus-exception',0)end
            if result then return table.unpack(result,1,result.n)end
            return true,'applied',{slots=slots,weight=weight}
        end}
    local function ready()r.record('core-ready');return r.coreReady end
    if options then options(r)end
    if mode=='vip'then
        -- Installed load would read this same fixture; no operational VIP data read.
        r.memory.seed(r.vipConfig.storageFile,r.vipConfig.tiers)
    end
    local env=H.environment()
    if ported then
        if mode=='vip'then
            r.api=H.load('kernel/server/vip/service.lua',env)({config=r.vipConfig,services=r.services,kernel=r.kernel,
                library=r.library,integrations=r.integrations,native=r.native,time=function()return r.now end,resource='forge-core'})
            assert(#r.trace==0 and #r.memory.trace==0 and #r.tasks==0,'VIP constructor must not initialize')
            assert(r.api.Initialize());r.events,r.threads,r.exported=r.api.Events,r.api.Threads,r.api.Exports
        else
            r.api=H.load('kernel/server/jobs/payments.lua',env)({config=r.config,services=r.services,kernel=r.kernel,
                library=r.library,integrations=r.integrations,native=r.native,time=function()return r.now end,
                isReady=ready,translate=r.translate,notifyPosition='top-right'})
        end
    else
        env.PR={Job=r.config,Vip=r.vipConfig,NotifyPos='top-right'};env.ForgeCore=r.services;env.ForgeCore.t=r.translate;env.pr_lib=r.library
        env.GetCurrentResourceName=function()return 'forge-core'end
        env.os={time=function()return r.now end}
        env.GetResourceState=function(name)
            if name=='qbx_core'then r.record('core-ready');return r.coreReady and 'started'or'stopped'end
            assert(name=='ox_inventory');r.record('inventory-ready');return r.inventoryReady and'started'or'stopped'
        end
        local qbx={};for name,fn in pairs(r.kernel)do qbx[name]=function(_,...)return fn(...)end end
        local ox={AddItem=function(_,...)return r.library.inventory.AddItem(...)end,
            ApplyPlayerInventoryBonus=function(_,...)return r.integrations.applyPlayerInventoryBonus(...)end}
        env.exports=setmetatable({qbx_core=qbx,ox_inventory=ox},{__call=function(_,name,fn)r.exported[name]=fn end})
        env.Wait=r.native.wait;env.SetTimeout=r.native.setTimeout
        env.ExecuteCommand=r.native.execute;env.GetPlayerIdentifierByType=r.native.getIdentifier;env.GetPlayers=r.native.getPlayers;env.print=r.native.print
        local loading=true
        env.CreateThread=function(fn)
            if mode=='vip'and loading then r.threads[#r.threads+1]=fn else r.native.spawn(fn)end
        end
        env.RegisterNetEvent=function(name,handler)r.events[#r.events+1]={name=name,handler=handler,network=true}end
        env.AddEventHandler=function(name,handler)r.events[#r.events+1]={name=name,handler=handler,network=false}end
        env.source=1
        H.load(mode=='vip'and'server/vip/service.lua'or'server/job/payments.lua',env);loading=false
        r.api=r.services[mode=='vip'and'VipService'or'JobPayments']
    end
    r.env=env
    function r.dispatch(name,src,...)
        r.currentSource=src;if not ported then env.source=src end
        for _,e in ipairs(r.events)do if e.name==name then e.handler(...)end end
    end
    function r.step(index)
        local co=assert(r.tasks[index or 1]);local ok,value=coroutine.resume(co);assert(ok,value);return value,coroutine.status(co)
    end
    function r.runTimers()local timers=r.timers;r.timers={};for _,timer in ipairs(timers)do timer.fn()end end
    return r
end
function F.case(mode,label,action,options)
    local a,b=F.new(false,mode,options),F.new(true,mode,options)
    local function run(r)
        local out=table.pack(pcall(action,r))
        if not out[1]then out[2]=tostring(out[2]):gsub('\nstack traceback:.*',''):gsub('^.-:%d+: ','')end
        return P.snapshot(out)
    end
    H.same(run(b),run(a),label..': return/error')
    H.same(b.trace,a.trace,label..': effects')
    local function state(r)
        local api=mode=='vip'and{tiers=r.api.tiers,sessions=r.api.sessions,revision=r.api.inventoryRevision,pending=r.api.pendingInventoryReset}
            or{settings=r.api.settings,nextPaymentAt=r.api.nextPaymentAt,started=r.api.started}
        local tasks={};for i,co in ipairs(r.tasks)do tasks[i]=coroutine.status(co)end
        return P.snapshot({api=api,players=r.players,money=r.money,bank=r.bank,files=r.memory.files,memory=r.memory.trace,
            timers=r.timers,tasks=tasks,events=r.events,threads=r.threads,exported=r.exported})
    end
    H.same(state(b),state(a),label..': state')
end
function F.compose(base,ports)
    local env=H.environment({require=function(name)
        assert(name=='kernel.server.jobs.payments'or name=='kernel.server.vip.service'or name=='kernel.config.forge_vip')
        return H.load(name:gsub('%.','/')..'.lua',H.environment())
    end})
    return H.load('kernel/server/jobs/payments_core.lua',env)(base,ports)
end
return F
