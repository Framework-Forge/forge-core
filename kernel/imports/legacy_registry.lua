-- Private per-consumer script semantics. No ambient environment/public loader or second framework authority.
local createLib=require 'kernel.modules.lib'
local createUtils=require 'kernel.modules.utils'
local createLocale=require 'kernel.shared.locale'
local aliases={['modules.lib']='lib',['modules/lib.lua']='lib',['@qbx_core/modules/lib.lua']='lib',
    ['modules.utils']='utils',['modules/utils.lua']='utils',['@qbx_core/modules/utils.lua']='utils',
    ['shared.locale']='locale',['shared/locale.lua']='locale',['@qbx_core/shared/locale.lua']='locale'}
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(ports)
    local target,owner=assert(ports.environment),assert(ports.isCurrent)
    assert(type(target)=='table'and type(ports.isServer)=='boolean','explicit consumer environment/side required')
    local phase,entered='open',0;local modules,loaded,loading,ledger={},{},{},{}
    local api={OperationalReady=false,Environment=target}
    local function current()local ok,value=pcall(owner);return phase=='open'and ok and value==true end
    local function check()if not current()then error('legacy_import_closed',0)end end
    local function guarded(fn)return function(...)
        check();entered=entered+1;local result=table.pack(pcall(fn,...));entered=entered-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end end
    local wrapped={}
    local function wrapTree(value)
        if wrapped[value]then return value end;wrapped[value]=true
        for key,v in pairs(value)do
            if type(v)=='function'then value[key]=guarded(v)elseif type(v)=='table'then wrapTree(v)end
        end;return value
    end
    function api.OwnField(object,key,value)
        check();local record={object=object,key=key,before=rawget(object,key),value=value}
        ledger[#ledger+1]=record;rawset(object,key,value);return value
    end
    local function lib()
        if not modules.lib then
            local p=copy(ports.lib);p.isServer=ports.isServer
            modules.lib=wrapTree(createLib(p))
        end;return modules.lib
    end
    local function utils()
        if not modules.utils then
            local p=copy(ports.utils);p.isServer=ports.isServer;p.helpers=lib()
            modules.utils=createUtils(p)
        end;return modules.utils
    end
    local function execute(kind)
        if kind=='lib'then api.OwnField(target,'qbx',lib())
        elseif kind=='locale'then
            modules.locale=modules.locale or wrapTree(createLocale(assert(ports.locale)));api.OwnField(target,'Locale',modules.locale)
        else
            -- Match the installed file: warnings precede requiring lib; its cache remains loaded after qbx restoration.
            local warn=assert(ports.utils.library.print.warn)
            warn('This resource is still using the deprecated qbx_core utils!')
            warn('If you are the author, please update to use the new lib module. If you are not, please tell them to update!')
            local previous=rawget(target,'qbx');api.Require('modules.lib');rawset(target,'qbx',previous)
            local u=utils()
            for key,v in pairs(u)do
                if key~='Initialize'and key~='String'and key~='Math'then api.OwnField(target,key,type(v)=='function'and guarded(v)or v)end
            end
            for _,key in ipairs({'split','trim','firstToUpper'})do api.OwnField(assert(target.string),key,guarded(u.String[key]))end
            api.OwnField(assert(target.math),'round',guarded(u.Math.round))
        end
    end
    function api.Require(name)
        check();local kind=aliases[name];assert(kind,'unsupported_legacy_import: '..tostring(name))
        if loaded[kind]then return true end;assert(not loading[kind],'circular_legacy_import: '..name)
        loading[kind]=true;entered=entered+1;local ok,problem=pcall(execute,kind);entered=entered-1;loading[kind]=nil
        if not ok then error(problem,0)end;loaded[kind]=true;return true
    end
    function api.Has(name)return aliases[name]~=nil end
    function api.IsCurrent()return current()end
    function api.Close()
        phase='closed'
        for i=#ledger,1,-1 do local r=ledger[i]
            if rawget(r.object,r.key)==r.value then rawset(r.object,r.key,r.before)end
        end;return true
    end
    function api.Progress()return{phase=phase,pending=entered,complete=phase=='closed'and entered==0}end
    return api
end
