local T=dofile('tests/kernel_qb_shared_harness.lua');local H,P=T.H,T.P;local S={H=H,P=P,T=T}
function S.new(ported,options)
    options=options or{};local r={trace={},qbExports={},resourceExports={},tasks={},commands={},convars=options.convars or{},resourceState='missing',counts=3}
    local function rec(kind,...)r.trace[#r.trace+1]={kind,P.snapshot(table.pack(...))}end;r.rec=rec
    local player={PlayerData={source=2,citizenid='QB88'},Functions={}}
    r.player=player;r.state={Players={[2]=player},Player_Buckets={},Entity_Buckets={},UsableItems={}}
    r.jobs={taxi={label='Taxi'}};r.gangs={ballas={label='Ballas'}}
    r.object={Shared={Items={}}}
    if options.blockedItems then r.object.Shared=T.shared(true,{}).shared end
    r.core={}
    local coreNames={'Login','Logout','Save','SaveOffline','DeleteCharacter','GenerateUniqueIdentifier','GetSource','SetPlayerBucket','SetEntityBucket',
        'GetPlayersInBucket','GetEntitiesInBucket','CreateUseableItem','CanUseItem','IsWhitelisted','AddPermission','RemovePermission','HasPermission',
        'GetPermission','IsOptin','ToggleOptin','IsPlayerBanned','Notify','GetCoreVersion'}
    for _,name in ipairs(coreNames)do r.core[name]=function(...)rec('core:'..name,...);return true,'tail',nil end end
    for _,name in ipairs({'GetPlayer','GetPlayerByCitizenId','GetOfflinePlayer','GetPlayerByPhone','CreatePlayer'})do r.core[name]=function(...)rec('core:'..name,...);if not r.missing then return player end end end
    r.core.GetQBPlayers=function(...)rec('core:GetQBPlayers',...);return r.state.Players end
    r.core.GetDutyCountJob=function(...)rec('core:GetDutyCountJob',...);return 1,{2}end
    r.core.GetBucketObjects=function(...)rec('core:GetBucketObjects',...);return r.state.Player_Buckets,r.state.Entity_Buckets end
    for _,kind in ipairs({'Job','Gang'})do
        local registry=kind=='Job'and r.jobs or r.gangs
        r.core['Get'..kind]=function(name)rec('core:Get'..kind,name);return registry[name]end
        r.core['Get'..kind..'s']=function()return registry end
        r.core['Create'..kind..'s']=function(values)rec('core:Create'..kind..'s',values);for k,v in pairs(values)do registry[k]=v end end
        r.core['Remove'..kind]=function(name)rec('core:Remove'..kind,name);registry[name]=nil;return true,'removed'end
    end
    local native={}
    native.GetConvar=function(key,fallback)return r.convars[key]or fallback end
    native.GetEntityCoords=function(id)rec('coords',id);return P.vector(1,2,3)end
    native.GetEntityHeading=function(id)rec('heading',id);return 90 end
    native.vec4=P.vector
    native.GetPlayerIdentifierByType=function(src,kind)rec('identifier',src,kind);return(kind=='license2'and'license2:'or'license:')..src end
    native.GetPlayerPed=function(src)rec('ped',src);return 42 end
    native.joaat=function(v)rec('joaat',v);return 123 end
    native.CreateVehicle=function(...)rec('vehicle',...);return 200 end
    native.DoesEntityExist=function(veh)rec('exists',veh);return true end
    native.Wait=function(ms)rec('wait',ms)end
    native.GetVehiclePedIsIn=function(...)rec('inVehicle',...);return r.inVehicle or 0 end
    native.TaskWarpPedIntoVehicle=function(...)rec('warp',...);r.inVehicle=200 end
    native.NetworkGetEntityOwner=function(veh)rec('owner',veh);return 2 end
    native.NetworkGetEntityFromNetworkId=function(id)rec('entity',id);return id+2000 end
    native.NetworkGetNetworkIdFromEntity=function(id)rec('netid',id);return id-100 end
    native.GetResourceState=function(name)assert(name=='qb-inventory');return r.resourceState end
    native.CreateThread=function(fn)rec('thread');r.tasks[#r.tasks+1]=fn end
    native.DropPlayer=function(...)rec('drop',...)end
    native.GetPlayerPing=function(...)rec('ping',...);return 1 end
    native.GetPlayers=function()return{'2','7'}end
    native.GetInvokingResource=function()return 'legacy_consumer'end
    native.TriggerClientEvent=function(...)rec('client',...)end
    native.TriggerEvent=function(...)rec('server',...)end
    native.IsPlayerAceAllowed=function(...)rec('ace',...);return r.ace~=false end
    native.source=function()return r.source or 2 end
    r.lib={print={}}
    for _,level in ipairs({'warn','debug','error','info'})do r.lib.print[level]=function(...)rec('log:'..level,...)end end
    r.lib.addCommand=function(name,properties,fn)rec('command',name,properties);r.commands[name]={properties=properties,fn=fn}end
    r.lib.table={merge=function(a,b)local c=H.copy(a);for k,v in pairs(b)do c[k]=H.copy(v)end;return c end}
    r.helpers={spawnVehicle=function(...)rec('spawn',...);return 300 end,getVehiclePlate=function(...)rec('plate',...);return 'QB88'end}
    r.inventory={search=function(...)rec('inventory',...);return r.counts end}
    local function register(name,fn)assert(not r.qbExports[name],name);r.qbExports[name]=fn end
    local function export(name,fn)assert(not r.resourceExports[name],name);r.resourceExports[name]=fn end
    r.ports={core=r.core,state=r.state,object=r.object,lib=r.lib,native=native,helpers=r.helpers,inventory=r.inventory,
        createExport=register,createResourceExport=export}
    local env=H.environment();r.env=env
    if ported then
        local p=H.load('kernel/compat/qb/server_player.lua',env)(r.ports);r.Player=p.Player;r.decorate=p.Decorate;r.ports.decorate=p.Decorate
        r.Functions=H.load('kernel/compat/qb/server_functions.lua',env)(r.ports)
        r.Commands=H.load('kernel/compat/qb/server_commands.lua',env)(r.ports)
    else
        for k,v in pairs(native)do if k~='source'then env[k]=v end end
        env.QBX=r.state;env.qbCoreCompat=r.object;env.qbx=r.helpers;env.lib=r.lib
        local exports={qbx_core={},ox_inventory={Search=function(_,...)return r.inventory.search(...)end},['qb-core']={}}
        for name,fn in pairs(r.core)do exports.qbx_core[name]=function(_,...)return fn(...)end end
        setmetatable(exports,{__call=function(_,...)return export(...)end});env.exports=exports
        for _,name in ipairs({'GetJob','GetGang','CreateJobs','CreateGangs','RemoveJob','RemoveGang','DeleteCharacter'})do env[name]=r.core[name]end
        r.Player=P.loadOrigin('bridge/qb/server/player.lua',env);r.decorate=env.AddDeprecatedFunctions
        env.require=function(name)
            if name=='server.functions'then return true elseif name=='bridge.qb.server.player'then return r.Player
            elseif name=='bridge.qb.shared.export-function'then return register end;error('Unbound QB require: '..name)
        end
        r.Functions=P.loadOrigin('bridge/qb/server/functions.lua',env)
        for name,fn in pairs(r.qbExports)do exports['qb-core'][name]=function(_,...)return fn(...)end end
        r.Commands=P.loadOrigin('bridge/qb/server/commands.lua',env,P.source('bridge/qb/server/commands.lua'):gsub('argument%?%.optional','(argument and argument.optional)'))
    end
    r.object.Functions=r.Functions
    r.flush=function()local tasks=r.tasks;r.tasks={};for _,fn in ipairs(tasks)do fn()end end
    r.capture=function(fn,...)
        local result=table.pack(pcall(fn,...))
        if not result[1]then result[2]=tostring(result[2]):gsub('^.-:%d+: ','')end
        return P.snapshot(result)
    end
    return r
end
return S
