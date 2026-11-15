-- Test-only: full installed client bodies, actual PR ledger and central helpers.
local Q=dofile('tests/kernel_skill_harness.lua')
local A=dofile('tests/kernel_work_menu_harness.lua')
local H,P=Q.H,Q.P
local R={Q=Q,A=A,H=H,P=P}
function R.definitions()
    return {revision=4,settings={enabled=true,defaultLevels={{title='Zero',from=0,to=100}}},
        skills={{name='a',label='Alpha',maxXp=100,clientGain=true,decay={enabled=true,amount=2,intervalMs=10000}},
            {name='sum',label='Sum',maxXp=50,calculation='sum_reputations'}},
        reputations={{name='rep',label='Reputation',skill='sum',maxXp=30,clientGain=true},
            {name='free',label='Free',skill='',maxXp=50,clientGain=false,decay={enabled=true,amount=3,intervalMs=10000}}}}
end
function R.packet(defs)
    return {token='session:1',revision=1,values={a=10,rep=5,free=10},ack={},definitions=defs or R.definitions()}
end
function R.new(ported)
    local r={trace={},cache={},time=0,exports={},events={},threads={},library={}}
    function r.record(k,...)r.trace[#r.trace+1]={kind=k,args=P.snapshot(table.pack(...))}end
    r.library.cache={set=function(k,v)r.record('cache-set',k,v);r.cache[k]=H.copy(v)end,
        get=function(k)r.record('cache-get',k);return r.cache[k]end,
        clear=function(k)r.record('cache-clear',k);r.cache[k]=nil end}
    r.native={emit=function(...)r.record('emit',...)end,emitServer=function(...)r.record('server',...);if r.send then return r.send(...)end end,
        time=function()return r.time end,wait=function(ms)r.record('wait',ms);return coroutine.yield(ms)end}
    local pe=H.environment({PRProgression={}});H.load('../pr_bridge/shared/progression.lua',pe);r.progression=pe.PRProgression
    r.config=H.load('kernel/config/forge_skills.lua',H.environment())()
    local e=H.environment()
    if ported then
        r.runtime=H.load('kernel/client/skill/runtime.lua',e)({config=r.config,library=r.library,progression=r.progression,native=r.native})
        r.exports,r.events,r.threads=r.runtime.Exports,r.runtime.Events,r.runtime.Threads
    else
        e.PRProgression=r.progression;e.PR={Skills=r.config};e.pr_lib=r.library
        e.RegisterNetEvent=function(name,handler)r.events[#r.events+1]={name=name,handler=handler,network=true}end
        e.AddEventHandler=function(name,handler)r.events[#r.events+1]={name=name,handler=handler,network=false}end
        e.TriggerEvent=r.native.emit;e.TriggerServerEvent=r.native.emitServer;e.Wait=r.native.wait;e.GetGameTimer=r.native.time
        e.CreateThread=function(fn)r.threads[#r.threads+1]=fn end
        e.exports=function(name,fn)r.exports[name]=fn end
        H.load('client/skills.lua',e)
    end
    function r.event(name,...)for _,entry in ipairs(r.events)do if entry.name==name then return entry.handler(...)end end;error('unknown test event')end
    function r.sync(packet)return r.event('forge-core:client:skills:sync',packet)end
    function r.collect()local extensions={};r.event('qbx_core:client:collectStatusExtensions',extensions);return extensions end
    function r.tick(now)
        r.time=now
        if not r.worker then r.worker=coroutine.create(r.threads[1]);assert(coroutine.resume(r.worker))end
        local ok,result=coroutine.resume(r.worker);assert(ok,result);return result
    end
    return r
end
function R.menu(ported,options)
    options=options or {}
    local ui=A.new(ported,function(r)
        r.config.Skills=H.load('kernel/config/forge_skills.lua',Q.env())()
        r.config.Skills.Callbacks.getAll='skills-get';r.config.Skills.Callbacks.fetchPlayer='skills-player'
        r.cache={}
        r.library.cache={get=function(name)r.record('cache-get',name);return r.cache[name]end}
        r.library.command=options.nativeCommand and nil or function()error('not installed in fixture')end
        if options.nativeCommand then r.library.command=nil end
    end)
    ui.menu.openSkillsMenu=nil
    local defs=R.definitions()
    ui.reply('skills-get',defs,true)
    ui.skill={name='a',label='Alpha',icon='book',maxXp=100,calculation='direct',levels={{title='One',from=0,to=10}},extra={preserve=true}}
    ui.rep={name='rep',label='Rep',icon='star',maxXp=100,skill='a',linkedSkill='a',levels={{title='RepOne',from=0,to=10}}}
    ui.reply('skills-player',true,{skills={{name='a',label='Alpha',xp=7,level={title='One',from=0,to=10,progress=7}}},
        reputations={{name='rep',skill='a',label='Rep',xp=2,level={title='One',from=0,to=10,progress=2}}}})
    ui.commands={};ui.skillCallbacks={}
    local e=H.environment()
    if ported then
        ui.skillMenu=H.load('kernel/client/menu/skills.lua',e)({menu=ui.menu,shared=ui.shared,config=ui.config,library=ui.library,native=ui.native})
        ui.commands,ui.skillCallbacks=ui.skillMenu.Commands,ui.skillMenu.Callbacks
    else
        e.ForgeCore={Client={Menu=ui.menu,MenuShared=ui.shared}};e.PR=ui.config;e.pr_lib=ui.library;e.SetTimeout=ui.native.setTimeout
        ui.library.callback.register=function(name,fn)ui.skillCallbacks[name]=fn end
        ui.library.command=options.nativeCommand and nil or function(name,props,fn)ui.commands[#ui.commands+1]={name=name,options=props,handler=fn,mode='library'}end
        if options.nativeCommand then ui.library.command=nil end
        e.RegisterCommand=function(name,fn,restricted)ui.commands[#ui.commands+1]={name=name,handler=fn,restricted=restricted,mode='native'}end
        H.load('client/menu/menu_skills.lua',e)
    end
    function ui.form(isNew,kind)
        local data={};if isNew then data[#data+1]=kind=='rep'and'new_rep'or'new_skill'end
        for _,value in ipairs({'Name','book',kind=='rep'and'__none'or'direct',123,'forge-gym','updateSkill','strength',2,true,false,true,4,20,true,10})do data[#data+1]=value end
        return data
    end
    return ui
end
function R.case(label,fn)
    local a,b=R.new(false),R.new(true)
    H.same(Q.outcome(fn,b),Q.outcome(fn,a),label..': result')
    H.same(b.trace,a.trace,label..': effects');H.same(b.cache,a.cache,label..': cache')
    H.same(b.exports.fetchSkills(),a.exports.fetchSkills(),label..': visible replica')
    H.same(b.collect(),a.collect(),label..': counters')
end
function R.menuCase(label,fn,options)
    local a,b=R.menu(false,options),R.menu(true,options)
    local function outcome(r)
        local result=table.pack(pcall(fn,r))
        if not result[1]then
            local msg=tostring(result[2])
            assert(not msg:find('assertion failed',1,true)and not msg:find('Unbound test boundary',1,true)
                and not msg:match('^[^\n]*tests/[^\n]-%.lua:'),msg)
            result[2]=msg:gsub('[^\n]-:%d+: ',''):gsub('stack traceback:[%s%S]*','')
        end
        return P.snapshot(result)
    end
    H.same(outcome(b),outcome(a),label..': result');H.same(b.trace,a.trace,label..': all effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),label..': all contexts')
    H.same(b.skill,a.skill,label..': input skill');H.same(b.rep,a.rep,label..': input reputation')
end
return R

