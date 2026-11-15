-- Explicit,resource-local factory imports. No external require fallback or package/global patch.
return function(ports)
    local read,compile,current=assert(ports.readFile),assert(ports.compile),assert(ports.isCurrent)
    local environment=assert(ports.environment);local probe=assert(ports.inventoryBridgeProbe)
    local env={};for key,value in pairs(environment)do env[key]=value end;setmetatable(env,{__index=environment})
    local aliases={['kernel.server.startup_context']='kernel.server.startup_forge_context',['kernel.server.main']='kernel.server.main_forge'}
    local phase,pending='prepared',0;local cache,loading={},{};local api={OperationalReady=false}
    local function valid()local ok,value=pcall(current);return phase~='closed'and ok and value==true end
    local function canonical(name)
        assert(type(name)=='string'and name:sub(1,7)=='kernel.','private kernel module required')
        assert(not name:find('..',1,true)and name:sub(-1)~='.','invalid kernel module path')
        for part in name:gmatch('[^.]+')do assert(part:match('^[%a_][%w_]*$'),'invalid kernel module segment')end
        return aliases[name]or name
    end
    function api.Require(name)
        assert(valid(),'native factory registry unavailable');name=canonical(name)
        if cache[name]~=nil then return cache[name]end
        assert(not loading[name],'circular kernel import:'..name);loading[name]=true;pending=pending+1
        local out=table.pack(pcall(function()
            local path=name:gsub('%.','/')..'.lua';local source=assert(read('forge-core',path),'missing private factory:'..path)
            assert(valid(),'native factory registry closed during read')
            local chunk,problem=compile(source,'@@forge-core/'..path,'t',env);assert(chunk,problem)
            assert(valid(),'native factory registry closed during compile');local value=chunk()
            assert(valid(),'native factory registry closed during load')
            if name=='kernel.server.startup_forge_context'then
                local factory=assert(value);value=function(base,input)
                    assert(valid(),'native factory registry unavailable');local p={};for k,v in pairs(input)do p[k]=v end
                    p.inventoryBridgeProbe=probe;return factory(base,p)
                end
            end
            if value==nil then value=true end;return value
        end));pending=pending-1;loading[name]=nil
        if not out[1]then error(out[2],0)end;cache[name]=out[2];return out[2]
    end
    env.require=api.Require;env._ENV=env
    function api.IsCurrent()return valid()end
    function api.Close()phase='closed';return pending==0 end
    function api.Progress()local count=0;for _ in pairs(cache)do count=count+1 end;return{phase=phase,pending=pending,modules=count,complete=phase=='closed'and pending==0,retainedFactoriesRevoked=false}end
    return api
end
