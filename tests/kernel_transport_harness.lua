-- Isolated installed-vs-port boundaries; no real callback/command/export/network/SQL registration.
local B=dofile('tests/kernel_business_harness.lua')
local H,P,J=B.H,B.P,B.J
local T={H=H,P=P,J=J,B=B}
function T.helpers()
    local env=H.environment({PRCore={}})
    env.PRCore.load=function(path)
        assert(path=='@pr_bridge/bridge/runtime/compat_services')
        return H.load('../pr_bridge/bridge/runtime/compat_services.lua',env)
    end
    return H.load('../pr_bridge/bridge/compat/framework/helpers.lua',env)
end
local original={security='server/callback_security.lua',callbacks='server/job/callbacks.lua',commands='server/job/commands.lua',compat='server/compat.lua'}
local private={security='kernel/server/callback_security.lua',callbacks='kernel/server/jobs/callbacks.lua',commands='kernel/server/jobs/commands.lua',compat='kernel/server/compat.lua'}
function T.new(ported,mode,options)
    local r={trace={},handlers={},callbacks={},commands={},events={},exports={},results={},now=1000,ping=50,
        source=1,allow=true,nativeAce=true,principal=true,caller='pr_bridge',save=true,reload=true,sync=true,
        jobs={taxi={label='Taxi',type='civ',defaultDuty=false,offDutyPay=true,grades={['0']={name='Driver',payment=50,isboss=false}}}},
        registry={jobs={taxi={name='taxi',stashes={{password='kept'}},owner='A'}}},itemDefs={water={},bread={}}}
    r.config={Job=J.config(true).config,AdminAce='fixture.admin',NotifyPos='top-right',Command='forgecore'}
    local codec=J.persistence().codec
    r.json={encode=function(value)
        if r.encodeError then error('fixture-codec',0)end
        if r.bytes then return string.rep('x',r.bytes)end
        return codec.encode(value)
    end}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    function r.result(name,...)
        local value=r.results[name];if value=='throw'then error('fixture-'..name,0)end
        if value then return table.unpack(value,1,value.n)end;return ...
    end
    r.player={PlayerData={source=1,citizenid='A',metadata={}},Functions={}}
    r.player.Functions.SetMetaData=function(k,v)r.record('metadata',k,v);r.player.PlayerData.metadata[k]=v end
    r.player.Functions.Save=function()r.record('save-player');return r.result('Save',true)end
    r.payload={jobs={{name='taxi',stashes={{password='fixture-secret',webhook='fixture://secret'}}}},gangs={},revision=1}
    local job={started=false,
        canManage=function(src)r.record('manage',src);return r.result('canManage',r.allow)end,
        start=function()r.record('start');r.services.JobService.started=true;return r.result('start',true)end,
        getPayload=function()r.record('payload');return r.result('getPayload',H.copy(r.payload))end,
        sendTo=function(...)r.record('sendTo',...);return r.result('sendTo')end,
        broadcast=function(...)r.record('broadcast',...);return r.result('broadcast')end,
        reload=function()r.record('reload');return r.result('reload',r.reload)end,
        upsert=function(src,group,kind)
            r.record('upsert',src,group,kind)
            if r.save then
                r.registry.jobs[group.name]=H.copy(group)
                if r.sync then r.jobs[group.name]={label=group.label,type=group.jobtype,grades=H.copy(group.grades)}end
            end
            return r.result('upsert',r.save,H.copy(group))
        end}
    for _,name in ipairs({'delete','createMei'})do job[name]=function(...)r.record(name,...);return r.result(name,true,{name='fixture'})end end
    local payments={};for _,name in ipairs({'update','force','updateMei'})do payments[name]=function(...)r.record(name,...);return r.result(name,true,{paid=1})end end
    local points={};for _,name in ipairs({'openStash','toggleDuty'})do points[name]=function(...)r.record(name,...);return r.result(name,true,'done',nil,4)end end
    local business={};for _,name in ipairs({'getRegisterBalance','registerAction','robRegister','openShop','getSupplyItems','supplyShop','sendAlarm','submitApplication','getApplications','reviewApplication','getEmployees','hirePlayer','fireEmployee','setEmployeeGrade'})do
        business[name]=function(...)r.record(name,...);return r.result(name,true,'done',nil,4)end
    end
    r.services={JobService=job,JobRegistry=r.registry,JobPayments=payments,JobPoints=points,JobBusiness=business,
        InventoryService={addCompatibilityItems=function(...)r.record('add-items',...);return r.result('addCompatibilityItems',true,2)end,
            reload=function()r.record('reload-items');return r.result('reloadItems',true)end}}
    r.kernel={GetJobs=function()r.record('jobs');return r.jobs end,
        GetPlayer=function(src)r.record('player',src);return r.result('GetPlayer',src==1 and r.player or nil)end}
    r.native={getGameTimer=function()r.record('clock');return r.now end,
        getPlayerPing=function(src)r.record('ping',src);return r.ping end,
        isPlayerAceAllowed=function(...)r.record('native-ace',...);return r.result('nativeAce',r.nativeAce)end,
        getInvokingResource=function()r.record('caller');return r.caller end,
        isPrincipalAceAllowed=function(...)r.record('principal',...);return r.result('principal',r.principal)end,
        getSource=function()return r.source end,print=function(...)r.record('print',...)end}
    local function register(name,handler)r.record('callback-register',name);r.handlers[name]=handler;return r.result('register')end
    local function command(name,props,handler)r.commands[#r.commands+1]={name=name,options=props,handler=handler,mode='library'}end
    r.library={callback={register=register,await=function(...)r.record('await',...);return r.result('await',nil,'timeout')end},command=command,
        debug={info=function(...)r.record('info',...)end},
        notify={NotifyPlayer=function(...)r.record('notify',...)end},
        inventory={Items=function()r.record('items');return r.result('Items',r.itemDefs)end}}
    r.library.callback.awaitClient=r.library.callback.await
    local helpers=T.helpers()
    r.library.load=function(path)r.record('helper-load',path);assert(path=='@pr_bridge/bridge/frameworks/compat_helpers');return helpers end
    r.translate=function(key,args)r.record('translate',key,args);return key end
    if options then options(r)end
    local env=H.environment()
    if ported then
        r.api=H.load(private[mode],env)({services=r.services,library=r.library,config=mode=='callbacks'and r.config.Job or r.config,
            native=r.native,kernel=r.kernel,json=r.json,translate=r.translate,time=function()return 1000 end})
        if mode=='callbacks'then r.callbacks=r.api elseif mode=='commands'then r.commands=r.api.Commands
        elseif mode=='security'then r.events=r.api.Events else r.exports=r.api.Exports end
    else
        env.ForgeCore=r.services;r.services.t=r.translate;env.PR=r.config;env.pr_lib=r.library;env.json=r.json
        env.GetGameTimer=r.native.getGameTimer;env.GetPlayerPing=r.native.getPlayerPing;env.IsPlayerAceAllowed=r.native.isPlayerAceAllowed
        env.GetInvokingResource=r.native.getInvokingResource;env.IsPrincipalAceAllowed=r.native.isPrincipalAceAllowed
        env.os={time=function()return 1000 end};env.print=r.native.print
        env.AddEventHandler=function(name,handler)r.events[#r.events+1]={name=name,handler=handler,network=false}end
        env.RegisterCommand=function(name,handler,restricted)r.commands[#r.commands+1]={name=name,handler=handler,restricted=restricted,mode='native'}end
        if mode=='compat'then env.exports=setmetatable({qbx_core={GetJobs=function()return r.kernel.GetJobs()end,
            GetPlayer=function(_,src)return r.kernel.GetPlayer(src)end},ox_inventory={Items=function()return r.library.inventory.Items()end}},
            {__call=function(_,name,handler)r.exports[name]=handler end})end
        if mode=='callbacks'then r.services.Callbacks={register=function(name,handler,opts)r.callbacks[#r.callbacks+1]={name=name,handler=handler,options=opts}end}end
        H.load(original[mode],env)
        r.api=mode=='security'and r.services.Callbacks or mode=='compat'and r.exports or mode=='callbacks'and r.callbacks or r.commands
        if mode=='security'then r.api.isPlayerAceAllowed=r.services.isPlayerAceAllowed;r.api.Events=r.events end
    end
    r.env=env
    function r.dispatch(name,src)r.source=src;env.source=src;for _,e in ipairs(r.events)do if e.name==name then e.handler()end end end
    function r.callback(key,...)
        local name=r.config.Job.Callbacks[key];for _,v in ipairs(r.callbacks)do if v.name==name then return v.handler(...)end end;error('Missing callback '..key)
    end
    return r
end
function T.message(errorValue)return tostring(errorValue):gsub('^.-:%d+: ','')end
function T.case(mode,label,action,options)
    local a,b=T.new(false,mode,options),T.new(true,mode,options)
    local function run(r)local out=table.pack(pcall(action,r));assert(out[1],label..': unexpected test error: '..T.message(out[2]));return P.snapshot(out)end
    H.same(run(b),run(a),label..': returns');H.same(b.trace,a.trace,label..': effects')
    local function state(r)return P.snapshot({registrations=r.api.registrations,buckets=r.api.buckets,jobs=r.jobs,registry=r.registry,
        player=r.player,started=r.services.JobService and r.services.JobService.started,callbacks=r.callbacks,commands=r.commands,events=r.events,exports=r.exports})end
    H.same(state(b),state(a),label..': state/descriptors')
end
function T.compose(base,ports)
    return H.load('kernel/server/jobs/transport_core.lua',H.environment({require=function(name)
        assert(name=='kernel.server.callback_security'or name=='kernel.server.jobs.callbacks'or name=='kernel.server.jobs.commands'or name=='kernel.server.compat')
        return H.load(name:gsub('%.','/')..'.lua',H.environment())
    end}))(base,ports)
end
return T
