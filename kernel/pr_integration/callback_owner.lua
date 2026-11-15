-- Compose installed adapters and owned52 engines in the Forge environment. No legacy engine adoption.
return function(ports)
    local n,pr=assert(ports.native),assert(ports.prCore);local current=assert(ports.isCurrent)
    assert(n.GetCurrentResourceName()=='forge-core','Forge callback owner resource required')
    local side=n.IsDuplicityVersion()and'server'or'client';local server=side=='server'
    assert(pr.forgeOwnedCallbacks==nil and not(pr.callback and pr.callback._transportInstalled),'legacy/owned callback transport already installed')
    local loadModule,available=assert(ports.load),assert(ports.available)
    local phase,pending='allocated',0;local tokens,leases,engines={}, {}, {};local registry
    local api={OperationalReady=false,Side=side,Owners={},Native={},Ox={}};pr.forgeOwnedCallbacks=api
    local priorCallback=pr.callback
    local function valid()local ok,value=pcall(current);return phase~='closed'and pr.forgeOwnedCallbacks==api and ok and value==true end
    local function track(fn,...)
        pending=pending+1;local out=table.pack(pcall(fn,...));pending=pending-1
        if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
    end
    local function remove(token)
        local found;for _,r in ipairs(tokens)do if r.token==token then found=r;break end end
        assert(found,'foreign native callback listener');if found.removed then return end
        local result=n.RemoveEventHandler(token);assert(result~=false,'callback listener removal rejected');found.removed=true
    end
    local env={};setmetatable(env,{__index=function(_,key)
        if key=='source'then return ports.getSource()end;return ports.environment[key]
    end})
    for _,key in ipairs({'GetCurrentResourceName','GetInvokingResource','GetGameTimer','GetConvarInt','DoesPlayerExist','TriggerClientEvent','TriggerServerEvent','SetTimeout'})do env[key]=n[key]end
    env.RemoveEventHandler=remove
    env.AddEventHandler=function(name,fn)
        local r={name=name};tokens[#tokens+1]=r
        local token=n.AddEventHandler(name,fn);assert(token~=nil and token~=false,'callback listener handle required');r.token=token
        return token
    end
    env.RegisterNetEvent=function(name,fn)n.RegisterNetEvent(name);if fn then return env.AddEventHandler(name,fn)end end
    local localPr={callback={}};env.PRCore=localPr
    local factory=loadModule('@pr_bridge/bridge/callback/owned_registration',env)
    local raw={};for _,protocol in ipairs({'native','ox'})do
        local owner=factory({protocol=protocol,side=side,createTransport=function(options)
            local engine=loadModule('@pr_bridge/bridge/callback/transport',env)(options);engines[#engines+1]=engine;return engine
        end});raw[protocol]=owner
        local scoped={Protocol=protocol,Side=side};api.Owners[protocol]=scoped
        scoped.IsReady=function()return phase=='open'and valid()and owner.IsReady()end
        for _,key in ipairs({'Capture','CaptureRegister','EventName'})do scoped[key]=function(...)
            assert(valid()and phase~='closing','callback owner closing');return owner[key](...)
        end end
        scoped.CaptureRegister=function(name,handler)
            assert(valid()and phase~='closing','callback owner closing')
            local ok,problem=pcall(owner.CaptureRegister,name,handler)
            if not ok then
                error(debug.traceback(('owned %s callback registration refused (%s): %s'):format(protocol,tostring(name),tostring(problem)),2),0)
            end
        end
        scoped.Reserve=function(name)
            assert(scoped.IsReady(),'callback transport unavailable');local lease=owner.Reserve(name);leases[#leases+1]={owner=owner,lease=lease};return lease
        end
        scoped.Bind=function(lease,fn)
            assert(scoped.IsReady(),'callback transport unavailable')
            return owner.Bind(lease,function(...)if phase~='open'or not valid()then return end;return track(fn,...)end)
        end
        scoped.Release=function(lease)
            for _,r in ipairs(leases)do if r.lease==lease and r.owner==owner and not r.released then
                local result=owner.Release(lease);r.released=result==true;return result
            end end;error('foreign/released callback lease',0)
        end
    end
    api.Native.register=api.Owners.native.CaptureRegister;api.Ox.register=api.Owners.ox.CaptureRegister
    function localPr.load(path)
        assert(path=='@pr_bridge/bridge/callback/transport','only owned transport can be opened by an adapter')
        return function(options)
            local protocol=options.claim and'ox'or'native'
            return raw[protocol].Open(options,{available=function(name,wire)
                return phase=='opening'and false or valid()and registry and not registry.exists(name)and available(name,wire)==true
            end,releaseClaim=function(name)
                assert(registry.valid(name),'foreign callback claim')
                ports.environment.exports.pr_bridge:oxService('setValidCallback',name,false)
                registry.set(name,false);return true
            end})
        end
    end
    local function publish(target,source)
        for k,v in pairs(source)do if k~='register'then target[k]=type(v)=='function'and function(...)
            assert(phase=='open'and valid(),'callback requests closed');return track(v,...)
        end or v end end
        local mt=getmetatable(source);if type(mt)=='table'and type(mt.__call)=='function'then setmetatable(target,{__call=function(_,...)
            assert(phase=='open'and valid(),'callback requests closed');return track(mt.__call,source,...)
        end})end
    end
    function api.Open()
        if phase~='allocated'or not valid()or(pr.callback and pr.callback._transportInstalled)then return false end
        phase='opening';pending=pending+1
        local ok,problem=pcall(function()
            registry=loadModule('@pr_bridge/bridge/callback/registry',env)
            local native=loadModule('@pr_bridge/bridge/callback/native',env)(server)
            env.lib={context=side,setValidCallback=function(name,value)
                -- OX validates requests in the public PR host, a different resource VM.
                -- Keep the private lease ledger, but publish ownership where validation runs.
                ports.environment.exports.pr_bridge:oxService('setValidCallback',name,value)
                registry.set(name,value)
            end};env.cache={resource='forge-core'}
            local ox=loadModule('@pr_bridge/bridge/compat/ox_lib/ox_callback',env)
            assert(phase=='opening'and valid(),'callback owner changed during Open')
            publish(api.Native,native);publish(api.Ox,ox)
            assert(pr.callback==priorCallback,'callback slot changed during Open');pr.callback=api.Native
        end);pending=pending-1
        if not ok or phase~='opening'or not valid()then api.Close();return false,problem end
        phase='open';return true
    end
    function api.Progress()
        local requests=0;for _,e in ipairs(engines)do for _ in pairs(e.getPending())do requests=requests+1 end end
        local listeners,remaining=0,0;for _,t in ipairs(tokens)do if not t.removed then listeners=listeners+1 end end
        for _,r in ipairs(leases)do if not r.released then remaining=remaining+1 end end
        return{phase=phase,pending=pending,requests=requests,listeners=listeners,leases=remaining,
            complete=phase=='closed'and pending==0 and requests==0 and listeners==0 and remaining==0,operationalReady=false}
    end
    function api.Close()
        if phase=='closed'then return true end;phase='closing'
        for i=#leases,1,-1 do local r=leases[i];if not r.released then local ok,v=pcall(r.owner.Release,r.lease);if ok and v==true then r.released=true end end end
        local progress=api.Progress();if progress.pending>0 or progress.requests>0 or progress.leases>0 then return false end
        for i=#tokens,1,-1 do local t=tokens[i];if not t.removed then pcall(remove,t.token)end end
        progress=api.Progress();if progress.listeners>0 then return false end
        phase='closed';if pr.callback==api.Native then pr.callback=priorCallback end
        if pr.forgeOwnedCallbacks==api then pr.forgeOwnedCallbacks=nil end;return true
    end
    return api
end
