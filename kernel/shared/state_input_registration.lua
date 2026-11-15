-- Private registration only; see NOTICE-54.md. No operational bootstrap.
local function copy(value, wrap, seen)
    if type(value)=='function'and wrap then return wrap(value)end
    if type(value)~='table'then return value end
    seen=seen or{};assert(not seen[value],'cyclic registration descriptor');seen[value]=true
    local out={};for k,v in pairs(value)do out[k]=copy(v,wrap,seen)end;seen[value]=nil;return out
end
return function(spec,ports)
    assert(type(spec)=='table'and type(ports)=='table','explicit registration specification/ports required')
    local owner,current=assert(spec.owner),assert(spec.isCurrent)
    assert(type(current)=='function'and current(),'canonical client required')
    assert(owner.StateInputRegistration==nil,'state/input registry already owned')
    local addBag,removeBag,resolve=assert(ports.addBag),assert(ports.removeBag),assert(ports.resolveEntity)
    local available=assert(ports.availableKey)
    for _,fn in ipairs({addBag,removeBag,resolve,available})do assert(type(fn)=='function','explicit registration function required')end
    local provider=assert(ports.keybind)
    assert(type(provider)=='table'and type(getmetatable(provider))=='table','owned PR keybind table required')
    local call,get,remove=getmetatable(provider).__call,provider.get,provider.remove
    assert(type(call)=='function'and type(get)=='function'and type(remove)=='function','complete PR keybind ports required')
    local bags,keys=copy(assert(spec.bags)),copy(assert(spec.keys))
    local prepare=spec.prepare
    assert(prepare==nil or type(prepare)=='function','invalid descriptor preparation')
    local phase='prepared-inactive'
    local api={State=phase,PhysicalKeyUnregistration=false}
    owner.StateInputRegistration=api
    local owned={}
    local disposing=false
    local function setPhase(v)phase=v;api.State=v end
    local function canonical()return owner.StateInputRegistration==api and current()end
    local function active()return phase=='installed'and canonical()end
    local function guarded(fn)return function(...)if active()then return fn(...)end end end
    local function check()
        local seen={}
        for _,d in ipairs(bags)do
            assert(type(d.key)=='string'and d.key~=''and type(d.handler)=='function','invalid statebag descriptor')
            assert(d.filter==nil or type(d.filter)=='string','invalid statebag filter')
            local id=d.key..'\0'..tostring(d.entity and''or d.filter);assert(not seen[id],'statebag collision: '..d.key);seen[id]=true
        end
        seen={}
        for _,d in ipairs(keys)do
            -- Installed core names already use this canonical PR command namespace.
            assert(type(d.name)=='string'and d.name:match('^[a-z][a-z0-9_%-]*$'),'noncanonical keybind name')
            assert(not seen[d.name],'keybind collision: '..d.name);seen[d.name]=true
            assert(type(d.onPressed)=='function','keybind onPressed required')
            assert(get(d.name)==nil and available(d.name,copy(d))==true,'occupied keybind namespace: '..d.name)
            assert(canonical(),'client replaced during keybind preflight')
        end
    end
    function api.Describe()return{bags=copy(bags),keys=copy(keys)}end
    function api.Dispose()
        if disposing then return false,'cleanup already in progress'end
        if phase=='disposed'and #owned==0 then return false end
        disposing=true
        setPhase('revoking') -- Revoke every callback before touching a provider.
        local errors={}
        for index=#owned,1,-1 do
            local item=owned[index]
            local ok,problem=pcall(function()
                if item.kind=='bag'then
                    assert(removeBag(item.token)~=false,'statebag removal refused')
                else
                    local binding=item.data
                    if type(binding.disable)=='function'then binding:disable(true)end
                    local registered=get(item.name)
                    if registered==binding then
                        assert(binding.name==item.name,'owned keybind name changed; provider destroy refused')
                        assert(remove(item.name)~=false,'keybind removal refused')
                        assert(get(item.name)~=binding,'keybind still owned after removal')
                    end -- nil or a foreign replacement: never destroy another owner's name.
                end
            end)
            if ok then table.remove(owned,index)else errors[#errors+1]=tostring(problem)end
        end
        setPhase(#errors==0 and'disposed'or'cleanup-pending')
        disposing=false
        if #errors>0 then return false,table.concat(errors,'\n')end
        return true
    end
    function api.Install()
        if phase~='prepared-inactive'then return false end
        setPhase('preparing')
        local ok,problem=pcall(function()
            assert(canonical(),'client no longer canonical')
            if prepare then for _,d in ipairs(prepare())do keys[#keys+1]=copy(d)end end
            assert(phase=='preparing'and canonical(),'client revoked/replaced during descriptor preparation');check()
            assert(phase=='preparing'and canonical(),'client revoked/replaced during preflight')
            setPhase('installing')
            for _,d in ipairs(bags)do
                assert(phase=='installing'and canonical(),'client revoked/replaced during statebag installation')
                local handler
                if d.entity then
                    handler=function(bagName,_,value)
                        if not active()then return end
                        local entity,netId=resolve(bagName)
                        if active()and entity then d.handler(entity,netId,value,bagName)end
                    end
                else handler=guarded(d.handler)end
                local token=addBag(d.key,d.entity and''or d.filter,handler)
                assert(token~=nil and token~=false,'statebag registration returned no owned cookie')
                owned[#owned+1]={kind='bag',token=token}
                assert(phase=='installing'and canonical(),'client revoked/replaced while receiving cookie')
            end
            for _,d in ipairs(keys)do
                assert(phase=='installing'and canonical()and get(d.name)==nil and available(d.name,copy(d))==true,'keybind namespace changed during installation')
                assert(phase=='installing'and canonical(),'client revoked/replaced during keybind namespace check')
                local data=copy(d,guarded)
                owned[#owned+1]={kind='key',name=d.name,data=data}
                local binding=call(provider,data)
                assert(phase=='installing'and canonical(),'client revoked/replaced during keybind publication')
                assert(binding==data and get(d.name)==data,'PR provider did not retain owned descriptor identity')
            end
            assert(phase=='installing'and canonical(),'client revoked/replaced during installation');setPhase('installed')
        end)
        if not ok then
            local _,cleanup=api.Dispose()
            if phase=='disposed'then setPhase('install-failed-revoked')end
            error(tostring(problem)..(cleanup and'\n'..cleanup or''),0)
        end
        return true
    end
    return api
end
