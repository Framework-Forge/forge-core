-- Actual66,internal06,PR logging module/provider and57 tasks. All transport/clock/data virtual.
local C=dofile('tests/kernel_configuration_harness.lua');local W=dofile('tests/kernel_worker_harness.lua')
local H=C.H;local R={C=C,H=H,W=W,S=C.S}
function R.logging(clock)
    local r={clock=clock or W.clock(),libraryCalls={},batchRequests={},requests={},callbacks={},events={},encodings={},current=true}
    local api={cache={resource='forge-core'}}
    local env=H.environment({cache=api.cache,GetConvar=function(name,default)
        return({['ox:logger']='fivemanage',['fivemanage:key']='virtual-only-key',['sv_projectName']='^1Fixture'})[name]or default end,
        GetPlayerName=function(src)return'Virtual'..src end,GetNumPlayerIdentifiers=function()return 1 end,
        GetPlayerIdentifier=function()return'license:virtual'end,AddEventHandler=function(name,fn)r.events[name]=fn end,
        SetTimeout=r.clock.native.SetTimeout,warn=function(...)r.warnings=table.pack(...)end,
        json={encode=function(value)r.encodings[#r.encodings+1]=H.copy(value);return'virtual-json'end,decode=function(value)return value end},
        PerformHttpRequest=function(...)r.batchRequests[#r.batchRequests+1]=table.pack(...);local callback=select(2,...);callback(200,'',{},'')end})
    env.string.strsplit=function(separator,value)local out={};for part in value:gmatch('[^'..separator..']+')do out[#out+1]=part end;return table.unpack(out)end
    env.PRCore={load=function(name,scope)
        assert(name=='@pr_bridge/bridge/logging/providers/fivemanage');return H.load('../pr_bridge/bridge/logging/providers/fivemanage.lua',scope)
    end}
    local installed=H.load('../pr_bridge/bridge/logging/server.lua',env)(api)
    r.ports={logger=function(...)
            r.libraryCalls[#r.libraryCalls+1]=table.pack(...);if r.libraryError then error('virtual library logger error')end;return installed(...)
        end,isCurrent=function()return r.current end,httpRequest=function(url,cb,...)
            r.requests[#r.requests+1]=table.pack(url,...);r.callbacks[#r.callbacks+1]=cb
            if r.httpError then error('virtual HTTP publication error')end
            if not r.defer then cb(r.status or 204,'',r.headers or{})end
        end}
    r.factory=H.load('../pr_bridge/bridge/logging/forge_delivery.lua',H.environment())
    function r.mount()r.api=r.factory(r.ports);return r.api end
    return r
end
function R.hooks()
    local r=R.S.hooks(true);r.trace={};r.current=true
    local env=C.V.B.O.P.T.T.W.D.R.env()
    r.scope=H.load('kernel/modules/owned_hooks.lua',env)({hooks=r.ports,isCurrent=function()return r.current end})
    assert(r.scope.Open());return r
end
function R.context()
    local r=C.context();r.log=R.logging(r.clock);r.internal=R.S.hooks(true);r.internal.trace={}
    r.internal.ports.checkDependency=r.fixture.ports.central.runtime.library.checkDependency
    local logger=R.S.logger(true);r.loggerFixture=logger
    local lp=H.copy(logger.ports);lp.thread,lp.wait=r.clock.native.CreateThread,r.clock.native.Wait
    lp.getGameTimer=function()return r.clock.now end
    r.supportPorts={configurationContext=r.configurationPorts,hooks=r.internal.ports,logger=lp,
        createDelivery=r.log.factory,delivery=r.log.ports,createTasks=W.create,running=coroutine.running,public=r.surface.ports,
        onError=function(err,id)r.errors[#r.errors+1]={err=err,id=id}end}
    local env=C.V.B.O.P.T.T.W.D.R.env();local requireModule=env.require;r.supportCaptures={}
    local names={['kernel.server.player']='Player',['kernel.server.functions']='Functions',['kernel.server.events']='Events',
        ['kernel.server.commands']='Commands',['kernel.server.character']='Character'}
    env.require=function(name)local ctor=requireModule(name)
        if names[name]then return function(p)r.supportCaptures[names[name]]=p;return ctor(p)end end;return ctor end
    env.print=function(...)r.fixture.central.record('print',...)end
    r.supportFactory=H.load('kernel/server/support_context.lua',env)
    function r.prepareSupport()r.api=r.supportFactory(r.fixture.base,r.supportPorts);r.graph=r.api.Graph;return r.api end
    function r.supportInstall()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    function r.startSupport()assert(r.supportInstall());r.emit('onResourceStart','forge-core');r.begin();r.resume();assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[2]))end
    return r
end
return R
