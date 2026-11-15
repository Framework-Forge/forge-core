-- Exact installed bodies vs factories. Local services/providers doubled here; composition tests use real core/PR services.
local S=dofile('tests/kernel_stores_harness.lua');local H,P,V=S.H,S.P,S.V
local R={S=S,H=H,P=P,V=V,env=S.env}
function R.config(ported)
    local e=H.environment({PR={}})
    if ported then return{Player=H.load('kernel/config/forge_player.lua',R.env())(),PlayerManagement=H.load('kernel/config/forge_player_management.lua',R.env())()}end
    H.load('shared/player.lua',e);H.load('shared/player_management.lua',e);return e.PR
end
function R.new(ported)
    local r={trace={},handlers={},events={},pluginDescriptors={},timerQueue={},registrations={},calls={},manage=true,resource='started',version='2.0',registerResult=true}
    function r.record(k,...)r.trace[#r.trace+1]={kind=k,args=P.snapshot(table.pack(...))}end
    r.config=R.config(ported);r.config.AdminAce='forge-core.admin'
    r.config.Staff=H.load('kernel/config/forge_staff.lua',R.env())('forge-core.admin')
    r.config.Weather=H.load('kernel/config/forge_weather.lua',R.env())()
    r.translate=function(k,p)r.record('translate',k,p);return k end
    r.clock={date=function(fmt,time)if fmt=='*t'then return{year=2026,month=10,day=22}end;return os.date(fmt,time or 1792638000)end}
    r.players={[1]={PlayerData={source=1,citizenid='CID1',license='license:one',charinfo={firstname='One',lastname='Player',birthdate='2000-10-22',nationality='Brazil',phone='123'},
        job={name='police',label='Police',grade={level=2,name='Sergeant'}},gang={name='none',grade=0},money={cash=10,bank=20},metadata={hunger=80,thirst=70}}},
        [2]={PlayerData={source=2,citizenid='CID2',charinfo={firstname='Two',lastname='Admin'},metadata={},job={},gang={}}}}
    r.lookup={GetPlayer=function(src)r.record('lookup',src);return r.players[tonumber(src)]end}
    r.online={'2','missing','1'};r.vips={};r.prisons={};r.wl={players={{citizenid='CID1',whitelisted=true}}};r.wlOk=true
    r.jobs={police={label='Police',grades={[2]={name='Sergeant'},[0]={name='Recruit'}}},unemployed={label='Unemployed',grades={[0]={name='Civilian'}}}}
    local function delegate(service,name,...)
        r.record('service',service,name,...);r.calls[#r.calls+1]={service,name,P.snapshot(table.pack(...))}
        if r.serviceError then error('fixture-service',0)end
        return r.actionResult~=false,r.actionPayload or{from=service,method=name}
    end
    r.services={JobService={started=true,canManage=function(src)r.record('can-manage',src);return r.manage end},JobRegistry={getJobs=function()r.record('jobs');return r.jobs end},
        VipService={get=function(src)r.record('vip',src);return r.vips[tonumber(src)]end},
        MultiJobService={getPlayerJobs=function(src)r.record('multi-jobs',src);return r.multiOk~=false,r.multiPayload or{jobs={{name='police',grade=2}}}end},
        PrisonService={status=function(src)r.record('prison',src);return r.prisons[src]or{enabled=true,jailed=false}end},
        WhitelistService={canManage=function()return r.manage end,
            listPlayers=function(src)r.record('whitelist-list',src);return r.wlOk,r.wl end,
            getPlayerRecord=function(src,cid)r.record('whitelist-record',src,cid);return r.wlOk,r.wlRecord end,
            getConfig=function()r.record('whitelist-config');return{enabled=true}end}}
    local methods={AfkService={'getSettings','save'},DensityService={'getSettings','save'},JobService={'getPayload','start','upsert','delete','createMei'},
        JobPayments={'update','updateMei','force'},PasswordService={'getSafeSettings','save'},SkillService={'getPayload','upsertSkill','deleteSkill','upsertReputation','deleteReputation'},
        StaffService={'list','add','remove'},WeaponService={'getPayload','upsert','delete','setActive'},WeatherService={'getState','setWeather','setDuration','addWeather','removeWeather','setTime','setTimeScale','setFreezeTime'},
        WhitelistService={'saveConfig','add','remove','ban'},PrisonService={'setSentence','release'}}
    for service,names in pairs(methods)do
        r.services[service]=r.services[service]or{}
        r.services[service].canManage=r.services[service].canManage or function(src)r.record('can-manage',src);return r.manage end
        for _,name in ipairs(names)do r.services[service][name]=function(...)return delegate(service,name,...)end end
    end
    r.services.JobService.start=function()r.record('job-start');r.services.JobService.started=true;return true end
    r.services.WeatherService.getState=function(src)r.record('weather-state',src);return r.weatherOk~=false,r.weather or{currentWeather={weather='CLEAR',time=10},currentTime={hour=12,minute=30}}end
    r.native={GetPlayers=function()r.record('get-players');return r.online end,GetPlayerName=function(src)r.record('native-name',src);return'Native '..tostring(src)end,
        GetCurrentResourceName=function()return'forge-core'end,GetResourceMetadata=function(...)r.record('version',...);return r.version end,
        SetTimeout=function(delay,fn)r.record('timer',delay);r.timerQueue[#r.timerQueue+1]={delay=delay,fn=fn}end}
    r.managementIntegration={resourceState=function()r.record('management-state');return r.resource end,
        registerPlugin=function(data)r.record('register-plugin',data);r.registrations[#r.registrations+1]=data.id
            if r.registerError then error('fixture-plugin-register',0)end
            if r.registerResult then r.pluginDescriptors[data.id]=H.copy(data)end;return r.registerResult,'fixture-rejection'end,
        unregisterPlugin=function(id)r.record('unregister-plugin',id);r.pluginDescriptors[id]=nil;return r.unregisterResult end}
    r.print=function(...)r.record('print',...)end
    if ported then
        local ports={config=r.config,services=r.services,lookup=r.lookup,native=r.native,clock=r.clock,translate=r.translate,
            managementIntegration=r.managementIntegration,print=r.print}
        r.service=H.load('kernel/server/player_management.lua',R.env())(ports);r.services.PlayerManagementService=r.service
        local info=H.load('kernel/server/player_info.lua',R.env())(ports)
        local callbacks=H.load('kernel/server/player_management_callbacks.lua',R.env())(ports)
        r.plugins=H.load('kernel/server/plugins.lua',R.env())(ports)
        r.descriptors={};for _,list in ipairs({info,callbacks,r.plugins.Callbacks})do for _,d in ipairs(list)do r.descriptors[#r.descriptors+1]=d;r.handlers[d.name]=d.handler end end
        r.events=r.plugins.Events
    else
        local e=H.environment({PR=r.config,ForgeCore=r.services,os=r.clock,print=r.print})
        r.services.t=r.translate;r.services.Callbacks={register=function(n,fn,opts)r.handlers[n]=fn end}
        for n,fn in pairs(r.native)do e[n]=fn end
        e.GetResourceState=function(name)assert(name=='forge-management');return r.managementIntegration.resourceState()end
        e.exports={qbx_core={GetPlayer=function(_,src)return r.lookup.GetPlayer(src)end},['forge-management']={
            RegisterPlugin=function(_,data)return r.managementIntegration.registerPlugin(data)end,
            UnregisterPlugin=function(_,id)return r.managementIntegration.unregisterPlugin(id)end}}
        e.AddEventHandler=function(n,fn)r.events[#r.events+1]={name=n,handler=fn,network=false}end
        H.load('server/player/management.lua',e);H.load('server/player/callbacks.lua',e);H.load('server/player/management_callbacks.lua',e);H.load('server/plugins.lua',e)
        r.service=r.services.PlayerManagementService
    end
    assert(#r.events==3 and #r.timerQueue==0 and #r.registrations==0,'inert plugin constructor')
    function r.info(src)return r.handlers[r.config.Player.Callbacks.getInfo](src or 1)end
    function r.pluginLoad(module,src)return r.handlers['forge-core:server:plugin:load'](src or 2,module)end
    function r.pluginAction(module,action,payload,src)return r.handlers['forge-core:server:plugin:action'](src or 2,module,action,payload)end
    function r.fire(n,...)for _,d in ipairs(r.events)do if d.name==n then d.handler(...)end end end
    function r.runTimers()local q=r.timerQueue;r.timerQueue={};for _,task in ipairs(q)do assert(task.delay==500);task.fn()end end
    r.trace={};return r
end
function R.case(name,fn)
    local a,b=R.new(false),R.new(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot({b.players,b.pluginDescriptors,#b.timerQueue}),P.snapshot({a.players,a.pluginDescriptors,#a.timerQueue}),name..' state')
end
function R.menu(ported)
    local r=S.menu(ported);local cfg=R.config(ported);r.config.Player,r.config.PlayerManagement=cfg.Player,cfg.PlayerManagement
    local fixture=R.new(true);r.config.Staff=fixture.config.Staff
    r.config.CharacterSlots=r.config.CharacterSlots or{}
    r.config.CharacterSlots.playerCallbacks=r.config.CharacterSlots.playerCallbacks or{logout='forge-core:server:characterSlots:logout'}
    r.config.Inventory=r.config.Inventory or{Callbacks={getGiveCatalog='forge-core:server:inventory:giveCatalog',give='forge-core:server:inventory:give'}}
    r.config.Vehicles=r.config.Vehicles or{Callbacks={adminCarCurrent='forge-core:server:vehicles:adminCarCurrent'}}
    r.config.MultiJob=r.config.MultiJob or{Callbacks={addJob='forge-core:server:multijob:addJob',removeJob='forge-core:server:multijob:removeJob'}}
    local _,detail=fixture.service.details(2,1);r.detail=detail;r.list={select(2,fixture.service.list(2))[1]}
    r.detail.staffPermissions={'admin'};r.detail.staffRole='admin';r.detail.whitelist={whitelisted=true,answers={One={value='Answer',correct=false}}}
    r.detail.jobs={{name='police',label='Police',gradeLabel='Sergeant',payment=100,active=true}}
    r.personalInfo=select(2,fixture.info(1));r.catalog={{token='item:burger',kind='item',name='burger',label='Burger'},{token='weapon:pistol',kind='weapon',name='weapon_pistol',label='Pistol'}}
    r.staffCatalog={{value='admin',label='Admin'},{value='moderator',label='Moderator'}}
    local parent=r.library.callback.await
    local tracked={};for _,v in pairs(r.config.PlayerManagement.Callbacks)do tracked[v]=true end
    for _,module in ipairs({'Player','Staff','Inventory','Vehicles','MultiJob'})do for _,v in pairs(r.config[module].Callbacks or{})do tracked[v]=true end end
    tracked[r.config.CharacterSlots.playerCallbacks.logout]=true
    r.library.callback.await=function(name,timeout,...)
        if not tracked[name]then return parent(name,timeout,...)end
        r.record('player-rpc',name,timeout,...)
        if r.rpcHook then return r.rpcHook(name,...)end
        if name==r.config.PlayerManagement.Callbacks.list then return true,H.copy(r.list)end
        if name==r.config.PlayerManagement.Callbacks.details then return true,H.copy(r.detail)end
        if name==r.config.Player.Callbacks.getInfo then return true,H.copy(r.personalInfo)end
        if name==r.config.Inventory.Callbacks.getGiveCatalog then return true,H.copy(r.catalog)end
        if name==r.config.Staff.Callbacks.catalog then return true,H.copy(r.staffCatalog)end
        return true,{}
    end
    for _,method in ipairs({'openPlayerCharacterSlots','openPlayerVipAdmin','openCharacterCreationSettings','openVipClassesMenu','openMultiJobMenu','openPlayerSkillsMenu'})do
        r.menu[method]=function(...)r.record('menu-route',method,...)end
    end
    if ported then
        local ports={config=r.config,menu=r.menu,shared=r.shared,native=r.native,library=r.library}
        H.load('kernel/client/menu/prison.lua',R.env())(ports)
        H.load('kernel/client/menu/player.lua',R.env())(ports);H.load('kernel/client/menu/players.lua',R.env())(ports)
    else H.load('client/menu/menu_prison.lua',r.env);H.load('client/menu/menu_player.lua',r.env);H.load('client/menu/menu_players.lua',r.env)end
    r.trace={};return r
end
function R.menuCase(name,fn)
    local a,b=R.menu(false),R.menu(true)
    H.same(V.outcome(fn,b),V.outcome(fn,a),name..' returns');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' contexts')
end
return R
