-- Private source delivery and ownership only. No manifest application or implicit consumer execution.
local createConsumer=require 'kernel.imports.consumer_delivery'
local relayPath='kernel/compat/qbx/export_relay.lua'
local files={relayPath,'kernel/imports/consumer_delivery.lua','kernel/imports/require_binding.lua','kernel/imports/consumer_context.lua',
    'kernel/imports/legacy_registry.lua','kernel/modules/lib.lua','kernel/modules/utils.lua','kernel/modules/playerdata.lua',
    'kernel/shared/locale.lua','kernel/shared/event_registration.lua','kernel/imports/entries/lib.lua','kernel/imports/entries/utils.lua',
    'kernel/imports/entries/playerdata.lua','kernel/imports/entries/locale.lua'}
table.sort(files)
return function(side,ports)
    assert(side=='server'or side=='client','explicit delivery side required')
    local read,compile,environment,current=assert(ports.readFile),assert(ports.compile),assert(ports.relayEnvironment),assert(ports.isCurrent)
    local phase,pending='allocated',0;local factory;local relay;local relayAttempted=false;local consumers={};local errors={}
    local api={OperationalReady=false};local allowed={};for _,name in ipairs(files)do allowed[name]=true end
    local function valid()local ok,value=pcall(current);return phase~='closed'and phase~='failed'and ok and value==true end
    local function check()assert(valid(),'qbx_delivery_closed')end
    local function tracked(fn,...)
        pending=pending+1;local result=table.pack(pcall(fn,...));pending=pending-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    local function readOwned(path)
        check();assert(allowed[path],'unsupported_compatibility_source');local text=tracked(read,path);check()
        assert(type(text)=='string','compatibility source missing: '..path);return text
    end
    local function closeChild(child)local ok,problem=pcall(child.Close);if not ok then errors[#errors+1]=tostring(problem)end end
    function api.Prepare()
        if phase~='allocated'or not valid()then return false,'qbx_delivery_not_allocated'end
        phase='preparing';local ok,problem=pcall(function()
            local text=readOwned(relayPath);local env=tracked(environment);check();assert(type(env)=='table','explicit relay environment required')
            local chunk,err=tracked(compile,text,'@@qbx_core/export_relay.lua','t',env);check();assert(chunk,err)
            factory=tracked(chunk);check();assert(type(factory)=='function','relay factory required')
        end)
        if not ok then if phase~='closed'then phase='failed'end;error(problem,0)end
        phase='prepared';return true
    end
    function api.AttachRelay(input)
        check();assert(phase=='prepared'and not relayAttempted,'one local relay per package required')
        relayAttempted=true -- Reserve before the resource-identity port can yield/reenter.
        assert(factory,'relay not prepared')
        local p={};for key,value in pairs(input)do p[key]=value end
        local prior=assert(p.isCurrent);p.isCurrent=function()return valid()and prior()end
        local child=tracked(factory,side,p);relay=child
        if not valid()then closeChild(child);error('relay_created_after_close',0)end
        return child
    end
    function api.AttachConsumer(id,input)
        check();assert(phase=='prepared'and type(id)=='string'and id:match('^[%w_-]+$')and not consumers[id],'unique explicit consumer required')
        consumers[id]=false -- Reserve before a supplied constructor/port can yield.
        local p={};for key,value in pairs(input)do p[key]=value end
        local prior=assert(p.isCurrent);p.isCurrent=function()return valid()and prior()end
        p.readFile=readOwned
        local child=tracked(createConsumer,p);consumers[id]=child
        if not valid()then closeChild(child);error('consumer_created_after_close',0)end
        return child
    end
    function api.Close()
        phase='closed';if relay then closeChild(relay)end
        for _,child in pairs(consumers)do if child then closeChild(child)end end
        return api.Progress().complete
    end
    function api.Progress()
        local total=pending;local complete=phase=='closed'and pending==0
        if relay then local p=relay.Progress();total=total+p.pending;complete=complete and p.complete end
        local count=0;for _,child in pairs(consumers)do if child then count=count+1;local p=child.Progress();total=total+p.pending;complete=complete and p.complete end end
        return{phase=phase,pending=total,consumers=count,relay=relay~=nil,errors=#errors,complete=complete and #errors==0,manifestApplied=false}
    end
    function api.Describe()
        local out={};for i,file in ipairs(files)do out[i]=file end
        return{files=out,side=side,manifestApplied=false,operationalReady=false,
            pending={'physical-qbx-resource','public-import-paths','metadata-version-detection','qb-core-owner-and-SetField','native-gateway-registration','authorized-boot'}}
    end
    return api
end
