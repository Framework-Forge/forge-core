-- Installed bodies against inactive ports, with strict PR/native doubles and memory-only JSON.
local I=dofile('tests/kernel_inventory_harness.lua')
local H,P,J=I.H,I.P,I.J
local W={I=I,H=H,P=P,J=J,compile=load}
function W.config(ported,seed)
    if ported then return H.load('kernel/config/forge_weapons.lua',H.environment())(H.copy(seed))end
    local env=H.environment({PR={Weapons=H.copy(seed)}});H.load('shared/weapons.lua',env);return env.PR.Weapons
end
function W.new(ported,mode,options)
    local r={ported=ported,mode=mode,trace={},events={},callbacks={},commands={},timers={},results={},
        qbxState='started',oxState='started',manage=false,aces={[2]={['forge-core.admin']=true}},
        records={weapon_pistol={name='weapon_pistol',label='Pistol',active=true,ammotype='AMMO_PISTOL'}},
        localCatalog={},oxCatalog={},source=1}
    r.config=W.config(true);r.memory=J.persistence();r.library={}
    for k,v in pairs(r.memory.api)do r.library[k]=v end
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    function r.result(method,...)
        local result=r.results[method];if result=='throw'then error('fixture-'..method,0)end
        if result then return table.unpack(result,1,result.n)end
        return ...
    end
    r.library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    local wrap=r.library.wrapJsonMutations
    r.library.wrapJsonMutations=function(path,service,names)r.record('wrap',path,names);return wrap(path,service,names)end
    r.native={isAceAllowed=function(src,ace)r.record('ace',src,ace);return(r.aces[src]or{})[ace]or false end,
        print=function(...)r.record('print',...)end,
        setTimeout=function(ms,fn)r.record('timer',ms);r.timers[#r.timers+1]={ms=ms,fn=fn}end}
    r.translate=function(...)r.record('translate',...);return(select(1,...))end
    r.services={JobService={canManage=function(src)r.record('job-manage',src);return r.manage end}}
    r.kernel={}
    for _,method in ipairs({'CreateWeapons','RemoveWeapon','HasWeapon'})do
        r.kernel[method]=function(...)
            r.record(method,...)
            if method=='HasWeapon'then return r.result(method,true,{label='Live'},true,123)end
            local ok=r.result(method,true)
            if ok~=false then
                if method=='CreateWeapons'then for name,entry in pairs((...))do r.localCatalog[name]=H.copy(entry)end
                else r.localCatalog[(...)]=nil end
            end
            return ok
        end
    end
    r.integrations={inventoryState=function()return r.oxState end}
    for _,method in ipairs({'SetWeaponItem','DisableWeaponItem','RemoveWeaponItem','HasWeaponItem'})do
        r.integrations[method]=function(name,data,active)
            r.record(method,name,data,active)
            if method=='HasWeaponItem'then return r.result(method,true,{label='Live OX'},true,'WEAPON_PISTOL')end
            local ok=r.result(method,true)
            if ok~=false then
                if method=='RemoveWeaponItem'then r.oxCatalog[name]=nil
                else r.oxCatalog[name]=H.copy(data);r.oxCatalog[name].disabled=method=='DisableWeaponItem'or nil end
            end
            return ok
        end
    end
    if options then options(r)end
    r.memory.seed(r.config.Storage.file,r.records)
    local env=H.environment({PR={Weapons=r.config,NotifyPos='top-right'},ForgeCore=r.services,pr_lib=r.library})
    r.env=env;r.services.t=r.translate
    env.IsPlayerAceAllowed=r.native.isAceAllowed;env.print=r.native.print;env.SetTimeout=r.native.setTimeout
    env.GetResourceState=function(name)
        if name=='qbx_core'then return r.qbxState end
        assert(name=='ox_inventory');return r.oxState
    end
    env.exports={qbx_core={},ox_inventory={}}
    for name,fn in pairs(r.kernel)do env.exports.qbx_core[name]=function(_,...)return fn(...)end end
    for name,fn in pairs(r.integrations)do if name~='inventoryState'then env.exports.ox_inventory[name]=function(_,...)return fn(...)end end end
    env.AddEventHandler=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=false}end
    env.RegisterCommand=function(name,fn,restricted)r.commands[#r.commands+1]={name=name,handler=fn,restricted=restricted}end
    r.services.Callbacks={register=function(name,fn)r.callbacks[#r.callbacks+1]={name=name,handler=fn}end}
    local function loadModule(file)
        if ported then
            return H.load('kernel/server/weapon/'..file..'.lua',H.environment())({
                config=r.config,library=r.library,services=r.services,native=r.native,translate=r.translate,
                kernel=r.kernel,integrations=r.integrations,resource='forge-core',notifyPosition='top-right',
                isReady=function()return r.qbxState:find('start')~=nil end})
        end
        H.load('server/weapon/'..(file=='projection'and'qbx_sync'or file)..'.lua',env)
        local keys={registry='WeaponRegistry',storage='WeaponStorage',projection='WeaponQbxSync',ox_sync='WeaponOxSync',service='WeaponService'}
        return keys[file]and r.services[keys[file]]or nil
    end
    r.services.WeaponRegistry=loadModule('registry')
    r.services.WeaponStorage=loadModule('storage')
    if mode=='projection'or mode=='ox_sync'then
        r.services.WeaponRegistry={
            getWeapons=function()r.record('get-all');return H.copy(r.records)end,
            getActiveWeapons=function()
                r.record('get-active');local active={};for name,entry in pairs(r.records)do if entry.active~=false then active[name]=H.copy(entry)end end;return active end}
        r.api=loadModule(mode)
    elseif mode=='registry'then r.api=r.services.WeaponRegistry
    elseif mode=='storage'then r.api=r.services.WeaponStorage
    else
        r.services.WeaponQbxSync={syncAll=function()r.record('project');return r.result('project',true)end}
        r.services.WeaponOxSync={syncAll=function()r.record('ox-sync');return r.result('ox-sync',true)end}
        r.api=loadModule('service')
        if ported then
            r.events=r.api.Events
            assert(#r.trace==0 and #r.memory.trace==0,'constructor must not wrap/load/save/project/register')
            if not r.noInit then assert(r.api.Initialize());assert(not r.api.Initialize())end
        end
        r.services.WeaponService=r.api
        if mode=='transport'then
            local callbacks=loadModule('callbacks');local commands=loadModule('commands')
            if ported then r.callbacks,r.commands=callbacks,commands end
        end
    end
    function r.dispatch(resource)
        for _,e in ipairs(r.events)do e.handler(ported and resource=='qbx_core'and'forge-core'or resource)end
    end
    function r.runTimers()local list=r.timers;r.timers={};for _,v in ipairs(list)do v.fn()end end
    function r.callback(index,...)return assert(r.callbacks[index]).handler(...)end
    function r.command(index,src,args)return assert(r.commands[index]).handler(src,args)end
    function r.state()
        local reg=r.services.WeaponRegistry or {}
        return P.snapshot({weapons=reg.weapons,revision=reg.revision,started=r.api.started,tracking=r.api.registeredWeapons,
            files=r.memory.files,localCatalog=r.localCatalog,oxCatalog=r.oxCatalog})
    end
    return r
end
function W.pair(mode,options)
    local a,b=W.new(false,mode,options),W.new(true,mode,options)
    local p={a=a,b=b,count=0}
    function p.run(label,fn)
        local function run(r)local out=table.pack(pcall(fn,r));assert(out[1],label..': unexpected test error '..tostring(out[2]));return P.snapshot(out)end
        H.same(run(b),run(a),label..': returns')
        H.same(b.trace,a.trace,label..': effects');H.same(b.memory.trace,a.memory.trace,label..': persistence')
        H.same(b.state(),a.state(),label..': state');p.count=p.count+1
    end
    return p
end
function W.compose(base,ports)
    local env=H.environment()
    env.require=function(name)
        assert(name=='kernel.config.forge_weapons'or name:match('^kernel%.server%.weapon%.'))
        return H.load(name:gsub('%.','/')..'.lua',H.environment())
    end
    return H.load('kernel/server/weapon/weapon_core.lua',env)(base,ports)
end
-- Exact installed OX client update and disarm helper bodies, not the complete inventory client.
function W.oxClient()
    local r={items={},events={},current=nil,disarms=0}
    local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('a'):gsub('\r\n','\n');f:close();return s end
    local items=read('../../../[ox]/ox_inventory/modules/items/client.lua')
    local i,j=assert(items:find('local function setForgeWeaponItem',1,true)),assert(items:find('local function splitExportName',1,true))
    local body=items:sub(i,j-1):gsub('Items%[name%]%?%.([%w_]+)','(Items[name] and Items[name].%1)')
    local env=H.environment({Items=r.items,originalWeaponItems={},cloneItem=H.copy,joaat=function(name)return #name end,
        RegisterNetEvent=function(name,fn)r.events[name]=r.events[name]or{};table.insert(r.events[name],fn)end})
    assert(W.compile(body,'@installed_ox_client_item_helpers','t',env))()
    local full=read('../../../[ox]/ox_inventory/client.lua')
    local first,last=assert(full:find('local function disarmDisabledForgeWeapon',1,true)),assert(full:find('local StashTarget',1,true))
    local disarm='local currentWeapon\n'..full:sub(first,last-1)..'\nreturn function(value)currentWeapon=value end,function()return currentWeapon end'
    env.Weapon={Disarm=function(current,noAnim)assert(current and noAnim==true);r.disarms=r.disarms+1;return nil end}
    r.equip,r.currentWeapon=assert(W.compile(disarm,'@installed_ox_disarm_helpers','t',env))()
    function r.emit(name,...)for _,fn in ipairs(r.events[name]or{})do fn(...)end end
    return r
end
return W
