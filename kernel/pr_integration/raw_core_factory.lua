-- PR library for the core itself. Explicit provider profile; never select or normalize a framework adapter.
return function(ports)
    local native,pr,public=assert(ports.native),assert(ports.prCore),assert(ports.public)
    assert(native.GetCurrentResourceName()=='forge-core','raw core PR belongs to forge-core')
    local side=native.IsDuplicityVersion()and'server'or'client'
    local owner,loadProvider=assert(ports.isCurrent),assert(ports.load)
    assert(pr.forgeRawCore==nil,'raw core PR already owned')
    local categories={inventory='bridge/inventories/',banking='bridge/banking/',database='bridge/database/',vehicle_key='bridge/vehicle_key/',
        notify='bridge/notifications/',textui='bridge/textui/',utils='bridge/utils/',math='bridge/utils/',table='bridge/utils/',
        string='bridge/utils/',timer='bridge/utils/',waitFor='bridge/utils/',library='bridge/library/',cache='bridge/cache/'}
    local entries,seen={},{}
    local function pathOf(path)
        assert(type(path)=='string'and not path:find('..',1,true)and not path:find('\\',1,true),'explicit PR module path required')
        local name=path:gsub('^@pr_bridge/',''):gsub('%.lua$','')
        assert(name:sub(1,7)=='bridge/'and not name:match('^bridge/framework')and not name:match('^bridge/compat')and name~='bridge/init','raw PR cannot load framework/compat bootstrap')
        return name
    end
    for _,d in ipairs(assert(ports.profile))do
        local prefix=assert(categories[d.field],'unsupported raw provider slot');local path=pathOf(d.path)
        local external=d.field=='inventory'or d.field=='banking'or d.field=='vehicle_key'
        assert(path:sub(1,#prefix)==prefix and(not external or not path:find('/default/',1,true))and not seen[d.field],'explicit external raw provider required')
        assert(rawget(public,d.field)==nil,'occupied raw provider slot: '..d.field)
        entries[#entries+1]={field=d.field,path=path,build=d.build,published=false};seen[d.field]=true
    end
    assert(#entries>0,'raw provider profile required')
    local phase,pending='allocated',0;local api={OperationalReady=false,Side=side,Public=public};pr.forgeRawCore=api
    local env={};for k,v in pairs(assert(ports.environment))do env[k]=v end;setmetatable(env,{__index=ports.environment})
    local function current()
        if phase=='closed'or pr.forgeRawCore~=api then return false end
        local ok,value=pcall(owner);if not ok or value~=true or native.GetCurrentResourceName()~='forge-core'then return false end
        for _,e in ipairs(entries)do if e.published and rawget(public,e.field)~=e.value then return false end end
        return true
    end
    local wrapped={};local function scope(value,copies)
        if type(value)=='function'then
            if not wrapped[value]then wrapped[value]=function(...)
                assert(phase=='prepared'and current(),'raw core PR unavailable');pending=pending+1
                local out=table.pack(pcall(value,...));pending=pending-1
                if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
            end end;return wrapped[value]
        end
        if type(value)~='table'then return value end
        copies=copies or{};if copies[value]then return copies[value]end;local out={};copies[value]=out
        for k,v in pairs(value)do out[k]=scope(v,copies)end
        local mt=getmetatable(value)
        if type(mt)=='table'and(mt.__index or mt.__call)then
            setmetatable(out,{__index=mt.__index and function(_,key)
                assert(phase=='prepared'and current(),'raw lazy provider unavailable');return scope(value[key],copies)
            end or nil,__call=type(mt.__call)=='function'and scope(mt.__call,copies)or nil})
        end
        return out
    end
    local localPr={context=side,callback=assert(ports.callback)};setmetatable(localPr,{__index=pr})
    function localPr.load(path,environment,optional)
        assert(current(),'raw PR module owner unavailable')
        return loadProvider('@pr_bridge/'..pathOf(path),environment or env,optional)
    end
    env.PRCore,env.Bridge,env.pr_lib=localPr,public,public
    function api.Prepare()
        if phase~='allocated'or not current()then return false end;phase='preparing';pending=pending+1
        local ok,problem=pcall(function()
            for _,e in ipairs(entries)do
                assert(current()and rawget(public,e.field)==nil,'raw PR scope changed during load')
                local value=localPr.load(e.path);if e.build then value=e.build(value,public,env)end
                assert(value~=nil and current(),'raw provider unavailable: '..e.field)
                assert(rawget(public,e.field)==nil,'raw slot occupied during load')
                e.value=scope(value);rawset(public,e.field,e.value);e.published=true
            end
        end);pending=pending-1
        if not ok or phase~='preparing'or not current()then api.Close();return false,problem end
        phase='prepared';return true
    end
    function api.Close()
        phase='closed'
        for i=#entries,1,-1 do local e=entries[i];if e.published and rawget(public,e.field)==e.value then rawset(public,e.field,nil)end end
        if pending==0 and pr.forgeRawCore==api then pr.forgeRawCore=nil end
        return pending==0
    end
    function api.Progress()return{phase=phase,pending=pending,complete=phase=='closed'and pending==0,operationalReady=false}end
    return api
end
