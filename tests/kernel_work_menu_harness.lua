-- Whole installed central/work menu sources against private factories; no live UI/network/resource/IO.
local Z=dofile('tests/kernel_job_zones_harness.lua')
local H,P,J,B=Z.H,Z.P,Z.J,Z.B
local A={H=H,P=P,J=J,B=B,Z=Z}
function A.new(ported,options)
    local r={trace={},contexts={},timers={},inputs={},alerts={},responses={},events={},callbacks={},exports={},
        client={},menu={},shared={},now=123,resources={},documents={ok=true},seat=true,controls={},ray=B.vector(1,2,3)}
    local payload=Z.payload()
    r.job,r.gang=payload.jobs[1],payload.gangs[1]
    r.point=r.job.stashes[1];r.shop=r.point.shops[1];r.application=r.point.applications[1]
    r.config={Job=J.config(true).config,NotifyPos='top-right',
        Garage={AdminMenu={enabled=true}},Rental={AdminMenu={enabled=true}},
        Skills={Calculation={direct='direct',sumReputations='sum'},Callbacks={getAll='skills-get',fetchPlayer='skills-player',saveSkill='skills-save',saveReputation='reps-save'}},
        Staff={Roles={{value='admin',label='Admin'}}}}
    r.state={jobs={r.job},gangs={r.gang},payments={enabled=true,account='bank',intervalMinutes=10,
        mei={enabled=true,openingCost=0,governmentAccount='government',paymentAccount='bank'}}}
    r.state.getGroups=function(kind)return kind=='gang'and r.state.gangs or r.state.jobs end
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    r.client.JobState={request=function()r.record('replica-request');if r.stateHook then return r.stateHook()end;return r.state end}
    r.client.Menu=r.menu
    for _,name in ipairs({'openSkillsMenu','openStaffMenu','openServerSettingsMenu','openPlayersManagement','openAutoMedicMenu','openMultiJobAdminMenu'})do
        r.menu[name]=function(...)r.record('future-'..name,...)end
    end
    r.library={table=H.load('../pr_bridge/bridge/utils/tables.lua',H.environment()),
        utils=H.load('../pr_bridge/bridge/utils/shared.lua',H.environment()),
        math=H.load('../pr_bridge/bridge/utils/numbers.lua',B.environment()),
        debug={info=function(...)r.record('info',...)end,warn=function(...)r.record('warn',...)end}}
    r.translate=function(key,params)r.record('translate',key,params);return key end
    r.library.Notify=function(...)r.record('notify',...)end
    r.library.menus={RegisterContext=function(ctx)r.record('context',ctx);r.contexts[ctx.id]=ctx;r.last=ctx;if r.registerHook then return r.registerHook(ctx)end;return r.uiReturn end,
        ShowContext=function(id)r.record('show',id);if r.showHook then return r.showHook(id)end;return r.uiReturn end,
        InputDialog=function(...)r.record('input',...);if r.inputHook then return r.inputHook(...)end;return table.remove(r.inputs,1)end,
        AlertDialog=function(...)r.record('alert',...);return table.remove(r.alerts,1)end}
    r.library.callback={await=function(name,timeout,...)
        assert(timeout==10000);r.record('await',name,timeout,...)
        if r.awaitHook then return r.awaitHook(name,...)end
        if r.awaitError then error('fixture-await',0)end
        local result=r.responses[name]
        if result then return table.unpack(result,1,result.n)end
        return true,{}
    end}
    r.library.openVisualAdminMenu=function(...)r.record('interface',...)end
    r.library.raycast={FromCamera=function(...)r.record('raycast',...);return nil,nil,r.ray end}
    r.library.textuiAdapter={Show=function(...)r.record('text-show',...)end,Hide=function()r.record('text-hide')end}
    local function vector(x,y,z)
        return setmetatable({x=x,y=y,z=z},{__sub=function(a,b)return vector(a.x-b.x,a.y-b.y,a.z-b.z)end,
            __len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end})
    end
    r.native={resourceName=function()return'forge-core'end,
        setTimeout=function(ms,fn)r.record('timer',ms);r.timers[#r.timers+1]={ms=ms,fn=fn}end,
        gameTimer=function()return r.now end,playerPedId=function()return 10 end,
        drawMarker=function(...)r.record('marker',...)end,
        controlReleased=function(_,key)return r.controls[key]==true end,
        wait=function(ms)r.record('wait',ms);return coroutine.yield(ms)end,
        playerId=function()return 1 end,activePlayers=function()return{1,2,3,4}end,
        playerPed=function(id)return id==4 and 0 or id end,
        coords=function(ped)return ped==10 and vector(0,0,0)or ped==2 and vector(3,4,0)or vector(100,100,0)end,
        serverId=function(id)return id+100 end}
    r.integrations={resourceState=function(name)r.record('resource-state',name);return r.resources[name]or'started'end,
        emitClientMenu=function(...)r.record('external-client',...)end,emitServerMenu=function(...)r.record('external-server',...)end,
        openDocuments=function(resource)r.record('documents',resource);if r.documentsError then error('fixture-documents',0)end;return r.documents end,
        openSeatMenu=function(...)r.record('seat',...);if r.seatError then error('fixture-seat',0)end;return r.seat end}
    function r.reply(name,...)r.responses[name]=table.pack(...)end
    if options then options(r)end
    local env=B.environment()
    if ported then
        local ports={menu=r.menu,shared=r.shared,client=r.client,config=r.config,library=r.library,
            translate=r.translate,native=r.native,integrations=r.integrations}
        for _,name in ipairs({'central','jobs','business_admin','mei','creator'})do
            local module=H.load('kernel/client/menu/'..name..'.lua',env)(ports)
            for _,event in ipairs(module.Events)do r.events[#r.events+1]=event end
            for name,fn in pairs(module.Callbacks)do r.callbacks[name]=fn end
            for name,fn in pairs(module.Exports)do r.exports[name]=fn end
            if module.Creator then r.creator=module.Creator end
        end
        assert(#r.trace==0,'no automatic UI, request, resource lookup, timer, registration or worker')
    else
        env.ForgeCore={Client=r.client,t=r.translate};r.client.MenuShared=r.shared
        env.pr_lib=r.library;env.PR=r.config
        local names={SetTimeout='setTimeout',GetGameTimer='gameTimer',PlayerPedId='playerPedId',DrawMarker='drawMarker',IsControlJustReleased='controlReleased',
            Wait='wait',PlayerId='playerId',GetEntityCoords='coords',GetActivePlayers='activePlayers',GetPlayerPed='playerPed',GetPlayerServerId='serverId',GetCurrentResourceName='resourceName'}
        for source,port in pairs(names)do env[source]=r.native[port]end
        env.GetResourceState=r.integrations.resourceState;env.TriggerEvent=r.integrations.emitClientMenu;env.TriggerServerEvent=r.integrations.emitServerMenu
        env.AddEventHandler=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=false}end
        env.exports=setmetatable({['forge-dk']={OpenAdminPanel=function()return r.integrations.openDocuments('forge-dk')end},
            Syn_Sit={OpenAdminMenu=function(_,...)return r.integrations.openSeatMenu('Syn_Sit',...)end}},
            {__call=function(_,name,fn)r.exports[name]=fn end})
        r.library.callback.register=function(name,fn)r.callbacks[name]=fn end
        for _,name in ipairs({'menu/menu.lua','menu/menu_job.lua','menu/menu_business.lua','menu/menu_mei.lua','job/creator.lua'})do H.load('client/'..name,env)end
        r.creator=r.client.JobCreator
    end
    function r.select(index,ctx,force)
        local option=assert((ctx or r.last).options[index])
        if not force and(option.disabled or option.readOnly)then return end
        return assert(option.onSelect)()
    end
    function r.runTimers(ms)
        local batch=r.timers;r.timers={}
        for _,timer in ipairs(batch)do if not ms or timer.ms==ms then timer.fn()else r.timers[#r.timers+1]=timer end end
    end
    function r.lastRequest()
        for i=#r.trace,1,-1 do if r.trace[i].kind=='await'then return r.trace[i].args end end
    end
    function r.dispatch(name,...)for _,event in ipairs(r.events)do if event.name==name then event.handler(...)end end end
    return r
end
function A.pair(options)
    local a,b=A.new(false,options),A.new(true,options);local p={a=a,b=b,count=0}
    function p.run(label,fn)
        local function run(r)local result=table.pack(pcall(fn,r));assert(result[1],label..': unexpected test error '..tostring(result[2]));return P.snapshot(result)end
        H.same(run(b),run(a),label..': returns')
        H.same(b.trace,a.trace,label..': all effects')
        H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),label..': retained contexts')
        H.same(P.snapshot({b.job,b.gang,b.state}),P.snapshot({a.job,a.gang,a.state}),label..': source state/mutation')
        p.count=p.count+1
    end
    return p
end
function A.compose(state,ports)
    local env=B.environment()
    env.require=function(name)assert(name:match('^kernel.client.menu.'));return H.load(name:gsub('%.','/')..'.lua',env)end
    return H.load('kernel/client/menu/work_core.lua',env)(state,ports)
end
return A

