-- Core's explicit PR provider profile. External resources remain behind PR;core responsibilities are not routed through PR.framework.
return function(ports)
    local n,pr,loadModule,rpc=assert(ports.native),assert(ports.prCore),assert(ports.load),assert(ports.rpc)
    assert(n.GetCurrentResourceName()=='forge-core','central PR providers require Forge resource')
    local side=n.IsDuplicityVersion()and'server'or'client';assert(rpc.Side==side,'RPC/provider side mismatch')
    assert(pr.forgeCoreServices==nil,'central PR providers already owned')
    local phase='allocated';local api={OperationalReady=false,Public={context=side}};pr.forgeCoreServices=api
    local owner=assert(ports.isCurrent);local raw;local children={}
    local function current()return phase~='closed'and pr.forgeCoreServices==api and owner()==true end
    local function module(path)if path:sub(1,1)~='@'then path='@pr_bridge/'..path end;return loadModule(path)end
    local function adopt(name,child)assert(current(),'provider scope closed during construction');children[#children+1]={name=name,scope=child};api[name]=child;return child end
    local env={};for k,v in pairs(assert(ports.environment))do env[k]=v end;setmetatable(env,{__index=ports.environment})
    env.ActiveBridges={inventory='ox',inventories='ox',database='oxmysql',banking='renewed',vehicle_key='pr_carkeys'}
    env.exports=assert(ports.external);env.GetCurrentResourceName=n.GetCurrentResourceName;env.IsDuplicityVersion=n.IsDuplicityVersion
    local profile={{field='inventory',path='bridge/inventories/ox/'..side},{field='banking',path='bridge/banking/renewed/'..side},
        {field='vehicle_key',path='bridge/vehicle_key/pr_carkeys/'..side}}
    if side=='server'then profile[#profile+1]={field='database',path='bridge/database/oxmysql/server'}end
    raw=module('@forge-core/kernel/pr_integration/raw_core_factory')({native=n,prCore=pr,public=api.Public,environment=env,profile=profile,
        isCurrent=current,callback=rpc.Native,load=loadModule});api.Raw=raw
    function api.Prepare()
        if phase~='allocated'or not current()or not rpc.Owners.native.IsReady()or not rpc.Owners.ox.IsReady()then return false end
        phase='preparing';local ok,problem=pcall(function()
            assert(raw.Prepare());if side=='server'then
                local inventoryConnection=module('bridge/inventories/ox/forge_control')(env)
                local common={inventory=api.Public.inventory,custom=inventoryConnection.Native(),isCurrent=current,
                    resourceState=assert(n.GetResourceState),executingResource=n.GetCurrentResourceName}
                local d={};for k,v in pairs(common)do d[k]=v end;d.owner='forge-core'
                adopt('Inventory',module('bridge/inventories/ox/forge_provider')(d))
                local o={};for k,v in pairs(common)do o[k]=v end;o.readResourceFile=assert(n.LoadResourceFile)
                adopt('Operations',module('bridge/inventories/ox/forge_operations')(o))
                adopt('Banking',module('bridge/banking/forge_society')({banking=api.Public.banking,renewed=ports.external['Renewed-Banking'],resourceState=n.GetResourceState,isCurrent=current}))
                adopt('Keys',module('bridge/vehicle_key/forge_provider')({vehicleKey=api.Public.vehicle_key,prCarkeys=ports.external.pr_carkeys,
                    resourceState=n.GetResourceState,selected=function()return'pr_carkeys'end,isCurrent=current,sendClient=assert(n.TriggerClientEvent)}))
            end
            assert(phase=='preparing'and current(),'central provider preparation cancelled')
        end)
        if not ok then api.Close();return false,problem end;phase='prepared';return true
    end
    function api.Open()
        if phase~='prepared'or not current()then return false end;phase='opening'
        for _,c in ipairs(children)do local ok,result=pcall(c.scope.Open)
            if not ok or result~=true or phase~='opening'or not current()then api.Close();return false,'provider_open:'..c.name end
        end
        phase='open';return true
    end
    function api.Close()
        phase='closed';local complete=true
        for i=#children,1,-1 do local c=children[i];local ok,result=pcall(c.scope.Close)
            if not ok or result~=true or not c.scope.Progress().complete then complete=false end
        end
        complete=raw.Close()and complete
        if complete and pr.forgeCoreServices==api then pr.forgeCoreServices=nil end;return complete
    end
    function api.Progress()
        local remaining={};for _,c in ipairs(children)do if not c.scope.Progress().complete then remaining[#remaining+1]=c.name end end
        local r=raw.Progress();return{phase=phase,remaining=remaining,raw=r,complete=phase=='closed'and #remaining==0 and r.complete,
            operationalReady=false}
    end
    return api
end
