local L=dofile('tests/kernel_locale_runtime_harness.lua');local H=L.H;local T={L=L,H=H,P=L.P}
function T.new()
    local r=L.R.context();r.locales=L.provider(true);r.settings={locale='pt-br'};r.providerCallbacks={}
    local env=H.environment({lib={locale=function(key)r.initialClientKey=key end},cache={resource='ox_lib'},
        require=function(name)assert(name=='resource.settings');return r.settings end,
        RegisterNUICallback=function(name,fn)r.providerCallbacks[name]=fn end,
        TriggerEvent=function()end,SendNUIMessage=function()end,LoadResourceFile=function()return nil end,json={decode=function()return{}end}})
    H.load(L.R.ox..'resource/locale/client.lua',env);r.locales.ports.getLocaleKey=env.lib.getLocaleKey
    local contextEnv=L.R.C.C.M.S.W.D.A.E.env();contextEnv.type=r.fixture.modules.Stores.environment().type;contextEnv.print=function()end
    local req=contextEnv.require
    contextEnv.require=function(name)local ctor=req(name)
        if name=='kernel.config.client'then return function(p)r.configConstructions=r.configConstructions+1;return ctor(p)end end;return ctor
    end
    r.localePorts={runtimeContext=r.importPorts,locale=r.locales.ports,createLocale=r.locales.factory,
        localeBinding={listen=r.events.listen,remove=r.events.remove,available=r.surface.ports.available,publishExport=r.surface.ports.publishExport}}
    r.localeFactory=H.load('kernel/client/locale_context.lua',contextEnv);r.api=nil
    function r.allocate()r.api=r.localeFactory(r.fixture.state,r.localePorts);return r.api end
    function r.prepareLocale(key)if not r.api then r.allocate()end;assert(r.api.Prepare(key));r.graph=r.api.Graph;return r.api end
    function r.installLocale()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return T
