-- Test-only full installed Points/Business vs inactive ports. All external effects simulated.
local J=dofile('tests/kernel_job_catalog_harness.lua')
local H,P=J.H,J.P
local B={H=H,P=P,J=J}
function B.vector(x,y,z,w)return {x=x,y=y,z=z,w=w,__cfxType=w~=nil and'vector4'or z~=nil and'vector3'or'vector2'}end
function B.environment(extra)
    local env=H.environment(extra)
    env.type=function(v)if type(v)=='table'and rawget(v,'__cfxType')then return v.__cfxType end;return type(v)end
    env.vector2,env.vector3,env.vector4=B.vector,B.vector,B.vector
    return env
end
function B.group(name,kind)
    return {name=name or'police',type=kind or'job',label='Police',
        grades={['0']={name='Member'},['2']={name='Recruiter',isrecruiter=true,isboss=false},['4']={name='Chief',isboss=true}},
        stashes={{id='Main Desk',title='Main',enabled=true,coords={x=1,y=2,z=3},
            stash={enabled=true,slots=10,weight=500,minGrade=2,password='pw',item='key',itemAmount=1,webhook='fixture://webhook'},
            duty={enabled=true,minGrade=0},
            shops={{id='supplies',type='shop',enabled=true,public=false,minGrade=2,buyGrade=2,supplyGrade=2,
                items={{name='burger',price=15,metadata={quality=7},stock=3}},stock={burger=10}}},
            registers={{id='cash',enabled=true,minGrade=2,balance=100,password='pw',robberyEnabled=true,robberyAmount=30,robberyAlertChance=100}},
            alarms={{id='panic',enabled=true,minGrade=2,message='Help'}},
            applications={{id='join',enabled=true,minScore=70,questions={{correct='yes'},{correct=2}},submissions={}}}}}}
end
function B.new(ported,mode,options)
    local r={trace={},hooks={},hookSequence=0,listeners={},results={},items={[1]={key=1,money=1000,burger=20}},
        bank={police=0},coreReady=true,inventoryReady=true,saveResult=true,allowed=false,rows={},random=1,
        players={[1]={source=1,citizenid='A',charinfo={firstname='Ana',lastname='Teste',phone='111'},
            job={name='police',grade={level=4},onduty=false},gang={name='ballas',grade={level=4}}}}}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    function r.result(method,fallback)
        local out=r.results[method]
        if out=='throw'then error('fixture-'..method,0)end
        if out then return table.unpack(out,1,out.n)end
        return fallback
    end
    r.config=J.config(true).config
    r.registry=J.new(ported,'registry').api
    r.registry.setAll({police=B.group()}, {})
    r.memory=J.persistence()
    r.json=r.memory.codec
    r.library={utils=H.load('../pr_bridge/bridge/utils/shared.lua',H.environment()),
        table=H.load('../pr_bridge/bridge/utils/tables.lua',H.environment()),
        math=H.load('../pr_bridge/bridge/utils/numbers.lua',B.environment()),debug={}}
    for _,level in ipairs({'info','warn','error'})do r.library.debug[level]=function(...)r.record('log-'..level,... )end end
    r.translate=function(key,args)r.record('translate',key,args);return key end
    r.native={
        print=function(...)r.record('print',...)end,
        getPlayerName=function(src)r.record('native-name',src);return 'Player '..src end,
        getIdentifier=function(src,kind)r.record('identifier',src,kind);return 'discord:123'end,
        getPed=function(src)r.record('ped',src);return src end,
        getCoords=function(ped)r.record('coords',ped);return B.vector(10,20,30)end,
        emit=function(...)r.record('alarm',...)end,
        listen=function(name,handler)
            r.record('listen',name);r.listeners[name]=r.listeners[name]or{};table.insert(r.listeners[name],handler)
        end}
    function r.registerHook(event,handler,opts)
        r.hookSequence=r.hookSequence+1
        local id='forge-core:'..event..':'..r.hookSequence
        r.record('hook-register',event,opts,id);r.hooks[id]={event=event,handler=handler}
        return r.result('RegisterHook',id)
    end
    r.integrations={
        inventoryReady=function()r.record('inventory-ready');return r.inventoryReady end,
        removeInventoryHooks=function(id)r.record('hook-remove',id);if r.removeHookError then error('remove-hook-exception',0)end;r.hooks[id]=nil end,
        httpRequest=function(url,cb,method,bytes,headers)r.record('http',url,method,bytes,headers);return nil end}
    r.library.inventory={
        RegisterHook=r.registerHook,
        RegisterStash=function(...)r.record('stash-register',...);return r.result('RegisterStash',nil)end,
        forceOpenInventory=function(...)r.record('stash-open',...);return r.result('forceOpenInventory',nil)end,
        HasItem=function(src,name,amount)r.record('has-item',src,name,amount);return r.result('HasItem',(r.items[src]or{})[name]~=nil and (r.items[src][name]>=amount))end,
        RegisterShop=function(...)r.record('shop-register',...);return r.result('RegisterShop',true)end,
        GetItemLabel=function(name)r.record('item-label',name);return r.result('GetItemLabel','Label '..name)end,
        Items=function(name)r.record('item',name);return {label='Item '..name}end,
        GetInventoryItems=function(src)r.record('inventory-items',src);return r.result('GetInventoryItems',{{name='burger',count=2},{name='burger',amount=3},{name='key',quantity=1}})end,
        GetItemCount=function(src,name)r.record('item-count',src,name);return r.result('GetItemCount',(r.items[src]or{})[name]or 0)end,
        RemoveItem=function(src,name,count)
            r.record('item-remove',src,name,count)
            local result=r.result('RemoveItem',((r.items[src]or{})[name]or 0)>=count)
            if result then r.items[src]=r.items[src]or{};r.items[src][name]=(r.items[src][name]or 0)-count end;return result
        end,
        AddItem=function(src,name,count)
            r.record('item-add',src,name,count);local result=r.result('AddItem',true)
            if result then r.items[src]=r.items[src]or{};r.items[src][name]=(r.items[src][name]or 0)+count end;return result
        end}
    r.library.banking={
        EnsureJobAccount=function(...)r.record('ensure-bank',...);return r.result('EnsureJobAccount',true)end,
        AddJobAccountBalance=function(name,amount,...)
            r.record('bank-add',name,amount,...);local result=r.result('AddJobAccountBalance',true)
            if result then r.bank[name]=(r.bank[name]or 0)+amount end;return result
        end,
        RecordJobTransaction=function(...)r.record('bank-record',...);return true end}
    r.library.phone={GetPhoneNumberFromIdentifier=function(...)r.record('phone',...);return r.result('Phone','222')end}
    r.library.database={query=function(...)r.record('query',...);return r.result('Query',H.copy(r.rows))end}
    r.playerAccess={
        GetPlayerData=function(src)r.record('player-data',src);return r.players[src]end,
        SetPlayerDuty=function(src,duty)
            r.record('duty',src,duty);local p=r.players[src];if p then p.job.onduty=duty end;return r.result('SetPlayerDuty',true)
        end,
        GetPlayerNameByIdentifier=function(id)r.record('identifier-name',id);return r.result('GetPlayerNameByIdentifier','Name '..id)end}
    for _,name in ipairs({'AddPlayerToJob','AddPlayerToGang','RemovePlayerFromJob','RemovePlayerFromGang'})do
        r.playerAccess[name]=function(...)r.record(name,...);return r.result(name,true)end
    end
    r.services={JobRegistry=r.registry,JobService={
        canManage=function(src)r.record('permission',src);return src==0 or r.allowed end,
        upsert=function(actor,group,kind)
            r.record('save-group',actor,group,kind)
            if r.saveHook then r.saveHook(group)end
            if r.saveResult then return r.registry.upsert(group,kind)end
            return r.saveResult,'save_failed'
        end}}
    r.kernel={GetGroupMembers=function(...)r.record('members',...);return r.result('GetGroupMembers',H.copy(r.rows))end}
    local function ready()r.record('core-ready');return r.coreReady end
    if options then options(r)end
    local env=B.environment()
    env.math.random=function(max)r.record('rng',max);return r.random end
    if ported then
        r.api=H.load('kernel/server/jobs/'..mode..'.lua',env)({config=r.config,services=r.services,library=r.library,
            playerAccess=r.playerAccess,kernel=r.kernel,isReady=ready,integrations=r.integrations,native=r.native,
            json=r.json,translate=r.translate,time=function()return 1000000 end})
    else
        env.PR={Job=r.config};env.ForgeCore=r.services;env.ForgeCore.t=r.translate
        env.pr_lib=r.library;r.library.framework=r.playerAccess
        env.json=r.json;env.os={time=function()return 1000000 end}
        env.GetResourceState=function(name)
            if name=='ox_inventory'then r.record('inventory-ready');return r.inventoryReady and'started'or'stopped'end
            assert(name=='qbx_core');r.record('core-ready');return r.coreReady and'started'or'stopped'
        end
        env.exports={ox_inventory={removeHooks=function(_,...)return r.integrations.removeInventoryHooks(...)end,
            registerHook=function(_,...)return r.registerHook(...)end},
            qbx_core={GetGroupMembers=function(_,...)return r.kernel.GetGroupMembers(...)end}}
        env.PerformHttpRequest=r.integrations.httpRequest
        env.GetPlayerName=r.native.getPlayerName;env.GetPlayerIdentifierByType=r.native.getIdentifier
        env.GetEntityCoords=r.native.getCoords;env.GetPlayerPed=r.native.getPed
        env.TriggerEvent=r.native.emit;env.AddEventHandler=r.native.listen;env.print=r.native.print
        H.load('server/job/'..mode..'.lua',env);r.api=r.services[mode=='points'and'JobPoints'or'JobBusiness']
    end
    assert(#r.trace==0,'constructors must not register/query/send effects')
    r.env=env
    function r.hook(event,payload)
        for _,hook in pairs(r.hooks)do if hook.event==event then local result=hook.handler(payload);if result==false then return false end end end
    end
    function r.post(success,payload)
        for _,hook in pairs(r.hooks)do
            if hook.event=='buyItem'then
                for name,list in pairs(r.listeners)do if r.hooks[name]==hook then for _,fn in ipairs(list)do fn(success,payload)end end end
            end
        end
    end
    return r
end
function B.case(mode,label,action,options)
    local a,b=B.new(false,mode,options),B.new(true,mode,options)
    local function run(r)
        local out=table.pack(pcall(action,r))
        if not out[1]then out[2]=tostring(out[2]):gsub('\nstack traceback:.*',''):gsub('^.-:%d+: ','')end
        assert(out[1],label..': unexpected test error: '..tostring(out[2]))
        return P.snapshot(out)
    end
    H.same(run(b),run(a),label..': returns/error')
    H.same(b.trace,a.trace,label..': effects')
    local function state(r)return P.snapshot({registry=r.registry.payload(),players=r.players,items=r.items,bank=r.bank,
        hooks=r.hooks,listeners=r.listeners,registered=r.api.registered,webhook=r.api.webhookData,hookId=r.api.hookId,
        shops=r.api.shops,openHook=r.api.openHookId,purchaseHook=r.api.purchaseHookId})end
    H.same(state(b),state(a),label..': state')
end
function B.edit(r,mutate,kind)
    kind=kind or'job';local name=kind=='gang'and'ballas'or'police'
    local group=r.registry.get(kind,name)or B.group(name,kind)
    mutate(group,group.stashes[1]);assert(r.registry.upsert(group,kind));return group
end
function B.expect(ok,value,expected)
    assert(ok==false and value==expected,'expected refusal '..tostring(expected)..', got '..tostring(ok)..'/'..tostring(value))
end
function B.compose(base,ports)
    return H.load('kernel/server/jobs/business_core.lua',B.environment({require=function(name)
        assert(name=='kernel.server.jobs.points'or name=='kernel.server.jobs.business')
        return H.load(name:gsub('%.','/')..'.lua',B.environment())
    end}))(base,ports)
end
return B
