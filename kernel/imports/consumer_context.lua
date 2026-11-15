-- Explicit resource-local imports. PlayerData is a consumer view, never the core authority.
local createRegistry=require 'kernel.imports.legacy_registry'
local createView=require 'kernel.modules.playerdata'
local createEvents=require 'kernel.shared.event_registration'
local aliases={['modules.playerdata']=true,['modules/playerdata.lua']=true,['@qbx_core/modules/playerdata.lua']=true}
return function(ports)
    local registry=createRegistry(ports);local target=registry.Environment
    local phase,entered,attempted,loaded='open',0,false,false
    local view,binding,previous,published;local owner={}
    local api={OperationalReady=false,Environment=target,Imports=registry}
    local function current()
        return phase~='closed'and registry.IsCurrent()and(not published or rawget(target,'QBX')==view.View)
    end
    local function check()assert(current(),'consumer_import_closed')end
    local function tracked(fn,...)
        entered=entered+1;local result=table.pack(pcall(fn,...));entered=entered-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    local function importPlayerData()
        if ports.isServer then return end
        view=createView({isServer=false,getPlayerData=assert(ports.getPlayerData,'complete PlayerData getter required')})
        previous=rawget(target,'QBX');rawset(target,'QBX',view.View);published=true;api.View=view.View
        view.Initialize();check()
        local eventPorts=assert(ports.events,'consumer event ports required');local entries={}
        for i,d in ipairs(view.Events)do
            entries[i]={owner='consumer.PlayerData',name=d.name,network=d.network,sourceFirst=false,handler=function(...)
                if phase~='loaded'or not current()then return end
                return tracked(d.handler,...)
            end}
        end
        binding=createEvents({owner=owner,side='client',entries=entries,isCurrent=current},{
            listen=function(...)check();return eventPorts.listen(...)end,
            markNetwork=function(...)check();return eventPorts.markNetwork(...)end,
            remove=assert(eventPorts.remove),source=function()end})
        local ok,problem=binding.Install();assert(ok,problem);check()
    end
    function api.Has(name)return aliases[name]==true or registry.Has(name)end
    function api.Require(name)
        check();if not aliases[name]then return registry.Require(name)end
        if loaded then return true end
        assert(not attempted,'consumer_playerdata_import_not_repeatable')
        attempted=true;phase='loading'
        local ok,problem=pcall(tracked,importPlayerData)
        if not ok then if phase~='closed'then phase='failed'end;error(problem,0)end
        check();loaded=true;phase='loaded';return true
    end
    function api.IsCurrent()return current()end
    function api.Close()
        phase='closed';registry.Close()
        if published and rawget(target,'QBX')==view.View then rawset(target,'QBX',previous)end
        if binding then return binding.Dispose()end;return true
    end
    function api.Progress()
        local p=registry.Progress();local state=binding and binding.State or'absent'
        local retired=state=='absent'or state=='disposed'or state=='install-failed'
        return{phase=phase,pending=entered+p.pending,binding=state,
            complete=phase=='closed'and entered+p.pending==0 and retired and p.complete}
    end
    return api
end
