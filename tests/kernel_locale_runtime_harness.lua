-- Installed locale engine versus new PR factory/local Forge datasets. Codec/IO/providers/events remain virtual.
local R=dofile('tests/kernel_runtime_import_harness.lua');local S=dofile('tests/kernel_server_delivery_harness.lua')
local H,P=R.H,R.P;local T={R=R,S=S,H=H,P=P}
T.languages={'ar','bg','cn','cs','da','de','ee','en','es','et','fa','fi','fr','ge','he','hu','in','is','it','ja','lt','lv','nl','no','pl','pt-br','pt','ro','rs','ru','sl','sv','th','tr','vn','zh-tw'}
local function read(path)local f=io.open(path,'rb');if not f then return nil end;local s=f:read('*a');f:close();return s end
function T.provider(ported)
    local r={raw=R.provider(),current=true,lang='en',reads={},warnings={},pulls={}}
    local env=r.raw.env;env.GetConvar=function(key,fallback)assert(key=='ox:locale'and fallback=='en');return r.lang end
    H.load(R.ox..'resource/locale/server.lua',env)
    local function file(resource,path)
        assert(resource=='forge-core');local key=assert(path:match((ported and'^kernel/locales/'or'^locales/')..'([^/]*)%.json$'))
        r.reads[#r.reads+1]=key;if r.readHook then r.readHook(key)end
        if r.override and r.override[key]~=nil then return r.override[key]end
        return read((ported and'kernel/locales/'or H.qbx..'locales/')..key..'.json')
    end
    env.LoadResourceFile=file;env.warn=function(message)r.warnings[#r.warnings+1]=message:gsub('kernel/locales/','locales/')end
    env.exports.other={getLocale=function(self,key)assert(self==env.exports.other);r.pulls[#r.pulls+1]=key;return r.foreign end}
    r.ports={resource='forge-core',path='kernel/locales',readFile=file,decode=env.json.decode,warn=env.warn,
        merge=env.lib.table.merge,wipe=env.lib.table.wipe,getLocaleKey=env.lib.getLocaleKey,
        pullLocale=function(resource,key)return env.exports[resource]:getLocale(key)end,
        isCurrent=function()return r.current end,running=coroutine.running}
    r.factory=H.load('../pr_bridge/bridge/delivery/forge_locale.lua',H.environment())
    if ported then r.api=r.factory(r.ports)else
        -- Reload whole import so its resource-local loader captures the test boundary above.
        H.load(R.ox..'imports/locale/shared.lua',env)
        r.api={Initialize=env.lib.locale,Translate=env.locale,GetLocales=env.lib.getLocales,GetLocale=r.raw.exported.getLocale,PullLocale=env.lib.getLocale}
    end
    return r
end
function T.server()
    local r=S.context();r.locales=T.provider(true);r.serverCaptures={}
    local env=S.M.R.C.V.B.O.P.T.T.W.D.R.env();local req=env.require;env.print=function()end
    env.require=function(name)local ctor=req(name);if type(ctor)~='function'then return ctor end
        return function(...)local args=table.pack(...);local p=args[3]or args[2]or args[1]
            if type(p)=='table'then r.serverCaptures[name]=p end
            if name=='kernel.config.shared'then r.configCounts.shared=r.configCounts.shared+1 end
            if name=='kernel.config.server'then r.configCounts.server=r.configCounts.server+1 end
            return ctor(table.unpack(args,1,args.n))
        end
    end
    r.importPorts={deliveryContext=r.deliveryPorts,locale=r.locales.ports,createLocale=r.locales.factory,
        imports={nativeCache={resource='forge-core',game='fxserver'},running=coroutine.running},createImports=r.locales.raw.factory,
        localeBinding={listen=r.events.listen,remove=r.events.remove,available=r.surface.ports.available,publishExport=r.surface.ports.publishExport}}
    r.importFactory=H.load('kernel/server/runtime_import_context.lua',env)
    function r.allocate()r.api=r.importFactory(r.fixture.base,r.importPorts);return r.api end
    function r.prepareImports(key)
        if not r.api then r.allocate()end;assert(r.api.Prepare(key));r.graph=r.api.Graph
        r.keys.api=r.fixture.base.ServerVehicleContext.Vehicles;r.configuration.api=r.fixture.base.ServerConfigurationContext.Boundary
        return r.api
    end
    function r.installImports()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    function r.startImports()assert(r.installImports());r.emit('onResourceStart','forge-core');r.begin();r.resume();assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[2]))end
    return r
end
return T
