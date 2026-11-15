-- Prepared consumer-local binding. No physical alias, public bootstrap or ambient require replacement.
local createContext=require 'kernel.imports.consumer_context'
local aliases={}
for _,module in ipairs({'modules.lib','modules.utils','modules.playerdata','shared.locale'})do
    local path=module:gsub('%.','/')
    for _,name in ipairs({'@qbx_core/'..path,'@qbx_core/'..path..'.lua','@qbx_core/'..module,'@qbx_core.'..module})do aliases[name]=module end
end
return function(ports)
    local context=createContext(ports);local target=context.Environment
    local package,requireFunction=assert(ports.package),assert(ports.requireFunction)
    assert(type(package)=='table'and type(package.loaded)=='table'and type(package.searchers)=='table','consumer package required')
    local searchers=package.searchers;local phase,entered='prepared',0
    local api={OperationalReady=false,Context=context};local searcher
    local function current()
        return context.IsCurrent()and rawget(target,'package')==package and package.searchers==searchers and rawget(target,'require')==requireFunction
    end
    local function invoke(module)
        assert(phase=='installed'and current(),'consumer_loader_closed')
        entered=entered+1;local result=table.pack(pcall(context.Require,module));entered=entered-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    searcher=function(name)
        local module=aliases[name];if not module then return end
        return function()return invoke(module)end
    end
    function api.Describe()
        local out={};for name,module in pairs(aliases)do out[name]=module end;return out
    end
    function api.Install()
        if phase~='prepared'then return false,'consumer_loader_not_repeatable'end
        assert(current(),'consumer_loader_owner_changed')
        for name in pairs(aliases)do assert(package.loaded[name]==nil,'consumer_import_already_cached: '..name)end
        local n,count=#searchers,0
        for key,value in pairs(searchers)do if type(key)=='number'then
            assert(key>=1 and key%1==0 and key<=n and type(value)=='function','dense consumer searchers required');count=count+1
        end end
        assert(count==n,'dense consumer searchers required')
        table.insert(searchers,1,searcher);phase='installed';return true
    end
    function api.ExecuteManifest(path)
        return invoke(assert(aliases[path],'unsupported_consumer_manifest_import: '..tostring(path)))
    end
    function api.Close()
        phase='closed'
        for i=#searchers,1,-1 do if searchers[i]==searcher then table.remove(searchers,i)end end
        return context.Close()
    end
    function api.Progress()
        local p=context.Progress();local cached={};local present=false
        for name in pairs(aliases)do if package.loaded[name]~=nil then cached[name]=package.loaded[name]end end
        for _,value in pairs(searchers)do if value==searcher then present=true end end
        return{phase=phase,pending=entered+p.pending,cachedAliases=cached,searcherRemaining=present,
            complete=phase=='closed'and entered+p.pending==0 and not present and p.complete}
    end
    return api
end
