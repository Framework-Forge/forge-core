-- Native Forge-owned raw entry;does not load the external PR init or select a framework.
return function(options)
    assert(GetCurrentResourceName()=='forge-core','raw PR entry must run inside Forge')
    assert(type(options)=='table'and type(options.namespaceAvailable)=='function'and type(options.isCurrent)=='function','explicit native raw PR options required')
    assert(PRCore.forgeRawEntry==nil,'raw PR entry already owned')
    local phase='allocated';local token;local api={OperationalReady=false};PRCore.forgeRawEntry=api
    local function current()return phase~='closed'and PRCore.forgeRawEntry==api and options.isCurrent()==true end
    local function module(path,environment)if path:sub(1,1)~='@'then path='@pr_bridge/'..path end;return PRCore.load(path,environment or _ENV)end
    local native={GetCurrentResourceName=GetCurrentResourceName,IsDuplicityVersion=IsDuplicityVersion,GetInvokingResource=GetInvokingResource,
        GetGameTimer=GetGameTimer,GetConvarInt=GetConvarInt,DoesPlayerExist=DoesPlayerExist,TriggerClientEvent=TriggerClientEvent,TriggerServerEvent=TriggerServerEvent,
        SetTimeout=SetTimeout,AddEventHandler=AddEventHandler,RemoveEventHandler=RemoveEventHandler,RegisterNetEvent=RegisterNetEvent,
        GetResourceState=GetResourceState,LoadResourceFile=LoadResourceFile}
    local rpc,services
    function api.Prepare()
        if phase~='allocated'or not current()then return false end;phase='preparing'
        local ok,problem=pcall(function()
            assert(rpc.Open());assert(services.Prepare())
            token=AddEventHandler(IsDuplicityVersion()and'onResourceStop'or'onClientResourceStop',function(name)if name=='forge-core'then api.Close()end end)
            assert(token~=nil and token~=false and phase=='preparing'and current(),'raw entry changed during Prepare')
        end)
        if not ok then api.Close();return false,problem end;phase='prepared';return true
    end
    function api.Close()
        if phase=='closed'then return true end;phase='closing'
        if options.beforeClose then local ok,result=pcall(options.beforeClose);if not ok or result~=true then return false end end
        local a=not services or services.Close();local b=not rpc or rpc.Close()
        if not a or not b then return false end
        if token then local ok,result=pcall(RemoveEventHandler,token);if not ok or result==false then return false end;token=nil end
        phase='closed';if PRCore.forgeRawEntry==api then PRCore.forgeRawEntry=nil end;return true
    end
    function api.Progress()return{phase=phase,rpc=rpc and rpc.Progress(),services=services and services.Progress(),stopToken=token~=nil,
        complete=phase=='closed'and(not rpc or rpc.Progress().complete)and(not services or services.Progress().complete)and token==nil,operationalReady=false}end
    local ok,problem=pcall(function()
        rpc=module('@forge-core/kernel/pr_integration/callback_owner')({native=native,prCore=PRCore,environment=_ENV,getSource=function()return source end,
            isCurrent=current,available=options.namespaceAvailable,load=module});api.RPC=rpc
        services=module('@forge-core/kernel/pr_integration/core_services_factory')({native=native,prCore=PRCore,environment=_ENV,external=exports,
            rpc=rpc,isCurrent=current,load=module});api.Services=services
    end)
    if not ok then api.Close();error(problem,0)end
    return api
end
