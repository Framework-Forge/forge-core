-- Prepared source delivery only. It does not write/apply a manifest or choose a public resource alias.
local modules={
    ['kernel.imports.require_binding']='kernel/imports/require_binding.lua',
    ['kernel.imports.consumer_context']='kernel/imports/consumer_context.lua',
    ['kernel.imports.legacy_registry']='kernel/imports/legacy_registry.lua',
    ['kernel.modules.lib']='kernel/modules/lib.lua',
    ['kernel.modules.utils']='kernel/modules/utils.lua',
    ['kernel.modules.playerdata']='kernel/modules/playerdata.lua',
    ['kernel.shared.locale']='kernel/shared/locale.lua',
    ['kernel.shared.event_registration']='kernel/shared/event_registration.lua'}
local entries={['modules.lib']='kernel/imports/entries/lib.lua',['modules.utils']='kernel/imports/entries/utils.lua',
    ['modules.playerdata']='kernel/imports/entries/playerdata.lua',['shared.locale']='kernel/imports/entries/locale.lua'}
return function(ports)
    local read,compile,makeEnv,owner=assert(ports.readFile),assert(ports.compile),assert(ports.moduleEnvironment),assert(ports.isCurrent)
    local phase,entered='allocated',0;local cache,loading={},{};local binding,environment
    local api={OperationalReady=false}
    local function current()local ok,value=pcall(owner);return phase~='closed'and phase~='failed'and ok and value==true end
    local function check()assert(current(),'consumer_delivery_closed')end
    local function tracked(fn,...)
        entered=entered+1;local result=table.pack(pcall(fn,...));entered=entered-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    local function execute(path)
        check();local source=read(path);check();assert(type(source)=='string','consumer source missing: '..path)
        local chunk,problem=compile(source,'@@forge-core/'..path,'t',environment);check();assert(chunk,problem)
        local value=chunk();check();assert(type(value)=='function','consumer factory required: '..path);return value
    end
    local function requirePrivate(name)
        check();local path=assert(modules[name],'unsupported_private_consumer_module: '..tostring(name))
        if cache[name]then return cache[name]end;assert(not loading[name],'consumer_delivery_cycle: '..name)
        loading[name]=true;local ok,value=pcall(execute,path);loading[name]=nil
        if not ok then error(value,0)end;cache[name]=value;return value
    end
    function api.Describe()
        local files={'kernel/imports/consumer_delivery.lua'};for _,path in pairs(modules)do files[#files+1]=path end
        for _,path in pairs(entries)do files[#files+1]=path end;table.sort(files)
        return{files=files,manifestApplied=false,order={'prepare','install-require','execute-entry'},publicAliasChosen=false}
    end
    function api.Prepare()
        if phase~='allocated'then return false,'consumer_delivery_not_repeatable'end
        check();phase='preparing'
        local ok,problem=pcall(tracked,function()
            environment=makeEnv(requirePrivate);check();assert(type(environment)=='table'and rawget(environment,'require')==requirePrivate,'private module environment required')
            local constructor=requirePrivate('kernel.imports.require_binding');check()
            local p={};for k,v in pairs(assert(ports.consumer))do p[k]=v end
            local prior=assert(p.isCurrent);p.isCurrent=function()return current()and prior()end
            binding=constructor(p);check();api.Binding=binding
        end)
        if not ok then if phase~='closed'then phase='failed'end;error(problem,0)end
        phase='prepared';return true
    end
    function api.Install()
        check();assert(phase=='prepared','consumer_delivery_not_prepared')
        local ok,problem=tracked(binding.Install);check();assert(ok,problem);phase='installed';return true
    end
    function api.ExecuteEntry(name)
        check();assert(phase=='installed','consumer_delivery_not_installed')
        local path=assert(entries[name],'unsupported_consumer_entry: '..tostring(name))
        return tracked(function()return execute(path)(binding)end)
    end
    function api.Close()phase='closed';if binding then return binding.Close()end;return true end
    function api.Progress()
        local p=binding and binding.Progress()or nil
        return{phase=phase,pending=entered+(p and p.pending or 0),binding=p,
            complete=phase=='closed'and entered==0 and(not p or p.complete)}
    end
    return api
end
