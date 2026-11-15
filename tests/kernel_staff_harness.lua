-- Test-only full installed staff sources vs private factories. No host ACL/DB/file writes.
local N=dofile('tests/kernel_multijob_harness.lua')
local H,P,J,A=N.H,N.P,N.J,N.A
local Q={H=H,P=P,J=J,A=A,N=N,count=0}
Q.env=N.env
function Q.config(ported,adminAce)
    if ported then return H.load('kernel/config/forge_staff.lua',H.environment())(adminAce)end
    local e=H.environment({PR={AdminAce=adminAce}});H.load('shared/staff.lua',e);return e.PR.Staff
end
-- Deliberately simulated platform graph, not a replacement for real FXServer ACE verification.
function Q.graph(r)
    r.parents,r.aces={},{}
    local function raw(principal,permission,visited)
        visited=visited or{}
        if visited[principal]then return nil end
        visited[principal]=true
        local allowed
        for key,value in pairs(r.aces[principal]or{})do
            if permission==key or permission:sub(1,#key+1)==key..'.'then
                if value==false then return false end
                if value then allowed=true end
            end
        end
        for parent in pairs(r.parents[principal]or{})do
            local value=raw(parent,permission,visited)
            if value==false then return false end
            if value then allowed=true end
        end
        return allowed
    end
    local function playerAllowed(src,permission)
        local value=raw('player.'..tostring(src),permission)
        if value==false then return false end
        for _,id in ipairs((r.ids or{})[tonumber(src)]or{})do
            local answer=raw('identifier.'..id,permission)
            if answer==false then return false end
            if answer then value=true end
        end
        return value==true
    end
    r.rawAllowed=function(principal,permission)return raw(principal,permission)==true end
    r.allowed=playerAllowed
    r.native={
        principalAllowed=function(principal,permission)
            r.record('principal',principal,permission)
            if r.principalError then error('principal-error',0)end
            local answer=r.rawAllowed(principal,permission)
            if answer and r.numericAce then return 1 end
            return answer
        end,
        playerAllowed=function(src,permission)
            r.record('player-ace',src,permission)
            if r.playerAceError then error('player-ace-error',0)end
            local answer=playerAllowed(src,permission)
            if answer and r.numericAce then return 1 end
            return answer
        end,
        identifiers=function(src)r.record('identifiers',src);if r.identifierError then error('identifier-error',0)end;return r.ids[tonumber(src)]or{}end,
        execute=function(command)
            r.record('execute',command)
            if r.executeHook then r.executeHook(command)end
            if r.executeError then error('execute-error',0)end
            if r.ignoreExecute then return end
            local action,principal,value,decision=command:match('^(%S+) (%S+) (%S+) ?(%S*)$')
            assert(action and principal and value,'graph command parse')
            if action=='add_principal'then r.parents[principal]=r.parents[principal]or{};r.parents[principal][value]=true
            elseif action=='remove_principal'then if r.parents[principal]then r.parents[principal][value]=nil end
            elseif action=='add_ace'then r.aces[principal]=r.aces[principal]or{};r.aces[principal][value]=decision~='deny'
            elseif action=='remove_ace'then if r.aces[principal]then r.aces[principal][value]=nil end
            else error('Unexpected simulated ACL command')end
        end,
        emitClient=function(...)r.record('client',...)end,emit=function(...)r.record('server',...)end,
        setTimeout=function(ms,fn)r.record('timer',ms);r.timers[#r.timers+1]={ms=ms,fn=fn}end,
        getPlayers=function()r.record('players');return r.online end,
        print=function(...)r.record('print',...)end,
    }
end
function Q.aceProvider(r,lookup)
    local e=H.environment({
        GetPlayerIdentifiers=r.native.identifiers,IsPrincipalAceAllowed=r.native.principalAllowed,
        IsPlayerAceAllowed=r.native.playerAllowed,ExecuteCommand=r.native.execute,
        GetConvar=function(name)
            r.record('convar',name)
            if name=='pr_bridge:admin'then return r.adminConvar or''end
            if name=='pr_bridge:ace:catalog'then return r.catalogConvar or''end
            return''
        end,
        GetCurrentResourceName=function()return'pr_bridge'end,
        GetResourcePath=function()return'E:/fixture/resources/pr_bridge'end,
        PRCore={callback={register=function(name,fn)r.prCallbacks[name]=fn end}},
        Bridge={framework={
            GetIdentifier=function(src)
                if r.forbidLookup then error('forbidden active framework adapter',0)end
                r.record('identity',src);local p=lookup.GetPlayer(src);return p and p.PlayerData.citizenid
            end,
            GetPlayer=function(src)
                if r.forbidLookup then error('forbidden active framework adapter',0)end
                return lookup.GetPlayer(src)
            end,
        }},
        io={open=function(path,mode)
            assert(mode=='r');r.record('config-open',path)
            local lines=r.configFiles[path:gsub('^E:/fixture/','')]
            if not lines then return nil end
            local file={}
            function file:lines()local i=0;return function()i=i+1;return lines[i]end end
            function file:close()r.record('config-close',path)end
            return file
        end},
    })
    return H.load('../pr_bridge/bridge/ace/server.lua',e)
end
function Q.new(ported,options)
    local r={trace={},timers={},rows={{citizenid='ONE'},{citizenid='TWO'},{citizenid='OFF'},{citizenid='MISSING'}},
        ids={[1]={'license:one','license:one','license2:second','fivem:1','discord:one','ip:skip'},[2]={'license:two'}},
        configFiles={},prCallbacks={},online={'1','2'},offline={},players={},saved={},manage={[2]=true},
        metadataResult=nil,saveResult=true,offlineResult=true}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    r.config=Q.config(ported)
    Q.graph(r)
    -- Explicit preconfigured platform fixture, not grants made by the service under test.
    for _,principal in ipairs({'group.admin','group.mod','group.staff','group.support'})do
        r.aces[principal]={[principal]=true}
    end
    local function makePlayer(src,cid,role)
        local p={PlayerData={source=src,citizenid=cid,charinfo={firstname=cid,lastname='Fixture'},metadata={staff=role}}}
        p.Functions={SetMetaData=function(key,value)
            r.record('metadata',src,cid,key,value);if r.metadataHook then r.metadataHook(p,key,value)end
            if r.metadataError then error('metadata-error',0)end
            if not r.skipMetadata then p.PlayerData.metadata[key]=value end
            return r.metadataResult
        end,Save=function()
            r.record('save',src,cid)
            if r.saveHook then r.saveHook(p)end
            if r.saveError then error('save-error',0)end
            r.saved[cid]=H.copy(p.PlayerData);return r.saveResult
        end}
        return p
    end
    r.players[1]=makePlayer(1,'ONE')
    r.players[2]=makePlayer(2,'TWO','group.admin')
    r.offline.OFF=makePlayer(nil,'OFF','group.support')
    r.kernel={
        GetPlayer=function(src)r.record('player',src);if r.lookupError then error('lookup-error',0)end;return r.players[tonumber(src)]end,
        GetPlayerByCitizenId=function(cid)r.record('online-cid',cid);if r.lookupError then error('lookup-error',0)end;for _,p in pairs(r.players)do if p.PlayerData.citizenid==cid then return p end end end,
        GetOfflinePlayer=function(cid)r.record('offline-cid',cid);if r.offlineHook then r.offlineHook(cid)end;if r.offlineError then error('offline-error',0)end;return r.offline[cid]end,
        SaveOffline=function(data)
            r.record('save-offline',data)
            if r.offlineSaveError then error('offline-save-error',0)end
            if r.offlineSaveHook then r.offlineSaveHook(data)end
            if r.offlineResult~=false then r.saved[data.citizenid]=H.copy(data)end
            return r.offlineResult
        end,
    }
    r.library={debug={},notify={NotifyPlayer=function(...)r.record('notify',...)end},
        db={query=function(sql)r.record('query',sql);if r.queryHook then r.queryHook()end;if r.queryError then error('query-error',0)end;return r.rows end}}
    for _,level in ipairs({'success','info','error'})do r.library.debug[level]=function(...)r.record('log-'..level,...)end end
    r.translate=function(key,args)r.record('translate',key,args);return key end
    r.jobService={canManage=function(src)r.record('canManage',src);if r.manageError then error('manage-error',0)end;return r.manage[src]end}
    if options then options(r)end
    r.ace=r.aceDisabled and nil or Q.aceProvider(r,r.kernel)
    if r.aceDisabled then r.ace=nil end
    if r.aceOverride then r.ace=r.aceOverride end
    r.library.ace=r.ace
    local e=H.environment()
    if ported then
        r.api=H.load('kernel/server/staff/service.lua',e)({config=r.config,services={JobService=r.jobService},library=r.library,
            kernel=r.kernel,native=r.native,ace=r.ace,translate=r.translate,notifyPosition='top-right'})
    else
        e.ForgeCore={JobService=r.jobService,t=r.translate};e.PR={Staff=r.config,NotifyPos='top-right'};e.pr_lib=r.library
        local qbx={};for name,fn in pairs(r.kernel)do qbx[name]=function(_,...)return fn(...)end end;e.exports={qbx_core=qbx}
        for source,port in pairs({IsPrincipalAceAllowed='principalAllowed',IsPlayerAceAllowed='playerAllowed',GetPlayerIdentifiers='identifiers',
            ExecuteCommand='execute',TriggerClientEvent='emitClient',TriggerEvent='emit',SetTimeout='setTimeout',GetPlayers='getPlayers'})do e[source]=r.native[port]end
        H.load('server/staff/service.lua',e);r.api=e.ForgeCore.StaffService
    end
    assert(#r.trace==0,'no automatic ACL/query/timer start')
    function r.runTimers()
        local batch=r.timers;r.timers={};for _,entry in ipairs(batch)do entry.fn()end
    end
    function r.snapshot()return P.snapshot({players=r.players,offline=r.offline,saved=r.saved,started=r.api.started,parents=r.parents,aces=r.aces})end
    return r
end
function Q.outcome(fn,r)
    local result=table.pack(pcall(fn,r))
    if not result[1]then
        local message=tostring(result[2])
        assert(not message:find('assertion failed',1,true)and not message:find('Unbound test boundary',1,true),message)
        result[2]=message:gsub('\nstack traceback:.*',''):gsub('^.-:%d+: ','')
    end
    return P.snapshot(result)
end
function Q.case(label,fn,options)
    local a,b=Q.new(false,options),Q.new(true,options)
    H.same(Q.outcome(fn,b),Q.outcome(fn,a),label..': return/error')
    H.same(b.trace,a.trace,label..': all effects')
    H.same(b.snapshot(),a.snapshot(),label..': graph/metadata/saves')
    Q.count=Q.count+1
end
function Q.boundaries(r,ported,nativeMode)
    r.callbacks,r.commands={},{}
    r.library.callback={await=function(...)r.record('await-menu',...);if r.awaitError then error('await-error',0)end;return r.menuReturn end}
    r.library.callback.awaitClient=r.library.callback.await
    if not nativeMode then
        r.library.command=function(name,options,handler)r.commands[#r.commands+1]={name=name,options=options,handler=handler,mode='library'}end
    end
    if ported then
        for _,entry in ipairs(H.load('kernel/server/staff/callbacks.lua',H.environment())({config=r.config,service=r.api}))do r.callbacks[entry.name]=entry.handler end
        r.commands=H.load('kernel/server/staff/commands.lua',H.environment())({config=r.config,service=r.api,library=r.library,
            translate=r.translate,native=r.native,notifyPosition='top-right'}).Commands
    else
        local e=H.environment({ForgeCore={StaffService=r.api,t=r.translate,Callbacks={register=function(name,fn)r.callbacks[name]=fn end}},
            PR={Staff=r.config,NotifyPos='top-right'},pr_lib=r.library,print=r.native.print,
            RegisterCommand=function(name,handler,restricted)r.commands[#r.commands+1]={name=name,handler=handler,restricted=restricted,mode='native'}end})
        H.load('server/staff/callbacks.lua',e);H.load('server/staff/commands.lua',e)
    end
    function r.command(name,src,params,...)
        for _,entry in ipairs(r.commands)do if entry.name==name then return entry.handler(src,params,...)end end
        error('missing command')
    end
end
function Q.boundaryCase(label,fn,nativeMode,options)
    local a,b=Q.new(false,options),Q.new(true,options)
    Q.boundaries(a,false,nativeMode);Q.boundaries(b,true,nativeMode)
    H.same(P.snapshot(b.commands),P.snapshot(a.commands),label..': command metadata')
    H.same(Q.outcome(fn,b),Q.outcome(fn,a),label..': return/error')
    H.same(b.trace,a.trace,label..': complete effects')
    H.same(b.snapshot(),a.snapshot(),label..': graph/metadata/saves')
    Q.count=Q.count+1
end
function Q.ui(ported,options)
    local r=A.new(ported,function(r)r.config.Staff=Q.config(ported);if options then options(r)end end)
    r.menu.openStaffMenu=nil
    if ported then
        r.staff=H.load('kernel/client/menu/staff.lua',H.environment())({menu=r.menu,shared=r.shared,config=r.config,native=r.native})
    else
        local e=H.environment({ForgeCore={Client={Menu=r.menu,MenuShared=r.shared}},PR=r.config,SetTimeout=r.native.setTimeout,
            pr_lib={callback={register=function(name,fn)r.callbacks[name]=fn end}}})
        H.load('client/menu/menu_staff.lua',e);r.staff={Callbacks=r.callbacks}
    end
    return r
end
function Q.uiCase(label,fn,options)
    local a,b=Q.ui(false,options),Q.ui(true,options)
    H.same(Q.outcome(fn,b),Q.outcome(fn,a),label..': return/error')
    H.same(b.trace,a.trace,label..': all UI/RPC/timer effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),label..': contexts')
    Q.count=Q.count+1
end
return Q

