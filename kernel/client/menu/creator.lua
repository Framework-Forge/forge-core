-- Complete installed job/creator.lua, inactive and dependency-bound; see NOTICE-25.md.
return function(ports)
    local Menu,Shared,client=assert(ports.menu),assert(ports.shared),assert(ports.client)
    local library,PR,native=assert(ports.library),assert(ports.config),assert(ports.native)
    local translate,integrations=ports.translate,ports.integrations
    local api={Menu=Menu,Shared=Shared,Events={},Callbacks={},Exports={}}
    local function listen(name,handler)api.Events[#api.Events+1]={name=name,handler=handler,network=false}end
    local function callback(name,handler)api.Callbacks[name]=handler end
    local function describeExport(name,handler)api.Exports[name]=handler end
local Creator = {}

function Creator.openJob()
    if client.Menu then
        client.Menu.openGroupCreator('job')
    end
end

function Creator.openGang()
    if client.Menu then
        client.Menu.openGroupCreator('gang')
    end
end



    api.Creator=Creator

    return api
end

