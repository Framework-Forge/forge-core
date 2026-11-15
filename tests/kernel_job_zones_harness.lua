-- Full installed client bodies vs private ports. All IO/UI/providers/time/network are simulated.
local B=dofile('tests/kernel_business_harness.lua')
local H,P,J=B.H,B.P,B.J
local Z={H=H,P=P,J=J,B=B}
function Z.payload()
    local job=B.group();local point=job.stashes[1]
    point.duty.coords={1,2,3}
    for _,key in ipairs({'shops','registers','alarms','applications'})do
        for _,p in ipairs(point[key])do p.coords={1,2,3}end
    end
    point.bossMenus={{id='boss',coords={1,2,3},minGrade=4}}
    point.applications[1].questions={{label='Why?',options={{label='Yes'},{text='No'},'Maybe'}}}
    local gang=H.copy(job);gang.name,gang.type='ballas','gang'
    return {jobs={job},gangs={gang}}
end
function Z.new(ported,mode,options)
    local r={trace={},events={},timers={},zones={},nextId=0,contexts={},mode=mode,inputs={},results={},
        data={citizenid='A',job={name='police',grade={level=4},onduty=false},gang={name='ballas',grade=4}},
        payload=Z.payload(),config=J.config(true).config,state='started',lockpick=true,progress=true,client={}}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    r.library={utils=H.load('../pr_bridge/bridge/utils/shared.lua',H.environment()),
        math=H.load('../pr_bridge/bridge/utils/numbers.lua',B.environment())}
    r.library.Notify=function(...)r.record('notify',...)end
    r.access={GetPlayerData=function()r.record('get-data');if r.dataHook then return r.dataHook()end;return r.data end,
        GetJobInfo=function()r.record('get-job');return r.jobInfo or{}end}
    r.translate=function(key,params)r.record('translate',key,params);return key end
    r.library.target={addBoxZone=function(data)
        r.record('zone-add',data)
        if r.addHook then return r.addHook(data)end
        r.nextId=r.nextId+1;r.zones[r.nextId]=data;return r.nextId
    end,removeZone=function(id)
        r.record('zone-remove',id)
        if r.removeError then error('fixture-remove',0)end
        r.zones[id]=nil;return r.removeResult
    end}
    r.library.callback={await=function(name,timeout,...)
        r.record('await',name,timeout,...)
        if r.awaitHook then return r.awaitHook(name,...)end
        if r.awaitError then error('fixture-await',0)end
        local result=r.results[name]
        if result then return table.unpack(result,1,result.n)end
        return true,'fixture-response'
    end}
    r.library.menus={InputDialog=function(...)r.record('input',...);if r.inputHook then return r.inputHook(...)end;return table.remove(r.inputs,1)end,
        RegisterContext=function(ctx)r.record('context',ctx);r.lastContext=ctx;r.contexts[ctx.id]=ctx;return r.contextResult end,
        ShowContext=function(id)r.record('show',id);return r.showResult end}
    r.library.inventory={openInventory=function(...)r.record('inventory',...);if r.inventoryError then error('fixture-inventory',0)end end}
    r.library.progress={doProgressbar=function(...)r.record('progress',...);return r.progress end}
    r.native={setTimeout=function(ms,fn)r.record('timer',ms);r.timers[#r.timers+1]={ms=ms,fn=fn}end,
        vector=B.vector,resourceName=function()return'forge-core'end}
    r.integrations={lockpickState=function()r.record('lockpick-state');return r.state end,
        startLockpick=function(...)r.record('lockpick',...);if r.lockpickHook then return r.lockpickHook(...)end;return r.lockpick end}
    if options then options(r)end
    local env=B.environment()
    if ported then
        r.module=H.load('kernel/client/job/'..mode..'.lua',env)({library=r.library,playerAccess=r.access,client=r.client,
            translate=r.translate,native=r.native,config=r.config,integrations=r.integrations,
            debugEnabled=r.debugEnabled,notifyPosition=r.notifyPosition})
        r.api=r.module[mode=='points'and'Points'or'Business'];r.events=r.module.Events
    else
        r.library.framework=r.access;env.pr_lib=r.library
        env.ForgeCore={Client=r.client,t=r.translate};env.PR={Job=r.config,Debug=r.debugEnabled,NotifyPos=r.notifyPosition}
        env.SetTimeout=r.native.setTimeout;env.GetCurrentResourceName=r.native.resourceName;env.vec3=r.native.vector
        env.RegisterNetEvent=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=true}end
        env.AddEventHandler=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=false}end
        env.GetResourceState=function(name)assert(name=='glitch-minigames');return r.integrations.lockpickState()end
        env.exports={['glitch-minigames']={StartLockpickGame=function(_,...)return r.integrations.startLockpick(...)end}}
        H.load('client/job/'..mode..'.lua',env)
        r.api=r.client[mode=='points'and'JobPoints'or'JobBusiness']
    end
    assert(#r.trace==0,'no zone, request, translation, timer or UI in constructor')
    function r.dispatch(name,...)
        for _,event in ipairs(r.events)do if event.name==name then event.handler(...)end end
    end
    function r.refresh(payload)return r.api.refresh(payload or r.payload)end
    function r.option(fragment)
        for id=1,r.nextId do
            local zone=r.zones[id]
            if zone then for _,option in ipairs(zone.options)do
                if option.name:find(fragment,1,true)then return option end
            end end
        end
        error('Missing option '..fragment,0)
    end
    function r.select(fragment)return r.option(fragment).onSelect()end
    function r.action(key)
        for _,option in ipairs(assert(r.lastContext).options)do
            if option.title==key then return assert(option.onSelect)()end
        end
        error('Missing context action '..key,0)
    end
    function r.flush()
        local batch=r.timers;r.timers={}
        for _,timer in ipairs(batch)do assert(timer.ms==250);timer.fn()end
    end
    return r
end
function Z.pair(mode,options)
    local a,b=Z.new(false,mode,options),Z.new(true,mode,options);local p={a=a,b=b,count=0}
    function p.run(label,fn)
        local function run(r)
            local result=table.pack(pcall(fn,r));assert(result[1],label..': test failed '..tostring(result[2]))
            return P.snapshot(result)
        end
        H.same(run(b),run(a),label..': returns')
        H.same(b.trace,a.trace,label..': all effects')
        H.same(P.snapshot(b.api),P.snapshot(a.api),label..': complete state')
        H.same(P.snapshot(b.zones),P.snapshot(a.zones),label..': live targets')
        H.same(P.snapshot(b.lastContext),P.snapshot(a.lastContext),label..': context')
        p.count=p.count+1
    end
    return p
end
function Z.compose(state,ports)
    local e=B.environment()
    e.require=function(name)assert(name=='kernel.client.job.points'or name=='kernel.client.job.business');return H.load(name:gsub('%.','/')..'.lua',e)end
    return H.load('kernel/client/job/zones_core.lua',e)(state,ports)
end
return Z

